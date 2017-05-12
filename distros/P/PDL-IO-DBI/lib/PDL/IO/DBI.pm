package PDL::IO::DBI;

use strict;
use warnings;

use Exporter 'import';
our @EXPORT_OK   = qw(rdbi1D rdbi2D);
our %EXPORT_TAGS = (all => \@EXPORT_OK);

our $VERSION = '0.012';

use Config;
use constant NO64BITINT => ($Config{ivsize} < 8) ? 1 : 0;
use constant NODATETIME => eval { require PDL::DateTime; require Time::Moment; 1 } ? 0 : 1;
use constant DEBUG      => $ENV{PDL_IO_DBI_DEBUG} ? 1 : 0;

use PDL;
use DBI;
use Time::Moment;

use Carp;
$Carp::Internal{ (__PACKAGE__) }++;

my %pck = (
  byte     => "C",
  short    => "s",
  ushort   => "S",
  long     => "l",
  longlong => "q",
  float    => "f",
  double   => "d",
);

my %tmap = (
  DBI::SQL_TINYINT   => byte,        # -6
  DBI::SQL_BIGINT    => longlong,    # -5
  DBI::SQL_NUMERIC   => double,      #  2
  DBI::SQL_DECIMAL   => double,      #  3
  DBI::SQL_INTEGER   => long,        #  4
  DBI::SQL_SMALLINT  => short,       #  5
  DBI::SQL_FLOAT     => double,      #  6
  DBI::SQL_REAL      => float,       #  7
  DBI::SQL_DOUBLE    => double,      #  8
  DBI::SQL_DATETIME  => '_dt_',      #  9 == DBI::SQL_DATE
 #DBI::SQL_INTERVAL  => longlong,    # 10 == DBI::SQL_TIME
  DBI::SQL_TIMESTAMP => '_dt_',      # 11
  DBI::SQL_BOOLEAN   => byte,        # 16
  DBI::SQL_TYPE_DATE => '_dt_',      # 91
 #DBI::SQL_TYPE_TIME                 # 92
  DBI::SQL_TYPE_TIMESTAMP => '_dt_', # 93
 #DBI::SQL_TYPE_TIME_WITH_TIMEZONE   # 94
  DBI::SQL_TYPE_TIMESTAMP_WITH_TIMEZONE => '_dt_', # 95
 #DBI::SQL_INTERVAL_YEAR                 101
 #DBI::SQL_INTERVAL_MONTH                102
 #DBI::SQL_INTERVAL_DAY                  103
 #DBI::SQL_INTERVAL_HOUR                 104
 #DBI::SQL_INTERVAL_MINUTE               105
 #DBI::SQL_INTERVAL_SECOND               106
 #DBI::SQL_INTERVAL_YEAR_TO_MONTH        107
 #DBI::SQL_INTERVAL_DAY_TO_HOUR          108
 #DBI::SQL_INTERVAL_DAY_TO_MINUTE        109
 #DBI::SQL_INTERVAL_DAY_TO_SECOND        110
 #DBI::SQL_INTERVAL_HOUR_TO_MINUTE       111
 #DBI::SQL_INTERVAL_HOUR_TO_SECOND       112
 #DBI::SQL_INTERVAL_MINUTE_TO_SECOND     113
  ################## DBD::SQLite uses text values instead of numerical constants corresponding to DBI::SQL_*
  'BIGINT'           => longlong, # 8 bytes, -9223372036854775808 .. 9223372036854775807
  'INT8'             => longlong, # 8 bytes
  'INTEGER'          => long,     # 4 bytes, -2147483648 .. 2147483647
  'INT'              => long,     # 4 bytes
  'INT4'             => long,     # 4 bytes
  'MEDIUMINT'        => long,     # 3 bytes, -8388608 .. 8388607
  'SMALLINT'         => short,    # 2 bytes, -32768 .. 32767
  'INT2'             => short,    # 2 bytes
  'TINYINT'          => byte,     # 1 byte, MySQL: -128 .. 127, MSSQL+Pg: 0 to 255
  'REAL'             => float,    # 4 bytes
  'FLOAT'            => double,   # 8 bytes
  'NUMERIC'          => double,
  'DECIMAL'          => double,
  'DOUBLE'           => double,
  'DOUBLE PRECISION' => double,
  'BOOLEAN'          => byte,
  'SMALLSERIAL'      => short,    # 2 bytes, 1 to 32767
  'SERIAL'           => long,     # 4 bytes, 1 to 2147483647
  'BIGSERIAL'        => longlong, # 8 bytes, 1 to 9223372036854775807
  'DATETIME'         => '_dt_',
  'DATE'             => '_dt_',
  'TIMESTAMP'        => '_dt_',
);

# https://www.sqlite.org/datatype3.html
# http://dev.mysql.com/doc/refman/5.7/en/integer-types.html
# http://www.postgresql.org/docs/9.6/static/datatype-numeric.html
# http://msdn.microsoft.com/en-us/library/ff848794.aspx

sub _dt_to_double {
  my $str = shift;
  $str .= 'T00Z' if $str =~ m/^\d{4}-\d\d-\d\d$/;
  $str .= 'Z'    if $str !~ m/(?:UTC|GMT|Z|[\+\-]\d\d(?:\:\d\d)?)$/;
  my $t = eval { Time::Moment->from_string($str, lenient=>1) } or die "INVALID DATETIME: $str"; #XXX-FIXME PDL::dt2ll / dt2dbl ?
  return $t->epoch * 1.0 + $t->millisecond / 1_000;
}

sub _dt_to_longlong {
  my $str = shift;
  $str .= 'T00Z' if $str =~ m/^\d{4}-\d\d-\d\d$/;
  $str .= 'Z'    if $str !~ m/(?:UTC|GMT|Z|[\+\-]\d\d(?:\:\d\d)?)$/;
  my $t = eval { Time::Moment->from_string($str, lenient=>1) } or die "INVALID DATETIME: $str"; #XXX-FIXME PDL::dt2ll
  return $t->epoch*1_000_000 + $t->microsecond;
}

sub rdbi1D {
  my ($dbh, $sql, $bind_values, $O) = _proc_args(@_);

  # reuse_sth (if defined) is a scalar reference to a statement handle to be reused
  my $reuse_sth = $O->{reuse_sth};
  my $sth;
  if ($reuse_sth && $$reuse_sth) {
    $sth = $$reuse_sth;
  }
  else {
    $sth = $dbh->prepare($sql) or croak "FATAL: prepare failed: " . $dbh->errstr;
    $sth->execute(@$bind_values)  or croak "FATAL: execute failed: " . $sth->errstr;
    $$reuse_sth = $sth if $reuse_sth;
  }

  my ($c_type, $c_pack, $c_sizeof, $c_pdl, $c_bad, $c_dataref, $c_idx, $c_convert, $allocated, $cols) = _init_1D($sth->{TYPE}, $O);
  warn "Initial size: '$allocated'\n" if $O->{debug};
  my $null2bad = $O->{null2bad};
  my $processed = 0;
  my $headerline = $sth->{NAME_lc};

  warn "Fetching data (type=", join(',', @$c_type), ") ...\n" if $O->{debug};
  while (my $data = $sth->fetchall_arrayref(undef, $O->{fetch_chunk})) { # limiting MaxRows
    my $rows = scalar @$data;
    if ($rows > 0) {
      $processed += $rows;
      if ($allocated < $processed) {
        $allocated += $O->{reshape_inc};
        warn "Reshape to: '$allocated'\n" if $O->{debug};
        for (0..$cols-1) {
          $c_pdl->[$_]->reshape($allocated);
          $c_dataref->[$_] = $c_pdl->[$_]->get_dataref;
        }
      }
      if ($null2bad) {
        for my $tmp (@$data) {
          for (0..$cols-1) {
            unless (defined $tmp->[$_]) {
              $tmp->[$_] = $c_bad->[$_];
              $c_pdl->[$_]->badflag(1);
            }
          }
        }
      }
      if (scalar @$c_convert > 0) {
        for my $c (0..$cols-1) {
          if (ref $c_convert->[$c] eq 'CODE') {
            for my $r (0..$rows-1) {
              $data->[$r]->[$c] = $c_convert->[$c]->($data->[$r]->[$c]);
            }
          }
        }
      }
      for my $ci (0..$cols-1) {
        my $bytes = '';
        {
          no warnings 'pack'; # intentionally disable all pack related warnings
          no warnings 'numeric'; # disable: Argument ??? isn't numeric in pack
          no warnings 'uninitialized'; # disable: Use of uninitialized value in pack
          $bytes .= pack($c_pack->[$ci], $data->[$_][$ci]) for(0..$rows-1);
        }
        my $len = length $bytes;
        my $expected_len = $c_sizeof->[$ci] * $rows;
        croak "FATAL: len mismatch $len != $expected_len" if $len != $expected_len;
        substr(${$c_dataref->[$ci]}, $c_idx->[$ci], $len) = $bytes;
        $c_idx->[$ci] += $expected_len;
      }
    }
    last if $reuse_sth;
  }
  croak "FATAL: DB fetch failed: " . $sth->errstr if $sth->err;

  if ($processed != $allocated) {
    warn "Reshape to: '$processed' (final)\n" if $O->{debug};
    $c_pdl->[$_]->reshape($processed) for (0..$cols-1);
  }
  $c_pdl->[$_]->upd_data for (0..$cols-1);
  if (ref $headerline eq 'ARRAY') {
    for (0..$cols-1) {
      $c_pdl->[$_]->hdr->{col_name} = $headerline->[$_] if $headerline->[$_] && $headerline->[$_] ne '';
    };
  }

  if ($processed == 0) {
    if ($reuse_sth) {
      # signal to callers that all chunks have been fetched
      $$reuse_sth = undef;
    }
    else {
      warn "rdbi1D: no data\n";
    }
  }

  return @$c_pdl;
}

sub rdbi2D {
  my ($dbh, $sql, $bind_values, $O) = _proc_args(@_);

  croak 'FATAL: reuse_sth not supported yet for rdbi2D' if $O->{reuse_sth};
  my $sth = $dbh->prepare($sql) or croak "FATAL: prepare failed: " . $dbh->errstr;
  $sth->execute(@$bind_values) or croak "FATAL: execute failed: " . $sth->errstr;

  my ($c_type, $c_pack, $c_sizeof, $c_pdl, $c_bad, $c_dataref, $c_convert, $allocated, $cols) = _init_2D($sth->{TYPE}, $O);
  warn "Initial size: '$allocated'\n" if $O->{debug};
  my $null2bad = $O->{null2bad};
  my $processed = 0;
  my $c_idx = 0;
  my $pck = "$c_pack\[$cols\]";

  warn "Fetching data (type=$c_type) ...\n" if $O->{debug};
  while (my $data = $sth->fetchall_arrayref(undef, $O->{fetch_chunk})) { # limiting MaxRows
    my $rows = scalar @$data;
    if ($rows > 0) {
      $processed += $rows;
      if ($allocated < $processed) {
        $allocated += $O->{reshape_inc};
        warn "Reshape to: '$allocated'\n" if $O->{debug};
        $c_pdl->reshape($cols, $allocated);
        $c_dataref = $c_pdl->get_dataref;
      }
      my $bytes = '';
      if ($null2bad) {
        for my $tmp (@$data) {
          for (@$tmp) {
            unless (defined $_) {
              $_ = $c_bad;
              $c_pdl->badflag(1);
            }
          }
        }
      }
      if (scalar @$c_convert > 0) {
        for my $c (0..$cols-1) {
          if (ref $c_convert->[$c] eq 'CODE') {
            for my $r (0..$rows-1) {
              $data->[$r]->[$c] = $c_convert->[$c]->($data->[$r]->[$c]);
            }
          }
        }
      }
      {
          no warnings 'pack'; # intentionally disable all pack related warnings
          no warnings 'numeric'; # disable: Argument ??? isn't numeric in pack
          no warnings 'uninitialized'; # disable: Use of uninitialized value in pack
        $bytes .= pack($pck, @$_) for (@$data);
      }
      my $len = length $bytes;
      my $expected_len = $c_sizeof * $cols * $rows;
      croak "FATAL: len mismatch $len != $expected_len" if $len != $expected_len;
      substr($$c_dataref, $c_idx, $len) = $bytes;
      $c_idx += $len;
    }
  }
  croak "FATAL: DB fetch failed: " . $sth->errstr if $sth->err;
  if ($processed != $allocated) {
    warn "Reshape to: '$processed' (final)\n" if $O->{debug};
    $c_pdl->reshape($cols, $processed); # allocate the exact size
  }
  $c_pdl->upd_data;

  warn "rdbi2D: no data\n" unless $processed > 0;

  return $c_pdl->transpose;
}

sub _proc_args {
  my $options = ref $_[-1] eq 'HASH' ? pop : {};
  my ($dsn_or_dbh, $sql, $bind_values) = @_;

  croak "FATAL: no SQL query"  unless $sql;
  croak "FATAL: no DBH or DSN" unless defined $dsn_or_dbh;
  my $reuse_sth = $options->{reuse_sth};
  if ($reuse_sth) {
    croak "FATAL: reuse_sth must either be false, a reference to a false value, or a reference to a statement handle"
      if $$reuse_sth && !eval { $$reuse_sth->isa('DBI::st') };
  }
  my $O = { %$options }; # make a copy

  # handle defaults for optional parameters
  $O->{fetch_chunk} =  8_000 unless defined $O->{fetch_chunk};
  my $alloc = $reuse_sth ? $O->{fetch_chunk} : 80_000;
  $O->{reshape_inc} = $alloc unless defined $O->{reshape_inc};
  $O->{type}        = 'auto' unless defined $O->{type};
  $O->{debug}       = DEBUG  unless defined $O->{debug};

  # reshape_inc cannot be lower than fetch_chunk
  $O->{reshape_inc} = $O->{fetch_chunk} if $O->{reshape_inc} < $O->{fetch_chunk};

  $bind_values = [] unless ref $bind_values eq 'ARRAY';

  # launch db query
  my $dbh = ref $dsn_or_dbh ? $dsn_or_dbh : DBI->connect($dsn_or_dbh) or croak "FATAL: connect failed: " . $DBI::errstr;

  return ($dbh, $sql, $bind_values, $O);
}

sub _init_1D {
  my ($sql_types, $O) = @_;

  croak "FATAL: no columns" unless ref $sql_types eq 'ARRAY';
  my $cols = scalar @$sql_types;
  croak "FATAL: no columns" unless $cols > 0;

  my @c_type;
  my @c_pack;
  my @c_sizeof;
  my @c_pdl;
  my @c_bad;
  my @c_dataref;
  my @c_idx;
  my @c_convert;

  if (ref $O->{type} eq 'ARRAY') {
    @c_type = @{$O->{type}};
  }
  else {
    $c_type[$_] = $O->{type} for (0..$cols-1);
  }
  for (0..$cols-1) { $c_type[$_] = 'auto' if !$c_type[$_] }

  my @detected_type = map { $sql_types->[$_] ? $tmap{$sql_types->[$_]} : undef } (0..$cols-1);
  if ($O->{debug}) {
    $detected_type[$_] or warn "column $_ has unknown type '$sql_types->[$_]' gonna use Double\n" for (0..$cols-1);
  }
  my $allocated = $O->{reshape_inc};

  my @c_dt;
  for (0..$cols-1) {
    if ($detected_type[$_] && $detected_type[$_] eq '_dt_') {
      if (!NODATETIME && ($c_type[$_] eq 'auto' || $c_type[$_] eq 'datetime')) {
        croak "PDL::DateTime not installed" if NODATETIME;
        $c_convert[$_] = \&_dt_to_longlong;
        $c_type[$_] = longlong;
        $c_dt[$_] = 'datetime';
      }
      elsif ($c_type[$_] eq longlong) {
        $c_convert[$_] = \&_dt_to_longlong;
      }
      else {
        $c_convert[$_] = \&_dt_to_double;
        $c_type[$_] = double;
      }
    }
    $c_type[$_] = $detected_type[$_] if !defined $c_type[$_] || $c_type[$_] eq 'auto';
    $c_type[$_] = double if !$c_type[$_];
    $c_pack[$_] = $pck{$c_type[$_]};
    croak "FATAL: your perl does not support 64bitint (avoid using type longlong)" if $c_pack[$_] eq 'q' && NO64BITINT;
    croak "FATAL: invalid type '$c_type[$_]' for column $_" if !$c_pack[$_];
    $c_sizeof[$_] = length pack($c_pack[$_], 1);
    $c_pdl[$_] = $c_dt[$_] ? PDL::DateTime->new(zeroes(longlong, $allocated)) : zeroes($c_type[$_], $allocated);
    $c_dataref[$_] = $c_pdl[$_]->get_dataref;
    $c_bad[$_] = $c_pdl[$_]->badvalue;
    $c_idx[$_] = 0;
    my $big = PDL::Core::howbig($c_pdl[$_]->get_datatype);
    croak "FATAL: column $_ mismatch (type=$c_type[$_], sizeof=$c_sizeof[$_], big=$big)" if $big != $c_sizeof[$_];
  }

  return (\@c_type, \@c_pack, \@c_sizeof, \@c_pdl, \@c_bad, \@c_dataref, \@c_idx, \@c_convert, $allocated, $cols);
}

sub _init_2D {
  my ($sql_types, $O) = @_;

  croak "FATAL: no columns" unless ref $sql_types eq 'ARRAY';
  my $cols = scalar @$sql_types;
  croak "FATAL: no columns" unless $cols > 0;

  my $c_type = $O->{type};
  if (!$c_type || $c_type eq 'auto') {
    # try to guess the best type
    my @detected_type = map { $sql_types->[$_] ? $tmap{$sql_types->[$_]} : undef } (0..$cols-1);
    if ($O->{debug}) {
      $detected_type[$_] or warn "column $_ has unknown type '$sql_types->[$_]' gonna use Double\n" for (0..$cols-1);
    }
    for (0..$#detected_type) {
      # DATETIME is auto-detected as double
      $detected_type[$_] = 'double' if $detected_type[$_] && $detected_type[$_] eq '_dt_';
      my $dt = $detected_type[$_] || 'double';
      $c_type = double    if $dt eq double;
      $c_type = float     if $dt eq float    && $c_type ne double;
      $c_type = longlong  if $dt eq longlong && $c_type !~ /^(double|float)$/;
      $c_type = long      if $dt eq long     && $c_type !~ /^(double|float|longlong)$/;
      $c_type = short     if $dt eq short    && $c_type !~ /^(double|float|longlong|long)$/;
      $c_type = byte      if $dt eq byte     && $c_type !~ /^(double|float|longlong|long|short)$/;
    }
    croak "FATAL: type detection failed" if !$c_type;
  }
  my $c_pack = $pck{$c_type};
  croak "FATAL: your perl does not support 64bitint (avoid using type longlong)" if $c_pack eq 'q' && NO64BITINT;
  croak "FATAL: invalid type '$c_type' for column $_" if !$c_pack;

  my @c_convert = ();
  for (0..$cols-1) {
    my $t = $tmap{$sql_types->[$_]} || '';
    if ($t eq '_dt_') {
        $c_convert[$_] = ($c_type eq 'longlong') ? \&_dt_to_longlong : \&_dt_to_double;
    }
  }

  my $allocated = $O->{reshape_inc};
  my $c_sizeof = length pack($c_pack, 1);
  my $c_pdl = zeroes($c_type, $cols, $allocated);
  my $c_dataref = $c_pdl->get_dataref;
  my $c_bad = $c_pdl->badvalue;

  my $howbig = PDL::Core::howbig($c_pdl->get_datatype);
  croak "FATAL: column $_ size mismatch (type=$c_type, sizeof=$c_sizeof, howbig=$howbig)" unless  $howbig == $c_sizeof;

  return ($c_type, $c_pack, $c_sizeof, $c_pdl, $c_bad, $c_dataref, \@c_convert, $allocated, $cols);
}

1;

__END__

=head1 NAME

PDL::IO::DBI - Create PDL from database (optimized for speed and large data)

=head1 SYNOPSIS

  use PDL;
  use PDL::IO::DBI ':all';

  # simple usage - using DSN + SQL query
  my $sql = "select ymd, open, high, low, close from quote where symbol = 'AAPL' AND ymd >= 20140404 order by ymd";
  my $pdl = rdbi2D("dbi:SQLite:dbname=Quotes.db", $sql);

  use DBI;

  # using DBI handle + SQL query with binded values
  my $dbh = DBI->connect("dbi:Pg:dbname=QDB;host=localhost", 'username', 'password');
  my $sql = "select ymd, open, high, low, close from quote where symbol = ? AND ymd >= ? order by ymd";
  # rdbi2D
  my $pdl = rdbi2D($dbh, $sql, ['AAPL', 20140104]);                     # 2D piddle
  # rdbi1D
  my ($y, $o, $h, $l, $c) = rdbi1D($dbh, $sql, ['AAPL', 20140104]);     # 5x 1D piddle (for each column)

  # using DBI handle + SQL query with binded values + extra options
  my $dbh = DBI->connect("dbi:Pg:dbname=QDB;host=localhost", 'username', 'password');
  my $sql = "select ymd, open, high, low, close from quote where symbol = ? AND ymd >= ? order by ymd";
  my $pdl = rdbi2D($dbh, $sql, ['AAPL', 20140104], { type=>float, fetch_chunk=>100000, reshape_inc=>100000 });

=head1 DESCRIPTION

For creating a piddle from database data one can use the following simple approach:

  use PDL;
  use DBI;
  my $dbh = DBI->connect($dsn);
  my $pdl = pdl($dbh->selectall_arrayref($sql_query));

However this approach does not scale well for large data (e.g. SQL queries resulting in millions of rows).

This module is optimized for creating piddles populated with very large database data. It currently B<supports only
reading data from database> not updating/inserting to DB.

The goal of this module is to be as fast as possible. It is designed to silently converts anything into a number
(wrong or undefined values are converted into C<0>).

=head1 FUNCTIONS

By default, PDL::IO::DBI doesn't import any function. You can import individual functions like this:

 use PDL::IO::DBI 'rdbi2D';

Or import all available functions:

 use PDL::IO::DBI ':all';

=head2 rdbi1D

Queries the database and stores the data into 1D piddles.

 $sql_query = "SELECT high, low, avg FROM data where year > 2010";
 my ($high, $low, $avg) = rdbi1D($dbh_or_dsn, $sql_query);
 #or
 my ($high, $low, $avg) = rdbi1D($dbh_or_dsn, $sql_query, \@sql_query_params);
 #or
 my ($high, $low, $avg) = rdbi1D($dbh_or_dsn, $sql_query, \@sql_query_params, \%options);
 #or
 my ($high, $low, $avg) = rdbi1D($dbh_or_dsn, $sql_query, \%options);

Example:

  my ($id, $high, $low) = rdbi1D($dbh, 'SELECT id, high, low FROM sales ORDER by id');

  # column types:
  #   id   .. INTEGER
  #   high .. NUMERIC
  #   low  .. NUMERIC

  print $id->info, "\n";
  PDL: Long D [100000]          # == 1D piddle, 100 000 rows from DB

  print $high->info, "\n";
  PDL: Double D [100000]        # == 1D piddle, 100 000 rows from DB

  print $low->info, "\n";
  PDL: Double D [100000]        # == 1D piddle, 100 000 rows from DB

  # column names (lowercase) are stored in loaded piddles in $pdl->hdr->{col_name}
  print $id->hdr->{col_name},   "\n";  # prints: id
  print $high->hdr->{col_name}, "\n";  # prints: high
  print $low->hdr->{col_name},  "\n";  # prints: low

Parameters:

=over

=item dbh_or_dsn

L<DBI> handle of database connection or data source name.

=item sql_query

SQL query.

=item sql_query_params

Optional bind values that can be used for queries with placeholders.

=back

Items supported in B<options> hash:

=over

=item type

Defines the type of output piddles: C<double>, C<float>, C<longlong>, C<long>, C<short>, C<byte>.
Default value is C<auto> which means that the type of the output piddles is auto detected.
B<BEWARE:> type `longlong` can be used only on perls with 64bitint support.

You can set one type for all columns/piddles:

  my ($high, $low, $avg) = rdbi1D($dbh_or_dsn, $sql_query, {type => double});

or separately for each column/piddle:

  my ($high, $low, $avg) = rdbi1D($dbh_or_dsn, $sql_query, {type => [long, double, double]});

=item fetch_chunk

We do not try to load all query results into memory at once, we load them in chunks defined by this parameter.
Default value is C<8000> (rows). If C<reuse_sth> is true, C<rdbi1D> will
return one chunk per call, and the number of rows in a chunk will never exceed
C<fetch_chunk>.

=item reshape_inc

As we do not try to load all query results into memory at once; we also do not know at the beginning how
many rows there will be. Therefore we do not know how big piddle to allocate, we have to incrementally
(re)allocate the piddle by increments defined by this parameter. Default value is C<80000> (unless
C<reuse_sth> is used).

If you know how many rows there will be you can improve performance by setting this parameter to expected row count.

If you are using C<reuse_sth>, C<reshape_inc> is by default equal to
C<fetch_chunk> to avoid reallocations, but you could set it to a different
value if you wanted to.

=item null2bad

Values C<0> (default) or C<1> - convert NULLs to BAD values (there is a performance cost when turned on).

=item reuse_sth

Whether to reuse the statement handle used to fetch the rows.

When C<reuse_sth> is C<false>, all rows matching the select statement are
fetched at once, and the statement handle is never reused. Every new call to
rdbi1D will rerun the select statement and fetch the same rows again.

When C<reuse_sth> is not C<false>, it must be a reference (either to undef,
or to a statement handle). In this case, the operation mode changes: rdbi1D
will try to fetch C<fetch_chunk> rows from the database, B<and will return
early>. It will reuse the statement handle passed in via C<reuse_sth>. If a
reference to C<undef> is passed, rdbi1D will initialize the statement handle
itself. The idea is that you call rdbi1D repeatedly to obtain subsets of the
total number of rows in the database matching the select statement. This can be
useful if the logic to handle subsets is already present in your code, and you
don't need all rows in memory at once.

As an example, suppose you are calculating a minimum value. (You would probably
do this in the database directly, but it makes for a simple example.) You don't
need to have all matching rows in memory at once. Fetching chunk by chunk will
do just fine:

  my $N = 500_000;
  my $minimum;
  my $sth;
  for (;;) {
    my ($values) = rdbi1D($dbh, "SELECT value FROM table", {reuse_sth => \$sth, fetch_chunk => $N});
    last unless $sth;
    if (!defined($minimum) || $values->minimum->sclr < $minimum) { $minimum = $values->minimum->sclr }
  }

You can avoid the allocation of a single large PDL in this way. This wouldn't
help you much if the database was small. But if it was so large the resulting
PDL didn't fit in memory, working in chunks allows you to process all of the
data. Note that C<reshape_inc> will be set to the same value as C<fetch_chunk>
to avoid a reallocation to the chunk size, unless you explicitly set
C<reshape_inc> to another value.

Note that rdbi1D sets the reused statement handle to C<undef> if there are no
more chunks, i.e., when the database query returns no rows. You can use this to
your advantage to terminate the loop fetching the chunks, without having to
count the rows yourself.

=item debug

Values C<0> (default) or C<1> - turn on/off debug messages

=back

=head2 rdbi2D

Queries the database and stores the data into a 2D piddle.

  my $pdl = rdbi2D($dbh_or_dsn, $sql_query);
  #or
  my $pdl = rdbi2D($dbh_or_dsn, $sql_query, \@sql_query_params);
  #or
  my $pdl = rdbi2D($dbh_or_dsn, $sql_query, \@sql_query_params, \%options);
  #or
  my $pdl = rdbi2D($dbh_or_dsn, $sql_query, \%options);

Example:

  my $pdl = rdbi2D($dbh, 'SELECT id, high, low FROM sales ORDER by id');

  # column types:
  #   id   .. INTEGER
  #   high .. NUMERIC
  #   low  .. NUMERIC

  print $pdl->info, "\n";
  PDL: Double D [100000, 3]     # == 2D piddle, 100 000 rows from DB

Parameters and items supported in C<options> hash are the same as by L</rdbi1D>.
C<reuse_sth> is not supported yet for L</rdbi2D>.

=head1 Handling DATE, DATETIME, TIMESTAMP database types

By default DATETIME values are converted to C<double> value representing epoch seconds e.g.

 # 1970-01-01T00:00:01.001     >>          1.001
 # 2000-12-31T12:12:12.5       >>  978264732.5
 # BEWARE: timestamp is truncated to milliseconds
 # 2000-12-31T12:12:12.999001  >>  978264732.999
 # 2000-12-31T12:12:12.999999  >>  978264732.999

If you specify an output type C<longlong> for DATETIME column then the DATETIME values are converted
to C<longlong> representing epoch microseconds e.g.

 # 1970-01-01T00:00:01.001        >>          1001000
 # 2000-12-31T12:12:12.5          >>  978264732500000
 # 2000-12-31T12:12:12.999999     >>  978264732999999
 # BEWARE: timestamp is truncated to microseconds
 # 2000-12-31T12:12:12.999999001  >>  978264732999999
 # 2000-12-31T12:12:12.999999999  >>  978264732999999

If you have L<PDL::DateTime> installed then rcsv1D automaticcally converts DATETIME columns
to L<PDL::DateTime> piddles:

 # autodetection - same as: type=>'auto'
 my ($datetime_piddle, $pr) = rdbi1D("select mydate, myprice from sales");

 # or you can explicitely use type 'datetime'
 my ($datetime_piddle, $pr) = rdbi1D("select mydate, myprice from sales", {type=>['datetime', double]});

=head1 SEE ALSO

L<PDL>, L<DBI>

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=head1 COPYRIGHT

2014+ KMX E<lt>kmx@cpan.orgE<gt>

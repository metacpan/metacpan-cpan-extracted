package PDL::IO::CSV;

use strict;
use warnings;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK   = qw(rcsv1D rcsv2D wcsv1D wcsv2D);
our %EXPORT_TAGS = (all => \@EXPORT_OK);

our $VERSION = '0.011';

use Config;
use constant NO64BITINT => ($Config{ivsize} < 8) ? 1 : 0;
use constant NODATETIME => eval { require PDL::DateTime; require Time::Moment; 1 } ? 0 : 1;
use constant DEBUG      => $ENV{PDL_IO_CSV_DEBUG} ? 1 : 0;

use PDL;
use Text::CSV_XS;
use Scalar::Util qw(looks_like_number openhandle blessed);
use POSIX qw();
use Time::Piece;

use Carp;
$Carp::Internal{ (__PACKAGE__) }++;

sub import {
  my $package = shift;
  {
    no strict 'refs';
    *{'PDL::wcsv2D'} = \&wcsv2D if grep { /^(:all|wcsv2D)$/ } @_;
    *{'PDL::wcsv1D'} = \&wcsv1D if grep { /^(:all|wcsv1D)$/ } @_;
  }
  __PACKAGE__->export_to_level(1, $package, @_) if @_;
}

my %pck = (
  byte     => "C",
  short    => "s",
  ushort   => "S",
  long     => "l",
  longlong => "q",
  float    => "f",
  double   => "d",
);

sub wcsv1D {
  my ($fh, $O, $C) = _proc_wargs('1D', @_);

  my $cols = 0;
  my $rows = 0;
  my @c_pdl;
  my @c_rows;
  my @c_type;
  my @c_size;
  my @c_pack;
  my @c_dataref;
  my @c_offset;
  my @c_max_offset;
  my @c_bad;

  my $bad2empty = $O->{bad2empty};

  while (blessed $_[0] && $_[0]->isa('PDL')) {
    $c_pdl[$cols] = shift;
    croak "FATAL: wcsv1D() expects 1D piddles" unless $c_pdl[$cols]->ndims == 1;
    $c_size[$cols]       = PDL::Core::howbig($c_pdl[$cols]->get_datatype);
    $c_dataref[$cols]    = $c_pdl[$cols]->get_dataref;
    $c_offset[$cols]     = 0;
    my $type             = $c_pdl[$cols]->type;
    my $dim              = $c_pdl[$cols]->dim(0);
    $c_pack[$cols]       = $pck{$type};
    croak "FATAL: your perl does not support 64bitint (avoid using type longlong)" if $c_pack[$cols] eq 'q' && NO64BITINT;
    $c_max_offset[$cols] = $c_size[$cols] * $dim;
    $rows = $dim if $rows < $dim;
    if ($bad2empty && $c_pdl[$cols]->check_badflag) {
      my $b = pdl($type, 1)->setbadif(1);
      my $d = $b->get_dataref;
      $c_bad[$cols] = substr($$d, 0, $c_size[$cols]); # raw bytes representind BAD value
    }
    $cols++;
  }

  my $csv = Text::CSV_XS->new($C) or croak "" . Text::CSV_XS->error_diag();
  if ($O->{header}) {
    my $count = scalar @{$O->{header}};
    croak "FATAL: wrong header (expected $cols items, got $count)" if $cols != $count;
    $csv->print($fh, $O->{header});
  }
  for my $r (0..$rows-1) {
    my @v = ('') x $cols;
    for my $c (0..$cols-1) {
      if ($c_max_offset[$c] >= $c_offset[$c]) {
        if ($bad2empty && $c_bad[$c]) {
          my $v = substr(${$c_dataref[$c]}, $c_offset[$c], $c_size[$c]);
          if ($v ne $c_bad[$c]) {
            $v[$c] = unpack($c_pack[$c], $v);
            $v[$c] = PDL::DateTime::ll2dt($v[$c]) if ref $c_pdl[$c] eq 'PDL::DateTime';
          }
        }
        else {
          my $v = substr(${$c_dataref[$c]}, $c_offset[$c], $c_size[$c]);
          $v[$c] = unpack($c_pack[$c], $v);
          $v[$c] = PDL::DateTime::ll2dt($v[$c]) if ref $c_pdl[$c] eq 'PDL::DateTime';
        }
      }
      $c_offset[$c] += $c_size[$c];
    }
    $csv->print($fh, \@v);
  }
  #XXX close $fh;
}

sub wcsv2D {
  my $pdl = shift;
  my ($fh, $O, $C) = _proc_wargs('2D', @_);

  croak "FATAL: wcsv2D() expects 2D piddle" unless $pdl->ndims == 2;
  my $p = $pdl->transpose;

  my ($cols, $rows) = $p->dims;
  my $type = $p->type;
  my $size = PDL::Core::howbig($p->get_datatype);
  my $packC = $pck{$type} . "[$cols]";
  my $pack1 = $pck{$type};
  croak "FATAL: your perl does not support 64bitint (avoid using type longlong)" if $pck{$type} eq 'q' && NO64BITINT;
  my $dataref = $p->get_dataref;
  my $offset = 0;
  my $colsize = $size * $cols;
  my $max_offset = $colsize * ($rows - 1);
  my $bad;
  if ($O->{bad2empty} && $p->check_badflag) {
    my $b = pdl($type, 1)->setbadif(1);
    my $d = $b->get_dataref;
    $bad = substr($$d, 0, $size); # raw bytes representind BAD value
  }

  my $csv = Text::CSV_XS->new($C) or croak "" . Text::CSV_XS->error_diag();
  if ($O->{header}) {
    my $n = scalar @{$O->{header}};
    croak "FATAL: wrong header (expected $cols items, got $n)" if $cols != $n;
    $csv->print($fh, $O->{header});
  }
  while ($offset <= $max_offset) {
    if (defined $bad) {
      my @v = map { my $v = substr($$dataref, $offset + $_*$size, $size); $v eq $bad ? '' : unpack($pack1, $v) } (0..$cols-1);
      $csv->print($fh, \@v);
    }
    else {
      my @v = unpack($packC, substr($$dataref, $offset, $colsize));
      $csv->print($fh, \@v);
    }
    $offset += $colsize;
  }
  #XXX close $fh;
}

sub rcsv1D {
  my ($fh, $coli, $O, $C) = _proc_rargs('1D', @_);

  my ($c_type, $c_pack, $c_sizeof, $c_pdl, $c_bad, $c_dataref, $c_idx, $c_dt, $allocated, $cols); # initialize after we get 1st line

  my $csv = Text::CSV_XS->new($C) or croak "" . Text::CSV_XS->error_diag();
  my $processed = 0;
  my $finished = 0;
  my $chunk = $O->{fetch_chunk};
  my $empty2bad = $O->{empty2bad};
  my $text2bad  = $O->{text2bad};
  my $dec_comma = $O->{decimal_comma};

  warn "Fetching 1D " . _dbg_msg($O, $C) . "\n" if $O->{debug};
  # skip headers
  my $headerline;
  my $headerdetection;
  if (looks_like_number($O->{header})) {
    if ($O->{header} == 1) {
      # get the header line (only if skipping exactly 1 line)
      $headerline = $csv->getline($fh);
    }
    else {
      $csv->getline($fh) for (1..$O->{header});
    }
  }
  elsif ($O->{header} && $O->{header} eq 'auto') {
    $headerdetection = 1;
  }

  while (!$finished) {
    my $rows = 0;
    my @bytes;
    my $r;
    while ($rows < $chunk) {
      my $r = $csv->getline($fh);
      if (defined $r) {
        if (defined $headerdetection) {
          my $numeric = 0;
          for (@$r) {
            if (looks_like_number($_)) {
              $numeric++;
            }
            elsif (!NODATETIME) {
              my $v = $O->{strptime} ? _strptime($_, $O->{strptime}) : PDL::DateTime::dt2ll($_);
              $numeric++ if defined $v;
            }
          }
          if ($numeric == 0) {
            # no numeric values found => skip this line but keep it as a potential header
            $headerline = $r;
            next;
          }
          $headerdetection = undef;
        }
        unless (defined $c_type) {
          ($c_type, $c_pack, $c_sizeof, $c_pdl, $c_bad, $c_dataref, $c_idx, $c_dt, $allocated, $cols) = _init_1D($coli, $r, $O);
          warn "Initialized size=$allocated, cols=$cols, type=".join(",",@$c_type)."\n" if $O->{debug};
        }
        if ($dec_comma) {
          for (@$r) { s/,/./ if defined $_ };
        }
        if ($empty2bad) {
          if (defined $coli) {
            for (0..$cols-1) {
              my $i = $coli->[$_];
              unless (defined $r->[$i]) { $r->[$i] = $c_bad->[$_]; $c_pdl->[$_]->badflag(1) }
            }
          }
          else {
            for (0..$cols-1) {
              unless (defined $r->[$_]) { $r->[$_] = $c_bad->[$_]; $c_pdl->[$_]->badflag(1) }
            }
          }
        }
        if (defined $c_dt) {
          for (0..$cols-1) {
            next unless defined $c_dt->[$_];
            my $v = $c_dt->[$_] ne 'datetime' ? _strptime($r->[$_], $c_dt->[$_]) : PDL::DateTime::dt2ll($r->[$_]);
            if (defined $v) {
              $r->[$_] = $v;
            }
            else {
              $r->[$_] = $c_bad->[$_];
              $c_pdl->[$_]->badflag(1);
            }
          }
        }
        if ($text2bad) {
          if (defined $coli) {
            for (0..$cols-1) {
              my $i = $coli->[$_];
              unless (looks_like_number($r->[$i])) { $r->[$i] = $c_bad->[$_]; $c_pdl->[$_]->badflag(1) }
            }
          }
          else {
            for (0..$cols-1) {
              unless (looks_like_number($r->[$_])) { $r->[$_] = $c_bad->[$_]; $c_pdl->[$_]->badflag(1) }
            }
          }
        }
        if (defined $coli) { # only selected columns
          no warnings 'pack'; # intentionally disable all pack related warnings
          no warnings 'numeric'; # disable: Argument ??? isn't numeric in pack
          no warnings 'uninitialized'; # disable: Use of uninitialized value in pack
          $bytes[$_] .= pack($c_pack->[$_], $r->[$coli->[$_]]) for (0..$cols-1);
        }
        else { # all columns
          no warnings 'pack'; # intentionally disable all pack related warnings
          no warnings 'numeric'; # disable: Argument ??? isn't numeric in pack
          no warnings 'uninitialized'; # disable: Use of uninitialized value in pack
          $bytes[$_] .= pack($c_pack->[$_], $r->[$_]) for (0..$cols-1);
        }
        $rows++;
      }
      else {
        $finished = 1;
        last;
      }
    }
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
      for my $ci (0..$cols-1) {
        my $len = length $bytes[$ci];
        my $expected_len = $c_sizeof->[$ci] * $rows;
        croak "FATAL: len mismatch $len != $expected_len" if $len != $expected_len;
        substr(${$c_dataref->[$ci]}, $c_idx->[$ci], $len) = $bytes[$ci];
        $c_idx->[$ci] += $expected_len;
      }
    }
  }

  #XXX close $fh;
  if (ref $c_pdl eq 'ARRAY') {
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
    return @$c_pdl;
  }

  warn "rcsv1D: no data\n";
  return undef;
}

sub rcsv2D {
  my ($fh, $coli, $O, $C) = _proc_rargs('2D', @_);

  my ($c_type, $c_pack, $c_sizeof, $c_pdl, $c_bad, $c_dataref, $allocated, $cols);

  my $csv = Text::CSV_XS->new($C) or croak "" . Text::CSV_XS->error_diag();
  my $processed = 0;
  my $c_idx = 0;
  my $finished;
  my $pck;
  my $chunk = $O->{fetch_chunk};
  my $empty2bad = $O->{empty2bad};
  my $text2bad  = $O->{text2bad};
  my $dec_comma = $O->{decimal_comma};
  my $bcount = 0;

  warn "Fetching 2D " . _dbg_msg($O, $C) . "\n" if $O->{debug};
  if ($O->{header}) {
    $csv->getline($fh) for (1..$O->{header});
  }
  while (!$finished) {
    my $bytes = '';
    my $rows = 0;
    while ($rows < $chunk) {
      my $r = $csv->getline($fh);
      if (defined $r) {
        unless (defined $pck) {
          ($c_type, $c_pack, $c_sizeof, $c_pdl, $c_bad, $c_dataref, $allocated, $cols) = _init_2D($coli, scalar @$r, $O);
          warn "Initialized size=$allocated, cols=$cols, type=$c_type\n" if $O->{debug};
          $pck = "$c_pack\[$cols\]";
        }
        if ($dec_comma) {
          for (@$r) { s/,/./ if defined $_ };
        }
        if ($empty2bad) {
          if (defined $coli) {
            for (0..$cols-1) {
              my $i = $coli->[$_];
              unless (defined $r->[$i]) { $r->[$i] = $c_bad; $c_pdl->badflag(1) }
            }
          }
          else {
            for (0..$cols-1) {
              unless (defined $r->[$_]) { $r->[$_] = $c_bad; $c_pdl->badflag(1) }
            }
          }
        }
        if ($text2bad) {
          if (defined $coli) {
            for (0..$cols-1) {
              my $i = $coli->[$_];
              unless (looks_like_number($r->[$i])) { $r->[$i] = $c_bad; $c_pdl->badflag(1) }
            }
          }
          else {
            for (0..$cols-1) {
              unless (looks_like_number($r->[$_])) { $r->[$_] = $c_bad; $c_pdl->badflag(1) }
            }
          }
        }
        if (defined $coli) { # only selected columns
          no warnings 'pack'; # intentionally disable all pack related warnings
          no warnings 'numeric'; # disable: Argument ??? isn't numeric in pack
          no warnings 'uninitialized'; # disable: Use of uninitialized value in pack
          $bytes .= pack($pck, map { $r->[$_] } @$coli);
        }
        else { # all columns
          no warnings 'pack'; # intentionally disable all pack related warnings
          no warnings 'numeric'; # disable: Argument ??? isn't numeric in pack
          no warnings 'uninitialized'; # disable: Use of uninitialized value in pack
          $bytes .= pack($pck, @$r);
        }
        $rows++;
      }
      else {
        $finished = 1;
        last;
      }
    }
    if ($rows > 0) {
      $processed += $rows;
      if ($allocated < $processed) {
        $allocated += $O->{reshape_inc};
        warn "Reshaping to $allocated\n" if $O->{debug};
        $c_pdl->reshape($cols, $allocated);
        $c_dataref = $c_pdl->get_dataref;
      }
      my $len = length $bytes;
      my $expected_len = $c_sizeof * $cols * $rows;
      croak "FATAL: len mismatch $len != $expected_len" if $len != $expected_len;
      substr($$c_dataref, $c_idx, $len) = $bytes;
      $c_idx += $len;
    }
  }

  #XXX close $fh;

  if (blessed $c_pdl && $c_pdl->isa('PDL')) {
    if ($processed != $allocated) {
      warn "Reshaping to $processed (final)\n" if $O->{debug};
      $c_pdl->reshape($cols, $processed); # allocate the exact size
    }
    $c_pdl->upd_data;
    return $c_pdl->transpose;
  }

  warn "rcsv2D: no data\n";
  return undef;
}

sub _dbg_msg {
  my ($O, $C) = @_;
  sprintf "chunk=%s, reshape=%s, bad=%s/%s, sep_char='%s'",
        $O->{fetch_chunk} ||= '?',
        $O->{reshape_inc} ||= '?',
        $O->{empty2bad}   ||= '?',
        $O->{text2bad}    ||= '?',
        $C->{sep_char}    ||= '?';
}

sub _proc_wargs {
  my $options        = ref $_[-1] eq 'HASH' ? pop : {};
  my $filename_or_fh = !blessed $_[-1] || !$_[-1]->isa('PDL') ? pop : undef;
  my $fn = shift;

  my $C = { %$options }; # make a copy

  my @keys = qw/ debug header bad2empty encoding /;
  my $O = { map { $_ => delete $C->{$_} } @keys };
  $O->{debug}     = DEBUG unless defined $O->{debug};
  $O->{bad2empty} = 1     unless defined $O->{bad2empty};
  $O->{header}    = ($fn eq '1D' ? 'auto' : 0) if !defined $O->{header};

  # explicitely set
  $C->{sep_char} = ','  unless defined $C->{sep_char};
  $C->{eol}      = "\n" unless defined $C->{eol};

  if (defined $O->{header}) {
    croak "FATAL: header should be arrayref" unless ref $O->{header} eq 'ARRAY' || $O->{header} eq 'auto';
    if ($O->{header} eq 'auto') {
      my @n;
      my $count = 0;
      for (@_) {
        push @n, my $n = $_->hdr->{col_name};
        $count++ if defined $n;
      }
      $O->{header} = $count > 0 ? \@n : undef;
    }
  }

  my $fh;
  if (!defined $filename_or_fh) {
    $fh = \*STDOUT;
  }
  elsif (openhandle($filename_or_fh)) {
    $fh = $filename_or_fh;
  }
  else {
    open $fh, ">", $filename_or_fh or croak "$filename_or_fh: $!";
  }
  binmode $fh, $O->{encoding} if $O->{encoding};

  return ($fh, $O, $C);
}

sub _proc_rargs {
  my $options = ref $_[-1] eq 'HASH' ? pop : {};
  my ($fn, $filename_or_fh, $coli) = @_;

  croak "FATAL: invalid column ids" if defined $coli && ref $coli ne 'ARRAY';
  croak "FATAL: invalid filename"   unless defined $filename_or_fh;
  my $C = { %$options }; # make a copy

  # get options related to this module the rest will be passed to Text::CSV_XS
  my @keys = qw/ reshape_inc fetch_chunk type debug empty2bad text2bad header decimal_comma encoding detect_datetime /;
  my $O = { map { $_ => delete $C->{$_} } @keys };
  $O->{fetch_chunk} ||= 40_000;
  $O->{reshape_inc} ||= 80_000;
  $O->{type}        ||= ($fn eq '1D' ? 'auto' : double);
  $O->{header}      ||= ($fn eq '1D' ? 'auto' : 0);
  if (!NODATETIME) {
    $O->{detect_datetime} = 1 if !defined $O->{detect_datetime};
    if ($O->{detect_datetime} =~ /%/) {
      $O->{strptime} = $O->{detect_datetime};
      $O->{detect_datetime} = 1;
    }
  }
  $O->{debug} = DEBUG unless defined $O->{debug};

  # reshape_inc cannot be lower than fetch_chunk
  $O->{reshape_inc} = $O->{fetch_chunk} if $O->{reshape_inc} < $O->{fetch_chunk};

  # explicitely set column separator default
  $C->{sep_char} = ',' unless defined $C->{sep_char};

  # empty2bad implies some Text::CSV_XS extra options
  if ($O->{empty2bad}) {
    $C->{blank_is_undef} = 1;
    $C->{empty_is_undef} = 1;
  }

  croak "FATAL: cannot use decimal_comma + sep_char ','" if $O->{decimal_comma} && $C->{sep_char} eq ',';

  my $fh;
  if (openhandle($filename_or_fh)) {
    $fh = $filename_or_fh;
  }
  else {
    open $fh, "<", $filename_or_fh or croak "$filename_or_fh: $!";
  }
  binmode $fh, $O->{encoding} if $O->{encoding};

  return ($fh, $coli, $O, $C);
}

sub _init_1D {
  my ($coli, $firstline, $O) = @_;
  my $colcount = scalar @$firstline;
  my $cols;
  if (!defined $coli) {    # take all columns
    $cols = $colcount;
  }
  else {
    $cols = scalar @$coli;
    ($_<0 || $_>$colcount) and croak "FATAL: invalid column '$_' (column count=$colcount)" for (@$coli);
  }
  croak "FATAL: invalid column count" unless $cols && $cols > 0 && $cols <= $colcount;

  my @c_type;
  my @c_pack;
  my @c_sizeof;
  my @c_pdl;
  my @c_bad;
  my @c_dataref;
  my @c_idx;

  if (ref $O->{type} eq 'ARRAY') {
    $c_type[$_] = $O->{type}->[$_] for (0..$cols-1);
  }
  else {
    $c_type[$_] = $O->{type} for (0..$cols-1);
  }

  my @c_dt;
  for (0..$cols-1) {
    if (!defined $c_type[$_] || $c_type[$_] eq 'auto') {
      $c_type[$_] = undef;
      if ($O->{detect_datetime}) {
        croak "PDL::DateTime not installed" if NODATETIME;
        my $v = $O->{strptime} ? _strptime($firstline->[$_], $O->{strptime}) : PDL::DateTime::dt2ll($firstline->[$_]);
        if (defined $v) {
          $c_dt[$_] = $O->{strptime} ? $O->{strptime} : 'datetime';
          $c_type[$_] = longlong;
        }
      }
    }
    elsif ($c_type[$_] eq 'datetime') {
      croak "PDL::DateTime not installed" if NODATETIME;
      $c_dt[$_] = 'datetime';
      $c_type[$_] = longlong;
    }
    elsif ($c_type[$_] =~ /%/) {
      $c_dt[$_] = $c_type[$_]; # strptime format
      $c_type[$_] = longlong;
    }
    $c_type[$_] = double if !$c_type[$_];
  }

  my $allocated = $O->{reshape_inc};
  for (0..$cols-1) {
    $c_type[$_] = double if !defined $c_type[$_];
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

  return (\@c_type, \@c_pack, \@c_sizeof, \@c_pdl, \@c_bad, \@c_dataref, \@c_idx, (@c_dt > 0 ? \@c_dt : undef), $allocated, $cols);
}

sub _init_2D {
  my ($coli, $colcount, $O) = @_;

  my $cols;
  if (!defined $coli) {    # take all columns
    $cols = $colcount;
  }
  else {
    $cols = scalar @$coli;
    ($_<0 || $_>$colcount) and croak "FATAL: invalid column '$_' (column count=$colcount)" for (@$coli);
  }
  croak "FATAL: invalid column count" unless $cols && $cols > 0 && $cols <= $colcount;

  my $c_type = $O->{type};
  my $c_pack = $pck{$c_type};
  croak "FATAL: your perl does not support 64bitint (avoid using type longlong)" if $c_pack eq 'q' && NO64BITINT;
  croak "FATAL: invalid type '$c_type' for column $_" if !$c_pack;

  my $allocated = $O->{reshape_inc};
  my $c_sizeof = length pack($c_pack, 1);
  my $c_pdl = zeroes($c_type, $cols, $allocated);
  my $c_dataref = $c_pdl->get_dataref;
  my $c_bad = $c_pdl->badvalue;

  my $big = PDL::Core::howbig($c_pdl->get_datatype);
  croak "FATAL: column $_ size mismatch (type=$c_type, sizeof=$c_sizeof, big=$big)" if $big != $c_sizeof;

  return ($c_type, $c_pack, $c_sizeof, $c_pdl, $c_bad, $c_dataref, $allocated, $cols);
}

sub _strptime {
  my ($string, $format) = @_;
  return eval { int POSIX::floor(Time::Piece->strptime($string, $format)->epoch * 1_000_000 + 0.5) };
}

1;

__END__

=head1 NAME

PDL::IO::CSV - Load/save PDL from/to CSV file (optimized for speed and large data)

=head1 SYNOPSIS

  use PDL;
  use PDL::IO::CSV ':all';

  my $pdl = rcsv2D('input.csv');
  $pdl *= 2;
  wcsv2D($pdl, 'double.csv');

  my ($pdl1, $pdl2, $pdl3) = rcsv1D('input.csv', [0, 1, 6]);
  wcsv1D($pdl1, 'col2.csv');
  #or
  $pdl2->wcsv1D('col2.csv');
  $pdl2->wcsv1D('col2_tabs.csv', {sep_char=>"\t"});

=head1 DESCRIPTION

The traditional way of creating PDL piddle from CSV data is via L<rcols|PDL::IO::Misc/rcols> function.

 my $pdl = rcols("data.csv", [1..4], { DEFTYPE=>double, COLSEP=>"," });

This module provides alternative implementation based on L<Text::CSV_XS> which should be significantly faster than
traditional approach.

PDL::IO::CSV supports reading CSV data and creating PDL piddle(s) as well as saving PDL data to CSV file.

=head1 FUNCTIONS

By default, PDL::IO::CSV doesn't import any function. You can import individual functions like this:

 use PDL::IO::CSV qw(rcsv2D wcsv2D);

Or import all available functions:

 use PDL::IO::CSV ':all';

=head2 rcsv1D

Loads data from CSV file into 1D piddles (separate for each column).

  my ($pdl1, $pdl2, $pdl3) = rcsv1D($csv_filename_or_filehandle);
  #or
  my ($pdl1, $pdl2, $pdl3) = rcsv1D($csv_filename_or_filehandle, \@column_ids);
  #or
  my ($pdl1, $pdl2, $pdl3) = rcsv1D($csv_filename_or_filehandle, \%options);
  #or
  my ($pdl1, $pdl2, $pdl3) = rcsv1D($csv_filename_or_filehandle, \@column_ids, \%options);

Parameters:

=over

=item csv_filename_or_filehandle

Path to CSV file to be loaded or a filehandle open for reading.

=item column_ids

Optional column indices (0-based) defining which columns to load from CSV file.
Default is C<undef> which means to load all columns.

=back

Items supported in B<options> hash:

=over

=item * type

Defines the type of output piddles: C<double>, C<float>, C<longlong>, C<long>, C<short>, C<byte>.
Default value is C<double>. B<BEWARE:> type `longlong` can be used only on perls with 64bitint support.

You can set one type for all columns/piddles:

  my ($a, $b, $c) = rcsv1D($csv, {type => double});

or separately for each column/piddle:

  my ($a, $b, $c) = rcsv1D($csv, {type => [long, double, double]});

Special datetime handling (you need to have L<PDL::DateTime> installed):

  my ($a, $b, $c) = rcsv1D($csv, {type => [long, 'datetime', double]});
  # piddle $b will be an instance of PDL::DateTime

or

  my ($a, $b, $c) = rcsv1D($csv, {type => [long, '%m/%d/%Y', double]});
  # piddle $b will be an instance of PDL::DateTime

or you cat let PDL::IO::CSV try to detect datetime columns (detection is based only on the first csv line)

  my ($a, $b, $c) = rcsv1D($csv, {detect_datetime=>1});

=item * detect_datetime

Values C<1> (default) or C<0>. Try to detect datetime columns, corresponding output piddles will be
instances of L<PDL::Datetime> (which you need to have installed).

Value C<1> means: try to detect datetime in ISO8601 format, e.g. C<'2016-12-16 11:59'>.

You can also specify a value as strptime format string, e.g. C<'%m/%d/%Y %H:%M:%S'>.

=item * fetch_chunk

We do not try to load all CSV data into memory at once; we load them in chunks defined by this parameter.
Default value is C<40000> (CSV rows).

=item * reshape_inc

As we do not try to load the whole CSV file into memory at once, we also do not know at the beginning how
many rows there will be. Therefore we do not know how big piddle to allocate, we have to incrementally
(re)allocated the piddle by increments defined by this parameter. Default value is C<80000>.

If you know how many rows there will be you can improve performance by setting this parameter to expected row count.

=item * empty2bad

Values C<0> (default) or C<1> - convert empty cells to BAD values (there is a performance cost when turned on).
If not enabled the empty values are silently converted into C<0>.

=item * text2bad

Values C<0> (default) or C<1> - convert values that don't pass L<looks_like_number|Scalar::Util/looks_like_number>
check to BAD values (there is a significant performance cost when turned on). If not enabled these non-numerical
values are silently converted into C<0>.

=item * header

Values C<0> or C<N> (positive integer) - consider the first C<N> lines as headers and skip them.
BEWARE: we are talking here about skipping CSV lines which in some cases might be more than 1 text line.

NOTE: header values (if any) are considered to be column names and are stored in loaded piddles in $pdl->hdr->{col_name}

NOTE: C<rcsv1D> accepts a special C<header> value C<'auto'> which skips rows (from beginning) that have
in all columns non-numeric values.

Default: for C<rcsv1D> - C<'auto'>; for C<rcsv2D> - C<0>.

=item * decimal_comma

Values C<0> (default) or C<1> - accept C<,> (comma) as a decimal separator (there is a performance cost when turned on).

=item * encoding

Optional enconding e.g. C<:utf8> (default C<undef>) that will be applied on input filehandle.

=item * debug

Values C<0> (default) or C<1> - turn on/off debug messages

=item * sep_char

Value separator, default value C<,> (comma).

=item * and all other options valid for L<new|Text::CSV_XS/new> method of L<Text::CSV_XS>

=back

=head2 rcsv2D

Loads data from CSV file into 2D piddle.

  my $pdl = rcsv2D($csv_filename_or_filehandle);
  #or
  my $pdl = rcsv2D($csv_filename_or_filehandle, \@column_ids);
  #or
  my $pdl = rcsv2D($csv_filename_or_filehandle, \%options);
  #or
  my $pdl = rcsv2D($csv_filename_or_filehandle, \@column_ids, \%options);

Parameters and items supported in C<options> hash are the same as by L</rcsv1D>.

=head2 wcsv1D

Saves data from one or more 1D piddles to CSV file.

  wcsv1D($pdl1, $pdl2, $pdl3, $csv_filename_or_filehandle, \%options);
  #or
  wcsv1D($pdl1, $pdl2, $pdl3, $csv_filename_or_filehandle);
  #or
  wcsv1D($pdl1, $pdl2, \%options); #prints to STDOUT
  #or
  wcsv1D($pdl1, $pdl2);

  # but also as a piddle method
  $pdl1D->wcsv1D("file.csv");

NOTE: piddles piddles are instances of L<PDL::DateTime> are exported by wcsv1D as ISO 8601 strings.

Parameters:

=over

=item piddles

One or more 1D piddles. All has to be 1D but may have different count of elements.

=item csv_filename_or_filehandle

Path to CSV file to write to or a filehandle open for writing. Default is STDOUT.

=back

Items supported in B<options> hash:

=over

=item * header

Arrayref with values that will be printed as the first CSV line. Or C<'auto'> value which means that column
names are taken from $pdl->hdr->{col_name}.

Default: for C<wcsv1D> - C<'auto'>; for C<wcsv2D> - C<undef>.

=item * bad2empty

Values C<0> or C<1> (default) - convert BAD values into empty strings (there is a performance cost when turned on).

=item * encoding

Optional enconding e.g. C<:utf8> (default C<undef>) that will be applied on output filehandle.

=item * debug

Values C<0> (default) or C<1> - turn on/off debug messages

=item * sep_char

Value separator, default value C<,> (comma).

=item * eol

New line separator, default value C<\n> (UNIX newline).

=item * and all other options valid for L<new|Text::CSV_XS/new> method of L<Text::CSV_XS>

=back

=head2 wcsv2D

Saves data from one 2D piddle to CSV file.

  wcsv2D($pdl, $csv_filename_or_filehandle, \%options);
  #or
  wcsv2D($pdl, $csv_filename_or_filehandle);
  #or
  wcsv2D($pdl, \%options); #prints to STDOUT
  #or
  wcsv2D($pdl);

  # but also as a piddle method
  $pdl->wcsv2D("file.csv");

Parameters and items supported in C<options> hash are the same as by L</wcsv1D>.

=head1 SEE ALSO

L<PDL>, L<Text::CSV_XS>

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=head1 COPYRIGHT

2014+ KMX E<lt>kmx@cpan.orgE<gt>

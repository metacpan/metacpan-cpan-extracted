package PDL::IO::XLSX;
use 5.010;
use strict;
use warnings;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK   = qw(rxlsx1D rxlsx2D wxlsx1D wxlsx2D);
our %EXPORT_TAGS = (all => \@EXPORT_OK);

our $VERSION = '0.004';

use Config;
use constant DEBUG => $ENV{PDL_IO_XLSX_DEBUG} ? 1 : 0;

use PDL;
use PDL::IO::XLSX::Writer;
use PDL::IO::XLSX::Reader;
use Scalar::Util qw(looks_like_number blessed);

use Carp;
$Carp::Internal{ (__PACKAGE__) }++;

sub import {
  my $package = shift;
  {
    no strict 'refs';
    *{'PDL::wxlsx2D'} = \&wxlsx2D if grep { /^(:all|wxlsx2D)$/ } @_;
    *{'PDL::wxlsx1D'} = \&wxlsx1D if grep { /^(:all|wxlsx1D)$/ } @_;
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

sub _serialdate2longlong {
  my $v = shift; # MS Excel serial datetime
  my $epoch_miliseconds_float = ($v - 25569) * 24 * 60 * 60 * 1000;
  return 1000 * int POSIX::floor($epoch_miliseconds_float + 0.5); # longlong epoch microseconds
}

sub _longlong2serialdate {
  my $v = shift;
  # return MS Excel serial datetime (with microsecond-only precision)
  return 25569 + ( int($v / 1000) / (24 * 60 * 60 * 1000) );
}

sub wxlsx1D {
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

  my %alias = (
    '%Y-%m-%d'              => [ 11, 'yyyy\-mm\-dd' ],
    '%Y-%m-%dT%H:%M'        => [ 16, 'yyyy\-mm\-dd\ hh:mm' ],
    '%Y-%m-%dT%H:%M:%S'     => [ 18, 'yyyy\-mm\-dd\ hh:mm:ss' ],
    '%Y-%m-%dT%H:%M:%S.%3N' => [ 22, 'yyyy\-mm\-dd\ hh:mm:ss.000' ],
    '%Y-%m-%dT%H:%M:%S.%6N' => [ 22, 'yyyy\-mm\-dd\ hh:mm:ss.000' ],
  );

  my $bad2empty = $O->{bad2empty};

  my @xlsx_format_array;
  my %xlsx_width_hash;

  while (blessed $_[0] && $_[0]->isa('PDL')) {
    $c_pdl[$cols] = shift;
    croak "FATAL: wxlsx1D() expects 1D piddles" unless $c_pdl[$cols]->ndims == 1;
    $c_size[$cols]       = PDL::Core::howbig($c_pdl[$cols]->get_datatype);
    $c_dataref[$cols]    = $c_pdl[$cols]->get_dataref;
    $c_offset[$cols]     = 0;
    my $type             = $c_pdl[$cols]->type;
    my $dim              = $c_pdl[$cols]->dim(0);
    $c_pack[$cols]       = $pck{$type};
    $c_max_offset[$cols] = $c_size[$cols] * $dim;
    $rows = $dim if $rows < $dim;
    if ($bad2empty && $c_pdl[$cols]->check_badflag) {
      my $b = pdl($type, 1)->setbadif(1);
      my $d = $b->get_dataref;
      $c_bad[$cols] = substr($$d, 0, $c_size[$cols]); # raw bytes representind BAD value
    }
    if (ref $c_pdl[$cols] eq 'PDL::DateTime') {
      my $strf = $c_pdl[$cols]->_autodetect_strftime_format; #XXX-TODO _autodetect_strftime_format is a hack!!
      my ($len, $fmt) = @{$alias{$strf}};
      if (defined $len && defined $fmt) {
        $xlsx_format_array[$cols] = $fmt; # 0-based index
        $xlsx_width_hash{$cols + 1} = $len ; # 1-based index
      }
    }
    $cols++;
  }

  my $xlsx = PDL::IO::XLSX::Writer->new(%$C);
  $xlsx->sheets->start($O->{sheet_name} // "Sheet1", \%xlsx_width_hash, \@xlsx_format_array);

  if (ref $O->{header} eq 'ARRAY') {
    croak "FATAL: wrong header (expected $cols items)" if $cols != scalar @{$O->{header}};
    $xlsx->sheets->add_row($O->{header}); #XXX-TODO apply a special style for header cells (gray background)
  }

  for my $r (0..$rows-1) {
    my @v = ('') x $cols;
    for my $c (0..$cols-1) {
      if ($c_max_offset[$c] >= $c_offset[$c]) {
        if ($bad2empty && $c_bad[$c]) {
          my $v = substr(${$c_dataref[$c]}, $c_offset[$c], $c_size[$c]);
          if ($v ne $c_bad[$c]) {
            $v[$c] = unpack($c_pack[$c], $v);
            $v[$c] = _longlong2serialdate($v[$c]) if ref $c_pdl[$c] eq 'PDL::DateTime';
          }
        }
        else {
          my $v = substr(${$c_dataref[$c]}, $c_offset[$c], $c_size[$c]);
          $v[$c] = unpack($c_pack[$c], $v);
          $v[$c] = _longlong2serialdate($v[$c]) if ref $c_pdl[$c] eq 'PDL::DateTime';
        }
      }
      $c_offset[$c] += $c_size[$c];
    }
    $xlsx->sheets->add_row(\@v);
  }
  $xlsx->sheets->save;
  $xlsx->xlsx_save($fh, $C->{overwrite});
}

sub wxlsx2D {
  my $pdl = shift;
  my ($fh, $O, $C) = _proc_wargs('2D', @_);

  croak "FATAL: wxlsx2D() expects 2D piddle" unless $pdl->ndims == 2;
  my $p = $pdl->transpose;

  my ($cols, $rows) = $p->dims;
  my $type = $p->type;
  my $size = PDL::Core::howbig($p->get_datatype);
  my $packC = $pck{$type} . "[$cols]";
  my $pack1 = $pck{$type};
  my $dataref = $p->get_dataref;
  my $offset = 0;
  my $colsize = $size * $cols;
  my $max_offset = $colsize * ($rows - 1);
  my $bad;
  if ($O->{bad2empty} && $p->check_badflag) {
    my $b = pdl($type, 1)->setbadif(1);
    my $d = $b->get_dataref;
    $bad = substr($$d, 0, $size); # raw bytes representing BAD value
  }

  my $xlsx = PDL::IO::XLSX::Writer->new(%$C);
  $xlsx->sheets->start($O->{sheet_name} // "Sheet1");

  if ($O->{header}) {
    my $n = scalar @{$O->{header}};
    croak "FATAL: wrong header (expected $cols items, got $n)" if $cols != $n;
    $xlsx->sheets->add_row($O->{header});
  }
  while ($offset <= $max_offset) {
    if (defined $bad) {
      my @v = map { my $v = substr($$dataref, $offset + $_*$size, $size); $v eq $bad ? '' : unpack($pack1, $v) } (0..$cols-1);
      $xlsx->sheets->add_row(\@v);
    }
    else {
      my @v = unpack($packC, substr($$dataref, $offset, $colsize));
      $xlsx->sheets->add_row(\@v);
    }
    $offset += $colsize;
  }
  $xlsx->sheets->save;

  $xlsx->xlsx_save($fh, $C->{overwrite});
}

sub rxlsx1D {
  my ($fh, $coli, $O, $C) = _proc_rargs('1D', @_);

  my ($c_type, $c_pack, $c_sizeof, $c_pdl, $c_bad, $c_dataref, $c_idx, $c_dt, $allocated, $cols); # initialize after we get 1st line

  my $xlsx = PDL::IO::XLSX::Reader->new($fh, %$C);
  my $processed = 0;
  my $finished = 0;
  my $reshape_inc = $O->{reshape_inc};
  my $empty2bad = $O->{empty2bad};
  my $text2bad  = $O->{text2bad};

  my $headerline;
  my $auto_detect_headerline;
  my $skip_before_headerline;
  my $rows = 0;
  my @bytes;

  if (looks_like_number($O->{header}) && $O->{header} >= 1) {
    $skip_before_headerline = $O->{header} - 1;
  }
  elsif (($O->{header}//'') eq 'auto') {
    $auto_detect_headerline = 1;
  }

  my $proc_line = sub {
        my $r = shift;
        my $f = shift;
        if (defined $r) {
          if (defined $skip_before_headerline) {
            if ($skip_before_headerline == 0) {
              $headerline = $r;
              $skip_before_headerline = undef;
            }
            else {
              $skip_before_headerline--;
            }
            return; # go to the next line
          }
          elsif (defined $auto_detect_headerline) {
            my $numeric = 0;
            for (@$r) { $numeric++ if looks_like_number($_) || defined PDL::DateTime::dt2ll($_) }
            if ($numeric == 0) {
              # no numeric values found => skip this line but keep it as a potential header
              $headerline = $r;
              return; # go to the next line
            }
            $auto_detect_headerline = undef;
          }
          unless (defined $c_type) {
            ($c_type, $c_pack, $c_sizeof, $c_pdl, $c_bad, $c_dataref, $c_idx, $c_dt, $allocated, $cols) = _init_1D($coli, $r, $f, $O);
            warn "Initialized size=$allocated, cols=$cols, type=".join(",",@$c_type)."\n" if $O->{debug};
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
              my $v = _serialdate2longlong($r->[$_]);
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
        if ($rows >= $reshape_inc || !defined $r) {
          $processed += $rows;
          if (!defined $r) {
            # flush/finalize
            $allocated = $processed;
            warn "Reshape to: '$allocated'\n" if $O->{debug};
            for (0..$cols-1) {
              $c_pdl->[$_]->reshape($allocated);
              $c_dataref->[$_] = $c_pdl->[$_]->get_dataref;
            }
          }
          elsif ($allocated < $processed) {
            $allocated += $reshape_inc;
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
          @bytes = ();
          $rows = 0;
          if (!defined $r) {
            # flush/finalize
            $c_pdl->[$_]->upd_data for (0..$cols-1);
          }
        }
  };

  warn "Fetching 1D " . _dbg_msg($O, $C) . "\n" if $O->{debug};
  if ($O->{sheet_name}) {
    $xlsx->parse_sheet_by_name($O->{sheet_name}, sub {
      my $r = [ map { $_->{v} } @{$_[0]} ]; #values
      my $f = [ map { $_->{f} } @{$_[0]} ]; #formats
      $proc_line->($r, $f);
    });
  }
  else {
    $xlsx->parse_sheet_by_id(1, sub {
      my $r = [ map { $_->{v} } @{$_[0]} ]; #values
      my $f = [ map { $_->{f} } @{$_[0]} ]; #formats
      $proc_line->($r, $f);
    });
  }

  $proc_line->(undef); # flush/finalize
  if (ref $headerline eq 'ARRAY') {
    for (0..$cols-1) {
      $c_pdl->[$_]->hdr->{col_name} = $headerline->[$_] if $headerline->[$_] && $headerline->[$_] ne '';
    };
  }

  return @$c_pdl if ref $c_pdl eq 'ARRAY';
  warn "rxlsx1D: no data\n";
  return undef;
}

sub rxlsx2D {
  my ($fh, $coli, $O, $C) = _proc_rargs('2D', @_);

  my ($c_type, $c_pack, $c_sizeof, $c_pdl, $c_bad, $c_dataref, $allocated, $cols);
  my $xlsx = PDL::IO::XLSX::Reader->new($fh, %$C);
  my $processed = 0;
  my $c_idx = 0;
  my $pck;
  my $reshape_inc = $O->{reshape_inc};
  my $empty2bad = $O->{empty2bad};
  my $text2bad  = $O->{text2bad};
  my $bcount = 0;
  my $bytes = '';
  my $rows = 0;
  my $headers_to_skip = looks_like_number($O->{header}) ? $O->{header} : 0;
  my $formats;

  my $proc_line = sub {
        my $r = shift;
        if (defined $r) {
          if ($headers_to_skip > 0) {
            $headers_to_skip--;
            return;
          }
          unless (defined $pck) {
            ($c_type, $c_pack, $c_sizeof, $c_pdl, $c_bad, $c_dataref, $allocated, $cols) = _init_2D($coli, scalar @$r, $O);
            warn "Initialized size=$allocated, cols=$cols, type=$c_type\n" if $O->{debug};
            $pck = "$c_pack\[$cols\]";
          }
          if ($empty2bad) {
            if (defined $coli) {
              for (0..$cols-1) {
                my $i = $coli->[$_];
                if (($r->[$i]//'') eq '') {
                  $r->[$i] = $c_bad;
                  $c_pdl->badflag(1);
                }
              }
            }
            else {
              for (0..$cols-1) {
                if (($r->[$_]//'') eq '') {
                  $r->[$_] = $c_bad;
                  $c_pdl->badflag(1);
                }
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
        if ($rows >= $reshape_inc || !defined $r) {
          $processed += $rows;
          if (!defined $r) {
            # flush/finalize
            $allocated = $processed;
            warn "Reshaping to $allocated\n" if $O->{debug};
            $c_pdl->reshape($cols, $allocated);
            $c_dataref = $c_pdl->get_dataref;
          }
          elsif ($allocated < $processed) {
            $allocated += $reshape_inc;
            warn "Reshaping to $allocated\n" if $O->{debug};
            $c_pdl->reshape($cols, $allocated);
            $c_dataref = $c_pdl->get_dataref;
          }
          my $len = length $bytes;
          my $expected_len = $c_sizeof * $cols * $rows;
          croak "FATAL: len mismatch $len != $expected_len" if $len != $expected_len;
          substr($$c_dataref, $c_idx, $len) = $bytes;
          $c_idx += $len;
          $bytes = '';
          $rows = 0;
          if (!defined $r) {
            # flush/finalize
            $c_pdl->upd_data;
            $c_pdl = $c_pdl->transpose;
          }
        }
  };

  warn "Fetching 2D " . _dbg_msg($O, $C) . "\n" if $O->{debug};
  if ($O->{sheet_name}) {
    $xlsx->parse_sheet_by_name($O->{sheet_name}, sub {
      my $r = [ map { $_->{v} } @{$_[0]} ]; #values
      my $f = [ map { $_->{f} } @{$_[0]} ]; #formats
      $proc_line->($r, $f);
    });
  }
  else {
    $xlsx->parse_sheet_by_id(1, sub {
      my $r = [ map { $_->{v} } @{$_[0]} ]; #values
      my $f = [ map { $_->{f} } @{$_[0]} ]; #formats
      $proc_line->($r, $f);
    });
  }

  $proc_line->(undef); # flush/finalize

  warn "rxlsx2D: no data\n" unless blessed $c_pdl && $c_pdl->isa('PDL');
  return $c_pdl;
}

sub _dbg_msg {
  my ($O, $C) = @_;
  sprintf "reshape=%s, bad=%s/%s",
        $O->{reshape_inc} ||= '?',
        $O->{empty2bad}   ||= '?',
        $O->{text2bad}    ||= '?',
}

sub _proc_wargs {
  my $options        = ref $_[-1] eq 'HASH' ? pop : {};
  my $filename_or_fh = !blessed $_[-1] || !$_[-1]->isa('PDL') ? pop : undef;
  my $fn = shift;

  my $C = { %$options }; # make a copy

  my @keys = qw/ debug header bad2empty sheet_name /;
  my $O = { map { $_ => delete $C->{$_} } @keys };
  $O->{debug}     //= DEBUG;
  $O->{bad2empty} //= 1;
  $O->{header}    //= ($fn eq '1D' ? 'auto' : undef);

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

  return ($filename_or_fh, $O, $C);
}

sub _proc_rargs {
  my $options = ref $_[-1] eq 'HASH' ? pop : {};
  my ($fn, $filename_or_fh, $coli) = @_;

  croak "FATAL: invalid column ids" if defined $coli && ref $coli ne 'ARRAY';
  croak "FATAL: invalid filename"   unless defined $filename_or_fh;
  my $C = { %$options }; # make a copy

  # get options related to this module the rest will be passed to PDL::IO::XLSX::Reader|Writer
  my @keys = qw/ reshape_inc type debug empty2bad text2bad header sheet_name /;
  my $O = { map { $_ => delete $C->{$_} } @keys };
  $O->{reshape_inc} ||= 80_000;
  $O->{type}        ||= ($fn eq '1D' ? 'auto' : double);
  $O->{header}      ||= ($fn eq '1D' ? 'auto' : 0);
  $O->{debug} = DEBUG unless defined $O->{debug};

  # empty2bad implies some PDL::IO::XLSX::Reader extra options
  if ($O->{empty2bad}) {
    $C->{blank_is_undef} = 1;
    $C->{empty_is_undef} = 1;
  }

  return ($filename_or_fh, $coli, $O, $C);
}

sub _init_1D {
  my ($coli, $firstline_v, $firstline_f, $O) = @_;
  my $colcount = scalar @$firstline_v;
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

  for (0..$cols-1) {
    if (!defined $c_type[$_] || $c_type[$_] eq 'auto') {
      if ($firstline_f->[$_] =~ /^datetime\.(date|time|datetime)$/) {
        $c_type[$_] = 'datetime';
      }
      elsif ($firstline_f->[$_] eq 'int') {
        $c_type[$_] = longlong;
      }
      else {
        $c_type[$_] = double;
      }
    }
  }

  my @c_dt;
  for (0..$cols-1) {
    if ($c_type[$_] eq 'datetime') {
      $c_type[$_] = longlong;
      $c_dt[$_] = 'datetime';
    }
  }

  my $allocated = $O->{reshape_inc};
  for (0..$cols-1) {
    $c_type[$_] = double if !defined $c_type[$_];
    $c_pack[$_] = $pck{$c_type[$_]};
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

1;

__END__

=head1 NAME

PDL::IO::XLSX - Load/save PDL from/to XLSX file (optimized for speed and large data)

=head1 SYNOPSIS

  use PDL;
  use PDL::IO::XLSX ':all';

  my $pdl = rxlsx2D('input.xlsx');
  $pdl *= 2;
  wxlsx2D($pdl, 'double.xlsx');

  my ($pdl1, $pdl2, $pdl3) = rxlsx1D('input.xlsx', [0, 1, 6]);
  wxlsx1D($pdl1, 'col2.xlsx');
  #or
  $pdl2->wxlsx1D('col2.xlsx');

=head1 DESCRIPTION

PDL::IO::XLSX supports reading XLSX files and creating PDL piddle(s) as well as saving PDL data to XLSX file.

=head1 FUNCTIONS

By default, PDL::IO::XLSX doesn't import any function. You can import individual functions like this:

 use PDL::IO::XLSX qw(rxlsx2D wxlsx2D);

Or import all available functions:

 use PDL::IO::XLSX ':all';

=head2 rxlsx1D

Loads data from XLSX file into 1D piddles (separate for each column).

  my ($pdl1, $pdl2, $pdl3) = rxlsx1D($xlsx_filename_or_filehandle);
  #or
  my ($pdl1, $pdl2, $pdl3) = rxlsx1D($xlsx_filename_or_filehandle, \@column_ids);
  #or
  my ($pdl1, $pdl2, $pdl3) = rxlsx1D($xlsx_filename_or_filehandle, \%options);
  #or
  my ($pdl1, $pdl2, $pdl3) = rxlsx1D($xlsx_filename_or_filehandle, \@column_ids, \%options);

Parameters:

=over

=item xlsx_filename_or_filehandle

Path to XLSX file to be loaded or a filehandle open for reading.

=item column_ids

Optional column indices (0-based) defining which columns to load from XLSX file.
Default is C<undef> which means to load all columns.

=back

Items supported in B<options> hash:

=over

=item * type

Defines the type of output piddles: C<double>, C<float>, C<longlong>, C<long>, C<short>, C<byte> + special
values C<'auto'> (try to autodetect) and C<'datetime'> (PDL::DateTime).

Default: for C<rxlsx1D> - C<'auto'>; for C<rxlsx2D> - C<double>.

You can set one type for all columns/piddles:

  my ($a, $b, $c) = rxlsx1D($xlsx, {type => double});

or separately for each column/piddle:

  my ($a, $b, $c) = rxlsx1D($xlsx, {type => [long, double, double]});

Special datetime handling:

  my ($a, $b, $c) = rxlsx1D($xlsx, {type => [long, 'datetime', double]});
  # piddle $b will be an instance of PDL::DateTime

=item * reshape_inc

As we do not try to load the whole XLSX file into memory at once, we also do not know at the beginning how
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

Values C<0> or C<N> (positive integer) - consider the first C<N> rows as headers and skip them.

NOTE: header values (if any) are considered to be column names and are stored in loaded piddles in $pdl->hdr->{col_name}

NOTE: C<rxlsx1D> accepts a special C<header> value C<'auto'> which skips rows (from beginning) that have
in all columns non-numeric values.

Default: for C<rxlsx1D> - C<'auto'>; for C<rxlsx2D> - C<0>.

=item * sheet_name

The name of xlsx sheet that will be read (default is the first sheet).

=item * debug

Values C<0> (default) or C<1> - turn on/off debug messages

=back

=head2 rxlsx2D

Loads data from XLSX file into 2D piddle.

  my $pdl = rxlsx2D($xlsx_filename_or_filehandle);
  #or
  my $pdl = rxlsx2D($xlsx_filename_or_filehandle, \@column_ids);
  #or
  my $pdl = rxlsx2D($xlsx_filename_or_filehandle, \%options);
  #or
  my $pdl = rxlsx2D($xlsx_filename_or_filehandle, \@column_ids, \%options);

Parameters and items supported in C<options> hash are the same as by L</rxlsx1D>.

=head2 wxlsx1D

Saves data from one or more 1D piddles to XLSX file.

  wxlsx1D($pdl1, $pdl2, $pdl3, $xlsx_filename_or_filehandle, \%options);
  #or
  wxlsx1D($pdl1, $pdl2, $pdl3, $xlsx_filename_or_filehandle);
  #or
  wxlsx1D($pdl1, $pdl2);

  # but also as a piddle method
  $pdl1D->wxlsx1D("file.xlsx");

Parameters:

=over

=item piddles

One or more 1D piddles. All has to be 1D but may have different count of elements.

=item xlsx_filename_or_filehandle

Path to XLSX file to write to or a filehandle open for writing.

=back

Items supported in B<options> hash:

=over

=item * header

Arrayref with values that will be printed as the first XLSX row. Or C<'auto'> value which means that column
names are taken from $pdl->hdr->{col_name}.

Default: for C<wxlsx1D> - C<'auto'>; for C<wxlsx2D> - C<undef>.

=item * bad2empty

Values C<0> or C<1> (default) - convert BAD values into empty strings (there is a performance cost when turned on).

=item * sheet_name

The name of created sheet inside xlsx (default is C<'Sheet1'>).

=item * debug

Values C<0> (default) or C<1> - turn on/off debug messages

=back

=head2 wxlsx2D

Saves data from one 2D piddle to XLSX file.

  wxlsx2D($pdl, $xlsx_filename_or_filehandle, \%options);
  #or
  wxlsx2D($pdl, $xlsx_filename_or_filehandle);
  #or
  wxlsx2D($pdl);

  # but also as a piddle method
  $pdl->wxlsx2D("file.xlsx");

Parameters and items supported in C<options> hash are the same as by L</wxlsx1D>.

=head1 CREDITS

This modules is largely inspired by L<Data::XLSX::Parser> and L<Excel::Writer::XLSX>.

=head1 SEE ALSO

L<PDL>

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=head1 COPYRIGHT

2016+ KMX E<lt>kmx@cpan.orgE<gt>

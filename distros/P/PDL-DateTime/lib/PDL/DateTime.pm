package PDL::DateTime;

use strict;
use warnings;
use parent 'PDL';

our $VERSION = '0.004';

use Scalar::Util 'looks_like_number';
use POSIX ();
use PDL::Types;
use PDL::Primitive;
use PDL::Basic qw(sequence);
use PDL::Math  qw(floor);
use PDL::Core  qw(longlong long double byte short indx);
use Time::Moment;
use Carp;

use overload '>'  => \&_num_compare_gt,
             '<'  => \&_num_compare_lt,
             '>=' => \&_num_compare_ge,
             '<=' => \&_num_compare_le,
             '==' => \&_num_compare_eq,
             '!=' => \&_num_compare_ne,
             '""' => \&_stringify,
             '+'  => sub { PDL::plus(@_) },
             '-'  => sub { PDL::minus(@_) };

my %INC_SECONDS = (
  week   => 60 * 60 * 24 * 7,
  day    => 60 * 60 * 24,
  hour   => 60 * 60,
  minute => 60,
  second => 1,
);

sub initialize {
  my ($class, %args) = @_;
  $class = ref $class ? ref $class : $class;
  return bless { %args, PDL => PDL->null }, $class;
}

sub new {
  my ($class, $data, %opts) = @_;

  # for 'PDL::DateTime' just make a copy
  return $data->copy(%opts) if ref $data eq 'PDL::DateTime';

  my $self = $class->initialize(%opts);
  # $data is expected to contain epoch timestamps in microseconds
  if (ref $data eq 'ARRAY') {
    $self->{PDL} = longlong($data);
  }
  elsif (ref $data eq 'PDL') {
    if ($data->type == longlong) {
      $self->{PDL} = $data->copy;
      # NOTE:
      # $x = sequence(longlong, 6)  # type LL
      # $u = long($x)               # == clone/copy of $x (type L)
      # $u = longlong($x)           # == same data, same type as $x
      # $w = PDL->new($x)           # == clone/copy of $x (type LL)
    }
    elsif ($data->type == double) {
      $self->{PDL} = longlong(floor($data + 0.5));
      $self->{PDL} -= $self->{PDL} % 1000; #truncate to milliseconds
    }
    else {
      $self->{PDL} = longlong($data);
    }
  }
  else {
    if (looks_like_number $data) {
      $self->{PDL} = longlong($data);
    }
    elsif ($data) {
      $self->{PDL} = longlong(_datetime_to_jumboepoch($data));
    }
    else {
      croak "PDL::DateTime->new: invalid data";
    }
  }

  return $self;
}

# Derived objects need to supply its own copy!
sub copy {
  my ($self, %opts) = @_;
  my $new = $self->initialize(%opts);
  # copy the PDL
  $new->{PDL} = $self->{PDL}->SUPER::copy;
  # copy the other stuff
  #$new->{someThingElse} = $self->{someThingElse};
  return $new;
}

sub new_from_epoch {
  my ($class, $ep, %opts) = @_;
  my $self = $class->initialize(%opts);
  $ep = double($ep) if ref $ep eq 'ARRAY';
  # convert epoch timestamp in seconds to microseconds
  $self->{PDL} = longlong(floor(double($ep) * 1_000 + 0.5)) * 1000;
  return $self;
}

sub new_from_ratadie {
  my ($class, $rd, %opts) = @_;
  my $self = $class->initialize(%opts);
  $rd = double($rd) if ref $rd eq 'ARRAY';
  # EPOCH = (RD - 719_163) * 86_400
  # only milisecond precision => strip microseconds
  $self->{PDL} = longlong(floor((double($rd) - 719_163) * 86_400_000 + 0.5)) * 1000;
  return $self;
}

sub new_from_serialdate {
  my ($class, $sd, %opts) = @_;
  my $self = $class->initialize(%opts);
  $sd = double($sd) if ref $sd eq 'ARRAY';
  # EPOCH = (SD - 719_163 - 366) * 86_400
  # only milisecond precision => strip microseconds
  $self->{PDL} = longlong(floor((double($sd) - 719_529) * 86_400_000 + 0.5)) * 1000;
  return $self;
}

sub new_from_juliandate {
  my ($class, $jd, %opts) = @_;
  my $self = $class->initialize(%opts);
  $jd = double($jd) if ref $jd eq 'ARRAY';
  # EPOCH = (JD - 2_440_587.5) * 86_400
  # only milisecond precision => strip microseconds
  $self->{PDL} = longlong(floor((double($jd) - 2_440_587.5) * 86_400_000 + 0.5)) * 1000;
  return $self;
}

sub new_from_datetime {
  my ($class, $array, %opts) = @_;
  my $self = $class->initialize(%opts);
  $self->{PDL} = longlong _datetime_to_jumboepoch($array);
  return $self;
}

sub new_from_parts {
  my ($class, $y, $m, $d, $H, $M, $S, $U, %opts) = @_;
  croak "new_from_parts: args - y, m, d - are mandatory" unless defined $y && defined $m && defined $d;
  my $self = $class->initialize(%opts);
  $y = long($y) if ref $y eq 'ARRAY';
  $d = long($d) if ref $d eq 'ARRAY';
  $m = long($m) if ref $m eq 'ARRAY';
  $H = long($H) if ref $H eq 'ARRAY';
  $M = long($M) if ref $M eq 'ARRAY';
  $S = long($S) if ref $S eq 'ARRAY';
  $U = long($U) if ref $U eq 'ARRAY';
  my $rdate = _ymd2ratadie($y->copy, $m->copy, $d->copy);
  my $epoch = (floor($rdate) - 719163) * 86400;
  $epoch += floor($H) * 3600 if defined $H;
  $epoch += floor($M) * 60   if defined $M;
  $epoch += floor($S)        if defined $S;
  $epoch = longlong($epoch) * 1_000_000;
  $epoch += longlong(floor($U)) if defined $U;
  $self->{PDL} = longlong($epoch);
  return $self;
}

sub new_from_ymd {
  my ($class, $ymd) = @_;
  my $y = floor(($ymd/10000) % 10000);
  my $m = floor(($ymd/100) % 100);
  my $d = floor($ymd % 100);
  return $class->new_from_parts($y, $m, $d);
}

sub new_sequence {
  my ($class, $start, $count, $unit, $step, %opts) = @_;
  croak "new_sequence: args - count, unit - are mandatory" unless defined $count && defined $unit;
  $step = 1 unless defined $step;
  my $self = $class->initialize(%opts);
  my $tm_start = $start eq 'now' ? Time::Moment->now_utc : _dt2tm($start);
  my $microseconds = $tm_start->microsecond;
  if ($unit eq 'year') {
    # slow :(
    my @epoch = ($tm_start->epoch);
    push @epoch, $tm_start->plus_years($_*$step)->epoch for (1..$count-1);
    $self->{PDL} = longlong(\@epoch) * 1_000_000 + $microseconds;
  }
  if ($unit eq 'quarter') {
    # slow :(
    my @epoch = ($tm_start->epoch);
    push @epoch, $tm_start->plus_months(3*$_*$step)->epoch for (1..$count-1);
    $self->{PDL} = longlong(\@epoch) * 1_000_000 + $microseconds;
  }
  if ($unit eq 'month') {
    # slow :(
    my @epoch = ($tm_start->epoch);
    push @epoch, $tm_start->plus_months($_*$step)->epoch for (1..$count-1);
    $self->{PDL} = longlong(\@epoch) * 1_000_000 + $microseconds;
  }
  elsif (my $inc = $INC_SECONDS{$unit}) { # week day hour minute second
    my $epoch = $tm_start->epoch;
    $self->{PDL} = (longlong(floor(sequence($count) * $step * $inc + 0.5)) + $epoch) * 1_000_000 + $microseconds;
  }
  return $self;
}

sub double_epoch {
  my $self = shift;
  # EP = JUMBOEPOCH / 1_000_000;
  my $epoch_milisec = ($self - ($self % 1000)) / 1000; # BEWARE: precision only in milliseconds!
  return double($epoch_milisec) / 1_000;
}

sub longlong_epoch {
  my $self = shift;
  # EP = JUMBOEPOCH / 1_000_000;
  # BEWARE: precision only in seconds!
  my $epoch_sec = ($self - ($self % 1_000_000)) / 1_000_000;
  return longlong($epoch_sec->{PDL});
}

sub double_ratadie {
  my $self = shift;
  # RD = EPOCH / 86_400 + 719_163;
  my $epoch_milisec = ($self - ($self % 1000)) / 1000; # BEWARE: precision only in milliseconds!
  return double($epoch_milisec) / 86_400_000 + 719_163;
}

sub double_serialdate {
  my $self = shift;
  # SD = EPOCH / 86_400 + 719_163 + 366;
  my $epoch_milisec = ($self - ($self % 1000)) / 1000; # BEWARE: precision only in milliseconds!
  return double($epoch_milisec) / 86_400_000 + 719_529;
}

sub double_juliandate {
  my $self = shift;
  # JD = EPOCH / 86_400 + 2_440_587.5;
  my $epoch_milisec = ($self - ($self % 1000)) / 1000; # BEWARE: precision only in milliseconds!
  return double($epoch_milisec) / 86_400_000 + 2_440_587.5;
}

sub dt_ymd {
  my $self = shift;
  my ($y, $m, $d) = _ratadie2ymd($self->double_ratadie);
  return (short($y), byte($m), byte($d));
}

sub dt_year {
  my $self = shift;
  my ($y, undef, undef) = _ratadie2ymd($self->double_ratadie);
  return short($y);
}

sub dt_quarter {
  my $self = shift;
  my (undef, $m, undef) = _ratadie2ymd($self->double_ratadie);
  return ((byte($m)-1) / 3) + 1;
}

sub dt_month {
  my $self = shift;
  my (undef, $m, undef) = _ratadie2ymd($self->double_ratadie);
  return byte($m);
}

sub dt_day {
  my $self = shift;
  my (undef, undef, $d) = _ratadie2ymd($self->double_ratadie);
  return byte($d);
}

sub dt_hour {
  my $self = shift;
  return PDL->new(byte((($self - ($self % 3_600_000_000)) / 3_600_000_000) % 24));
}

sub dt_minute {
  my $self = shift;
  return PDL->new(byte((($self - ($self % 60_000_000)) / 60_000_000) % 60));
}

sub dt_second {
  my $self = shift;
  return PDL->new(byte((($self - ($self % 1_000_000)) / 1_000_000) % 60));
}

sub dt_microsecond {
  my $self = shift;
  return PDL->new(long($self % 1_000_000));
}

sub dt_day_of_week {
  my $self = shift;
  my $days = ($self - ($self % 86_400_000_000)) / 86_400_000_000;
  return PDL->new(byte(($days + 3) % 7) + 1); # 1..Mon, 7..Sun
}

sub dt_day_of_year {
  my $self = shift;
  my $rd1 = long(floor($self->double_ratadie));
  my $rd2 = long(floor($self->dt_align('year')->double_ratadie));
  return PDL->new(short, ($rd1 - $rd2 + 1));
}

sub dt_add {
  my $self = shift;
  if ($self->is_inplace) {
    $self->set_inplace(0);
    while (@_) {
      my ($unit, $num) = (shift, shift);
      if ($unit eq 'month') {
        $self += $self->_plus_delta_m($num);
      }
      elsif ($unit eq 'quarter') {
        $self += $self->_plus_delta_m($num * 3);
      }
      elsif ($unit eq 'year') {
        $self += $self->_plus_delta_m($num * 12);
      }
      elsif ($unit eq 'millisecond') {
        $self += $num * 1000;
      }
      elsif ($unit eq 'microsecond') {
        $self += $num;
      }
      elsif (my $inc = $INC_SECONDS{$unit}) { # week day hour minute second
        my $add = longlong(floor($num * $inc * 1_000_000 + 0.5));
        $self->inplace->plus($add, 0);
      }
    }
    return $self;
  }
  else {
    my $rv = $self->copy;
    while (@_) {
      my ($unit, $num) = (shift, shift);
      if ($unit eq 'month') {
        $rv += $rv->_plus_delta_m($num);
      }
      elsif ($unit eq 'quarter') {
        $rv += $rv->_plus_delta_m($num * 3);
      }
      elsif ($unit eq 'year') {
        $rv += $rv->_plus_delta_m($num * 12);
      }
      elsif ($unit eq 'millisecond') {
        $rv += $num * 1000;
      }
      elsif ($unit eq 'microsecond') {
        $rv += $num;
      }
      elsif(my $inc = $INC_SECONDS{$unit}) { # week day hour minute second
        $rv += longlong(floor($num * $inc * 1_000_000 + 0.5));
      }
    }
    return $rv;
  }
}

sub dt_align {
  my ($self, $unit, $up) = @_;
  if ($self->is_inplace) {
    $self->set_inplace(0);
    return $self unless defined $unit;
    if ($unit eq 'year') {
      $self->{PDL} = $self->_allign_myq(0, 1, 0, $up)->{PDL};
    }
    elsif ($unit eq 'quarter') {
      $self->{PDL} = $self->_allign_myq(0, 0, 1, $up)->{PDL};
    }
    elsif ($unit eq 'month') {
      $self->{PDL} = $self->_allign_myq(1, 0, 0, $up)->{PDL};
    }
    elsif ($unit eq 'millisecond') {
      my $sub = $self % 1_000;
      $self->inplace->minus($sub, 0);
    }
    elsif (my $inc = $INC_SECONDS{$unit}) { # week day hour minute second
      my $sub = $unit eq 'week' ? ($self + 3 * 60 * 60 * 24 * 1_000_000) % ($inc * 1_000_000) : $self % ($inc * 1_000_000);
      $sub -= 6 * 60 * 60 * 24 * 1_000_000 if $up && $unit eq 'week';
      $self->inplace->minus($sub, 0);
    }
    return $self;
  }
  else {
    return unless defined $unit;
    if ($unit eq 'year') {
      return $self->_allign_myq(0, 1, 0, $up);
    }
    elsif ($unit eq 'quarter') {
      return $self->_allign_myq(0, 0, 1, $up);
    }
    elsif ($unit eq 'month') {
      return $self->_allign_myq(1, 0, 0, $up);
    }
    elsif ($unit eq 'millisecond') {
      return $self - $self % 1_000;
    }
    elsif (my $inc = $INC_SECONDS{$unit}) { # week day hour minute second
      my $sub = $unit eq 'week' ? ($self + 3 * 60 * 60 * 24 * 1_000_000) % ($inc * 1_000_000) : $self % ($inc * 1_000_000);
      $sub -= 6 * 60 * 60 * 24 * 1_000_000 if $up && $unit eq 'week';
      return $self - $sub;
    }
  }
}

sub dt_at {
  my $self = shift;
  my $fmt = looks_like_number($_[-1]) ? 'auto' : pop;
  my $v = PDL::Core::at_c($self, [@_]);
  $fmt = $self->_autodetect_strftime_format if !$fmt || $fmt eq 'auto';
  return _jumboepoch_to_datetime($v, $fmt);
}

sub dt_set {
  my $self = shift;
  my $datetime = pop;
  PDL::Core::set_c($self, [@_], _datetime_to_jumboepoch($datetime));
}

sub dt_unpdl {
  my ($self, $fmt) = @_;
  $fmt = $self->_autodetect_strftime_format if !$fmt || $fmt eq 'auto';
  if ($fmt eq 'epoch') {
    return (double($self) / 1_000_000)->unpdl;
  }
  elsif ($fmt eq 'epoch_int') {
    return longlong(($self - ($self % 1_000_000)) / 1_000_000)->unpdl;
  }
  else {
    my $array = $self->unpdl;
    _jumboepoch_to_datetime($array, $fmt, 1); # change $array inplace!
    return $array;
  }
}

sub dt_diff {
  my ($self, $unit) = @_;
  return PDL->new('BAD')->reshape(1) if $self->nelem == 1;
  my $rv = PDL->new(longlong, 'BAD')->glue(0, $self->slice("1:-1") - $self->slice("0:-2"));
  return $rv unless $unit;
  return double($rv) / 604_800_000_000 if $unit eq 'week';
  return double($rv) /  86_400_000_000 if $unit eq 'day';
  return double($rv) /   3_600_000_000 if $unit eq 'hour';
  return double($rv) /      60_000_000 if $unit eq 'minute';
  return double($rv) /       1_000_000 if $unit eq 'second';
  return double($rv) /           1_000 if $unit eq 'millisecond';
  croak "dt_diff: invalid unit '$unit'";
}

sub dt_periodicity {
  my $self = shift;
  return '' if !$self->is_increasing && !$self->is_decreasing;
  my $freq = $self->qsort->dt_diff->median;
  return '' if $freq eq 'BAD' || $freq < 0;
  if ($freq < 1_000 ) {
    # $freq < 1 millisecond
    return "microsecond";
  }
  elsif ($freq < 1_000_000 ) {
    # 1 millisecond <= $freq < 1 second
    return "millisecond";
  }
  elsif ($freq < 60_000_000 ) {
    # 1 second <= $freq < 1 minute
    return "second";
  }
  elsif ($freq < 3_600_000_000) {
    # 1 minute <= $freq < 1 hour
    return "minute";
  }
  elsif ($freq < 86_400_000_000) {
    # 1 hour <= $freq < 24 hours
    return "hour";
  }
  elsif ($freq == 86_400_000_000) {
    # 24 hours
    return "day";
  }
  elsif ($freq == 604_800_000_000) {
    # 7 days
    return "week";
  }
  elsif ($freq >= 2_419_200_000_000 && $freq <= 2_678_400_000_000 ) {
    # 28days <= $freq <= 31days
    return "month";
  }
  elsif ($freq >= 7_776_000_000_000 && $freq <=  7_948_800_000_000 ) {
    # 90days <= $freq <= 92days
    return "quarter";
  }
  elsif ($freq >= 31_536_000_000_000 && $freq <=  31_622_400_000_000 ) {
    # 365days <= $freq <= 366days
    return "year";
  }
  return ''; # unknown
}

sub dt_startpoints {
  my ($self, $unit) = @_;
  croak "dt_startpoints: undefined unit" unless $unit;
  croak "dt_startpoints: 1D piddle required" unless $self->ndims == 1;
  croak "dt_startpoints: input not increasing" unless $self->is_increasing;
  return indx(0)->append($self->dt_endpoints($unit)->slice("0:-2") + 1);
}

sub dt_endpoints {
  my ($self, $unit) = @_;
  croak "dt_endpoints: undefined unit" unless $unit;
  croak "dt_endpoints: 1D piddle required" unless $self->ndims == 1;
  croak "dt_endpoints: input not increasing" unless $self->is_increasing;
  my $diff = $self->dt_align($unit)->dt_diff;
  my $end = which($diff != 0) - 1;
  if ($end->nelem == 0) {
    $end = indx([$self->nelem-1]);
  }
  else {
    $end = $end->append($self->nelem-1) unless $end->at($end->nelem-1) == $end->nelem-1;
  }
  return indx($end);
}

sub dt_slices {
  my ($self, $unit) = @_;
  croak "dt_slices: undefined unit" unless $unit;
  croak "dt_slices: 1D piddle required" unless $self->ndims == 1;
  croak "dt_slices: input not increasing" unless $self->is_increasing;
  my $end   = $self->dt_endpoints($unit);
  my $start = indx([0]);
  $start = $start->append($end->slice("0:-2") + 1) if $end->nelem > 1;
  return $start->cat($end)->transpose;
}

sub dt_nperiods {
  my ($self, $unit) = @_;
  croak "dt_nperiods: undefined unit" unless $unit;
  return $self->dt_endpoints($unit)->nelem;
}

sub is_increasing {
  my ($self, $strictly) = @_;
  return !(which($self->dt_diff <= 0)->nelem > 0) if $strictly;
  return !(which($self->dt_diff <  0)->nelem > 0);
}

sub is_decreasing {
  my ($self, $strictly) = @_;
  return !(which($self->dt_diff >= 0)->nelem > 0) if $strictly;
  return !(which($self->dt_diff >  0)->nelem > 0);
}

sub is_uniq {
  my $self = shift;
  my $diff = $self->qsort->dt_diff;
  return !(which($diff == 0)->nelem > 0);
}

sub is_regular {
  my $self = shift;
  my $dt = $self->dt_diff;
  my $diff = $self->dt_diff->qsort;
  my $min = $diff->min;
  my $max = $diff->max;
   return ($min ne "BAD") && ($max ne "BAD") && ($min == $max) && ($max > 0);
}

### private methods

sub _stringify {
  my $self = shift;
  my $data = $self->ndims > 0 ? $self->dt_unpdl : $self->dt_unpdl->[0];
  my $rv = _print_array($data, 0);
  $rv =~ s/\n$//;
  return $rv;
}

sub _num_compare_gt {
  my ($self, $other, $swap) = @_;
  $other = PDL::DateTime->new_from_datetime($other) if !ref $other && !looks_like_number($other);
  PDL::gt($self, $other, $swap);
}

sub _num_compare_lt {
  my ($self, $other, $swap) = @_;
  $other = PDL::DateTime->new_from_datetime($other) if !ref $other && !looks_like_number($other);
  PDL::lt($self, $other, $swap);
}

sub _num_compare_ge {
  my ($self, $other, $swap) = @_;
  $other = PDL::DateTime->new_from_datetime($other) if !ref $other && !looks_like_number($other);
  PDL::ge($self, $other, $swap);
}

sub _num_compare_le {
  my ($self, $other, $swap) = @_;
  $other = PDL::DateTime->new_from_datetime($other) if !ref $other && !looks_like_number($other);
  PDL::le($self, $other, $swap);
}

sub _num_compare_eq {
  my ($self, $other, $swap) = @_;
  $other = PDL::DateTime->new_from_datetime($other) if !ref $other && !looks_like_number($other);
  PDL::eq($self, $other, $swap);
}

sub _num_compare_ne {
  my ($self, $other, $swap) = @_;
  $other = PDL::DateTime->new_from_datetime($other) if !ref $other && !looks_like_number($other);
  PDL::ne($self, $other, $swap);
}

sub _autodetect_strftime_format {
  my $self = shift;
  if (which(($self % (24*60*60*1_000_000)) != 0)->nelem == 0) {
    return "%Y-%m-%d";
  }
  elsif (which(($self % (60*1_000_000)) != 0)->nelem == 0) {
    return "%Y-%m-%dT%H:%M";
  }
  elsif (which(($self % 1_000_000) != 0)->nelem == 0) {
    return "%Y-%m-%dT%H:%M:%S";
  }
  elsif (which(($self % 1_000) != 0)->nelem == 0) {
    return "%Y-%m-%dT%H:%M:%S.%3N";
  }
  else {
    return "%Y-%m-%dT%H:%M:%S.%6N";
  }
}

sub _plus_delta_m {
  my ($self, $delta_m) = @_;
  my $day_fraction = $self % 86_400_000_000;
  my $rdate_bf = ($self - $day_fraction)->double_ratadie;
  my ($y, $m, $d) = _ratadie2ymd($rdate_bf);
  my $rdate_af = _ymd2ratadie($y, $m, $d, $delta_m);
  my $rv = longlong($rdate_af - $rdate_bf) * 86_400_000_000;
  return $rv;
}

sub _allign_myq {
  my ($self, $mflag, $yflag, $qflag, $up) = @_;
  my $rdate = $self->double_ratadie;
  my ($y, $m, $d) = _ratadie2ymd($rdate);
  $m .= $up ? 12 : 1 if $yflag;
  $m  = $up ? $m+((3-$m)%3) : $m-(($m-1)%3) if $qflag;
  $d .= $up ? _days_in_month($y, $m) : 1;
  $rdate = _ymd2ratadie($y, $m, $d);
  return PDL::DateTime->new(longlong(floor($rdate) - 719163) * 86_400_000_000);
}

### public functions (used e.g. by PDL::IO::CSV)

sub dt2ll {
  eval {
    my $tm = Time::Moment->from_string(_fix_datetime_value(shift), lenient=>1);
    $tm->epoch * 1_000_000 + $tm->microsecond;
  };
}

sub ll2dt {
  my $v = shift;
  my $us = int($v % 1_000_000);
  my $ts = int(($v - $us) / 1_000_000);
  my $rv = eval { Time::Moment->from_epoch($ts, $us * 1000)->to_string(reduced=>1) } or return;
  $rv =~ s/(T00:00)?Z$//;
  return $rv;
}

### private functions

sub _dt2tm {
  eval { Time::Moment->from_string(_fix_datetime_value(shift), lenient=>1) };
}

sub _ll2tm {
  my $v = shift;
  my $us = int($v % 1_000_000);
  my $ts = int(($v - $us) / 1_000_000);
  eval { Time::Moment->from_epoch($ts, $us * 1000) };
}

sub _print_array {
  my ($val, $level) = @_;
  my $prefix = " " x $level;
  if (ref $val eq 'ARRAY' && !ref $val->[0]) {
    return $prefix . join(" ", '[', @$val, ']') . "\n";
  }
  elsif (ref $val eq 'ARRAY') {
    my $out = $prefix."[\n";
    $out .= _print_array($_, $level + 1) for (@$val);
    $out .= $prefix."]\n";
  }
  else {
    return $prefix . $val . "\n";
  }
}

sub _fix_datetime_value {
  my $v = shift;
  # '2015-12-29' > '2015-12-29T00Z'
  return $v."T00Z" if $v =~ /^\d\d\d\d-\d\d-\d\d$/;
  # '2015-12-29 11:59' > '2015-12-29 11:59Z'
  return $v."Z"    if $v =~ /^\d\d\d\d-\d\d-\d\d[ T]\d\d:\d\d$/;
  # '2015-12-29 11:59:11' > '2015-12-29 11:59:11Z' or '2015-12-29 11:59:11.123' > '2015-12-29 11:59:11.123Z'
  return $v."Z"    if $v =~ /^\d\d\d\d-\d\d-\d\d[ T]\d\d:\d\d:\d\d(\.\d+)?$/;
  return $v;
}

sub _datetime_to_jumboepoch {
  my ($dt, $inplace) = @_;
  my $tm;
  if (ref $dt eq 'ARRAY') {
    my @new;
    for (@$dt) {
      my $s = _datetime_to_jumboepoch($_, $inplace);
      if ($inplace) {
        $_ = (ref $_ ? undef : $s) if ref $_ ne 'ARRAY';
      }
      else {
        push @new, $s;
      }
    }
    return \@new if !$inplace;
  }
  else {
    if (looks_like_number $dt) {
      return int POSIX::floor($dt * 1_000_000 + 0.5);
    }
    elsif (!ref $dt) {
      $tm = ($dt eq 'now') ? Time::Moment->now_utc : _dt2tm($dt);
    }
    elsif (ref $dt eq 'DateTime' || ref $dt eq 'Time::Piece') {
      $tm = eval { Time::Moment->from_object($dt) };
    }
    elsif (ref $dt eq 'Time::Moment') {
      $tm = $dt;
    }
    return undef unless $tm;
    return int($tm->epoch * 1_000_000 + $tm->microsecond);
  }
}

sub _jumboepoch_to_datetime {
  my ($v, $fmt, $inplace) = @_;
  return 'BAD' unless defined $v;
  if (ref $v eq 'ARRAY') {
    my @new;
    for (@$v) {
      my $s = _jumboepoch_to_datetime($_, $fmt, $inplace);
      if ($inplace) {
        $_ = $s if ref $_ ne 'ARRAY';
      }
      else {
        push @new, $s;
      }
    }
    return \@new if !$inplace;
  }
  elsif (!ref $v) {
    my $tm = _ll2tm($v);
    return 'BAD' unless defined $tm;
    if ($fmt eq 'Time::Moment') {
      return $tm;
    }
    else {
      return $tm->strftime($fmt);
    }
  }
}

my $DAYS_PER_400_YEARS  = 146_097;
my $DAYS_PER_100_YEARS  =  36_524;
my $DAYS_PER_4_YEARS    =   1_461;
my $MAR_1_TO_DEC_31     =     306;

sub _ymd2ratadie {
  my ($y, $m, $d, $delta_m) = @_;
  # based on Rata Die calculation from https://metacpan.org/source/DROLSKY/DateTime-1.10/lib/DateTime.xs#L151
  # RD: 1       => 0001-01-01
  # RD: 2       => 0001-01-02
  # RD: 719163  => 1970-01-01
  # RD: 730120  => 2000-01-01
  # RD: 2434498 => 6666-06-06
  # RD: 3652059 => 9999-12-31

  if (defined $delta_m) {
    # handle months + years
    $m->inplace->plus($delta_m - 1, 0);
    my $extra_y = floor($m / 12);
    $m->inplace->modulo(12, 0);
    $m->inplace->plus(1, 0);
    $y->inplace->plus($extra_y, 0);
    # fix days
    my $dec_by_one = ($d==31) * (($m==4) + ($m==6) + ($m==9) + ($m==11));
    # 1800, 1900, 2100, 2200, 2300 - common; 2000, 2400 - leap
    my $is_nonleap_yr = (($y % 4)!=0) + (($y % 100)==0) - (($y % 400)==0);
    my $dec_nonleap_feb = ($m==2) * ($d>28) * $is_nonleap_yr * ($d-28);
    my $dec_leap_feb    = ($m==2) * ($d>29) * (1 - $is_nonleap_yr) * ($d-29);
    $d->inplace->minus($dec_by_one + $dec_leap_feb + $dec_nonleap_feb, 0);
  }

  my $rdate = double($d); # may contain day fractions
  $rdate->setbadif(($y < 1) + ($y > 9999));
  $rdate->setbadif(($m < 1) + ($m > 12));
  $rdate->setbadif(($d < 1) + ($d >= 32));  # not 100% correct (max. can be 31.9999999)

  my $m2 = ($m <= 2);
  $y -= $m2;
  $m += $m2 * 12;

  $rdate += floor(($m * 367 - 1094) / 12);
  $rdate += floor($y % 100 * $DAYS_PER_4_YEARS / 4);
  $rdate += floor($y / 100) * $DAYS_PER_100_YEARS + floor($y / 400);
  $rdate -= $MAR_1_TO_DEC_31;
  return $rdate;
}

sub _ratadie2ymd {
  # based on Rata Die calculation from  https://metacpan.org/source/DROLSKY/DateTime-1.10/lib/DateTime.xs#L82
  my $rdate = shift;

  my $d = floor($rdate);
  $d += $MAR_1_TO_DEC_31;

  my $c = floor((($d * 4) - 1) / $DAYS_PER_400_YEARS); # century
  $d   -= floor($c * $DAYS_PER_400_YEARS / 4);
  my $y = floor((($d * 4) - 1) / $DAYS_PER_4_YEARS);
  $d   -= floor($y * $DAYS_PER_4_YEARS / 4);
  my $m = floor((($d * 12) + 1093) / 367);
  $d   -= floor((($m * 367) - 1094) / 12);
  $y   += ($c * 100);

  my $m12 = ($m > 12);
  $y += $m12;
  $m -= $m12 * 12;

  return ($y, $m, $d);
}

sub _is_non_leap_year {
  my $y = shift;
  return (($y % 4)!=0) + (($y % 100)==0) - (($y % 400)==0);
}

sub _days_in_year {
  my $y = shift;
  return 366 - _is_non_leap_year($y);
}

sub _days_in_month {
  my ($y, $m) = @_;
  my $dec_simple = (2*($m==2) + ($m==4) + ($m==6) + ($m==9) + ($m==11));
  my $dec_nonleap_feb  = ($m==2) * _is_non_leap_year($y);
  return 31 - $dec_simple - $dec_nonleap_feb;
}

1;

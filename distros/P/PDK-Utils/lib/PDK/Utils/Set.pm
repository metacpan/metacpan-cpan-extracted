package PDK::Utils::Set;

use v5.30;
use Moose;
use POSIX qw(floor ceil);
use experimental 'smartmatch';
use namespace::autoclean;

has mins => (is => 'rw', isa => 'ArrayRef[Int]', default => sub { [] },);

has maxs => (is => 'rw', isa => 'ArrayRef[Int]', default => sub { [] },);

around BUILDARGS => sub {
  my $orig  = shift;
  my $class = shift;

  if (@_ == 0) {
    return $class->$orig();
  }
  elsif (@_ == 1 and ref($_[0]) eq __PACKAGE__) {
    my $setObj = $_[0];
    return $class->$orig(mins => [@{$setObj->mins}], maxs => [@{$setObj->maxs}]);
  }
  elsif (@_ == 2 and defined $_[0] and defined $_[1] and $_[0] =~ /^\d+$/o and $_[1] =~ /^\d+$/o) {
    my ($MIN, $MAX) = $_[0] < $_[1] ? ($_[0], $_[1]) : ($_[1], $_[0]);
    return $class->$orig(mins => [$MIN], maxs => [$MAX]);
  }
  else {
    return $class->$orig(@_);
  }
};

sub BUILD {
  my $self = shift;
  my @ERROR;
  my $lengthOfMin = @{$self->mins};
  my $lengthOfMax = @{$self->maxs};

  if ($lengthOfMin != $lengthOfMax) {
    push(@ERROR, 'Attribute (mins) and (maxs) must has same length at constructor ' . __PACKAGE__);
  }
  for (my $i = 0; $i < $lengthOfMin; $i++) {
    if ($self->mins->[$i] > $self->maxs->[$i]) {
      push(@ERROR, 'Attribute (mins) must not bigger than (maxs) in the same index at constructor ' . __PACKAGE__);
      last;
    }
  }
  if (@ERROR > 0) {
    confess(join(', ', @ERROR));
  }
}

sub length {
  my $self        = shift;
  my $lengthOfMin = @{$self->mins};
  my $lengthOfMax = @{$self->maxs};

  confess("ERROR: Attribute (mins) 's length($lengthOfMin) not equal (maxs) 's length($lengthOfMax)")
    if $lengthOfMin != $lengthOfMax;
  return $lengthOfMin;
}

sub min {
  my $self = shift;
  return ($self->length > 0 ? $self->mins->[0] : undef);
}

sub max {
  my $self = shift;
  return ($self->length > 0 ? $self->maxs->[-1] : undef);
}

sub dump {
  my $self   = shift;
  my $length = $self->length;
  for (my $i = 0; $i < $length; $i++) {
    say $self->mins->[$i] . "  " . $self->maxs->[$i];
  }
}

sub addToSet {
  my ($self, $MIN, $MAX) = @_;
  if ($MIN > $MAX) {
    ($MAX, $MIN) = ($MIN, $MAX);
  }
  my $length = $self->length;
  if ($length == 0) {
    $self->mins([$MIN]);
    $self->maxs([$MAX]);
    return;
  }

  my $minArray = $self->mins;
  my $maxArray = $self->maxs;
  my $index;
  for (my $i = 0; $i < $length; $i++) {
    if ($MIN < $minArray->[$i]) {
      $index = $i;
      last;
    }
  }
  $index = $length if not defined $index;

  my (@min, @max);
  push(@min, @{$minArray}[0 .. $index - 1]);
  push(@max, @{$maxArray}[0 .. $index - 1]);
  push(@min, $MIN);
  push(@max, $MAX);
  push(@min, @{$minArray}[$index .. $length - 1]);
  push(@max, @{$maxArray}[$index .. $length - 1]);

  $self->mins(\@min);
  $self->maxs(\@max);
}

sub mergeToSet {
  my $self = shift;
  if (@_ == 1 and ref($_[0]) eq __PACKAGE__) {
    my $setObj = $_[0];
    my $length = $setObj->length;
    for (my $i = 0; $i < $length; $i++) {
      $self->_mergeToSet($setObj->mins->[$i], $setObj->maxs->[$i]);
    }
  }
  else {
    $self->_mergeToSet(@_);
  }
}

sub _mergeToSet {
  my ($self, $MIN, $MAX) = @_;
  if ($MIN > $MAX) {
    ($MAX, $MIN) = ($MIN, $MAX);
  }
  my $length = $self->length;
  if ($length == 0) {
    $self->mins([$MIN]);
    $self->maxs([$MAX]);
    return;
  }

  my $minArray = $self->mins;
  my $maxArray = $self->maxs;
  my ($minIndex, $maxIndex) = (-1, $length);

MIN: {
    for (my $i = 0; $i < $length; $i++) {
      if ($MIN >= $minArray->[$i] and $MIN <= $maxArray->[$i] + 1) {
        $minIndex = $i;
        last MIN;
      }
      elsif ($MIN < $minArray->[$i]) {
        $minIndex += 0.5;
        last MIN;
      }
      else {
        $minIndex++;
      }
    }
    $minIndex += 0.5;
  }

MAX: {
    for (my $j = $length - 1; $j >= $minIndex; $j--) {
      if ($MAX >= $minArray->[$j] - 1 and $MAX <= $maxArray->[$j]) {
        $maxIndex = $j;
        last MAX;
      }
      elsif ($MAX > $maxArray->[$j]) {
        $maxIndex -= 0.5;
        last MAX;
      }
      else {
        $maxIndex--;
      }
    }
    $maxIndex -= 0.5;
  }

  my $minIndexInt     = POSIX::ceil($minIndex);
  my $maxIndexInt     = POSIX::floor($maxIndex);
  my $isMinIndexInSet = $minIndex == $minIndexInt ? 1 : 0;
  my $isMaxIndexInSet = $maxIndex == $maxIndexInt ? 1 : 0;

  my (@min, @max);
  push(@min, @{$minArray}[0 .. $minIndexInt - 1]);
  push(@max, @{$maxArray}[0 .. $minIndexInt - 1]);
  push(@min, $isMinIndexInSet ? $minArray->[$minIndexInt] : $MIN);
  push(@max, $isMaxIndexInSet ? $maxArray->[$maxIndexInt] : $MAX);
  push(@min, @{$minArray}[$maxIndexInt + 1 .. $length - 1]);
  push(@max, @{$maxArray}[$maxIndexInt + 1 .. $length - 1]);

  $self->mins(\@min);
  $self->maxs(\@max);
}

sub compare {
  my ($self, $setObj) = @_;
  if ($self->isEqual($setObj)) {
    return 'equal';
  }
  elsif ($self->_isContain($setObj)) {
    return 'containButNotEqual';
  }
  elsif ($self->_isBelong($setObj)) {
    return 'belongButNotEqual';
  }
  else {
    return 'other';
  }
}

sub isEqual {
  my ($self, $setObj) = @_;
  return (@{$self->mins} ~~ @{$setObj->mins} and @{$self->maxs} ~~ @{$setObj->maxs});
}

sub notEqual {
  my ($self, $setObj) = @_;
  return !(@{$self->mins} ~~ @{$setObj->mins} and @{$self->maxs} ~~ @{$setObj->maxs});
}

sub isContain {
  my ($self, $setObj) = @_;
  if ($self->isEqual($setObj)) {
    return 1;
  }
  else {
    return $self->_isContain($setObj);
  }
}

sub _isContain {
  my ($self, $setObj) = @_;
  my $copyOfSelf = PDK::Utils::Set->new($self);
  $copyOfSelf->mergeToSet($setObj);
  return $self->isEqual($copyOfSelf);
}

sub isContainButNotEqual {
  my ($self, $setObj) = @_;
  if ($self->isEqual($setObj)) {
    return 0;
  }
  else {
    return $self->_isContain($setObj);
  }
}

sub isBelong {
  my ($self, $setObj) = @_;
  if ($self->isEqual($setObj)) {
    return 1;
  }
  else {
    return $self->_isBelong($setObj);
  }
}

sub _isBelong {
  my ($self, $setObj) = @_;
  my $copyOfSetObj = PDK::Utils::Set->new($setObj);
  $copyOfSetObj->mergeToSet($self);
  return $setObj->isEqual($copyOfSetObj);
}

sub isBelongButNotEqual {
  my ($self, $setObj) = @_;
  if ($self->isEqual($setObj)) {
    return 0;
  }
  else {
    return $self->_isBelong($setObj);
  }
}

sub interSet {
  my $result = PDK::Utils::Set->new;
  my ($self, $setObj) = @_;
  if ($self->length == 0) {
    return $self;
  }
  if ($setObj->length == 0) {
    return $setObj;
  }
  my $i = 0;
  my $j = 0;

  while ($i < $self->length and $j < $setObj->length) {
    my @rangeSet1 = ($self->mins->[$i],   $self->maxs->[$i]);
    my @rangeSet2 = ($setObj->mins->[$j], $setObj->maxs->[$j]);
    my ($min, $max) = $self->interRange(\@rangeSet1, \@rangeSet2);
    $result->_mergeToSet($min, $max) if defined $min;
    if ($setObj->maxs->[$j] > $self->maxs->[$i]) {
      $i++;
    }
    elsif ($setObj->maxs->[$j] == $self->maxs->[$i]) {
      $i++;
      $j++;
    }
    else {
      $j++;
    }
  }
  return $result;
}

sub interRange {
  my ($self, $rangeSet1, $rangeSet2) = @_;
  my ($min, $max);
  $min = $rangeSet1->[0] > $rangeSet2->[0] ? $rangeSet1->[0] : $rangeSet2->[0];
  $max = $rangeSet1->[1] < $rangeSet2->[1] ? $rangeSet1->[1] : $rangeSet2->[1];
  if ($min > $max) {
    return;
  }
  else {
    return ($min, $max);
  }
}

for my $func (qw(addToSet _mergeToSet)) {
  before $func => sub {
    shift;
    unless (@_ == 2 and $_[0] =~ /^\d+$/o and $_[1] =~ /^\d+$/o) {
      confess("ERROR: function $func can only has two numeric argument");
    }
  }
}

for my $func (qw(compare isEqual isContain _isContain isContainButNotEqual isBelong _isBelong isBelongButNotEqual)) {
  before $func => sub {
    shift;
    confess("ERROR: the first param of function($func) is not a PDK::Utils::Set") if ref($_[0]) ne 'PDK::Utils::Set';
  }
}

__PACKAGE__->meta->make_immutable;
1;

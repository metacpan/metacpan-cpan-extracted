package PDK::Utils::Set;

#------------------------------------------------------------------------------
# 加载扩展模块
#------------------------------------------------------------------------------
use Moose;
use namespace::autoclean;
use POSIX        qw/ceil floor/;
use experimental qw/smartmatch/;

#------------------------------------------------------------------------------
# 定义对象通用方法和属性
#------------------------------------------------------------------------------
has mins => (is => 'rw', isa => 'ArrayRef[Int]', default => sub { [] },);

has maxs => (is => 'rw', isa => 'ArrayRef[Int]', default => sub { [] },);

#------------------------------------------------------------------------------
# 集合对象深度 - 数组长度
#------------------------------------------------------------------------------
sub length {
  my $self        = shift;
  my $lengthOfMin = @{$self->mins};
  my $lengthOfMax = @{$self->maxs};
  if ($lengthOfMin != $lengthOfMax) {
    confess "Attribute (mins)'s length($lengthOfMin) not equal (maxs)'s length($lengthOfMax)";
  }
  else {
    return $lengthOfMin;
  }
}

#------------------------------------------------------------------------------
# 集合对象最小值
#------------------------------------------------------------------------------
sub min {
  my $self = shift;
  return ($self->length > 0 ? $self->mins->[0] : undef);
}

#------------------------------------------------------------------------------
# 集合对象最大值
#------------------------------------------------------------------------------
sub max {
  my $self = shift;
  return ($self->length > 0 ? $self->maxs->[-1] : undef);
}

#------------------------------------------------------------------------------
# 打印集合对象内部数据
#------------------------------------------------------------------------------
sub dump {
  my $self   = shift;
  my $length = $self->length;
  for (my $i = 0; $i < $length; $i++) {
    print "min: $self->mins->[$i]" . "- max :$self->maxs->[$i]" . "\n";
  }
}

#------------------------------------------------------------------------------
# 添加集合数值到集合对象
# 不需要检查重复，需要检查排序，所以用这个的时候要特别慎重
# 只有在确定输入与set不重复的情况下才可使用，否则会有问题
#------------------------------------------------------------------------------
sub addToSet {
  my ($self, $MIN, $MAX) = @_;

  # 检查数值大小并排序
  ($MIN, $MAX) = $MIN > $MAX ? ($MAX, $MIN) : ($MIN, $MAX);
  my $length = $self->length;
  if ($length == 0) {
    $self->mins([$MIN]);
    $self->maxs([$MAX]);
    return;
  }

  # 将数值与区间最小值比较，确定是否需要插值
  my $index;
  my $minArray = $self->mins;
  my $maxArray = $self->maxs;
  for (my $i = 0; $i < $length; $i++) {
    if ($MIN < $minArray->[$i]) {
      $index = $i;
      last;
    }
  }
  $index ||= $length;
  my (@min, @max);
  push @min, @{$minArray}[0 .. $index - 1];
  push @max, @{$maxArray}[0 .. $index - 1];
  push @min, $MIN;
  push @max, $MAX;
  push @min, @{$minArray}[$index .. $length - 1];
  push @max, @{$maxArray}[$index .. $length - 1];
  $self->mins(\@min);
  $self->maxs(\@max);
}

#------------------------------------------------------------------------------
# 添加集合数值到集合对象
#------------------------------------------------------------------------------
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

#------------------------------------------------------------------------------
# 添加集合数值到集合对象
# 需要检查重复，也需要检查排序
#------------------------------------------------------------------------------
sub _mergeToSet {
  my ($self, $MIN, $MAX) = @_;

  # 数值判断并排序
  ($MIN, $MAX) = $MIN > $MAX ? ($MAX, $MIN) : ($MIN, $MAX);

  # 判断是否已有数据
  my $length = $self->length;
  if ($length == 0) {
    $self->mins([$MIN]);
    $self->maxs([$MAX]);
    return;
  }

  my $minArray = $self->mins;
  my $maxArray = $self->maxs;
  my ($minIndex, $maxIndex) = (-1, $length);

  # 从小到大查询确定数值关系：命中区间值、比最小区间值还小即代表需要新增，其他则代表不确定(不满足条件)继续查询
  # 遍历所有数值仍未满足条件，则需要插入数据到集合最右边
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

  # 从大到小查询确定数值关系：命中区间值、比最大值还大即代表需要新增，其他则代表不确定(不满足条件)继续查询
  # 遍历所有数值仍未满足条件，则需要插入数据到集合最右边
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

  # min使用向上取整，即 POSIX::ceil(0.5) == 1 ,  POSIX::ceil(1) == 1
  # max使用向下取整，即 POSIX::floor(-0.5) == -1 ,  POSIX::floor(-1) == -1
  my $minIndexInt = POSIX::ceil($minIndex);
  my $maxIndexInt = POSIX::floor($maxIndex);

  # 判断数值是否命中集合区间值
  my $isMinIndexInSet = ($minIndex == $minIndexInt) ? 1 : 0;
  my $isMaxIndexInSet = ($maxIndex == $maxIndexInt) ? 1 : 0;

  my (@min, @max);
  push @min, @{$minArray}[0 .. $minIndexInt - 1];
  push @max, @{$maxArray}[0 .. $minIndexInt - 1];
  push @min, $isMinIndexInSet ? $minArray->[$minIndexInt] : $MIN;
  push @max, $isMaxIndexInSet ? $maxArray->[$maxIndexInt] : $MAX;
  push @min, @{$minArray}[$maxIndexInt + 1 .. $length - 1];
  push @max, @{$maxArray}[$maxIndexInt + 1 .. $length - 1];
  $self->mins(\@min);
  $self->maxs(\@max);
}

#------------------------------------------------------------------------------
# 集合对象比较：相等、包含不等，属于不等和其他关系
#------------------------------------------------------------------------------
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

#------------------------------------------------------------------------------
# 定义对象通用方法和属性
#------------------------------------------------------------------------------
sub isEqual {
  my ($self, $setObj) = @_;
  return (@{$self->mins} ~~ @{$setObj->mins} and @{$self->maxs} ~~ @{$setObj->maxs});
}

#------------------------------------------------------------------------------
# 定义对象通用方法和属性
#------------------------------------------------------------------------------
sub notEqual {
  my ($self, $setObj) = @_;
  return !$self->isEqual($setObj);
}

#------------------------------------------------------------------------------
# 定义对象通用方法和属性
#------------------------------------------------------------------------------
sub isContain {
  my ($self, $setObj) = @_;
  if ($self->isEqual($setObj)) {
    return 1;
  }
  else {
    return $self->_isContain($setObj);
  }
}

#------------------------------------------------------------------------------
# 定义对象通用方法和属性
#------------------------------------------------------------------------------
sub _isContain {
  my ($self, $setObj) = @_;
  my $copyOfSelf = PDK::Utils::Set->new($self);
  $copyOfSelf->mergeToSet($setObj);
  return $self->isEqual($copyOfSelf);
}

#------------------------------------------------------------------------------
# 定义对象通用方法和属性
#------------------------------------------------------------------------------
sub isContainButNotEqual {
  my ($self, $setObj) = @_;
  if ($self->isEqual($setObj)) {
    return;
  }
  else {
    return $self->_isContain($setObj);
  }
}

#------------------------------------------------------------------------------
# 定义对象通用方法和属性
#------------------------------------------------------------------------------
sub isBelong {
  my ($self, $setObj) = @_;
  if ($self->isEqual($setObj)) {
    return 1;
  }
  else {
    return $self->_isBelong($setObj);
  }
}

#------------------------------------------------------------------------------
# 定义对象通用方法和属性
#------------------------------------------------------------------------------
sub _isBelong {
  my ($self, $setObj) = @_;
  my $copyOfSetObj = PDK::Utils::Set->new($setObj);
  $copyOfSetObj->mergeToSet($self);
  return $setObj->isEqual($copyOfSetObj);
}

#------------------------------------------------------------------------------
# 定义对象通用方法和属性
#------------------------------------------------------------------------------
sub isBelongButNotEqual {
  my ($self, $setObj) = @_;
  if ($self->isEqual($setObj)) {
    return;
  }
  else {
    return $self->_isBelong($setObj);
  }
}

#------------------------------------------------------------------------------
# 提取2个区间值最长集合区间
#------------------------------------------------------------------------------
sub interSet {
  my ($self, $setObj) = @_;

  # 边界条件检查
  if ($self->length == 0) {
    return $self;
  }
  if ($setObj->length == 0) {
    return $setObj;
  }

  my $i      = 0;
  my $j      = 0;
  my $result = PDK::Utils::Set->new;
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

#------------------------------------------------------------------------------
# 提取2个区间值的最大值和最小值
#------------------------------------------------------------------------------
sub interRange {
  my ($self, $rangeSet1, $rangeSet2) = @_;
  my ($min, $max);
  $min = ($rangeSet1->[0] < $rangeSet2->[0]) ? $rangeSet1->[0] : $rangeSet2->[0];
  $max = ($rangeSet1->[1] > $rangeSet2->[1]) ? $rangeSet1->[1] : $rangeSet2->[1];
  if ($min > $max) {
    return;
  }
  else {
    return ($min, $max);
  }
}

#------------------------------------------------------------------------------
# 对象初始化入参检查
#------------------------------------------------------------------------------
around BUILDARGS => sub {

  # 代表特定的函数
  my $orig  = shift;
  my $class = shift;
  if (@_ == 0) {
    return $class->$orig();
  }
  elsif (@_ == 1 and ref $_[0] eq __PACKAGE__) {
    my $setObj = $_[0];
    return $class->$orig(mins => [@{$setObj->{mins}}], maxs => [@{$setObj->{maxs}}]);
  }
  elsif (@_ == 2 and defined $_[0] and defined $_[1] and $_[0] =~ /^\d+$/o and $_[1] =~ /^\d+$/o) {
    my ($MIN, $MAX) = $_[0] < $_[1] ? ($_[0], $_[1]) : ($_[1], $_[0]);
    return $class->$orig(mins => [$MIN], maxs => [$MAX]);
  }
  else {
    return $class->$orig(@_);
  }
};

#------------------------------------------------------------------------------
# 对象初始化合法性检查
#------------------------------------------------------------------------------
sub BUILD {
  my $self = shift;
  my @ERROR;
  my $lengthOfMin = @{$self->mins};
  my $lengthOfMax = @{$self->maxs};
  if ($lengthOfMin != $lengthOfMax) {
    push @ERROR, 'Attribute (mins) and (maxs) must has same length at constructor ' . __PACKAGE__;
  }
  for (my $i = 0; $i < $lengthOfMin; $i++) {
    if ($self->mins->[$i] > $self->maxs->[$i]) {
      push @ERROR, 'Attribute (mins) must not bigger than (maxs) in the same index at constructor ' . __PACKAGE__;
      last;
    }
  }
  if (@ERROR > 0) {
    confess join(', ', @ERROR);
  }
}

#------------------------------------------------------------------------------
# 对象方法入参运行时检查
#------------------------------------------------------------------------------
for my $func (qw/ addToSet _mergeToSet /) {
  before $func => sub {
    my $self = shift;
    unless (@_ == 2 and $_[0] =~ /^\d+$/o and $_[1] =~ /^\d+$/o) {
      confess "ERROR: function $func can only has two numeric argument";
    }
  }
}

for my $func (qw/ compare isEqual isContain _isContain isContainButNotEqual isBelong _isBelong isBelongButNotEqual /) {
  before $func => sub {
    my $self = shift;
    confess "ERROR: the first param of function($func) is not a PDK::Utils::Set" if ref($_[0]) ne 'PDK::Utils::Set';
  }
}

__PACKAGE__->meta->make_immutable;
1;

package Netstack::Utils::Set;

#------------------------------------------------------------------------------
# 加载扩展模块功能
#------------------------------------------------------------------------------
use 5.016;
use Moose;
use namespace::autoclean;
use POSIX;
use experimental 'smartmatch';

#------------------------------------------------------------------------------
# 定义 Netstack::Utils::Set 方法属性
#------------------------------------------------------------------------------
has mins => (
  is      => 'rw',
  isa     => 'ArrayRef[Int]',
  default => sub { [] },
);

has maxs => (
  is      => 'rw',
  isa     => 'ArrayRef[Int]',
  default => sub { [] },
);

#------------------------------------------------------------------------------
# Moose BUILDARGS 钩子函数
#------------------------------------------------------------------------------
around BUILDARGS => sub {
  my $orig  = shift;
  my $class = shift;

  # 对象实例化钩子函数
  if ( @_ == 0 ) {
    return $class->$orig();
  }
  elsif ( @_ == 1 and ref( $_[0] ) eq __PACKAGE__ ) {
    my $setObj = $_[0];
    return $class->$orig(
      mins => \$setObj->mins->@*,
      maxs => \$setObj->maxs->@*
    );
  }
  elsif ( @_ == 2
    and defined $_[0]
    and defined $_[1]
    and $_[0] =~ /^\d+$/o
    and $_[1] =~ /^\d+$/o )
  {
    # 确保 MIN MAX 按顺序存放
    my ( $MIN, $MAX ) = $_[0] < $_[1] ? ( $_[0], $_[1] ) : ( $_[1], $_[0] );
    return $class->$orig(
      mins => [$MIN],
      maxs => [$MAX]
    );
  }
  else {
    return $class->$orig(@_);
  }
};

#------------------------------------------------------------------------------
# Moose BUILD 钩子函数 | 确保实例化对象的min max 按顺序存放和长度相等
#------------------------------------------------------------------------------
sub BUILD {
  my $self = shift;
  my @ERROR;
  my $lengthOfMin = $self->mins->@*;
  my $lengthOfMax = $self->maxs->@*;

  # 约束性检查 | 集合对象成员数必须相等、确保集合对象的 min < max
  if ( $lengthOfMin != $lengthOfMax ) {
    push @ERROR, 'Attribute (mins) and (maxs) must has same length at constructor ' . __PACKAGE__;
  }
  for ( my $i = 0; $i < $lengthOfMin; $i++ ) {
    if ( $self->mins->[$i] > $self->maxs->[$i] ) {
      push @ERROR, 'Attribute (mins) must not bigger than (maxs) in the same index at constructor ' . __PACKAGE__;
      last;
    }
  }
  # 异常拦截
  if ( @ERROR > 0 ) {
    confess join( ', ', @ERROR );
  }
}

#------------------------------------------------------------------------------
# 集合对象空间长度
#------------------------------------------------------------------------------
sub length {
  my $self = shift;
  # 集合对象长度
  my $lengthOfMin = $self->mins->@*;
  my $lengthOfMax = $self->maxs->@*;

  # 边界条件检查
  confess "ERROR: Attribute (mins) 's length($lengthOfMin) not equal (maxs) 's length($lengthOfMax)"
    if $lengthOfMin != $lengthOfMax;
  # 返回计算结果
  return $lengthOfMin;
}

#------------------------------------------------------------------------------
# min 集合对象最小值
#------------------------------------------------------------------------------
sub min {
  my $self = shift;
  return ( $self->length > 0 ? $self->mins->[0] : undef );
}

#------------------------------------------------------------------------------
# max 集合对象最大值
#------------------------------------------------------------------------------
sub max {
  my $self = shift;
  return ( $self->length > 0 ? $self->maxs->[-1] : undef );
}

#------------------------------------------------------------------------------
# dump 打印集合对象
#------------------------------------------------------------------------------
sub dump {
  my $self   = shift;
  my $length = $self->length;
  for ( my $i = 0; $i < $length; $i++ ) {
    say $self->mins->[$i] . "  " . $self->maxs->[$i];
  }
}

#------------------------------------------------------------------------------
# addToSet 不需要检查重复，需要检查排序，所以用这个的时候要特别慎重
# 只有在确定输入与set不重复的情况下才可使用，否则会有问题
#------------------------------------------------------------------------------
sub addToSet {
  my ( $self, $MIN, $MAX ) = @_;
  # 确保集合对象的顺序
  ( $MIN, $MAX ) = $MIN > $MAX ? ( $MAX, $MIN ) : ( $MIN, $MAX );

  # 检查是否存在集合对象，空集合对象直接插入数据
  my $length = $self->length;
  if ( $length == 0 ) {
    $self->mins( [$MIN] );
    $self->maxs( [$MAX] );
    return;
  }

  my $minArray = $self->mins;
  my $maxArray = $self->maxs;

  # 遍历集合对象 minArray(本身线性递增) | 非空集合则需要确定插入点
  my $index;
  for ( my $i = 0; $i < $length; $i++ ) {
    # 从最小成员对象开始查找，插入点落在集合区间左开部分
    if ( $MIN < $minArray->[$i] ) {
      $index = $i;
      last;
    }
  }

  # 找了一圈仍未确定插入点，则必定在最后一个集合区间
  $index = $length if not defined $index;

  # 确定插入点填充实际数据
  my ( @min, @max );
  push @min, $minArray->@[ 0 .. $index - 1 ];
  push @max, $maxArray->@[ 0 .. $index - 1 ];
  push @min, $MIN;
  push @max, $MAX;
  push @min, $minArray->@[ $index .. $length - 1 ];
  push @max, $maxArray->@[ $index .. $length - 1 ];

  # 数据绑定
  $self->mins( \@min );
  $self->maxs( \@max );
}

#------------------------------------------------------------------------------
# mergeToSet 合并到已有集合对象，需要检查重复，也需要检查排序 | 支持传入集合对象、数组
#------------------------------------------------------------------------------
sub mergeToSet {
  my $self = shift;
  # 入参是否为一个集合对象
  if ( @_ == 1 and ref( $_[0] ) eq __PACKAGE__ ) {
    my $setObj = $_[0];
    my $length = $setObj->length;
    # 遍历集合对象并合并数据
    for ( my $i = 0; $i < $length; $i++ ) {
      $self->_mergeToSet( $setObj->mins->[$i], $setObj->maxs->[$i] );
    }
  }
  else {
    $self->_mergeToSet(@_);
  }
}

#------------------------------------------------------------------------------
# mergeToSet 合并到已有集合对象
#------------------------------------------------------------------------------
sub _mergeToSet {
  my ( $self, $MIN, $MAX ) = @_;
  # 检查排序
  ( $MIN, $MAX ) = $MIN > $MAX ? ( $MAX, $MIN ) : ( $MIN, $MAX );

  # 判断是否已经初始化过 mins maxs 对象
  my $length = $self->length;
  if ( $length == 0 ) {
    $self->mins( [$MIN] );
    $self->maxs( [$MAX] );
    return;
  }

  my $minArray = $self->mins;
  my $maxArray = $self->maxs;
  # 索引位置在数组长度区间各偏移一个单位
  my ( $minIndex, $maxIndex ) = ( -1, $length );

  # 边际递减确定合并数据的区间，合并数据可能跨界（分布在多个集合区间）
  MIN: {
    for ( my $i = 0; $i < $length; $i++ ) {
      # 命中集合对象区间 ($minArray, $maxArray)
      if ( $MIN >= $minArray->[$i] and $MIN <= $maxArray->[$i] ) {
        $minIndex = $i;
        last MIN;
      }
      # 命中集合对象区间 ($minArray, $maxArray) 左开区间 | 比最小还小
      elsif ( $MIN < $minArray->[$i] ) {
        $minIndex += 0.5;
        last MIN;
      }
      # 命中集合对象区间 ($minArray, $maxArray) 右开区间 | 比最大还大
      # 集合对象可能存在多个不连续区间，该动作代表移位计算（当前区间不满足要求）
      else {
        $minIndex++;
      }
    }
    $minIndex += 0.5;
  }
  MAX: {
    for ( my $j = $length - 1; $j >= $minIndex; $j-- ) {
      # 命中集合对象区间 ($minArray, $maxArray)
      if ( $MAX >= $minArray->[$j] and $MAX <= $maxArray->[$j] ) {
        $maxIndex = $j;
        last MAX;
      }
      # 命中集合对象区间 ($minArray, $maxArray) 右开区间，比最大还大
      elsif ( $MAX > $maxArray->[$j] ) {
        $maxIndex -= 0.5;
        last MAX;
      }
      # 命中集合对象区间 ($minArray, $maxArray) 左开区间，比最小还小
      # 集合对象可能存在多个不连续区间，该动作代表移位计算（当前区间不满足要求）
      else {
        $maxIndex--;
      }
    }
    $maxIndex -= 0.5;
  }

  # 分别向上向下取整 POSIX::ceil(0.5) = 1, POSIX::floor(-0.5) = -1
  my $minIndexInt = POSIX::ceil($minIndex);
  my $maxIndexInt = POSIX::floor($maxIndex);
  # 是否命中已有集合区间
  my $isMinIndexInSet = ( $minIndex == $minIndexInt ) ? 1 : 0;
  my $isMaxIndexInSet = ( $maxIndex == $maxIndexInt ) ? 1 : 0;
  # 已确定插入点合并数据
  my ( @min, @max );
  push @min, $minArray->@[ 0 .. $minIndexInt - 1 ];
  push @max, $maxArray->@[ 0 .. $minIndexInt - 1 ];
  push @min, $isMinIndexInSet ? $minArray->[$minIndex] : $MIN;
  push @max, $isMaxIndexInSet ? $maxArray->[$maxIndex] : $MAX;
  push @min, $minArray->@[ $maxIndexInt + 1 .. $length - 1 ];
  push @max, $maxArray->@[ $maxIndexInt + 1 .. $length - 1 ];
  # 数据绑定
  $self->mins( \@min );
  $self->maxs( \@max );
}

#------------------------------------------------------------------------------
# compare 比对两个集合对象关系 | 包括完全相等、包含但不相等、属于另一个集合但不相等、其他
#------------------------------------------------------------------------------
sub compare {
  my ( $self, $setObj ) = @_;
  if ( $self->isEqual($setObj) ) {
    return 'equal';
  }
  elsif ( $self->_isContain($setObj) ) {
    return 'containButNotEqual';
  }
  elsif ( $self->_isBelong($setObj) ) {
    return 'belongButNotEqual';
  }
  else {
    return 'other';
  }
}

#------------------------------------------------------------------------------
# isEqual 两个集合对象完全相同 | "~~ 判断两个数组对象是否相等"
#------------------------------------------------------------------------------
sub isEqual {
  my ( $self, $setObj ) = @_;
  return ( $self->mins->@* ~~ $setObj->mins->@* and $self->maxs->@* ~~ $setObj->maxs->@* );
}

#------------------------------------------------------------------------------
# notEqual 两个集合对象不等性判断 | 基于isEqual取反
#------------------------------------------------------------------------------
sub notEqual {
  my ( $self, $setObj ) = @_;
  return !( $self->mins->@* ~~ $setObj->mins->@* and $self->maxs->@* ~~ $setObj->maxs->@* );
}

#------------------------------------------------------------------------------
# isContain A对象是否包含B对象
#------------------------------------------------------------------------------
sub isContain {
  my ( $self, $setObj ) = @_;
  # 完全一致
  if ( $self->isEqual($setObj) ) {
    return 1;
  }
  else {
    return $self->_isContain($setObj);
  }
}

#------------------------------------------------------------------------------
# _isContain 两个对象相等也理解为包含另外一个对象
#------------------------------------------------------------------------------
sub _isContain {
  my ( $self, $setObj ) = @_;
  # 复刻一份self集合对象
  my $copyOfSelf = Netstack::Utils::Set->new($self);
  # 合并B集合对象到A集合对象
  $copyOfSelf->mergeToSet($setObj);
  # 将A集合与$copyOfSelf比较，合并B集合对象的没有发生改变，代表B为A的子集
  return $self->isEqual($copyOfSelf);
}

#------------------------------------------------------------------------------
# isContainButNotEqual A对象包含B对象，且两个对象不相等
#------------------------------------------------------------------------------
sub isContainButNotEqual {
  my ( $self, $setObj ) = @_;
  if ( $self->isEqual($setObj) ) {
    return;
  }
  else {
    return $self->_isContain($setObj);
  }
}

#------------------------------------------------------------------------------
# isBelong B对象是否包含A对象
#------------------------------------------------------------------------------
sub isBelong {
  my ( $self, $setObj ) = @_;
  if ( $self->isEqual($setObj) ) {
    return 1;
  }
  else {
    return $self->_isBelong($setObj);
  }
}

#------------------------------------------------------------------------------
# _isBelong B对象是否包含A对象
#------------------------------------------------------------------------------
sub _isBelong {
  my ( $self, $setObj ) = @_;
  # 复刻B集合对象
  my $copyOfSetObj = Netstack::Utils::Set->new($setObj);
  # 将A对象合并到复刻的B集合对象
  $copyOfSetObj->mergeToSet($self);
  # 判断B对象与合并A的复刻B对象是否相等，合并过来没发生改变，代表A为B的子集
  return $setObj->isEqual($copyOfSetObj);
}

#------------------------------------------------------------------------------
# isBelongButNotEqual B对象是否包含A对象，且两个对象不相等
#------------------------------------------------------------------------------
sub isBelongButNotEqual {
  my ( $self, $setObj ) = @_;
  if ( $self->isEqual($setObj) ) {
    return;
  }
  else {
    return $self->_isBelong($setObj);
  }
}

#------------------------------------------------------------------------------
# interSet B对象是否包含A对象，且两个对象不相等
#------------------------------------------------------------------------------
sub interSet {
  my ( $self, $setObj ) = @_;
  # 实例化集合对象
  my $result = Netstack::Utils::Set->new;
  # 检查是否已携带 min max 属性
  if ( $self->length == 0 ) {
    return $self;
  }
  if ( $setObj->length == 0 ) {
    return $setObj;
  }

  # 遍历两个集合对象
  my $i = 0;
  my $j = 0;
  while ( $i < $self->length and $j < $setObj->length ) {
    my @rangeSet1 = ( $self->mins->[$i],   $self->maxs->[$i] );
    my @rangeSet2 = ( $setObj->mins->[$j], $setObj->maxs->[$j] );
    # 两个数组的最大最小值|可能返回 undef
    my ( $min, $max ) = $self->interRange( \@rangeSet1, \@rangeSet2 );
    # 如果定义了 min 则合并到初始化的集合对象
    $result->_mergeToSet( $min, $max ) if defined $min;

    # B对象比A对象的最大值还大，自增A对象区间值
    if ( $setObj->maxs->[$j] > $self->maxs->[$i] ) {
      $i++;
    }
    # B对象的最大值和A对象的最大值相等
    elsif ( $setObj->maxs->[$j] == $self->maxs->[$i] ) {
      $i++;
      $j++;
    }
    # B对象比A对象的最小值还小，自增B对象区间值
    else {
      $j++;
    }
  }
  return $result;
}

#------------------------------------------------------------------------------
# interRange 返回两个集合对象的最大最小值
#------------------------------------------------------------------------------
sub interRange {
  my ( $self, $rangeSet1, $rangeSet2 ) = @_;
  my $min
    = ( $rangeSet1->[0] < $rangeSet2->[0] )
    ? $rangeSet1->[0]
    : $rangeSet2->[0];
  my $max
    = ( $rangeSet1->[1] > $rangeSet2->[1] )
    ? $rangeSet1->[1]
    : $rangeSet2->[1];

  # 返回计算结果
  return ( $min > $max )
    ? undef
    : ( $min, $max );
}

#------------------------------------------------------------------------------
# addToSet _mergeToSet 入参检查，必须传入2个数字
#------------------------------------------------------------------------------
for my $func (qw/ addToSet _mergeToSet /) {
  before $func => sub {
    my $self = shift;
    unless ( @_ == 2 and $_[0] =~ /^\d+$/o and $_[1] =~ /^\d+$/o ) {
      confess "ERROR: function $func can only has two numeric argument";
    }
  }
}

#------------------------------------------------------------------------------
# 集合对象比较函数钩子函数，确保入参为集合对象
#------------------------------------------------------------------------------
for my $func (qw/ compare isEqual isContain _isContain isContainButNotEqual isBelong _isBelong isBelongButNotEqual /) {
  before $func => sub {
    my $self = shift;
    confess "ERROR: the first param of function($func) is not a Netstack::Utils::Set"
      if ref( $_[0] ) ne 'Netstack::Utils::Set';
  }
}

__PACKAGE__->meta->make_immutable;
1;

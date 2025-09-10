package PDK::Utils::Set;

use utf8;
use v5.30;
use Moose;
use namespace::autoclean;
use Carp;
use POSIX;
use Data::Dumper;
use experimental 'smartmatch';

# 最小值数组属性，存储每个区间的最小值
has mins => (
    is      => 'rw',            # 读写属性
    isa     => 'ArrayRef[Int]', # 整数数组引用类型
    default => sub {[]},        # 默认值为空数组
);

# 最大值数组属性，存储每个区间的最大值
has maxs => (
    is      => 'rw',            # 读写属性
    isa     => 'ArrayRef[Int]', # 整数数组引用类型
    default => sub {[]},        # 默认值为空数组
);

# 构建参数处理
around BUILDARGS => sub {
    my $orig = shift;
    my $class = shift;

    if (@_ == 0) {
        # 无参数调用，使用默认值
        return $class->$orig();
    }
    elsif (@_ == 1 and ref($_[0]) eq __PACKAGE__) {
        # 单个参数且为同类对象，复制其区间
        my $setObj = $_[0];
        return $class->$orig(mins => [ @{$setObj->mins} ], maxs => [ @{$setObj->maxs} ]);
    }
    elsif (@_ == 2 and defined $_[0] and defined $_[1] and $_[0] =~ /^\d+$/o and $_[1] =~ /^\d+$/o) {
        # 两个数字参数，创建一个区间
        my ($MIN, $MAX) = $_[0] < $_[1] ? ($_[0], $_[1]) : ($_[1], $_[0]);
        return $class->$orig(mins => [ $MIN ], maxs => [ $MAX ]);
    }
    else {
        # 其他情况，直接传递参数
        return $class->$orig(@_);
    }
};

# 对象构建验证
sub BUILD {
    my $self = shift;
    my @ERROR;
    my $lengthOfMin = @{$self->mins};
    my $lengthOfMax = @{$self->maxs};

    # 检查最小值和最大值数组长度是否一致
    if ($lengthOfMin != $lengthOfMax) {
        push(@ERROR, '属性 (mins) 和 (maxs) 在构造函数 ' . __PACKAGE__ . ' 中必须保持相同长度');
    }

    # 检查每个区间的最小值是否不大于最大值
    for (my $i = 0; $i < $lengthOfMin; $i++) {
        if ($self->mins->[$i] > $self->maxs->[$i]) {
            push(@ERROR, '在构造函数 ' . __PACKAGE__ . ' 中，同一索引位置的 (mins) 不能大于 (maxs)');
            last;
        }
    }

    # 如果有错误，抛出异常
    if (@ERROR > 0) {
        confess(join(', ', @ERROR));
    }
}

# 获取区间数量
sub length {
    my $self = shift;
    my $lengthOfMin = @{$self->mins};
    my $lengthOfMax = @{$self->maxs};

    # 验证最小值和最大值数组长度一致
    confess("错误: 属性 (mins) 的长度($lengthOfMin) 与 (maxs) 的长度($lengthOfMax) 不一致") if $lengthOfMin != $lengthOfMax;

    return $lengthOfMin;
}

# 获取整体最小值
sub min {
    my $self = shift;
    return ($self->length > 0 ? $self->mins->[0] : undef);
}

# 获取整体最大值
sub max {
    my $self = shift;
    return ($self->length > 0 ? $self->maxs->[-1] : undef);
}

# 输出所有区间
sub dump {
    my $self = shift;
    my $length = $self->length;
    for (my $i = 0; $i < $length; $i++) {
        say $self->mins->[$i] . "  " . $self->maxs->[$i]
    }
}

# 向集合中添加区间（不检查重叠）
# 注意：使用该方法时需特别谨慎，只有在确定输入与现有区间不重叠时才能使用，否则可能导致错误。
sub addToSet {
    my ($self, $MIN, $MAX) = @_;

    # 确保最小值不大于最大值
    if ($MIN > $MAX) {
        ($MAX, $MIN) = ($MIN, $MAX)
    }

    my $length = $self->length;

    # 如果集合为空，直接添加
    if ($length == 0) {
        $self->mins([ $MIN ]);
        $self->maxs([ $MAX ]);
        return;
    }

    my $minArray = $self->mins;
    my $maxArray = $self->maxs;
    my $index;

    # 查找插入位置
    for (my $i = 0; $i < $length; $i++) {
        if ($MIN < $minArray->[$i]) {
            $index = $i;
            last;
        }
    }

    # 如果未找到插入位置，说明应插入到末尾
    $index = $length if not defined $index;

    # 构建新的区间数组
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

# 合并区间到集合（检查并合并重叠区间）
sub mergeToSet {
    my $self = shift;

    # 处理单个Set对象参数
    if (@_ == 1 and ref($_[0]) eq __PACKAGE__) {
        my $setObj = $_[0];
        my $length = $setObj->length;
        for (my $i = 0; $i < $length; $i++) {
            $self->_mergeToSet($setObj->mins->[$i], $setObj->maxs->[$i]);
        }
    }
    else {
        # 处理两个数字参数
        $self->_mergeToSet(@_);
    }
}

# 内部方法：合并单个区间到集合
sub _mergeToSet {
    my ($self, $MIN, $MAX) = @_;

    # 确保最小值不大于最大值
    if ($MIN > $MAX) {
        ($MAX, $MIN) = ($MIN, $MAX)
    }

    my $length = $self->length;

    # 如果集合为空，直接添加
    if ($length == 0) {
        $self->mins([ $MIN ]);
        $self->maxs([ $MAX ]);
        return;
    }

    my $minArray = $self->mins;
    my $maxArray = $self->maxs;
    my ($minIndex, $maxIndex) = (-1, $length);

    # 查找新区间的最小值位置
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

    # 查找新区间的最大值位置
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

    # 计算整数索引位置
    # min使用向上取整，即 POSIX::ceil(0.5) == 1 ,  POSIX::ceil(1) == 1
    # max使用向下取整，即 POSIX::floor(-0.5) == -1 ,  POSIX::floor(-1) == -1
    my $minIndexInt = POSIX::ceil($minIndex);
    my $maxIndexInt = POSIX::floor($maxIndex);
    my $isMinIndexInSet = $minIndex == $minIndexInt ? 1 : 0;
    my $isMaxIndexInSet = $maxIndex == $maxIndexInt ? 1 : 0;

    # 构建合并后的区间数组
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

# 比较两个集合的关系
sub compare {
    my ($self, $setObj) = @_;
    if ($self->isEqual($setObj)) {
        return 'equal'; # 相等
    }
    elsif ($self->_isContain($setObj)) {
        return 'containButNotEqual'; # 包含但不相等
    }
    elsif ($self->_isBelong($setObj)) {
        return 'belongButNotEqual'; # 属于但不相等
    }
    else {
        return 'other'; # 其他关系
    }
}

# 判断两个集合是否相等
sub isEqual {
    my ($self, $setObj) = @_;
    return (@{$self->mins} ~~ @{$setObj->mins} and @{$self->maxs} ~~ @{$setObj->maxs});
}

# 判断两个集合是否不相等
sub notEqual {
    my ($self, $setObj) = @_;
    return !(@{$self->mins} ~~ @{$setObj->mins} and @{$self->maxs} ~~ @{$setObj->maxs});
}

# 判断当前集合是否包含另一个集合（包含相等情况）
sub isContain {
    my ($self, $setObj) = @_;
    if ($self->isEqual($setObj)) {
        return 1;
    }
    else {
        return $self->_isContain($setObj);
    }
}

# 内部方法：判断当前集合是否包含另一个集合（不包含相等情况）
sub _isContain {
    my ($self, $setObj) = @_;
    my $copyOfSelf = PDK::Utils::Set->new($self);
    $copyOfSelf->mergeToSet($setObj);
    return $self->isEqual($copyOfSelf);
}

# 判断当前集合是否包含另一个集合但不相等
sub isContainButNotEqual {
    my ($self, $setObj) = @_;
    if ($self->isEqual($setObj)) {
        return 0;
    }
    else {
        return $self->_isContain($setObj);
    }
}

# 判断当前集合是否属于另一个集合（包含相等情况）
sub isBelong {
    my ($self, $setObj) = @_;
    if ($self->isEqual($setObj)) {
        return 1;
    }
    else {
        return $self->_isBelong($setObj);
    }
}

# 内部方法：判断当前集合是否属于另一个集合（不包含相等情况）
sub _isBelong {
    my ($self, $setObj) = @_;
    my $copyOfSetObj = PDK::Utils::Set->new($setObj);
    $copyOfSetObj->mergeToSet($self);
    return $setObj->isEqual($copyOfSetObj);
}

# 判断当前集合是否属于另一个集合但不相等
sub isBelongButNotEqual {
    my ($self, $setObj) = @_;
    if ($self->isEqual($setObj)) {
        return 0;
    }
    else {
        return $self->_isBelong($setObj);
    }
}

# 计算两个集合的交集
sub interSet {
    my $result = PDK::Utils::Set->new;
    my ($self, $setObj) = @_;

    # 如果任一集合为空，返回空集合
    if ($self->length == 0) {
        return $self;
    }
    if ($setObj->length == 0) {
        return $setObj;
    }

    # 使用双指针法计算交集
    my $i = 0;
    my $j = 0;

    while ($i < $self->length and $j < $setObj->length) {
        my @rangeSet1 = ($self->mins->[$i], $self->maxs->[$i]);
        my @rangeSet2 = ($setObj->mins->[$j], $setObj->maxs->[$j]);
        my ($min, $max) = $self->interRange(\@rangeSet1, \@rangeSet2);
        $result->_mergeToSet($min, $max) if defined $min;

        # 移动指针
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

# 计算两个区间的交集
sub interRange {
    my ($self, $rangeSet1, $rangeSet2) = @_;
    my ($min, $max);

    # 计算交集的最小值和最大值
    $min = $rangeSet1->[0] > $rangeSet2->[0] ? $rangeSet1->[0] : $rangeSet2->[0];
    $max = $rangeSet1->[1] < $rangeSet2->[1] ? $rangeSet1->[1] : $rangeSet2->[1];

    # 如果没有交集，返回空
    if ($min > $max) {
        return;
    }
    else {
        return ($min, $max);
    }
}

# 为方法添加参数验证
for my $func (qw(addToSet _mergeToSet)) {
    before $func => sub {
        my $self = shift;
        unless (@_ == 2 and $_[0] =~ /^\d+$/o and $_[1] =~ /^\d+$/o) {
            confess("错误: 方法 $func 只能接收两个数字参数");
        }
    }
}

# 为比较方法添加参数验证
for my $func (qw(compare isEqual isContain _isContain isContainButNotEqual isBelong _isBelong isBelongButNotEqual)) {
    before $func => sub {
        my $self = shift;
        confess("错误: 方法($func) 的第一个参数必须是 PDK::Utils::Set 对象") if ref($_[0]) ne 'PDK::Utils::Set';
    }
};

__PACKAGE__->meta->make_immutable;
1;

=encoding utf8
=head1 名称

PDK::Utils::Set - 区间集合操作工具类

=head1 简介

该模块提供了一个基于区间的集合类，实现了区间的添加、合并、比较、交集等常用操作。

=head1 属性

=over 4

=item mins

整数数组引用，存储区间集合中每个区间的最小值。

=item maxs

整数数组引用，存储区间集合中每个区间的最大值。

=back

=head1 构造方法

=over 4

=item new()

无参数构造，创建一个空集合。

=item new($setObj)

传入同类对象，复制其区间。

=item new($MIN, $MAX)

传入两个整数，创建一个单区间集合。

=item new(%args)

传入参数哈希，手动指定 C<mins> 与 C<maxs>。

=back

=head1 方法说明

=head2 基础操作

=over 4

=item length()

返回集合中的区间数量。

=item min()

返回集合整体的最小值（第一个区间的最小值），若集合为空返回 undef。

=item max()

返回集合整体的最大值（最后一个区间的最大值），若集合为空返回 undef。

=item dump()

打印所有区间，格式为 "MIN  MAX"。

=back

=head2 集合构造与合并

=over 4

=item addToSet($MIN, $MAX)

向集合中插入区间（不检查重叠，需保证输入与现有区间不冲突）。

=item mergeToSet($MIN, $MAX | $setObj)

向集合中合并区间，若重叠或相邻则会自动合并。

=back

=head2 集合比较

=over 4

=item compare($setObj)

比较两个集合的关系，返回以下字符串之一：

=over 8

=item * equal - 两个集合完全相等

=item * containButNotEqual - 当前集合包含对方但不相等

=item * belongButNotEqual - 当前集合属于对方但不相等

=item * other - 其他关系

=back

=item isEqual($setObj)

判断集合是否相等。

=item notEqual($setObj)

判断集合是否不相等。

=item isContain($setObj)

判断当前集合是否包含另一个集合（包含相等情况）。

=item isContainButNotEqual($setObj)

判断当前集合是否包含另一个集合但不相等。

=item isBelong($setObj)

判断当前集合是否属于另一个集合（包含相等情况）。

=item isBelongButNotEqual($setObj)

判断当前集合是否属于另一个集合但不相等。

=back

=head2 集合运算

=over 4

=item interSet($setObj)

返回两个集合的交集，结果为新的集合对象。

=item interRange(\@rangeSet1, \@rangeSet2)

计算两个区间的交集，返回 (MIN, MAX)，若无交集则返回空。

=back

=head1 错误处理

=over 4

=item *

如果 C<mins> 与 C<maxs> 长度不一致，构造函数会抛出异常。

=item *

如果同一索引的最小值大于最大值，构造函数会抛出异常。

=item *

C<addToSet> 与 C<_mergeToSet> 方法只允许传入两个整数参数，否则抛出异常。

=item *

比较方法的参数必须是 C<Firewall::Utils::Set> 对象，否则抛出异常。

=back

=head1 使用示例

    use PDK::Utils::Set;

    # 创建区间集合
    my $set = PDK::Utils::Set->new(1, 5);
    $set->addToSet(10, 20);

    # 合并区间
    $set->mergeToSet(6, 9);

    # 打印集合
    $set->dump;

    # 交集
    my $set2 = PDK::Utils::Set->new(4, 15);
    my $inter = $set->interSet($set2);
    $inter->dump;

    # 比较关系
    say $set->compare($set2);   # equal / containButNotEqual / belongButNotEqual / other

=head1 作者

WENWU YAN E<lt>968828@gmail.comE<gt>

=head1 版权与许可

本模块遵循与 Perl 相同的许可协议。

=cut


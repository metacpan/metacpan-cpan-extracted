package PDK::Utils::Cache;

use utf8;
use v5.30;
use Moose;
use namespace::autoclean;
use Carp;

our $VERSION = '0.005';

# 缓存数据结构属性
has cache => (
    is      => 'ro',           # 只读属性
    isa     => 'HashRef[Ref]', # 哈希引用，值为引用类型
    default => sub {{}},       # 默认值为空哈希引用
);

# 获取缓存值
sub get {
    my $self = shift;
    my @keys = @_;

    return $self->locate(@_);
}

# 设置缓存值
sub set {
    my $self = shift;
    # 参数检查：至少需要键和值
    confess("错误：至少要有一个键和一个值") if @_ < 2;

    my $value = pop;   # 最后一个参数为值
    my $lastKey = pop; # 倒数第二个参数为最后一级键
    my @keys = @_;     # 其余参数为路径键

    my @step; # 记录路径用于错误信息
    my $ref = $self->cache;

    # 遍历路径键，构建嵌套哈希结构
    while (my $key = shift @keys) {
        push(@step, $key);

        # 如果当前键不存在，创建新的哈希引用
        if (not exists $ref->{$key}) {
            $ref->{$key} = {};
        }

        $ref = $ref->{$key};

        # 检查当前引用是否为哈希引用
        if (defined $ref and ref($ref) ne 'HASH') {
            confess("错误：cache->" . join('->', @step) . " 不是一个哈希引用");
        }
    }

    # 设置最终键的值
    $ref->{$lastKey} = $value;
}

# 清除缓存
sub clear {
    my $self = shift;
    my @keys = @_;

    if (@keys) {
        # 清除指定路径的缓存
        my $lastKey = pop @keys;
        my $ref = $self->locate(@keys);

        if (defined $ref and ref($ref) eq 'HASH') {
            delete($ref->{$lastKey});
        }
    }
    else {
        # 清除所有缓存
        $self->{cache} = {};
    }
}

# 定位到缓存中的指定路径
sub locate {
    my $self = shift;
    my @keys = @_;
    my $ref = $self->cache;

    # 沿着键路径遍历
    while (my $key = shift @keys) {
        # 如果键不存在，返回未定义值
        if (not exists $ref->{$key}) {
            $ref = undef;
            last;
        }

        $ref = $ref->{$key};
    }

    return $ref;
}

__PACKAGE__->meta->make_immutable;
1;

=encoding utf8
=head1 NAME

PDK::Utils::Cache - 简单的层级缓存工具类

=head1 SYNOPSIS

    use PDK::Utils::Cache;

    my $cache = PDK::Utils::Cache->new;

    # 设置缓存
    $cache->set('user', 'profile', 'name', 'Wenwu');
    $cache->set('user', 'profile', 'age', 18);

    # 获取缓存
    my $name = $cache->get('user', 'profile', 'name'); # Wenwu

    # 删除指定缓存
    $cache->clear('user', 'profile', 'age');

    # 清空缓存
    $cache->clear();

=head1 DESCRIPTION

该模块提供一个基于 Perl 哈希结构的简易缓存工具，支持多级键路径的存取和清除操作，适合在程序运行期间存储临时数据。

=head1 ATTRIBUTES

=head2 cache

    isa => HashRef[Ref]
    is  => 'ro'

内部缓存数据结构，默认是一个空的哈希引用。

=head1 METHODS

=head2 get(@keys)

    my $value = $cache->get('user', 'profile', 'name');

根据多级键路径获取缓存值。

等价于调用 C<locate(@keys)>。

=head2 set(@keys, $value)

    $cache->set('user', 'profile', 'name', 'Wenwu');

设置缓存值，支持多级路径。

参数要求：

=over 4

=item * 至少包含一个键和一个值

=item * 路径上不存在的键会自动创建为新的哈希引用

=item * 如果路径上的某个节点不是哈希引用，会抛出异常

=back

=head2 clear(@keys)

    $cache->clear();                        # 清除所有缓存
    $cache->clear('user', 'profile', 'id'); # 清除指定路径的缓存值

清除缓存数据：

=over 4

=item * 无参数：清空所有缓存

=item * 指定路径：删除路径上对应的值

=back

=head2 locate(@keys)

    my $ref = $cache->locate('user', 'profile');

返回指定路径对应的值或引用。

如果路径不存在，返回 undef。

=head1 EXAMPLES

    use PDK::Utils::Cache;

    my $cache = PDK::Utils::Cache->new;

    # 设置缓存
    $cache->set('user', 'profile', 'name', 'Wenwu');
    $cache->set('user', 'profile', 'age', 18);

    # 获取缓存
    my $name = $cache->get('user', 'profile', 'name'); # Wenwu

    # 删除指定缓存
    $cache->clear('user', 'profile', 'age');

    # 清空缓存
    $cache->clear();

=head1 ERROR HANDLING

=over 4

=item *

调用 C<set> 时，如果路径上的某个节点不是哈希引用，会抛出异常。

=item *

调用 C<set> 时，如果参数少于两个（缺少键或值），会抛出异常。

=back

=head1 AUTHOR

WENWU YAN E<lt>968828@gmail.comE<gt>

=head1 LICENSE AND COPYRIGHT

This software is licensed under the same terms as Perl itself.

=cut

package Netstack::Utils::Cache;

#------------------------------------------------------------------------------
# 加载扩展模块功能
#------------------------------------------------------------------------------
use 5.018;
use Moose;
use namespace::autoclean;

#------------------------------------------------------------------------------
# 定义 Netstack::Utils::Cache 方法属性
#------------------------------------------------------------------------------
has cache => (
  is      => 'ro',
  isa     => 'HashRef[Ref]',
  default => sub { {} },
);

#------------------------------------------------------------------------------
# get 获取缓存数据 | 查询特定的缓存对象
#------------------------------------------------------------------------------
sub get {
  my $self = shift;
  return $self->locate(@_);
}

#------------------------------------------------------------------------------
# set 设置缓存数据 | 设置特定的缓存对象
#------------------------------------------------------------------------------
sub set {
  my $self = shift;
  confess __PACKAGE__ . " ERROR: 必须提供键值对" if @_ < 2;
  # 初始化变量
  my $value   = pop;
  my $lastKey = pop;
  my @keys    = @_;
  my $ref     = $self->cache;
  # 提供2个以上入参
  my @step;
  while ( my $key = shift @keys ) {
    push @step, $key;
    if ( not exists $ref->{$key} ) {
      $ref->{$key} = undef;
    }
    $ref = $ref->{$key};
    if ( defined $ref and ref($ref) ne 'HASH' ) {
      confess "ERROR: cache->" . join( '->', @step ) . " not a valid HashRef";
    }
  }
  $ref->{$lastKey} = $value;
}

#------------------------------------------------------------------------------
# clear 清楚缓存数据
#------------------------------------------------------------------------------
sub clear {
  my $self = shift;
  my @keys = @_;
  if (@keys) {
    my $lastKey = pop @keys;
    my $ref     = $self->locate(@keys);
    if ( defined $ref and ref($ref) eq 'HASH' ) {
      delete( $ref->{$lastKey} );
    }
  }
  else {
    $self->{cache} = {};
  }
}

#------------------------------------------------------------------------------
# locate 加载缓存,，只支持单值索引 | 加载特定的缓存对象
#------------------------------------------------------------------------------
sub locate {
  my $self = shift;
  # 初始化变量
  my @keys = @_;
  my $ref  = $self->cache;
  # 遍历待查询的 keyStr
  while ( my $key = shift @keys ) {
    if ( not exists $ref->{$key} ) {
      return;
    }
    $ref = $ref->{$key};
  }
  return $ref;
}

__PACKAGE__->meta->make_immutable;
1;

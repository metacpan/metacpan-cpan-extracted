package PDK::Utils::Cache;

# ABSTRACT: PDK Utils
#------------------------------------------------------------------------------
# 加载扩展模块
#------------------------------------------------------------------------------
use Moose;
use namespace::autoclean;

#------------------------------------------------------------------------------
# 定义模块方法属性
#------------------------------------------------------------------------------
has cache => (is => 'ro', isa => 'HashRef[Ref]', default => sub { {} },);

#------------------------------------------------------------------------------
# 定义模块方法属性
#------------------------------------------------------------------------------
sub get {
  my $self = shift;
  return $self->locate(@_);
}

#------------------------------------------------------------------------------
# 定义模块方法属性
#------------------------------------------------------------------------------
sub set {
  my $self = shift;
  confess "必须同时设定键值对才能缓存数据" if @_ < 2;

  my $value   = pop;
  my $lastKey = pop;
  my @keys    = @_;

  my @step;
  my $cache = $self->cache;
  while (my $key = shift @keys) {
    push @step, $key;

    # 判定是否存在缓存
    unless (exists $cache->{$key}) {
      $cache->{$key} = undef;
    }

    # 刷新 cache 对象
    if (defined $cache and ref $cache ne 'HASH') {
      confess "Cache->" . join('->', @step) . " not a valid HashRef";
    }
    else {
      $cache = $cache->{$key};
    }
  }
  $cache->{$lastKey} = $value;
}

#------------------------------------------------------------------------------
# 定义模块方法属性
#------------------------------------------------------------------------------
sub clear {
  my $self = shift;
  my @keys = @_;

  if (@keys) {
    my $lastKey = pop @keys;
    my $cache   = $self->locate(@keys);
    if (defined $cache and ref $cache eq 'HASH') {
      delete $cache->{$lastKey};
    }
  }
  else {
    $self->{cache} = {};
  }
}

#------------------------------------------------------------------------------
# 定义模块方法属性
#------------------------------------------------------------------------------
sub locate {
  my $self = shift;
  my @keys = @_;

  my $ref = $self->cache;
  while (my $key = shift @keys) {
    unless (exists $ref->{$key}) {
      $ref = undef;
      last;
    }
    else {
      $ref = $ref->{$key};
    }
  }
  return $ref;
}

__PACKAGE__->meta->make_immutable;
1;

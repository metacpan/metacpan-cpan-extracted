package PDK::Firewall::Element::Service::Role;

#------------------------------------------------------------------------------
# 加载扩展模块
#------------------------------------------------------------------------------
use Moose::Role;
use namespace::autoclean;

#------------------------------------------------------------------------------
# 加载 ServiceMeta 模块 - 类似 use Moose::Role，说明该模块继承 ServiceMeta
#------------------------------------------------------------------------------
use PDK::Firewall::Element::ServiceMeta::Role;

#------------------------------------------------------------------------------
# 继承 PDK::Firewall::Element::Role 方法属性
#------------------------------------------------------------------------------
with 'PDK::Firewall::Element::Role';

#------------------------------------------------------------------------------
# PDK::Firewall::Element::Service::Role 通用属性
#------------------------------------------------------------------------------
has srvName => (is => 'ro', isa => 'Str', required => 1,);

has srcPort => (is => 'ro', isa => 'Str', required => 0,);

has dstPort => (is => 'ro', isa => 'Str', required => 0,);

has description => (is => 'ro', isa => 'Str', required => 0,);

has range => (is => 'ro', isa => 'PDK::Utils::Set', lazy => 1, builder => '_buildRange',);

has metas => (is => 'ro', does => 'HashRef[PDK::Firewall::Element::ServiceMeta::Role]', default => sub { {} },);

has dstPortRangeMap => (is => 'ro', isa => 'HashRef[PDK::Utils::Set]', default => sub { {} },);

has refnum => (is => 'ro', isa => 'Int', default => 0);

#------------------------------------------------------------------------------
# 定义防火墙服务端口对象通用签名方法
#------------------------------------------------------------------------------
sub _buildSign {
  my $self = shift;
  return $self->createSign($self->srvName);
}

#------------------------------------------------------------------------------
# getServiceClassName 获取服务端口名
#------------------------------------------------------------------------------
sub getServiceClassName {
  return ref shift;
}

#------------------------------------------------------------------------------
# getServiceClassName 获取原始端口（预定义）名
#------------------------------------------------------------------------------
sub getServiceMetaClassName {
  my ($self, $serviceClassName) = @_;
  my $serviceMetaClassName = $serviceClassName // $self->getServiceClassName;
  $serviceMetaClassName =~ s/::Service::/::ServiceMeta::/o;
  return $serviceMetaClassName;
}

#------------------------------------------------------------------------------
# 对象已有属性是否和待比较属性是否一致
#------------------------------------------------------------------------------
sub diffAttr {
  my $self = shift;
  my ($obj, @attrs) = @_;
  my @ERROR;
  for my $attr (@attrs) {
    if ($self->$attr ne $obj->$attr) {
      push @ERROR, qq{输入的$attr [$obj->$attr] 与已有的$attr [$self->$attr] 不同};
    }
  }
  return @ERROR;
}

#------------------------------------------------------------------------------
# 服务端口添加源对象
#------------------------------------------------------------------------------
sub addMeta {
  my $self = shift;

  my $serviceClassName;
  my $serviceMetaClassName;
  eval {
    $serviceClassName     = $self->getServiceClassName;
    $serviceMetaClassName = $self->getServiceMetaClassName;
  } or confess "Can't getServiceClassName when execute addMeta method";

  if (@_ == 1 and $_[0]->isa($serviceClassName)) {
    my $serviceObj = $_[0];

    # 签名对象唯一性检查，确保为相同对象
    if (my @error = $self->diffAttr($serviceObj, qw/ sign /)) {
      confess('ERROR: ' . join(', ', @error) . ' 无法执行方法addMeta');
    }

    for my $meta (values %{$serviceObj->metas}) {
      unless (defined $self->metas->{$meta->sign}) {
        $self->metas->{$meta->sign} = $meta;
        $self->mergeDstPortRangeMap($meta);
      }
      else {
        warn qq{已存在 sign 为  $meta->{sign} 的 serviceMeta，无需再add\n};
      }
    }
  }
  else {
    my $meta;
    if (@_ == 1 and $_[0]->isa($serviceMetaClassName)) {
      $meta = $_[0];
    }
    else {
      eval "use $serviceMetaClassName; 1" or confess "Can't load plugin $serviceMetaClassName: $@";
      $meta = $serviceMetaClassName->new(@_);
    }

    unless (defined $self->metas->{$meta->sign}) {
      $self->metas->{$meta->sign} = $meta;
      $self->mergeDstPortRangeMap($meta);
    }
    else {
      warn qq{已存在 sign 为 $meta->{sign} 的 serviceMeta，无需再add\n};
    }
  }
}

#------------------------------------------------------------------------------
# 将源对象转换为集合对象
#------------------------------------------------------------------------------
sub mergeDstPortRangeMap {
  my ($self, $meta) = @_;
  my $protocol = $meta->protocol;
  $self->dstPortRangeMap->{$protocol} //= PDK::Utils::Set->new;
  $self->dstPortRangeMap->{$protocol}->mergeToSet($meta->dstPortRange);
}

#------------------------------------------------------------------------------
# 具体实现 range 属性懒加载方法
#------------------------------------------------------------------------------
sub _buildRange {
  my $self  = shift;
  my $range = PDK::Utils::Set->new;
  for my $meta (values %{$self->metas}) {
    $range->mergeToSet($meta->range);
  }
  return $range;
}

#------------------------------------------------------------------------------
# Moose BUILDARGS 在实例创建之前生效，可以接收哈希和哈希的引用
# https://metacpan.org/pod/Moose::Manual::Construction
# https://metacpan.org/pod/Moose::Object
# 必须设置为 $metaObj->sign，否则报错
#------------------------------------------------------------------------------
around BUILDARGS => sub {
  my $orig  = shift;
  my $class = shift;

  # 自动创建服务端口对象的 meta 属性，类似成员对象 - 如果服务端口支持多协议呢？
  if (@_ > 2) {
    my $serviceMetaClassName = $class->getServiceMetaClassName($class);
    eval "use $serviceMetaClassName; 1" or confess "Can't load module $serviceMetaClassName: $@";
    my $meta = $serviceMetaClassName->new(@_);
    return $class->$orig(@_, 'metas', {$meta->sign => $meta});
  }
  else {
    return $class->$orig(@_);
  }
};

#------------------------------------------------------------------------------
# Moose BUILD 用于对象创建后，进行属性检查逻辑
# https://metacpan.org/pod/Moose::Manual::Construction
#------------------------------------------------------------------------------
sub BUILD {
  my $self = shift;
  for my $meta (values %{$self->metas}) {
    $self->mergeDstPortRangeMap($meta);
  }
}

1;

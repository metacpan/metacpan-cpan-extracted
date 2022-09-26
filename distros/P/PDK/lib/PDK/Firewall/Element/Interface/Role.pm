package PDK::Firewall::Element::Interface::Role;

#------------------------------------------------------------------------------
# 加载扩展模块
#------------------------------------------------------------------------------
use Moose::Role;
use namespace::autoclean;
use PDK::Utils::Set;

#------------------------------------------------------------------------------
# 引用 PDK::Firewall::Element::Interface::Role 角色
#------------------------------------------------------------------------------
with 'PDK::Firewall::Element::Role';

#------------------------------------------------------------------------------
# PDK::Firewall::Element::Route::Role 通用属性
#------------------------------------------------------------------------------
has name => (is => 'ro', isa => 'Str', required => 1,);

has description => (is => 'ro', isa => 'Str', required => 0,);

has ipAddress => (is => 'ro', isa => 'Str', required => 0,);

has mask => (is => 'ro', isa => 'Int', required => 0,);

# 接口类型是二层还是三层
has interfaceType => (is => 'ro', isa => 'Str', default => 'layer2',);

has range => (is => 'ro', isa => 'PDK::Utils::Set', default => sub { PDK::Utils::Set->new() });

# 接口路由
has routes => (is => 'ro', isa => 'HashRef', default => sub { {} },);

# 接口安全区,并非每家厂商都实现接口关联安全区
has zoneName => (is => 'ro', isa => 'Str', required => 0,);

#------------------------------------------------------------------------------
# 设置防火墙接口通用签名方法
#------------------------------------------------------------------------------
sub _buildSign {
  my $self = shift;
  return $self->createSign($self->name);
}

#------------------------------------------------------------------------------
# 新增接口路由函数 => 路由对象
#------------------------------------------------------------------------------
sub addRoute {
  my ($self, $route) = @_;
  $self->routes->{$route->sign} = $route;
  $self->range->mergeToSet($route->range);
}

#------------------------------------------------------------------------------
# Moose BUILD 用于对象创建后，进行属性检查逻辑
# 运行时对象检查
# https://metacpan.org/pod/Moose::Manual::Construction
#------------------------------------------------------------------------------
sub BUILD {
  my $self = shift;
  my @ERROR;
  if ($self->interfaceType ne 'layer2' and $self->interfaceType ne 'layer3') {
    push @ERROR, "Attribute (interfaceType)'s value must be 'layer2' or 'layer3' at constructor " . __PACKAGE__;
  }
  confess join(', ', @ERROR) if (@ERROR > 0);
}

1;

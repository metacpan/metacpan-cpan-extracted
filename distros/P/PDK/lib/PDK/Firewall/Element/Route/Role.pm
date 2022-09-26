package PDK::Firewall::Element::Route::Role;

#------------------------------------------------------------------------------
# 加载扩展模块
#------------------------------------------------------------------------------
use Moose::Role;
use namespace::autoclean;
use PDK::Utils::Ip;

#------------------------------------------------------------------------------
# 继承 PDK::Firewall::Element::Role 方法属性
#-------------------------------------------------------------------------------
with 'PDK::Firewall::Element::Role';

#------------------------------------------------------------------------------
# 定义路由对象通用属性和方法
#------------------------------------------------------------------------------
has type => (is => 'ro', isa => 'Str', default => 'static',);

has description => (is => 'ro', isa => 'Str', default => 'static',);

has network => (is => 'ro', isa => 'Str', required => 0,);

has mask => (is => 'ro', isa => 'Int', required => 0,);

has nextHop => (is => 'ro', isa => 'Str', required => 0,);

# 路由对象关联 VRF
has routeInstance => (is => 'ro', isa => 'Str', default => 'default',);

has range => (is => 'ro', isa => 'PDK::Utils::Set', lazy => 1, builder => '_buildRange',);

# 路由关联的安全区
has zoneName => (is => 'ro', isa => 'Str', required => 0,);

has distance => (is => 'ro', isa => 'Int', default => 10,);

has priority => (is => 'ro', isa => 'Int', default => 10,);

# 策略路由相关属性 - 源接口、原地址掩码
has srcInterface => (is => 'ro', isa => 'Str', required => 0,);

has srcIpmask => (is => 'ro', isa => 'Str', required => 0,);

has srcRange => (is => 'ro', isa => 'PDK::Utils::Set', lazy => 1, builder => '_buildSrcRange',);

has dstInterface => (is => 'ro', isa => 'Str', required => 0,);

#------------------------------------------------------------------------------
# 路由对象通用签名方法
#------------------------------------------------------------------------------
sub _buildSign {
  my $self = shift;
  if ($self->type =~ /static|connect/i) {
    return $self->createSign($self->network, $self->mask);
  }
  else {
    return $self->createSign($self->network, $self->srcIpmask);
  }
}

#------------------------------------------------------------------------------
# 懒加载生成路由集合区间对象
#------------------------------------------------------------------------------
sub _buildRange {
  my $self = shift;
  return PDK::Utils::Ip->new->getRangeFromIpMask($self->network, $self->mask);
}

#------------------------------------------------------------------------------
# 懒加载生成策略路由集合区间对象
#------------------------------------------------------------------------------
sub _buildSrcRange {
  my $self = shift;
  if ($self->type eq 'policy') {
    if (my $srcIpmask = $self->srcIpmask) {
      my ($ip, $mask) = split('/', $srcIpmask);
      return PDK::Utils::Ip->new->getRangeFromIpMask($ip, $mask);
    }
    else {
      return PDK::Utils::Ip->new->getRangeFromIpMask('0.0.0.0', 0);
    }
  }
  else {
    return PDK::Utils::Ip->new->getRangeFromIpMask('0.0.0.0', 0);
  }
}

#------------------------------------------------------------------------------
# Moose BUILDARGS 在实例创建之前生效，可以接收哈希和哈希的引用
# https://metacpan.org/pod/Moose::Manual::Construction
# https://metacpan.org/pod/Moose::Object
#------------------------------------------------------------------------------
around BUILDARGS => sub {
  my $orig  = shift;
  my $class = shift;

  my %param = @_;
  $param{network} = PDK::Utils::Ip->new->getNetIpFromIpMask($param{network}, $param{mask});
  return $class->$orig(@_);
};

1;

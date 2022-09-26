package PDK::Firewall::Element::NatPool::Role;

#------------------------------------------------------------------------------
# 加载扩展模块
#------------------------------------------------------------------------------
use Moose::Role;
use namespace::autoclean;
use PDK::Utils::Ip;
use PDK::Utils::Set;

#------------------------------------------------------------------------------
# 继承 PDK::Firewall::Element::NatPool::Role 角色
#------------------------------------------------------------------------------
with 'PDK::Firewall::Element::Role';

#------------------------------------------------------------------------------
# PDK::Firewall::Element::NatPool::Role 通用属性
#------------------------------------------------------------------------------
has poolName => (is => 'ro', isa => 'Str', required => 1,);

has poolIp => (is => 'ro', isa => 'Str|ArrayRef', required => 1,);

has poolPort => (is => 'ro', isa => 'Int', required => 0,);

has natDirection => (is => 'ro', isa => 'Str', default => 'source',);

# _buildRange 需要具体实现
has poolRange => (is => 'ro', isa => 'PDK::Utils::Set', lazy => 1, builder => '_buildRange');

has poolPortRange => (is => 'ro', isa => 'PDK::Utils::Set', required => 0,);

# 地址转换为接口地址,特殊场景接口地址转换
has interfaceName => (is => 'ro', isa => 'Str', required => 0,);

has zone => (is => 'ro', isa => 'Str', required => 0,);

#------------------------------------------------------------------------------
# 设定地址转换池通用签名方法
#------------------------------------------------------------------------------
sub _buildSign {
  my $self = shift;
  return $self->createSign($self->poolName);
}

#------------------------------------------------------------------------------
# 具体实现PDK::Firewall::Element::NatPool::Role _buildRange 方法
#------------------------------------------------------------------------------
sub _buildRange {
  my $self = shift;
  if ($self->poolIp =~ /^(?<ipmin>[^-]+)(-|\s+)(?<ipmax>.+)$/ox) {
    my $min = PDK::Utils::Ip->new->getRangeFromIpMask(split('/', $+{ipmin}))->min;
    my $max = PDK::Utils::Ip->new->getRangeFromIpMask(split('/', $+{ipmax}))->max;
    return PDK::Utils::Set->new($min, $max);
  }
  elsif ($self->poolIp =~ /^\d+\.\d+\.\d+\.\d+(\/\d+)?\s*$/ox) {
    my ($ip, $mask) = split('/', $self->poolIp);
    return PDK::Utils::Ip->new->getRangeFromIpMask($ip, $mask);
  }
  else {
    warn "$self->poolIp is wrong!\n";
    return PDK::Utils::Set->new;
  }
}

1;

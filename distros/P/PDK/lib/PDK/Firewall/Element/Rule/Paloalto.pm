package PDK::Firewall::Element::Rule::Paloalto;

#------------------------------------------------------------------------------
# 加载扩展插件
#------------------------------------------------------------------------------
use Moose;
use namespace::autoclean;

#------------------------------------------------------------------------------
# 加载 SRX 解析插件
#------------------------------------------------------------------------------
use PDK::Firewall::Element::AddressGroup::Paloalto;
use PDK::Firewall::Element::ServiceGroup::Paloalto;

#------------------------------------------------------------------------------
# 继承 PDK::Firewall::Element::Rule::Role 角色 方法属性
#------------------------------------------------------------------------------
with 'PDK::Firewall::Element::Rule::Role';

#------------------------------------------------------------------------------
# 定义 PDK::Firewall::Element::Rule::Netscreen 方法属性
#------------------------------------------------------------------------------
has '+policyId' => (required => 0,);

has ruleName => (is => 'ro', isa => 'Str', required => 1,);

has fromZone => (is => 'ro', isa => 'ArrayRef', required => 0, traits => ['Array'], handles => {addFromZone => 'push'});

has toZone => (is => 'ro', isa => 'ArrayRef', required => 0, traits => ['Array'], handles => {addToZone => 'push'});

has '+action' => (required => 0, writer => 'setAction',);

#------------------------------------------------------------------------------
# 具体实现 PDK::Firewall::Element::Role => _buildRange 方法 | ruleName 唯一
#------------------------------------------------------------------------------
sub _buildSign {
  my $self = shift;
  return $self->createSign($self->ruleName);
}

#------------------------------------------------------------------------------
# PDK::Firewall::Element::Rule::Role _buildSrcAddressGroup 具体实现
#------------------------------------------------------------------------------
sub _buildSrcAddressGroup {
  my $self = shift;
  return PDK::Firewall::Element::AddressGroup::Paloalto->new(fwId => $self->fwId, addrGroupName => '^', zone => '^');
}

#------------------------------------------------------------------------------
# PDK::Firewall::Element::Rule::Role _buildDstAddressGroup 具体实现
#------------------------------------------------------------------------------
sub _buildDstAddressGroup {
  my $self = shift;
  return PDK::Firewall::Element::AddressGroup::Paloalto->new(fwId => $self->fwId, addrGroupName => '^', zone => '^');
}

#------------------------------------------------------------------------------
# PDK::Firewall::Element::Rule::Role _buildServiceGroup 具体实现
#------------------------------------------------------------------------------
sub _buildServiceGroup {
  my $self = shift;
  return PDK::Firewall::Element::ServiceGroup::Paloalto->new(fwId => $self->fwId, srvGroupName => '^');
}

#------------------------------------------------------------------------------
# 具体实现 忽略 disable 状态的策略
#------------------------------------------------------------------------------
sub ignore {
  my $self = shift;
  return ((defined $self->isDisable && $self->isDisable eq 'yes') || ($self->hasSchedule && $self->schedule->isExpired));
}

__PACKAGE__->meta->make_immutable;
1;

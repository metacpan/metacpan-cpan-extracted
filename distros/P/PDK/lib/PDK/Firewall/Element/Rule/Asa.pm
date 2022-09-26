package PDK::Firewall::Element::Rule::Asa;

#------------------------------------------------------------------------------
# 加载扩展模块
#------------------------------------------------------------------------------
use Moose;
use namespace::autoclean;
use PDK::Firewall::Element::ProtocolGroup::Asa;

#------------------------------------------------------------------------------
# 加载 PDK::Firewall::Element::Rule::Role 角色
#------------------------------------------------------------------------------
with 'PDK::Firewall::Element::Rule::Role';

#------------------------------------------------------------------------------
# PDK::Firewall::Element::Rule::Asa 通用属性
#------------------------------------------------------------------------------
has '+policyId' => (required => 0,);

has zone => (is => 'ro', isa => 'Str', required => 0,);

has aclName => (is => 'ro', isa => 'Str', required => 1,);

has aclLineNumber => (is => 'ro', isa => 'Int', required => 1,);

has protocolGroup =>
  (is => 'ro', isa => 'PDK::Firewall::Element::ProtocolGroup::Asa', lazy => 1, builder => '_buildProtocolGroup',);

#------------------------------------------------------------------------------
# 重写 PDK::Firewall::Element::Role => _buildRange 方法
# 由于asa配置文件本身所决定，如果在配置文件中插入一个rule，可能会导致其它rule的
# aclLineNumber发生变化，所以本sign不具备长时间有效性，只能即查即用，切记切记
#------------------------------------------------------------------------------
sub _buildSign {
  my $self = shift;
  return $self->createSign($self->aclName, $self->aclLineNumber);
}

#------------------------------------------------------------------------------
# 协议栈协议对象
#------------------------------------------------------------------------------
sub protocolMembers {
  my $self = shift;
  return $self->protocolGroup->proGroupMembers;
}

#------------------------------------------------------------------------------
# 添加策略协议栈
#------------------------------------------------------------------------------
sub addProtocolMembers {
  my ($self, $name, $obj) = @_;
  $self->protocolGroup->addProGroupMember($name, $obj);
}

#------------------------------------------------------------------------------
# PDK::Firewall::Element::Rule::Role _buildProtocolGroup 具体实现
#------------------------------------------------------------------------------
sub _buildProtocolGroup {
  my $self = shift;
  return PDK::Firewall::Element::ProtocolGroup::Asa->new(fwId => $self->fwId, proGroupName => '^');
}

__PACKAGE__->meta->make_immutable;
1;

package PDK::Firewall::Element::Rule::H3c;

#------------------------------------------------------------------------------
# 加载扩展模块
#------------------------------------------------------------------------------
use Moose;
use namespace::autoclean;

#------------------------------------------------------------------------------
# 加载 PDK::Firewall::Element::Rule::Role 角色
#------------------------------------------------------------------------------
with 'PDK::Firewall::Element::Rule::Role';

#------------------------------------------------------------------------------
# PDK::Firewall::Element::Rule::H3c 通用属性
#------------------------------------------------------------------------------
# rule type ACL or object-policy(obj)
has '+policyId' => (required => 0,);

has ruleType => (is => 'ro', isa => 'Str', default => 'obj');

has objName => (is => 'ro', isa => 'Str', required => 0,);

has aclName => (is => 'ro', isa => 'Str', required => 0,);

has aclRuleNum => (is => 'ro', isa => 'Int', required => 0,);

has aclType => (is => 'ro', isa => 'Str', required => 0,);

#------------------------------------------------------------------------------
# 重写 PDK::Firewall::Element::Role => _buildRange 方法
#------------------------------------------------------------------------------
sub _buildSign {
  my $self = shift;
  if ($self->ruleType eq 'obj') {
    return $self->createSign($self->objName, $self->policyId);
  }
  else {
    return $self->createSign($self->aclName, $self->aclRuleNum);
  }
}

__PACKAGE__->meta->make_immutable;
1;

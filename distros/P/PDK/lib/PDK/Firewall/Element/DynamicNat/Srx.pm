package PDK::Firewall::Element::DynamicNat::Srx;

#------------------------------------------------------------------------------
# 加载扩展模块
#------------------------------------------------------------------------------
use Moose;
use namespace::autoclean;

#-----------------------------------------------------------------------------
# 引用 PDK::Firewall::Element::DynamicNat::Role 角色
#------------------------------------------------------------------------------
with 'PDK::Firewall::Element::DynamicNat::Role';

#------------------------------------------------------------------------------
# PDK::Firewall::Element::DynamicNat::Srx 通用属性
#------------------------------------------------------------------------------
has '+fromZone' => (required => 1,);

has ruleName => (is => 'ro', isa => 'Str', required => 1,);

has ruleSet => (is => 'ro', isa => 'Str', required => 1,);

# has natSrcPool => (is => 'ro', isa => 'PDK::Firewall::Element::NatPool::Srx | Undef', required => 0,);
# has natDstPool => (is => 'ro', isa => 'PDK::Firewall::Element::NatPool::Srx | Undef', required => 0,);

#------------------------------------------------------------------------------
# 重写 PDK::Firewall::Element::Role => _buildRange 方法
#------------------------------------------------------------------------------
sub _buildSign {
  my $self = shift;
  return $self->createSign($self->ruleSet, $self->ruleName);
}

__PACKAGE__->meta->make_immutable;
1;

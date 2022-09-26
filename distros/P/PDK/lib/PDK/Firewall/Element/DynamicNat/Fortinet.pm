package PDK::Firewall::Element::DynamicNat::Fortinet;

#------------------------------------------------------------------------------
# 加载扩展模块
#------------------------------------------------------------------------------
use Moose;
use namespace::autoclean;

#------------------------------------------------------------------------------
# 引用 PDK::Firewall::Element::DynamicNat::Role 角色
#------------------------------------------------------------------------------
with 'PDK::Firewall::Element::DynamicNat::Role';

#------------------------------------------------------------------------------
# PDK::Firewall::Element::DynamicNat::Fortinet 通用属性
#------------------------------------------------------------------------------
has name => (is => 'ro', isa => 'Str', required => 0,);

has policyId => (is => 'ro', isa => 'Int', required => 0,);

# has natSrcPool => (is => 'ro', isa => 'PDK::Firewall::Element::NatPool::Fortinet | Undef', required => 0,);

#------------------------------------------------------------------------------
# 重写 PDK::Firewall::Element::Address::Role => _buildRange 方法
#------------------------------------------------------------------------------
sub _buildSign {
  my $self = shift;
  return $self->createSign($self->name // $self->policyId);
}

__PACKAGE__->meta->make_immutable;
1;

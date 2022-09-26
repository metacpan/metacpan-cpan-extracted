package PDK::Firewall::Element::DynamicNat::Neteye;

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
# PDK::Firewall::Element::DynamicNat::Neteye 通用属性
#------------------------------------------------------------------------------
has id => (is => 'ro', isa => 'Str', required => 1,);

has matchRule => (is => 'ro', isa => 'PDK::Firewall::Element::Rule::Role', required => 0,);

#------------------------------------------------------------------------------
# 重写 PDK::Firewall::Element::Role => _buildRange 方法
#------------------------------------------------------------------------------
sub _buildSign {
  my $self = shift;
  return $self->createSign($self->natDirection, $self->id);
}

__PACKAGE__->meta->make_immutable;
1;

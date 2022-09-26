package PDK::Firewall::Element::DynamicNat::Asa;

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
# PDK::Firewall::Element::DynamicNat::Asa 通用属性
#------------------------------------------------------------------------------
has '+fromZone' => (required => 1,);

has '+natDirection' => (required => 0,);

has ruleName => (is => 'ro', isa => 'Str', required => 1,);

# 可能携带也可能不携带 | 不能作为签名属性
has aclName => (is => 'ro', isa => 'Str', required => 0,);

#------------------------------------------------------------------------------
# 重写 PDK::Firewall::Element::Role => _buildRange 方法
#------------------------------------------------------------------------------
sub _buildSign {
  my $self = shift;
  return $self->createSign($self->fromZone, $self->ruleName);
}

__PACKAGE__->meta->make_immutable;
1;

package PDK::Firewall::Element::StaticNat::Hillstone;

#------------------------------------------------------------------------------
# 加载扩展模块
#------------------------------------------------------------------------------
use Moose;
use namespace::autoclean;
use PDK::Utils::Set;

#------------------------------------------------------------------------------
# 引入 PDK::Firewall::Element::StaticNat::Role 角色
#------------------------------------------------------------------------------
with 'PDK::Firewall::Element::StaticNat::Role';

#------------------------------------------------------------------------------
# PDK::Firewall::Element::StaticNat::Hillstone 通用属性
#------------------------------------------------------------------------------
has id => (is => 'ro', isa => 'Str', required => 1,);

has natInterface => (is => 'ro', isa => 'Str|Undef', required => 0,);

#------------------------------------------------------------------------------
# 重写 PDK::Firewall::Element::Role => _buildRange 方法
#------------------------------------------------------------------------------
sub _buildSign {
  my $self = shift;
  return $self->createSign($self->id);
}

__PACKAGE__->meta->make_immutable;
1;

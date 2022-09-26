package PDK::Firewall::Element::AddressGroup::Hillstone;

#------------------------------------------------------------------------------
# 加载扩展模块
#------------------------------------------------------------------------------
use Moose;
use namespace::autoclean;

#------------------------------------------------------------------------------
# 继承 PDK::Firewall::Element::AddressGroup::Role 角色
#------------------------------------------------------------------------------
with 'PDK::Firewall::Element::AddressGroup::Role';

__PACKAGE__->meta->make_immutable;
1;

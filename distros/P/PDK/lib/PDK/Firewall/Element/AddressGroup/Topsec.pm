package PDK::Firewall::Element::AddressGroup::Topsec;

#------------------------------------------------------------------------------
# 加载扩展模块
#------------------------------------------------------------------------------
use Moose;
use namespace::autoclean;

#------------------------------------------------------------------------------
# 引用 PDK::Firewall::Element::AddressGroup::Role 角色
#------------------------------------------------------------------------------
with 'PDK::Firewall::Element::AddressGroup::Role';

__PACKAGE__->meta->make_immutable;
1;

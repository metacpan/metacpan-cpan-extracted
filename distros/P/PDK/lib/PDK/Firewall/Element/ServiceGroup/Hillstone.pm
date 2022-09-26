package PDK::Firewall::Element::ServiceGroup::Hillstone;

#------------------------------------------------------------------------------
# 加载扩展模块
#------------------------------------------------------------------------------
use Moose;
use namespace::autoclean;

#------------------------------------------------------------------------------
# 引入 PDK::Firewall::Element::ServiceGroup::Role 角色
#------------------------------------------------------------------------------
with 'PDK::Firewall::Element::ServiceGroup::Role';

__PACKAGE__->meta->make_immutable;
1;

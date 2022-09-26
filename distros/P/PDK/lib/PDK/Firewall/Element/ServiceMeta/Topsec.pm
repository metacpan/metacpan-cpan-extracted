package PDK::Firewall::Element::ServiceMeta::Topsec;

#------------------------------------------------------------------------------
# 加载扩展模块
#------------------------------------------------------------------------------
use Moose;
use namespace::autoclean;

#------------------------------------------------------------------------------
# 引入 PDK::Firewall::Element::ServiceMeta::Role 角色
#------------------------------------------------------------------------------
with 'PDK::Firewall::Element::ServiceMeta::Role';

__PACKAGE__->meta->make_immutable;
1;

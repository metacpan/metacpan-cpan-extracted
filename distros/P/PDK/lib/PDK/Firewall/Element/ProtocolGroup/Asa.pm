package PDK::Firewall::Element::ProtocolGroup::Asa;

#------------------------------------------------------------------------------
# 加载扩展模块
#------------------------------------------------------------------------------
use Moose;
use namespace::autoclean;

#------------------------------------------------------------------------------
# 引用 PDK::Firewall::Element::ProtocolGroup::Role 角色
#------------------------------------------------------------------------------
with 'PDK::Firewall::Element::ProtocolGroup::Role';

__PACKAGE__->meta->make_immutable;
1;

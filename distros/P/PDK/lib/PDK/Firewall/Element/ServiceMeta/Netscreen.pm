package PDK::Firewall::Element::ServiceMeta::Netscreen;

#------------------------------------------------------------------------------
# 加载扩展模块
#------------------------------------------------------------------------------
use Moose;
use namespace::autoclean;

#------------------------------------------------------------------------------
# 引入 PDK::Firewall::Element::ServiceMeta::Role 角色
#------------------------------------------------------------------------------
with 'PDK::Firewall::Element::ServiceMeta::Role';

#------------------------------------------------------------------------------
# PDK::Firewall::Element::ServiceMeta::Netscreen 通用属性
#------------------------------------------------------------------------------
has timeout => (is => 'ro', isa => 'Undef|Str', default => undef, writer => 'setTimeout',);

__PACKAGE__->meta->make_immutable;
1;

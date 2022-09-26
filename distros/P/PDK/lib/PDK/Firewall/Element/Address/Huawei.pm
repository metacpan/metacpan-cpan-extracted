package PDK::Firewall::Element::Address::Huawei;

#------------------------------------------------------------------------------
# 加载扩展模块
#------------------------------------------------------------------------------
use Moose;
use namespace::autoclean;

#------------------------------------------------------------------------------
# 引用 PDK::Firewall::Element::Address::Role 角色
#------------------------------------------------------------------------------
with 'PDK::Firewall::Element::Address::Role';

# 是否为 vpn-instance 实例
has vpn => (is => 'ro', isa => 'Str', default => 'default',);

__PACKAGE__->meta->make_immutable;
1;


package PDK::Firewall::Element::Rule::Topsec;

#------------------------------------------------------------------------------
# 加载扩展模块
#------------------------------------------------------------------------------
use Moose;
use namespace::autoclean;

#------------------------------------------------------------------------------
# 加载 PDK::Firewall::Element::Rule::Role 角色
#------------------------------------------------------------------------------
with 'PDK::Firewall::Element::Rule::Role';

#------------------------------------------------------------------------------
# PDK::Firewall::Element::Rule::Netscreen 通用属性
#------------------------------------------------------------------------------
has fromZone => (is => 'ro', isa => 'HashRef[Undef|Str]|Undef',);

has toZone => (is => 'ro', isa => 'HashRef[Undef|Str]|Undef',);

has fromVlan => (is => 'ro', isa => 'HashRef[Str|Undef]Undef',);

has toVlan => (is => 'ro', isa => 'HashRef[Str|Undef]|Undef',);

__PACKAGE__->meta->make_immutable;
1;

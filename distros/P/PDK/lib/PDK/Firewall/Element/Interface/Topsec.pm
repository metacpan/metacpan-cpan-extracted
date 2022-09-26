package PDK::Firewall::Element::Interface::Topsec;

#------------------------------------------------------------------------------
# 加载扩展模块
#------------------------------------------------------------------------------
use Moose;
use namespace::autoclean;

#------------------------------------------------------------------------------
# 引用 PDK::Firewall::Element::Interface::Role 角色
#------------------------------------------------------------------------------
with 'PDK::Firewall::Element::Interface::Role';

#------------------------------------------------------------------------------
# PDK::Firewall::Element::Interface::Topsec 通用属性
#------------------------------------------------------------------------------
has accessMode => (is => 'rw', isa => 'Str', default => 'access',);

has accessVlan => (is => 'rw', isa => 'ArrayRef', default => sub { [] },);

__PACKAGE__->meta->make_immutable;
1;

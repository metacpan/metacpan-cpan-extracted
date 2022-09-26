package PDK::Firewall::Element::Rule::Netscreen;

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
has hasApplicationCheck => (is => 'ro', isa => 'Undef|Str', default => undef, writer => 'setHasApplicationCheck',);

has alias => (is => 'ro', isa => 'Undef|Str', default => undef,);

has priority => (is => 'ro', isa => 'Int', required => 1,);

__PACKAGE__->meta->make_immutable;
1;

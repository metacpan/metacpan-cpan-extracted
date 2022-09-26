package PDK::Firewall::Element::Zone::Paloalto;

#------------------------------------------------------------------------------
# 加载扩展模块
#------------------------------------------------------------------------------
use Moose;
use namespace::autoclean;

#------------------------------------------------------------------------------
# 继承 PDK::Firewall::Element::Zone::Role 角色 方法属性
#------------------------------------------------------------------------------
with 'PDK::Firewall::Element::Zone::Role';

#------------------------------------------------------------------------------
# 定义 PDK::Firewall::Element::Zone::PaloAlto 方法属性
#------------------------------------------------------------------------------
has "+routeInstance" => (is => 'ro', isa => 'Str', required => 1,);

has profile => (is => 'ro', writer => 'setProfile');

has log => (is => 'ro', writer => 'setLog');

has identify => (is => 'ro', writer => 'setIdentify');

__PACKAGE__->meta->make_immutable;
1;

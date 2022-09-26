package PDK::Firewall::Element::StaticNat::Role;

#------------------------------------------------------------------------------
# 加载扩展模块
#------------------------------------------------------------------------------
use Moose::Role;
use namespace::autoclean;
use PDK::Utils::Set;

#------------------------------------------------------------------------------
# 继承 PDK::Firewall::Element::Role 方法属性
#------------------------------------------------------------------------------
with 'PDK::Firewall::Element::Role';

#------------------------------------------------------------------------------
# 定义静态地址转换通用方法和属性
#------------------------------------------------------------------------------
has realZone => (is => 'ro', isa => 'Str|Undef', required => 0,);

has natZone => (is => 'ro', isa => 'Str|Undef', required => 0,);

has realIp => (is => 'ro', isa => 'Str', required => 1,);

has natIp => (is => 'ro', isa => 'Str', required => 1,);

has realIpRange => (is => 'ro', isa => 'PDK::Utils::Set', default => sub { PDK::Utils::Set->new },);

has natIpRange => (is => 'ro', isa => 'PDK::Utils::Set', lazy => 1, default => sub { PDK::Utils::Set->new },);

has natInterface => (is => 'ro', isa => 'Str|Undef', required => 0,);

1;

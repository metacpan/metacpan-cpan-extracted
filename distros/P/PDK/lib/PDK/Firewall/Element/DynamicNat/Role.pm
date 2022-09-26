package PDK::Firewall::Element::DynamicNat::Role;

#------------------------------------------------------------------------------
# 加载扩展模块
#------------------------------------------------------------------------------
use Moose::Role;
use namespace::autoclean;
use PDK::Utils::Set;

#-----------------------------------------------------------------------------
# 引用 PDK::Firewall::Element::Role 角色
#------------------------------------------------------------------------------
with 'PDK::Firewall::Element::Role';

#------------------------------------------------------------------------------
# 定义模块通用方法属性
#------------------------------------------------------------------------------
has fromZone => (is => 'ro', isa => 'Str', required => 0,);

has toZone => (is => 'ro', isa => 'Str', required => 0,);

# 转换前地址 -源地址
has srcIpRange => (is => 'ro', isa => 'PDK::Utils::Set', default => sub { PDK::Utils::Set->new },);

# 转换前地址 - 目的地址
has dstIpRange => (is => 'ro', isa => 'PDK::Utils::Set', default => sub { PDK::Utils::Set->new },);

has srvRange => (is => 'ro', isa => 'PDK::Utils::Set', required => 0,);

has dstPort => (is => 'ro', isa => 'Str', required => 0,);

# 端口复用
has natDstPort => (is => 'ro', isa => 'Str', required => 0,);

# 目标地址转换
has natDstIp => (is => 'ro', isa => 'Str | Undef', required => 0,);

# 端口地址转换
has natSrvRange => (is => 'ro', isa => 'PDK::Utils::Set|Undef', required => 0,);

# 转换方向
has natDirection => (is => 'ro', isa => 'Str', required => 1,);

has proto => (is => 'ro', isa => 'Str', default => 'tcp',);

has natInterface => (is => 'ro', isa => 'Str', required => 0,);

# has natSrcPool => (is => 'ro', does => 'PDK::Firewall::Element::NatPool::Role|Undef', required => 0,);
# 源地址转换池
has natSrcPool => (is => 'ro', isa => 'Str', required => 0,);

# 源地址转换
has natSrcRange => (is => 'ro', isa => 'PDK::Utils::Set', required => 0,);

# has natDstPool => (is => 'ro', does => 'PDK::Firewall::Element::NatPool::Role|Undef', required => 0,);
# 目的地址转换池
has natDstPool => (is => 'ro', isa => 'Str', required => 0,);

# 目的地址转换
has natDstRange => (is => 'ro', isa => 'PDK::Utils::Set', required => 0,);

1;

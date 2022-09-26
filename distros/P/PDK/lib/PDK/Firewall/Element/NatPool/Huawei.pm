package PDK::Firewall::Element::NatPool::Huawei;

#------------------------------------------------------------------------------
# 加载扩展模块
#------------------------------------------------------------------------------
use Moose;
use namespace::autoclean;
use PDK::Utils::Ip;

#------------------------------------------------------------------------------
# 引用 PDK::Firewall::Element::NatPool::Role 角色
#------------------------------------------------------------------------------
with 'PDK::Firewall::Element::NatPool::Role';

#------------------------------------------------------------------------------
# PDK::Firewall::Element::NatPool::Huawei 通用属性
#------------------------------------------------------------------------------
has mode => (is => 'ro', isa => 'Str', required => 0,);

has id => (is => 'ro', isa => 'Int', required => 0,);

has '+poolIp' => (required => 0,);

has natDirection => (is => 'ro', isa => 'Str', required => 0,);

#------------------------------------------------------------------------------
# 具体实现PDK::Firewall::Element::NatPool::Role _buildRange 方法
#------------------------------------------------------------------------------
# sub _buildRange {
#   my $self = shift;
#   my $set  = PDK::Utils::Set->new();
#   for my $ipRange (@{$self->{poolIp}}) {
#     my ($minIp, $maxIp) = split(/\s+/, $ipRange);
#     $set->mergeToSet(PDK::Utils::Ip->new->getRangeFromIpRange($minIp, $maxIp));
#   }
#   return $set;
# }

__PACKAGE__->meta->make_immutable;
1;

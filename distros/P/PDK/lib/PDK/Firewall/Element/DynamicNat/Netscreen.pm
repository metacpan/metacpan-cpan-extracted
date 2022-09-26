package PDK::Firewall::Element::DynamicNat::Netscreen;

#------------------------------------------------------------------------------
# 加载扩展模块
#------------------------------------------------------------------------------
use Moose;
use namespace::autoclean;

#------------------------------------------------------------------------------
# 引用 PDK::Firewall::Element::DynamicNat::Role 角色
#------------------------------------------------------------------------------
with 'PDK::Firewall::Element::DynamicNat::Role';

#------------------------------------------------------------------------------
# PDK::Firewall::Element::DynamicNat::Netscreen 通用属性
#------------------------------------------------------------------------------
has srv => (is => 'ro', isa => 'PDK::Firewall::Element::Service::Netscreen', required => 0,);

has policyId => (is => 'ro', isa => 'Int', required => 0,);

# has natSrcPool => (is => 'ro', isa => 'PDK::Firewall::Element::NatPool::Netscreen | Undef', required => 0,);

#------------------------------------------------------------------------------
# 重写 PDK::Firewall::Element::Role => _buildRange 方法
#------------------------------------------------------------------------------
sub _buildSign {
  my $self = shift;
  if (defined $self->{policyId}) {
    return $self->createSign($self->policyId);
  }
  else {
    if (defined $self->{natDstIp} and defined $self->{natDstPort}) {
      return $self->createSign($self->{natDstIp}, $self->{natDstPort});
    }
  }
}

__PACKAGE__->meta->make_immutable;
1;

package PDK::Firewall::Element::Rule::Srx;

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
has '+policyId' => (required => 0,);

has ruleName => (is => 'ro', isa => 'Str', required => 1,);

has '+fromZone' => (required => 1,);

has '+toZone' => (required => 1,);

has '+action' => (required => 0, writer => 'setAction',);

#------------------------------------------------------------------------------
# 防火墙策略对象签名方法
#------------------------------------------------------------------------------
sub _buildSign {
  my $self = shift;
  return $self->createSign($self->{fromZone}, $self->{toZone}, $self->{ruleName});
}

__PACKAGE__->meta->make_immutable;
1;

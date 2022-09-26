package PDK::Firewall::Element::StaticNat::Paloalto;

#------------------------------------------------------------------------------
# 加载扩展模块
#------------------------------------------------------------------------------
use Moose;
use namespace::autoclean;
use PDK::Utils::Set;

#------------------------------------------------------------------------------
# 继承 PDK::Firewall::Element::StaticNat::Role 角色 方法属性
#------------------------------------------------------------------------------
with 'PDK::Firewall::Element::StaticNat::Role';

#------------------------------------------------------------------------------
# 定义 PDK::Firewall::Element::StaticNat::PaloAlto 方法属性
#------------------------------------------------------------------------------
has '+natZone' => (required => 1,);

has dstIpRange => (is => 'ro', isa => 'PDK::Utils::Set', default => sub { PDK::Utils::Set->new(0, 4294967295) },);

has ruleName => (is => 'ro', isa => 'Str', required => 1,);

has ruleSet => (is => 'ro', isa => 'Str', required => 1,);

#------------------------------------------------------------------------------
# 具体实现 PDK::Firewall::Element::Role => _buildRange 方法
#------------------------------------------------------------------------------
sub _buildSign {
  my $self = shift;
  return $self->createSign($self->ruleSet, $self->ruleName);
}

__PACKAGE__->meta->make_immutable;
1;

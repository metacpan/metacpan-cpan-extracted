package PDK::Firewall::Element::DynamicNat::Paloalto;

#-----------------------------------------------------------------------------
# 加载扩展模块
#------------------------------------------------------------------------------
use Moose;
use namespace::autoclean;

#-----------------------------------------------------------------------------
# 引用 PDK::Firewall::Element::DynamicNat::Role 角色
#------------------------------------------------------------------------------
with 'PDK::Firewall::Element::DynamicNat::Role';

#------------------------------------------------------------------------------
# PDK::Firewall::Element::DynamicNat::PaloAlto 通用属性
#------------------------------------------------------------------------------
has tag => (is => 'ro', writer => 'setTag');

has description => (is => 'ro', writer => 'setDescription');

#------------------------------------------------------------------------------
# 具体实现 PDK::Firewall::Element::Role => _buildSign | 确保唯一性
#------------------------------------------------------------------------------
has fromZone => (is => 'ro', isa => 'ArrayRef', required => 0, traits => ['Array'], handles => {addFromZone => 'push'});

has toZone => (is => 'ro', isa => 'ArrayRef', required => 0, traits => ['Array'], handles => {addToZone => 'push'});

has dstPort => (is => 'ro', isa => 'ArrayRef', required => 0, traits => ['Array'], handles => {addPort => 'push'});

has srcIpRange => (is => 'ro', isa => 'PDK::Utils::Set', default => sub { PDK::Utils::Set->new },);

has dstIpRange => (is => 'ro', isa => 'PDK::Utils::Set', default => sub { PDK::Utils::Set->new },);

# 源地址装的pool
has natSrcPool => (
  is => 'ro',

  # isa      => 'PDK::Firewall::Element::NatPool::PaloAlto | Undef',
  required => 0,
);

# 源地址转换的rangeSet
has natSrcRange => (is => 'ro', isa => 'PDK::Utils::Set | Undef', required => 0,);

# 目的地址装的pool
has natDstPool => (
  is => 'ro',

  # isa      => 'PDK::Firewall::Element::NatPool::PaloAlto | Undef',
  required => 0,
);

# 目的地址转换的rangeSet
has natDstRange => (is => 'ro', isa => 'PDK::Utils::Set | Undef', required => 0,);

has natDstPort => (is => 'ro', isa => 'Int | Undef', required => 0, writer => 'setNatDstPort');

has ruleName => (is => 'ro', isa => 'Str', required => 1,);

has natDirection => (is => 'ro', isa => 'Str', required => 0, writer => 'setNatDirection');

#------------------------------------------------------------------------------
# 重写 PDK::Firewall::Element::Role => _buildRange 方法
#------------------------------------------------------------------------------
sub _buildSign {
  my $self = shift;
  return $self->createSign($self->ruleName);
}

__PACKAGE__->meta->make_immutable;
1;

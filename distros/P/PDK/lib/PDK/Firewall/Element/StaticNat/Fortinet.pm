package PDK::Firewall::Element::StaticNat::Fortinet;

#------------------------------------------------------------------------------
# 加载扩展模块
#------------------------------------------------------------------------------
use Moose;
use namespace::autoclean;
use PDK::Utils::Ip;

#------------------------------------------------------------------------------
# 引入 PDK::Firewall::Element::StaticNat::Role 角色
#------------------------------------------------------------------------------
with 'PDK::Firewall::Element::StaticNat::Role';

#------------------------------------------------------------------------------
# PDK::Firewall::Element::StaticNat::Fortinet 通用属性
#------------------------------------------------------------------------------
has name => (is => 'ro', isa => 'Str', required => 1,);

has '+realIp' => (required => 1,);

has '+natIp' => (required => 1,);

has realIpRange => (is => 'ro', isa => 'PDK::Utils::Set', lazy => 1, builder => '_buildRealIpRange',);

has natIpRange => (is => 'ro', isa => 'PDK::Utils::Set', lazy => 1, builder => '_buildNatIpRange',);

has natInterface => (is => 'ro', isa => 'Str', required => 1,);

#------------------------------------------------------------------------------
# 重写 PDK::Firewall::Element::Role => _buildRange 方法
#------------------------------------------------------------------------------
sub _buildSign {
  my $self = shift;
  return $self->createSign($self->name);
}

#------------------------------------------------------------------------------
# 生成 _buildRealIpRange 对象
#------------------------------------------------------------------------------
sub _buildRealIpRange {
  my $self    = shift;
  my $ipRegex = '\d+\.\d+\.\d+\.\d+';
  my $range;
  if ($self->realIp =~ /$ipRegex-$ipRegex/) {
    my ($ipmin, $ipmax) = split('-', $self->realIp);
    $ipmax = $ipmin if not defined $ipmin;
    $range = PDK::Utils::Ip->new->getRangeFromIpRange($ipmin, $ipmax);
  }
  elsif ($self->realIp =~ /$ipRegex(\/\d+)?/) {
    my ($ip, $mask) = split('/', $self->realIp);
    $range = PDK::Utils::Ip->new->getRangeFromIpMask($ip, $mask);
  }
  return $range;
}

#------------------------------------------------------------------------------
# 生成 _buildNatIpRange 对象
#------------------------------------------------------------------------------
sub _buildNatIpRange {
  my $self = shift;
  my ($ipmin, $ipmax) = split('-', $self->natIp);
  $ipmax = $ipmin if not defined $ipmax;
  my $range = PDK::Utils::Ip->new->getRangeFromIpRange($ipmin, $ipmax);
  return $range;
}

__PACKAGE__->meta->make_immutable;
1;

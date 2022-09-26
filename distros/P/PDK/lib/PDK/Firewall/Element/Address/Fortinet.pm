package PDK::Firewall::Element::Address::Fortinet;

#------------------------------------------------------------------------------
# 加载扩展模块
#------------------------------------------------------------------------------
use Moose;
use namespace::autoclean;

#------------------------------------------------------------------------------
# 引用 PDK::Firewall::Element::Address::Role 角色
#------------------------------------------------------------------------------
with 'PDK::Firewall::Element::Address::Role';

#------------------------------------------------------------------------------
# PDK::Firewall::Element::Address::Fortinet 通用属性
#------------------------------------------------------------------------------
has startIp => (is => 'ro', isa => 'Str', required => 0,);

has endIp => (is => 'ro', isa => 'Str', required => 0,);

#------------------------------------------------------------------------------
# 重写 PDK::Firewall::Element::Address::Role => _buildRange 方法
#------------------------------------------------------------------------------
sub _buildRange {
  my $self  = shift;
  my $type  = $self->type;
  my $range = PDK::Utils::Set->new;

  if ($type eq 'subnet') {
    $range = PDK::Utils::Ip->new->getRangeFromIpMask($self->ip, $self->mask);
  }
  elsif ($type eq 'ipmask') {
    $range = PDK::Utils::Ip->new->getRangeFromIpRange($self->startIp, $self->endIp);
  }
  return $range;
}

__PACKAGE__->meta->make_immutable;
1;

package PDK::Firewall::Element::Address::Role;

#------------------------------------------------------------------------------
# 加载扩展模块
#------------------------------------------------------------------------------
use Moose::Role;
use namespace::autoclean;
use PDK::Utils::Ip;
use PDK::Utils::Set;

#------------------------------------------------------------------------------
# 继承 PDK::Firewall::Element::Role 方法属性
#------------------------------------------------------------------------------
with 'PDK::Firewall::Element::Role';

#------------------------------------------------------------------------------
# PDK::Firewall::Element::Address::Role 通用属性
#------------------------------------------------------------------------------
has addrName => (is => 'ro', isa => 'Str', required => 1,);

has zone => (is => 'ro', isa => 'Str', required => 0,);

has ip => (is => 'ro', isa => 'Str', required => 0,);

has mask => (is => 'ro', isa => 'Str', required => 0,);

# 新增 iprange 属性
has iprange => (is => 'ro', isa => 'Str', required => 0,);

has description => (is => 'ro', isa => 'Str', required => 0,);

has range => (is => 'ro', isa => 'PDK::Utils::Set', lazy => 1, builder => '_buildRange',);

has type => (is => 'ro', isa => 'Str', default => 'subnet');

has refnum => (is => 'ro', isa => 'Int', default => 0);

has members => (is => 'rw', isa => 'ArrayRef[Hash]', default => sub { [] },);

#------------------------------------------------------------------------------
# 设定防火墙地址对象通用签名方法: ASA、Netscreen和Srx 需要自行实现签名
#------------------------------------------------------------------------------
sub _buildSign {
  my $self = shift;
  return $self->createSign($self->addrName);
}

#------------------------------------------------------------------------------
# builder => _buildRange 将 ip 转换为 range 格式
#------------------------------------------------------------------------------
sub _buildRange {
  my $self = shift;
  if ($self->ip and $self->mask) {
    return PDK::Utils::Ip->new->getRangeFromIpMask($self->ip, $self->mask);
  }
  elsif ($self->iprange or $self->type eq 'iprange') {
    my ($min, $max) = split('-', $self->iprange);
    return PDK::Utils::Ip->new->getRangeFromIpRange($min, $max);
  }
  else {
    return PDK::Utils::Set->new;
  }
}

#------------------------------------------------------------------------------
# 新增地址组成员方法
#------------------------------------------------------------------------------
sub addMember {
  my ($self, $member) = @_;

  # 边界条件处理
  confess __PACKAGE__ . " addMember 方法必须携带具体的member" unless defined $member;
  push @{$self->members}, $member;

  # 判断是否已加载 range 对象
  $self->{range} = $self->range;
  for my $type (keys %{$member}) {
    if ($type eq 'ipmask') {
      my ($ip, $mask) = split('/', $member->{$type});
      my $ipSet = PDK::Utils::Ip->new->getRangeFromIpMask($ip, $mask);
      $self->range->mergeToSet($ipSet);
    }
    elsif ($type eq 'range') {
      my ($ipmin, $ipmax) = split(/\s+|-/, $member->{$type});
      my $ipSet = PDK::Utils::Ip->new->getRangeFromIpRange($ipmin, $ipmax);
      $self->range->mergeToSet($ipSet);
    }
    elsif ($type eq 'obj' and $member->{$type}->does("PDK::Firewall::Element::Address::Role")) {
      $self->range->mergeToSet($member->{$type}->range);
    }
  }
}

1;

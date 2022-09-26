package PDK::Firewall::Element::ServiceMeta::Role;

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
# 调用 serviceMeta 通用属性和方法
#------------------------------------------------------------------------------
has srvName => (is => 'ro', isa => 'Str', required => 1,);

has protocol => (is => 'ro', isa => 'Str', required => 0,);

has srcPort => (is => 'ro', isa => 'Str', required => 0,);

has dstPort => (is => 'ro', isa => 'Str', required => 0,);

has srcPortRange => (is => 'ro', isa => 'PDK::Utils::Set', default => sub { PDK::Utils::Set->new(0, 65535) });

has dstPortRange => (is => 'ro', isa => 'PDK::Utils::Set', lazy => 1, builder => '_buildDstPortRange',);

has range => (is => 'ro', isa => 'PDK::Utils::Set', builder => '_buildRange',);

#------------------------------------------------------------------------------
# 定义服务端口元对象通用签名方法
#------------------------------------------------------------------------------
sub _buildSign {
  my $self = shift;
  return $self->createSign($self->srvName, $self->protocol, $self->srcPort, $self->dstPort);
}

#------------------------------------------------------------------------------
# 生成源端区间集合
#------------------------------------------------------------------------------
sub buildSrcPortRange {
  my $srcPort = shift;
  my ($min, $max);
  if ($srcPort =~ /^\s*(\d+)\s*$/o) {
    ($min, $max) = ($1, $1);
  }
  elsif ($srcPort =~ /^\s*(\d+)[\s+\-](\d+)\s*$/o) {
    ($min, $max) = ($1, $2);
  }
  else {
    return PDK::Utils::Set->new(0, 65535);
  }
  return PDK::Utils::Set->new($min, $max);
}

#------------------------------------------------------------------------------
# _buildDstPortRange 具体实现
#------------------------------------------------------------------------------
sub _buildDstPortRange {
  my $self    = shift;
  my $dstPort = $self->dstPort;
  my ($min, $max);
  if ($dstPort and $dstPort =~ /^\s*(\d+)\s*$/) {
    ($min, $max) = ($1, $1);
    return PDK::Utils::Set->new($min, $max);
  }
  elsif ($dstPort and $dstPort =~ /^\s*(\d+)[\s+\-](\d+)\s*$/o) {
    ($min, $max) = ($1, $2);
    return PDK::Utils::Set->new($min, $max);
  }
  else {
    # ($min, $max) = (0, 65535);
    warn "ERROR: Attribute (dstPort) 's value [$dstPort] 's format is wrong";
    return PDK::Utils::Set->new;
  }
}

#------------------------------------------------------------------------------
# _buildRange 具体实现
#------------------------------------------------------------------------------
sub _buildRange {
  my $self     = shift;
  my $protocol = $self->protocol;
  my $dstPort  = $self->dstPort;
  if ($protocol and $dstPort) {
    my $service = $self->protocol . '/' . $self->dstPort;
    return PDK::Utils::Ip->new->getRangeFromService($service);
  }
  else {
    return PDK::Utils::Set->new;
  }
}

#------------------------------------------------------------------------------
# Moose BUILDARGS 在实例创建之前生效，可以接收哈希和哈希的引用
#------------------------------------------------------------------------------
around BUILDARGS => sub {
  my $orig      = shift;
  my $className = shift;

  my %params = @_;
  $params{protocol} = lc $params{protocol} if defined $params{protocol};
  $params{srcPort} //= '0-65535';
  $params{srcPortRange} = &buildSrcPortRange($params{srcPort});
  if ($params{protocol} and $params{protocol} !~ /^(tcp|udp)$/io) {
    $params{dstPort} = '0-65535' unless defined $params{dstPort};
  }
  return $className->$orig(%params);
};

1;

package PDK::Firewall::Element::ServiceMeta::Srx;

#------------------------------------------------------------------------------
# 加载扩展模块
#------------------------------------------------------------------------------
use Moose;
use namespace::autoclean;

#------------------------------------------------------------------------------
# 引入 PDK::Firewall::Element::ServiceMeta::Role 角色
#------------------------------------------------------------------------------
with 'PDK::Firewall::Element::ServiceMeta::Role';

#------------------------------------------------------------------------------
# PDK::Firewall::Element::ServiceMeta::Srx 通用属性
#------------------------------------------------------------------------------
has term => (is => 'ro', isa => 'Str', required => 1,);

has timeout => (is => 'ro', isa => 'Undef|Str', default => undef,);

has uuid => (is => 'ro', isa => 'Undef|Str', default => undef,);

#------------------------------------------------------------------------------
# 重写 PDK::Firewall::Element::Role => _buildRange 方法
#------------------------------------------------------------------------------
sub _buildSign {
  my $self = shift;
  return $self->createSign($self->srvName, $self->term);
}

#------------------------------------------------------------------------------
# Moose BUILDARGS 在实例创建之前生效，可以接收哈希和哈希的引用
#------------------------------------------------------------------------------
around BUILDARGS => sub {
  my $orig   = shift;
  my $class  = shift;
  my %params = @_;
  $params{term}    //= ' ';
  $params{srcPort} //= '0-65535';
  if (defined $params{uuid}) {
    $params{protocol} = 'ms-rpc-' . $params{protocol};
  }
  if (defined $params{protocol} and $params{protocol} !~ /^(tcp|udp)$/io) {
    $params{dstPort} = '0-65535' unless defined $params{dstPort};
  }
  return $class->$orig(%params);
};

__PACKAGE__->meta->make_immutable;
1;

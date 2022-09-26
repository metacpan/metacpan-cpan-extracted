package PDK::Firewall::Element::ServiceMeta::Paloalto;

#------------------------------------------------------------------------------
# 加载扩展模块
#------------------------------------------------------------------------------
use Moose;
use namespace::autoclean;

#------------------------------------------------------------------------------
# 继承 PDK::Firewall::Element::ServiceMeta::Role 角色 方法属性
#------------------------------------------------------------------------------
with 'PDK::Firewall::Element::ServiceMeta::Role';

#------------------------------------------------------------------------------
# Moose BUILDARGS 在实例创建之前生效，可以接收哈希和哈希的引用
#------------------------------------------------------------------------------
around BUILDARGS => sub {
  my $orig   = shift;
  my $class  = shift;
  my %params = @_;
  $params{srcPort} = '0-65535' if not defined $params{srcPort};

  # 边界条件判断，暂时仅支持 TCP|UDP 端口
  # TODOS：后续需要支持 ESP 端口？
  if (defined $params{protocol} and $params{protocol} !~ /^(tcp|udp)$/io) {
    $params{dstPort} = '0-65535' if not defined $params{dstPort};
  }
  return $class->$orig(%params);
};

#------------------------------------------------------------------------------
# 具体实现 PDK::Firewall::Element::Role => _buildSign 方法
#------------------------------------------------------------------------------
sub _buildSign {
  my $self = shift;
  return $self->createSign($self->srvName);
}

__PACKAGE__->meta->make_immutable;
1;

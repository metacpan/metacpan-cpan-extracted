package PDK::Firewall::Element::Service::Netscreen;

#------------------------------------------------------------------------------
# 加载扩展模块
#------------------------------------------------------------------------------
use Moose;
use namespace::autoclean;

#------------------------------------------------------------------------------
# 引入 PDK::Firewall::Element::Service::Role 角色
#------------------------------------------------------------------------------
with 'PDK::Firewall::Element::Service::Role';

#------------------------------------------------------------------------------
# timeout 具体实现功能推敲
#------------------------------------------------------------------------------
sub timeout {
  my $self = shift;
  my $timeout;
  for my $serviceMeta (values %{$self->metas}) {
    $timeout = $serviceMeta->timeout;
    last;
  }
  return $timeout;
}

#------------------------------------------------------------------------------
# setTimeout 具体实现功能推敲
#------------------------------------------------------------------------------
sub setTimeout {
  my ($self, $timeout) = @_;
  for my $serviceMeta (values %{$self->metas}) {
    $serviceMeta->setTimeout($timeout);
  }
}

__PACKAGE__->meta->make_immutable;
1;

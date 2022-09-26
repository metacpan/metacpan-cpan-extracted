package PDK::Firewall::Element::ServiceGroup::Role;

#------------------------------------------------------------------------------
# 加载扩展模块
#------------------------------------------------------------------------------
use Moose::Role;
use namespace::autoclean;

#------------------------------------------------------------------------------
# 引入 PDK::Firewall::Element::ServiceGroup::Role 角色
#------------------------------------------------------------------------------
with 'PDK::Firewall::Element::Role';

#------------------------------------------------------------------------------
# 设置服务端口组对象通用方法和属性
#------------------------------------------------------------------------------
has srvGroupName => (is => 'ro', isa => 'Str', required => 1,);

has description => (is => 'ro', isa => 'Str', required => 0,);

has srvGroupMembers => (
  is      => 'ro',
  does    => 'HashRef[PDK::Firewall::Element::Service::Role|PDK::Firewall::Element::ServiceGroup::Role]',
  default => sub { {} },
);

has dstPortRangeMap => (is => 'ro', isa => 'HashRef[PDK::Utils::Set]', default => sub { {} },);

has range => (is => 'ro', isa => 'PDK::Utils::Set', lazy => 1, builder => '_buildRange',);

# 对象被关联调用计数器
has refnum => (is => 'ro', isa => 'Int', default => 0);

#------------------------------------------------------------------------------
# 定义服务端口组通用签名方法
#------------------------------------------------------------------------------
sub _buildSign {
  my $self = shift;
  return $self->createSign($self->srvGroupName);
}

#------------------------------------------------------------------------------
# 实现 range 属性懒加载方法
#------------------------------------------------------------------------------
sub _buildRange {
  my $self  = shift;
  my $range = PDK::Utils::Set->new;
  for my $service (values %{$self->srvGroupMembers}) {
    $range->mergeToSet($service->range);
  }
  return $range;
}

#------------------------------------------------------------------------------
# addSrvGroupMember 添加服务端口组成员
#------------------------------------------------------------------------------
sub addSrvGroupMember {
  my ($self, $name, $obj) = @_;
  confess "ERROR: srvGroupMemberName must defined" unless defined $name;

  unless (not defined $obj or $obj->does('PDK::Firewall::Element::Service::Role') or $obj->does(__PACKAGE__)) {
    confess "ERROR: 参数 obj 只能是 PDK::Firewall::Element::Service::Role or " . __PACKAGE__ . " or Undef";
  }
  if (!!$obj) {
    for my $protocol (keys %{$obj->dstPortRangeMap}) {
      $self->dstPortRangeMap->{$protocol} //= PDK::Utils::Set->new;
      $self->dstPortRangeMap->{$protocol}->mergeToSet($obj->dstPortRangeMap->{$protocol});
    }
    $self->{srvGroupMembers}{$name} = $obj;
  }
  else {
    $self->{srvGroupMembers}{$name} = undef;
  }
}

1;

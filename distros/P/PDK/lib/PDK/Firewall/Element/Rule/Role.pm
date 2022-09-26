package PDK::Firewall::Element::Rule::Role;

#------------------------------------------------------------------------------
# 加载扩展模块
#------------------------------------------------------------------------------
use Moose::Role;
use namespace::autoclean;

#------------------------------------------------------------------------------
# 加载 PDK::Firewall::Element::Role 角色
#------------------------------------------------------------------------------
with 'PDK::Firewall::Element::Role';

#------------------------------------------------------------------------------
# 定义防火墙策略对象通用方法和属性
#------------------------------------------------------------------------------
has policyId => (is => 'ro', isa => 'Str', required => 1,);

has fromZone => (is => 'ro', isa => 'Str', required => 0, traits => ['String'], handles => {addFromZone => 'append'});

has toZone => (is => 'ro', isa => 'Str', required => 0, traits => ['String'], handles => {addToZone => 'append'});

has fromInterface => (is => 'ro', isa => 'Str', required => 0,);

has toInterface => (is => 'ro', isa => 'Str', required => 0,);

has action => (is => 'ro', isa => 'Str', default => 'permit',);

has isDisable => (is => 'ro', isa => 'Str', default => 'enable', writer => 'setIsDisable',);

has hasLog => (is => 'ro', isa => 'Undef|Str', default => undef, writer => 'setHasLog');

has description => (is => 'ro', isa => 'Str|Undef', default => undef,);

has schName => (is => 'ro', isa => 'Undef|Str', default => undef, writer => 'setSchName');

has content => (is => 'ro', isa => 'Str', required => 0, writer => 'setContent',);

has srcAddressGroup =>
  (is => 'ro', does => 'PDK::Firewall::Element::AddressGroup::Role', lazy => 1, builder => '_buildSrcAddressGroup',);

has dstAddressGroup =>
  (is => 'ro', does => 'PDK::Firewall::Element::AddressGroup::Role', lazy => 1, builder => '_buildDstAddressGroup',);

has serviceGroup =>
  (is => 'ro', does => 'PDK::Firewall::Element::ServiceGroup::Role', lazy => 1, builder => '_buildServiceGroup',);

has schedule =>
  (is => 'ro', does => 'PDK::Firewall::Element::Schedule::Role', predicate => 'hasSchedule', writer => 'setSchedule',);

has ruleNum => (is => 'ro', isa => 'Int', required => 0,);

#------------------------------------------------------------------------------
# 无效策略
#------------------------------------------------------------------------------
sub ignore {
  my $self = shift;
  return (defined $self->isDisable and $self->isDisable eq 'disable' or $self->hasSchedule and $self->schedule->isExpired);
}

#------------------------------------------------------------------------------
# 重写 PDK::Firewall::Element::Role => _buildRange 方法
#------------------------------------------------------------------------------
sub _buildSign {
  my $self = shift;
  return $self->createSign($self->policyId);
}

#------------------------------------------------------------------------------
# 动态获取调用者厂商信息
#------------------------------------------------------------------------------
sub vendor {
  my $self   = shift;
  my $obj    = ref $self;
  my $vendor = substr($obj, length("PDK::Firewall::Element::Rule::"));
  return $vendor;
}

#------------------------------------------------------------------------------
# PDK::Firewall::Element::Rule::Role _buildSrcAddressGroup 具体实现
#------------------------------------------------------------------------------
sub _buildSrcAddressGroup {
  my $self = shift;

  # 动态加载防火墙源地址组对象，并实例化对象
  my $vendor = $self->vendor;
  my $plugin = "PDK::Firewall::Element::AddressGroup::$vendor";
  eval "use $plugin; 1" or confess "Can't load plugin $plugin: $@";
  return $plugin->new(fwId => $self->fwId, addrGroupName => '^', zone => '^');
}

#------------------------------------------------------------------------------
# PDK::Firewall::Element::Rule::Role _buildDstAddressGroup 具体实现
#------------------------------------------------------------------------------
sub _buildDstAddressGroup {
  my $self = shift;

  # 动态加载防火墙目标地址组对象，并实例化对象
  my $vendor = $self->vendor;
  my $plugin = "PDK::Firewall::Element::AddressGroup::$vendor";
  eval "use $plugin; 1" or confess "Can't load plugin $plugin: $@";
  return $plugin->new(fwId => $self->fwId, addrGroupName => '^', zone => '^');
}

#------------------------------------------------------------------------------
# PDK::Firewall::Element::Rule::Role _buildServiceGroup 具体实现
#------------------------------------------------------------------------------
sub _buildServiceGroup {
  my $self = shift;

  # 动态加载防火墙预定义服务端口信息，并实例化对象
  my $vendor = $self->vendor;
  my $plugin = "PDK::Firewall::Element::ServiceGroup::$vendor";
  eval "use $plugin; 1" or confess "Can't load plugin $plugin: $@";
  return $plugin->new(fwId => $self->fwId, srvGroupName => '^');
}

#------------------------------------------------------------------------------
# 源地址成员
#------------------------------------------------------------------------------
sub srcAddressMembers {
  my $self = shift;
  return $self->srcAddressGroup->addrGroupMembers;
}

#------------------------------------------------------------------------------
# 目的地址成员
#------------------------------------------------------------------------------
sub dstAddressMembers {
  my $self = shift;
  return $self->dstAddressGroup->addrGroupMembers;
}

#------------------------------------------------------------------------------
# 服务端口成员
#------------------------------------------------------------------------------
sub serviceMembers {
  my $self = shift;
  return $self->serviceGroup->srvGroupMembers;
}

#------------------------------------------------------------------------------
# 新增源地址成员
#------------------------------------------------------------------------------
sub addSrcAddressMembers {
  my ($self, $memberName, $obj) = @_;
  $self->srcAddressGroup->addAddrGroupMember($memberName, $obj);
}

#------------------------------------------------------------------------------
# 新增目的地址成员
#------------------------------------------------------------------------------
sub addDstAddressMembers {
  my ($self, $memberName, $obj) = @_;
  $self->dstAddressGroup->addAddrGroupMember($memberName, $obj);
}

#------------------------------------------------------------------------------
# 新增服务端口成员
#------------------------------------------------------------------------------
sub addServiceMembers {
  my ($self, $memberName, $obj) = @_;
  $self->serviceGroup->addSrvGroupMember($memberName, $obj);
}

1;

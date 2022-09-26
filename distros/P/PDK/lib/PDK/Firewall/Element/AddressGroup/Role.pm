package PDK::Firewall::Element::AddressGroup::Role;

#------------------------------------------------------------------------------
# 加载扩展模块
#------------------------------------------------------------------------------
use Moose::Role;
use namespace::autoclean;
use PDK::Utils::Set;

#------------------------------------------------------------------------------
# 继承 PDK::Firewall::Element::Role 方法属性
#------------------------------------------------------------------------------
with 'PDK::Firewall::Element::Role';

#------------------------------------------------------------------------------
# PDK::Firewall::Element::AddressGroup::Role 通用属性
#------------------------------------------------------------------------------
has zone => (is => 'ro', isa => 'Str', required => 0,);

has description => (is => 'ro', isa => 'Str', required => 0,);

has addrGroupName => (is => 'ro', isa => 'Str', required => 1,);

has addrGroupMembers => (
  is      => 'ro',
  does    => 'HashRef[PDK::Firewall::Element::Address::Role|PDK::Firewall::Element::AddressGroup::Role|Undef]',
  default => sub { {} },
);

has range => (is => 'ro', isa => 'PDK::Utils::Set', default => sub { PDK::Utils::Set->new },);

has refnum => (is => 'ro', isa => 'Int', default => 0);

#------------------------------------------------------------------------------
# 设定防火墙地址组通用签名方法
#------------------------------------------------------------------------------
sub _buildSign {
  my $self = shift;
  return $self->createSign($self->addrGroupName);
}

#------------------------------------------------------------------------------
# 新增地址组成员方法
#------------------------------------------------------------------------------
sub addAddrGroupMember {
  my ($self, $name, $obj) = @_;
  confess "ERROR: addrGroupMemberName must defined" unless defined $name;

  unless (not defined $obj or $obj->does('PDK::Firewall::Element::Address::Role') or $obj->does(__PACKAGE__)) {
    confess "ERROR: 参数 obj 只能是 PDK::Firewall::Element::Address::Role or " . __PACKAGE__ . " or Undef";
  }
  if (!!$obj) {
    $self->{addrGroupMembers}{$name} = $obj;
    $self->range->mergeToSet($obj->range);
  }
  else {
    warn qq{Must provide name and object when execute addAddrGroupMember\n};
  }
}

1;

package PDK::Firewall::Element::ProtocolGroup::Role;

#------------------------------------------------------------------------------
# 加载扩展模块
#------------------------------------------------------------------------------
use Moose::Role;
use namespace::autoclean;

#------------------------------------------------------------------------------
# 引用 PDK::Firewall::Element::Role 角色
#------------------------------------------------------------------------------
with 'PDK::Firewall::Element::Role';

#------------------------------------------------------------------------------
# PDK::Firewall::Element::ProtocolGroup::Role 通用属性
#------------------------------------------------------------------------------
# 协议组名称
has proGroupName => (is => 'ro', isa => 'Str', required => 1,);

# 成员对象可以是协议或协议组
has proGroupMembers => (
  is      => 'ro',
  does    => 'HashRef[PDK::Firewall::Element::Protocol::Role|PDK::Firewall::Element::ProtocolGroup::Role]',
  default => sub { {} },
);

# 协议组支持的协议
has protocols => (is => 'ro', does => 'HashRef[PDK::Firewall::Element::Protocol::Role]', default => sub { {} },);

#------------------------------------------------------------------------------
# 实现 PDK::Firewall::Element::Role => _buildRange 方法
#------------------------------------------------------------------------------
sub _buildSign {
  my $self = shift;
  return $self->createSign($self->proGroupName);
}

#------------------------------------------------------------------------------
# 新增协议对象成员方法
#------------------------------------------------------------------------------
sub addProGroupMember {
  my ($self, $name, $obj) = @_;
  confess "ERROR: proGroupMemberName must defined" unless defined $name;
  unless (defined $obj and ($obj->does('PDK::Firewall::Element::Protocol::Role') or $obj->does(__PACKAGE__))) {
    confess "ERROR: 参数 obj 只能是 PDK::Firewall::Element::Protocol::Role or " . __PACKAGE__ . " or Undef";
  }

  $self->{proGroupMembers}{$name} = $obj;
  if ($name and $obj) {
    if ($obj->does('PDK::Firewall::Element::Protocol::Role')) {
      $self->protocols->{$obj->protocol} = $obj;
    }
    elsif ($obj->does(__PACKAGE__)) {
      for my $protocol (keys %{$obj->protocols}) {
        $self->protocols->{$protocol} = $obj->protocols->{$protocol};
      }
    }
  }
}

1;

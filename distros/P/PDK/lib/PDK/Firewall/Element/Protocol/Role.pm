package PDK::Firewall::Element::Protocol::Role;

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
# PDK::Firewall::Element::Protocol::Role 通用方法
#------------------------------------------------------------------------------
has protocol => (is => 'ro', isa => 'Str', required => 1,);

#------------------------------------------------------------------------------
# 重写 PDK::Firewall::Element::Role => _buildRange 方法
#------------------------------------------------------------------------------
sub _buildSign {
  my $self = shift;
  return $self->createSign($self->protocol);
}

#------------------------------------------------------------------------------
# Moose BUILDARGS 在实例创建之前生效，可以接收哈希和哈希的引用
# https://metacpan.org/pod/Moose::Manual::Construction
# https://metacpan.org/pod/Moose::Object
#------------------------------------------------------------------------------
around BUILDARGS => sub {
  my $orig  = shift;
  my $class = shift;

  # 接收传递进来的变量
  my %params = @_;
  $params{protocol} = lc $params{protocol} if defined $params{protocol};
  return $class->$orig(@_);
};

1;

package PDK::Device::Basic;

#------------------------------------------------------------------------------
# 加载系统模块
#------------------------------------------------------------------------------
use Moose::Role;
use namespace::autoclean;
use Try::Tiny;

#------------------------------------------------------------------------------
# 注册 Expect 为 Moose 对象类型
#------------------------------------------------------------------------------
use Moose::Util::TypeConstraints;
subtype Expect => as Object => where { $_->isa('Expect') };

#------------------------------------------------------------------------------
# 继承该模块必须实现的方法和属性
#------------------------------------------------------------------------------
requires 'connect';
requires 'waitfor';
requires 'getConfig';
requires 'execCommands';

#------------------------------------------------------------------------------
# 网络设备连接器通用属性和方法
#------------------------------------------------------------------------------
has expect => (is => 'ro', isa => 'Expect');

has host => (is => 'ro', isa => 'Str', required => 1,);

has username => (is => 'ro', isa => 'Str', required => 1,);

has password => (is => 'ro', isa => 'Str', required => 1,);

has enpassword => (is => 'ro', required => 0,);

has proto => (is => 'ro', required => 0, default => 'ssh',);

has _login_ => (is => 'ro', required => 0, default => 0,);

has _enable_ => (is => 'ro', required => 0, default => 0,);

#------------------------------------------------------------------------------
# 动态获取防火墙厂商信息
#------------------------------------------------------------------------------
sub vendor {
  my $self  = shift;
  my $class = ref $self;
  my $name  = [split(/::/, $class)]->[-1];
  return $name;
}

#------------------------------------------------------------------------------
# 设备登陆函数入口
#------------------------------------------------------------------------------
sub login {
  my $self = shift;

  # 如果已有 _login_ 记录，直接返回结果
  return {success => 1} if $self->{_login_};

  # 尝试连接设备进行响应逻辑判断
  try {
    $self->connect() unless (defined $self->{expect});
  }
  catch {
    if (/RSA modulus too small/mi) {
      try { $self->connect('-v -1 -c des ') }
      catch {
        return {success => 0, reason => $_};
      }
    }
    elsif (/Selected cipher type <unknown> not supported/mi) {
      try {
        $self->connect('-c des ');
      }
      catch {
        return {success => 0, reason => $_};
      }
    }
    elsif (/Connection refused/mi) {
      try {
        $self->{proto} = 'telnet';
        $self->connect();
      }
      catch {
        return {success => 0, reason => $_};
      }
    }
    elsif (/IDENTIFICATION HAS CHANGED/mi) {
      try {
        `/usr/bin/ssh-keygen -R $self->{host}`;
        $self->connect();
      }
      catch {
        return {success => 0, reason => $_};
      }
    }
    else {
      return {success => 0, reason => $_};
    }
  };

  # 如果未捕捉到异常信号，则登陆成功
  return {success => 1};
}

#------------------------------------------------------------------------------
# Cisco 设备发送指令入口函数，接收字符串
#------------------------------------------------------------------------------
sub send {
  my ($self, $command) = @_;
  my $exp = $self->expect;
  $exp->send($command);
}

#------------------------------------------------------------------------------
# _buildExpect 懒加载动态生成 Expect->new 对象
#------------------------------------------------------------------------------
sub _buildExpect {
  my $self = shift;

  # 初始化Expect函数
  my $exp = Expect->new();

  # $self->{$exp} = $exp;
  $exp->raw_pty(1);
  $exp->debug(0);
  $exp->restart_timeout_upon_receive(1);

  # 是否打印日志，一般用于排错
  # $exp->log_file("output.log");
  $exp->log_stdout(1);
  return $exp;
}

1;

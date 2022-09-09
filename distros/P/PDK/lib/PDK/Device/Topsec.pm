package PDK::Device::Topsec;

#------------------------------------------------------------------------------
# 加载系统模块
#------------------------------------------------------------------------------
use Moose;
use namespace::autoclean;
use Expect;

#------------------------------------------------------------------------------
# 加载通用方法属性
#------------------------------------------------------------------------------
with 'PDK::Device::Role';

#------------------------------------------------------------------------------
# Topsec 设备 Expect 初始化函数入口
#------------------------------------------------------------------------------
sub connect {
  my ($self, $args) = @_;

  # 检查是否携带变量并初始化
  $args ||= "";
  my $prompt   = '^\S+\s*[#>$%]\s*\z';
  my $username = $self->username;
  my $password = $self->password;
  my $host     = $self->host;

  # 初始化Expect函数
  my $exp = $self->expect;

  # 设置登录逻辑
  my $loginFlag = 1;
  my $command   = $self->{proto} . " $args" . " -l $username $host";
  $exp->spawn($command) || die "Cannot spawn $command: $!\n";
  my @ret = $exp->expect(
    10,
    [
      qr/Are you sure you want to continue connecting/mi => sub {
        $exp->send("yes\n");
        exp_continue;
      }
    ],
    [
      qr/assword:\s*$/mi => sub {
        if (!!$loginFlag) {
          $loginFlag = 0;
          $exp->send("$password\n");
        }
        else {
          confess "username or password is wrong!";
        }
        exp_continue;
      }
    ],
    [
      qr/ogin:\s*$/mi => sub {
        $exp->send("$username\n");
        exp_continue;
      }
    ],
    [
      qr/$prompt/ => sub {
        $self->{_login_} = 1;
      }
    ],
  );

  # Expect是否异常
  if (defined $ret[1]) {
    confess $ret[3] . $ret[1];
  }
  return 1;
}

#------------------------------------------------------------------------------
# Topsec 设备抓取运行配置函数入口
#------------------------------------------------------------------------------
sub getConfig {
  my $self = shift;

  # 抓取设备命令脚本，输入不分页命令加速输出
  my @commands = ("show-running nostop");
  my $config   = $self->execCommands(@commands);

  my $lines = "";
  if ($config->{success} == 1) {
    $lines = $config->{result};
  }
  else {
    return $config;
  }
  return {success => 1, config => $lines};
}

#------------------------------------------------------------------------------
# Topsec 设备捕捉命令输入 prompt 回显
#------------------------------------------------------------------------------
sub waitfor {
  my ($self, $prompt) = @_;
  my $buff = "";

  # 定义需要捕捉的回显字符串
  $prompt ||= '^\S+[$%#]\s*\z';
  my $exp = $self->expect;
  my @ret = $exp->expect(
    30,
    [
      qr/--More--/mi => sub {
        $exp->send(" ");

        # 捕捉配置分页关键字无需写入buff
        $buff .= $exp->before();
        exp_continue;
      }
    ],
    [
      qr/$prompt/m => sub {
        $buff .= $exp->before() . $exp->match();
      }
    ]
  );

  # 如果捕捉到异常记录，跳出函数
  if (defined $ret[1]) {
    confess $ret[3] . $ret[1];
  }
  return $buff;
}

#------------------------------------------------------------------------------
# Topsec 设备 execCommands 函数入口
#------------------------------------------------------------------------------
sub execCommands {
  my ($self, @commands) = @_;

  # 判断是否已登陆设备
  if ($self->{_login_} == 0) {
    my $ret = $self->login();
    return $ret unless $ret->{success};
  }

  # 初始化 result 变量，并开始执行命令
  my $result = "";
  for my $cmd (@commands) {
    next if $cmd =~ /^\s*$/;

    $self->send($cmd . "\n");
    my $buff = $self->waitfor();
    if ($buff =~ /error\s+-\d+/mi) {
      return {success => 0, failCommand => $cmd, reason => $result . $buff};
    }
    else {
      $result .= $buff;
    }
  }
  return {success => 1, result => $result};
}

__PACKAGE__->meta->make_immutable;
1;

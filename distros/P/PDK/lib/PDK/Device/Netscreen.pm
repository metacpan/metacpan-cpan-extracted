package PDK::Device::Netscreen;

#------------------------------------------------------------------------------
# 加载系统模块
#------------------------------------------------------------------------------
use Moose;
use namespace::autoclean;
use Expect;

#------------------------------------------------------------------------------
# 加载通用方法属性
#------------------------------------------------------------------------------
with 'PDK::Device::Basic';
with 'PDK::Device::Role';

#------------------------------------------------------------------------------
# Netscreen 设备 Expect 初始化函数入口
#------------------------------------------------------------------------------
sub connect {
  my ($self, $args) = @_;

  # 检查是否携带变量并初始化
  $args ||= "";
  my $username = $self->username;
  my $password = $self->password;
  my $host     = $self->host;
  my $prompt   = '^.+->\s*\z';

  # 初始化Expect函数
  my $exp        = $self->expect;
  my $login_flag = 1;

  my $command = $self->{proto} . " $args" . " -l $username $host";
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
        if ($login_flag) {
          $login_flag = 0;
          $exp->send("$password\n");
        }
        else {
          confess "username or password is wrong!";
        }
        exp_continue;
      }
    ],
    [
      qr/(ogin|name):\s*$/mi => sub {
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
# Netscreen 设备抓取运行配置函数入口
#------------------------------------------------------------------------------
sub getConfig {
  my $self = shift;

  # 抓取设备命令脚本，输入不分页命令加速输出
  my @commands = ("get config");
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
# Netscreen 设备捕捉命令输入 prompt 回显
#------------------------------------------------------------------------------
sub waitfor {
  my ($self, $prompt) = @_;
  my $buff = "";

  # 定义需要捕捉的回显字符串
  $prompt ||= '^.+->\s*\z';
  my $exp = $self->expect;
  my @ret = $exp->expect(
    60,
    [
      qr/^.+more\s*.+$/mi => sub {
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

  # 处理非常态配置，影响计算哈希
  $buff =~ s/\r\n|\n+\n/\n/g;
  $buff =~ s/\x{08}+\s+\x{08}+//g;
  $buff =~ s/^\s*$//gm;
  return $buff;
}

#------------------------------------------------------------------------------
# Netscreen 设备 execCommands 函数入口
#------------------------------------------------------------------------------
sub execCommands {
  my ($self, @commands) = @_;

  # 判断是否已登陆设备
  if ($self->{_login_} == 0) {
    my $ret = $self->login();
    return $ret unless ($ret->{success});
  }
  $self->enable() unless ($self->{_enable_});

  # 初始化 result 变量，并开始执行命令
  my $result = "";
  my $policyId;
  for my $cmd (@commands) {
    next if $cmd =~ /^\s*$/;
    if ($cmd =~ /set policy id X+/) {
      $cmd = "set policy id $policyId" if (defined $policyId);
      return {success => 0, reason => "policyId not defined, maybe missed set policy top"} unless defined $policyId;
    }

    $self->send($cmd . "\n");
    my $buff = $self->waitfor();
    if ($buff =~ /^\s+\^-+unknown keyword/i) {
      return {success => 0, failCommand => $cmd, reason => $result . $buff};
    }
    else {
      if ($cmd =~ /top/i) {
        $buff =~ /policy\s+id\s*=\s*(?<policyId>\d+)\s*/mi;
        $policyId = $+{policyId};
      }
      $result .= $buff;
    }
  }
  if ($result =~ /error:/i) {
    return {success => 0, result => $result};
  }
  else {
    return {success => 1, result => $result};
  }
}

__PACKAGE__->meta->make_immutable;
1;

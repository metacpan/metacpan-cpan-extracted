package PDK::Device::Huawei::Usg;

use v5.30;
use Moose;
use Expect qw'exp_continue';
use Carp   qw'croak';
extends 'PDK::Device::Huawei';
use namespace::autoclean;

sub getConfig {
  my $self = shift;

  my $commands = ["screen-width 512", "screen-length 512 temporary", "dis current-configuration", "save"];

  my $config = $self->execCommands($commands);

  if ($config->{success} == 0) {
    return $config;
  }
  else {
    my $lines = $config->{result};
    return {success => 1, config => $lines};
  }
}

sub ftpConfig {
  my ($self, $hostname, $server, $username, $password) = @_;

  $server   //= $ENV{PDK_FTP_SERVER};
  $username //= $ENV{PDK_FTP_USERNAME};
  $password //= $ENV{PDK_FTP_PASSWORD};

  croak "请正确提供 FTP 服务器地址、账户和密码或者设置相关环境变量!" unless $username and $password and $server;

  if (!$self->{exp}) {
    my $login = $self->login();
    croak $login->{reason} if $login->{success} == 0;
  }

  my $host    = $self->{host};
  my $command = "put config.cfg $self->{month}/$self->{date}/";

  if (!!$hostname) {
    $command .= $hostname . '_' . $host . '.txt';
  }
  else {
    $command .= $host . '.txt';
  }

  my $exp    = $self->{exp};
  my $result = $exp ? $exp->match() || '' : '';

  my $ftp_cmd = "ftp $server vpn-instance default";
  $self->dump("生成 FTP 备份指令：$ftp_cmd");

  $self->send("$ftp_cmd\n");
  $self->dump("准备连接 FTP 服务器");

  my @ret = $exp->expect(
    15,
    [
      qr/User\s*\(/i => sub {
        $self->send("$username\n");
        $result .= $exp->before() . $exp->match();
        exp_continue;
      }
    ],
    [
      qr/assword:/i => sub {
        $self->send("$password\n");
        $result .= $exp->before() . $exp->match();
      }
    ],
    [
      eof => sub {
        croak("执行[ftpConfig/登录FTP服务器]，与设备 $self->{host} 会话丢失，连接被意外关闭！" . $exp->before());
      }
    ],
    [
      timeout => sub {
        croak("执行[ftpConfig/登录FTP服务器]，与设备 $self->{host} 会话超时！");
      }
    ],
  );

  croak($ret[3]) if defined $ret[1];

  @ret = $exp->expect(
    10,
    [
      qr/(ftp: Login failed.|Username)/i => sub {
        croak("FTP 登录失败: 用户名或密码错误！");
      }
    ],
    [
      qr/User logged in/i => sub {
        $result .= $exp->before() . $exp->match();
        $self->dump("成功连接 FTP 服务器($server)");
      }
    ],
    [
      eof => sub {
        croak("执行[ftpConfig/检查是否成功登录FTP]，与设备 $self->{host} 会话丢失！" . $exp->before());
      }
    ],
    [
      timeout => sub {
        croak("执行[ftpConfig/检查是否成功登录FTP]，与设备 $self->{host} 会话超时！");
      }
    ],
  );

  croak($ret[3]) if defined $ret[1];

  $self->send("$command\n");
  @ret = $exp->expect(
    15,
    [
      qr/(No such file or directory|The system cannot)/i => sub {
        croak "执行脚本 $command 异常，上传失败！";
      }
    ],
    [
      qr/Transfer complete.*ftp[>\]]/ms => sub {
        $result .= $exp->before() . $exp->match() . $exp->after();
        $self->dump("脚本 $command 已执行完毕, 文件上传成功");
      }
    ],
    [
      eof => sub {
        croak("执行[ftpConfig/检查备份任务是否成功]，与设备 $self->{host} 会话丢失！" . $exp->before());
      }
    ],
    [
      timeout => sub {
        croak("执行[ftpConfig/检查备份任务是否成功]，与设备 $self->{host} 会话超时！");
      }
    ],
  );

  croak($ret[3]) if defined $ret[1];
  $self->send("quit\n");

  return {success => 1, config => $result};
}

__PACKAGE__->meta->make_immutable;

1;

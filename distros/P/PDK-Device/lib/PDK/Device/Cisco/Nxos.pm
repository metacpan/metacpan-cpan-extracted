package PDK::Device::Cisco::Nxos;

use v5.30;
use Moose;
use Expect qw'exp_continue';
use Carp   qw'croak';
extends 'PDK::Device::Cisco';
use namespace::autoclean;

sub ftpConfig {
  my ($self, $hostname, $server, $username, $password) = @_;

  $server   //= $ENV{PDK_FTP_SERVER};
  $username //= $ENV{PDK_FTP_USERNAME};
  $password //= $ENV{PDK_FTP_PASSWORD};

  croak "请正确提供 FTP 服务器地址、账户和密码，或者设置相关的环境变量！" unless $username && $password && $server;

  if (!$self->{exp}) {
    my $login = $self->login();
    croak $login->{reason} if $login->{success} == 0;
  }

  my $host = $self->{host};

  my $command = "copy running-config ftp://$username\@$server/$self->{month}/$self->{date}/";

  if (!!$hostname) {
    $command .= "${hostname}_${host}.txt";
  }
  else {
    $command .= "$host.txt";
  }

  my $exp    = $self->{exp};
  my $result = $exp->match() || '';

  my $vrf = 'default';

  $self->send("$command\n");
  $self->dump("准备连接到 FTP 服务器");

  my @ret = $exp->expect(
    15,
    [
      qr/Enter vrf/i => sub {
        $self->send("$vrf\n");
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
        croak("执行[$command/尝试FTP备份配置]，与设备 $self->{host} 会话丢失，连接被意外关闭！原因：" . $exp->before());
      }
    ],
    [
      timeout => sub {
        croak("执行[$command/尝试FTP备份配置]，与设备 $self->{host} 会话超时，请检查网络连接或服务器状态！");
      }
    ],
  );

  croak($ret[3]) if defined $ret[1];

  @ret = $exp->expect(
    10,
    [
      qr/Transfer of file aborted \*/mi => sub {
        croak "执行脚本 $command 异常，上传失败！";
      }
    ],
    [
      qr/Copy complete\./mi => sub {
        $result .= $exp->before() . $exp->match();
        $self->dump("脚本 $command 已执行完毕，文件上传成功");
        exp_continue;
      }
    ],
    [
      qr/$self->{prompt}/mi => sub {
        $result .= $exp->before() . $exp->match();
      }
    ],
    [
      eof => sub {
        croak("执行[$command/检查备份任务是否完成]，与设备 $self->{host} 会话丢失，连接被意外关闭！原因：" . $exp->before());
      }
    ],
    [
      timeout => sub {
        croak("执行[$command/检查备份任务是否完成]，与设备 $self->{host} 会话超时，请检查网络连接或服务器状态！");
      }
    ],
  );

  croak($ret[3]) if defined $ret[1];

  return {success => 1, config => $result};
}

__PACKAGE__->meta->make_immutable;
1;

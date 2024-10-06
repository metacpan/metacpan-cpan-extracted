package PDK::Device::Cisco::Nxos;

use 5.030;
use strict;
use warnings;

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

  croak "请正确提供 FTP 服务器地址、账户和密码!" unless $username and $password and $server;

  my $host = $self->{host};

  my $command = "copy running-config ftp://$username" . '@' . "$server/$self->{month}/$self->{date}/";

  if ($hostname) {
    $command .= $hostname . '_' . $host . '.cfg';
  }
  else {
    $command .= $host . '.cfg';
  }

  if (!$self->{exp}) {
    my $login = $self->login();
    if ($login->{success} != 1) {
      croak $login->{reason};
    }
  }

  my $exp    = $self->{exp};
  my $result = $exp->match() // '';

  my $vrf = 'default';

  $exp->send("$command\n");
  my @ret = $exp->expect(
    15,
    [
      qr/Enter vrf/mi => sub {
        $result .= $exp->before() . $exp->match();
        $exp->send("$vrf\n");
        exp_continue;
      }
    ],
    [
      qr/assword:/mi => sub {
        $result .= $exp->before() . $exp->match();
        $exp->send("$password\n");
      }
    ],
    [
      eof => sub {
        croak("执行[$command/尝试FTP备份配置]，与设备 $self->{host} 会话丢失，连接被意外关闭！具体原因：\n" . $exp->before());
      }
    ],
    [
      timeout => sub {
        croak("执行[$command/尝试FTP备份配置]，与设备 $self->{host} 会话超时，请检查网络连接或服务器状态！具体原因：\n" . $exp->before());
      }
    ],
  );

  if (defined $ret[1]) {
    croak $ret[3];
  }

  @ret = $exp->expect(
    10,
    [
      qr/Transfer of file aborted \*/mi => sub {
        croak "执行脚本 $command 异常，上传失败!";
      }
    ],
    [
      qr/Copy complete\./mi => sub {
        $result .= $exp->before() . $exp->match();
        say "[debug] 脚本 $command 已执行完毕, 文件上传成功!" if $self->{debug};
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
        croak("执行[$command/检查备份任务是否完成]，与设备 $self->{host} 会话丢失，连接被意外关闭！具体原因：\n" . $exp->before());
      }
    ],
    [
      timeout => sub {
        croak("执行[$command/检查备份任务是否完成]，与设备 $self->{host} 会话超时，请检查网络连接或服务器状态！具体原因：\n" . $exp->before());
      }
    ],
  );

  if (defined $ret[1]) {
    croak $ret[3];
  }

  return {success => 1, config => $result};
}

__PACKAGE__->meta->make_immutable;
1;

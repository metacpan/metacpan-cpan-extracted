package PDK::Device::Huawei;

use 5.030;
use strict;
use warnings;

use Moose;
use Expect qw'exp_continue';
use Carp   qw'croak';
with 'PDK::Device::Base';
use namespace::autoclean;

has prompt => (is => 'ro', required => 1, default => '^\s*[<\[].*?[>\]]\s*$',);

sub errCodes {
  my $self = shift;

  return [
    qr/(Ambiguous|Incomplete|not recognized|Unrecognized)/i,
    qr/(Wrong parameter|Too many parameters|does not exist)/i,
    qr/^Error:/mi,
  ];
}

sub waitfor {
  my ($self, $prompt) = @_;

  my $buff = "";
  $prompt //= $self->{prompt};

  my $exp = $self->{exp};

  my @ret = $exp->expect(
    15,
    [
      qr/^\s*---- More ----\s*$/mi => sub {
        $exp->send(" ");
        $buff .= $exp->before();
        exp_continue;
      }
    ],
    [
      qr/Are you sure to continue/i => sub {
        $exp->send("y\r");
        $buff .= $exp->before() . $exp->match();
        exp_continue;
      }
    ],
    [
      qr/This command will change the default screen width/i => sub {
        $exp->send("Y\r");
        $buff .= $exp->before() . $exp->match();
        exp_continue;
      }
    ],
    [
      qr/press the enter key/i => sub {
        $exp->send("\r");
        $buff .= $exp->before() . $exp->match();
        exp_continue;
      }
    ],
    [
      qr/$prompt/mi => sub {
        $buff .= $exp->before() . $exp->match();
      }
    ],
    [
      eof => sub {
        croak("执行[waitfor/自动交互执行回显]，与设备 $self->{host} 会话丢失，连接被意外关闭！具体原因：\n" . $exp->before());
      }
    ],
    [
      timeout => sub {
        croak("执行[waitfor/自动交互执行回显]，与设备 $self->{host} 会话超时，请检查网络连接或服务器状态！具体原因：\n" . $exp->before());
      }
    ],
  );

  croak($ret[3]) if defined $ret[1];

  $buff =~ s/\x1b\[\d+D\s+\x1b\[\d+D//g;
  $buff =~ s/\r\n|\n+\n/\n/g;
  $buff =~ s/^%.+$//mg;
  $buff =~ s/^\s*$//mg;

  return $buff;
}

sub runCommands {
  my ($self, $commands) = @_;

  croak "执行[runCommands]，必须提供一组待下发脚本" unless ref $commands eq 'ARRAY';

  if ($commands->[0] !~ /^sy/i) {
    unshift @$commands, 'system-view';
  }

  unless ($commands->[-1] =~ /^(sa|write)/i) {
    push @$commands, 'save';
  }

  $self->execCommands($commands);
}

sub getConfig {
  my $self = shift;

  my $commands = ["screen-length disable temporary", "screen-width 512", "dis current-configuration", "save"];

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

  croak "请正确提供 FTP 服务器地址、账户和密码!" unless $username and $password and $server;

  my $host = $self->{host};

  my $command = "put vrpcfg.zip $self->{month}/$self->{date}/";

  if ($hostname) {
    $command .= $hostname . '_' . $host . '.zip';
  }
  else {
    $command .= $host . '.zip';
  }

  if (!$self->{exp}) {
    my $login = $self->login();
    croak $login->{reason} if $login->{success} == 0;
  }

  my $exp    = $self->{exp};
  my $result = $exp ? $exp->match() : "";

  my $ftp_cmd = "ftp $server vpn-instance default";
  say "[debug] 生成 FTP 备份指令：$ftp_cmd" if $self->{debug};

  $exp->send("$ftp_cmd\n");
  my @ret = $exp->expect(
    15,
    [
      qr/User\s*\(/i => sub {
        $result .= $exp->before() . $exp->match();
        $exp->send("$username\n");
        exp_continue;
      }
    ],
    [
      qr/assword:/i => sub {
        $result .= $exp->before() . $exp->match();
        $exp->send("$password\n");
      }
    ],
    [
      eof => sub {
        croak("执行[ftpConfig/登录FTP服务器]，与设备 $self->{host} 会话丢失，连接被意外关闭！具体原因：\n" . $exp->before());
      }
    ],
    [
      timeout => sub {
        croak("执行[ftpConfig/登录FTP服务器]，与设备 $self->{host} 会话超时，请检查网络连接或服务器状态！具体原因：\n" . $exp->before());
      }
    ],
  );

  croak($ret[3]) if defined $ret[1];

  @ret = $exp->expect(
    10,
    [
      qr/(ftp: Login failed.|Username)/i => sub {
        croak("FTP 会话丢失: username or password is wrong!");
      }
    ],
    [
      qr/User logged in/i => sub {
        $result .= $exp->before() . $exp->match();
        say "[debug] 成功连接 FTP 服务器($server)" if $self->{debug};
      }
    ],
    [
      eof => sub {
        croak("执行[ftpConfig/检查是否成功登录FTP]，与设备 $self->{host} 会话丢失，连接被意外关闭！具体原因：\n" . $exp->before());
      }
    ],
    [
      timeout => sub {
        croak("执行[ftpConfig/检查是否成功登录FTP]，与设备 $self->{host} 会话超时，请检查网络连接或服务器状态！具体原因：\n" . $exp->before());
      }
    ],
  );

  $exp->send("$command\n");
  @ret = $exp->expect(
    15,
    [
      qr/(No such file or directory|The system cannot)/i => sub {
        croak "执行脚本 $command 异常，上传失败!";
      }
    ],
    [
      qr/Transfer complete.*ftp[>\]]/ms => sub {
        $result .= $exp->before() . $exp->match() . $exp->after();
        say "\n[debug] 脚本 $command 已执行完毕, 文件上传成功!" if $self->{debug};
      }
    ],
    [
      eof => sub {
        croak("执行[ftpConfig/检查备份任务是否成功]，与设备 $self->{host} 会话丢失，连接被意外关闭！具体原因：\n" . $exp->before());
      }
    ],
    [
      timeout => sub {
        croak("执行[ftpConfig/检查备份任务是否成功]，与设备 $self->{host} 会话超时，请检查网络连接或服务器状态！具体原因：\n" . $exp->before());
      }
    ],
  );

  croak($ret[3]) if defined $ret[1];
  $exp->send("quit\n");

  return {success => 1, config => $result};
}

__PACKAGE__->meta->make_immutable;
1;

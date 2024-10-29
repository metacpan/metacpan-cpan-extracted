package PDK::Device::Huawei;

use utf8;
use v5.30;
use Moose;
use Expect qw(exp_continue);
use Carp   qw(croak);
use namespace::autoclean;

with 'PDK::Device::Role';

has prompt => (is => 'ro', required => 1, default => '^\s*[<\[].*?[>\]]\s*$', );

sub errCodes {
  shift;

  return [
    qr/(Ambiguous|Incomplete|not recognized|Unrecognized)/i,
    qr/(Wrong parameter|Too many parameters|does not exist)/i,
    qr/^Error:/mi,
  ];
}

sub waitfor {
  my ($self, $prompt, $params) = @_;

  croak "当同时定义 prompt 和 params 时，'params' 必须是一个哈希引用" if $prompt && $prompt && ref($params) ne 'HASH';

  my $buff = "";

  $prompt //= $self->{prompt};

  my $exp = $self->{exp};

  my $exp_rule;
  if ($prompt && !$params) {
    $exp_rule = [
      qr/$prompt/mi => sub {
        $buff .= $exp->before() . $exp->match();
      }
    ];
  }
  elsif ($prompt && $params) {
    $exp_rule = [
      qr/$prompt/mi => sub {
        my $send     = $params->{send}     // '';
        my $continue = $params->{continue} // 0;
        my $cache    = $params->{cache}    // 1;

        $self->send($send)                      if !!$send;
        $buff .= $exp->before() . $exp->match() if !!$cache;
        exp_continue                            if !!$continue;
      }
    ];
  }

  my $handles = [
    [
      qr/^\s*---- More ----\s*$/i => sub {
        $self->send(" ");
        $buff .= $exp->before();
        exp_continue;
      }
    ],
    [
      qr/Are you sure to continue/i => sub {
        $self->send("y\r");
        $buff .= $exp->before() . $exp->match();
        exp_continue;
      }
    ],
    [
      qr/This command will change the default screen width/i => sub {
        $self->send("y\r");
        $buff .= $exp->before() . $exp->match();
        exp_continue;
      }
    ],
    [
      qr/press the enter key/i => sub {
        $self->send("\r");
        $buff .= $exp->before() . $exp->match();
        exp_continue;
      }
    ],
    [
      eof => sub {
        croak("[waitfor/自动交互执行回显] 与设备 $self->{host} 会话丢失，连接被意外关闭！具体原因" . $exp->before());
      }
    ],
    [
      timeout => sub {
        croak("[waitfor/自动交互执行回显] 与设备 $self->{host} 会话超时，请检查网络连接或服务器状态");
      }
    ],
  ];

  splice(@{$handles}, -2, 0, $exp_rule);

  my @ret = $exp->expect($self->{timeout}, @{$handles});

  croak($ret[3]) if defined $ret[1];

  $buff =~ s/\x1b\[\d+D\s+\x1b\[\d+D//g;
  $buff =~ s/\r\n|\n+\n/\n/g;
  $buff =~ s/^%.+$//mg;
  $buff =~ s/^\s*$//mg;

  return $buff;
}

sub runCommands {
  my ($self, @commands) = @_;

  my @cmds = @commands == 1 && ref $commands[0] eq 'ARRAY' ? @{$commands[0]} : @commands;

  $self->{mode} = 'deployCommands';

  unshift @cmds, 'system-view' if $cmds[0] !~ /^sy/i;

  push @cmds, 'save force' unless $cmds[-1] =~ /^(sa|write)/i;

  $self->execCommands(@cmds);
}

sub getConfig {
  my $self = shift;

  my $commands = ["screen-length disable temporary", "screen-width 512", "dis current-configuration", "save", ];

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

  if (!$self->{exp}) {
    my $login = $self->login();
    croak $login->{reason} if $login->{success} == 0;
  }

  my $host    = $self->{host};
  my $command = "put vrpcfg.zip $self->{month}/$self->{date}/";

  $command .= $hostname ? "$hostname\_$host.txt" : "$host.txt";

  my $exp    = $self->{exp};
  my $result = $exp ? ($exp->match() || '') : '';

  my $ftp_cmd = "ftp $server vpn-instance default";
  $self->dump("生成 FTP 备份指令：$ftp_cmd");

  $self->send("$ftp_cmd\n");
  $self->dump("正在连接 FTP 服务器");

  my @ret = $exp->expect(
    30,
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
        croak("[ftpConfig/登录FTP服务器] 与设备 $self->{host} 会话丢失，连接被意外关闭！具体原因" . $exp->before());
      }
    ],
    [
      timeout => sub {
        croak("[ftpConfig/登录FTP服务器] 与设备 $self->{host} 会话超时，请检查网络连接或服务器状态");
      }
    ],
  );
  croak($ret[3]) if defined $ret[1];

  @ret = $exp->expect(
    30,
    [
      qr/(ftp: Login failed.|Username)/i => sub {
        croak("FTP 会话丢失: username or password is wrong!");
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
        croak("[ftpConfig/检查是否成功登录FTP] 与设备 $self->{host} 会话丢失，连接被意外关闭！具体原因" . $exp->before());
      }
    ],
    [
      timeout => sub {
        croak("[ftpConfig/检查是否成功登录FTP] 与设备 $self->{host} 会话超时，请检查网络连接或服务器状态");
      }
    ],
  );
  croak($ret[3]) if defined $ret[1];

  $self->dump("正在执行FTP备份任务");
  $self->send("$command\n");
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
        $self->dump("脚本 $command 已执行完毕, 文件上传成功");
      }
    ],
    [
      eof => sub {
        croak("[ftpConfig/检查备份任务是否成功] 与设备 $self->{host} 会话丢失，连接被意外关闭！具体原因" . $exp->before());
      }
    ],
    [
      timeout => sub {
        croak("[ftpConfig/检查备份任务是否成功] 与设备 $self->{host} 会话超时，请检查网络连接或服务器状态");
      }
    ],
  );
  croak($ret[3]) if defined $ret[1];

  $self->send("quit\n");
  return {success => 1, config => $result};
}

__PACKAGE__->meta->make_immutable;
1;

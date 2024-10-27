package PDK::Device::Radware;

use utf8;
use v5.30;
use Moose;
use Expect qw'exp_continue';
use Carp   qw'croak';
use namespace::autoclean;

with 'PDK::Device::Role';

has prompt => (is => 'ro', required => 1, default => '^>>.*?#\s*$', );

sub errCodes {
  my $self = shift;

  return [qr/^Error:.*?$/mi, ];
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
      qr/Confirm saving without first applying changes/i => sub {
        $self->send("y\r");
        $buff .= $exp->before() . $exp->match();
        exp_continue;
      }
    ],
    [
      qr/Confirm saving to FLASH/i => sub {
        $self->send("y\r");
        $buff .= $exp->before() . $exp->match();
        exp_continue;
      }
    ],
    [
      qr/Confirm dumping all information/i => sub {
        $self->send("y\r");
        $buff .= $exp->before() . $exp->match();
        exp_continue;
      }
    ],
    [
      qr/(Display|Include) private keys/i => sub {
        $self->send($self->{passphrase} ? "y\r" : "n\r");
        $buff .= $exp->before() . $exp->match();
        exp_continue;
      }
    ],
    [
      qr/(Enter|Reconfirm) passphrase/i => sub {
        $self->send("$self->{passphrase}\r");
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

  return $buff;
}

sub runCommands {
  my ($self, @commands) = @_;

  my @cmds = @commands == 1 && ref $commands[0] eq 'ARRAY' ? @{$commands[0]} : @commands;

  $self->{mode} = 'deployCommands';

  unshift @cmds, 'cd' if $cmds[0] !~ /^cd/mi;

  push @cmds, 'apply', 'save' unless $cmds[-1] =~ /^(apply|save)/mi;

  $self->execCommands(@cmds);
}

sub getConfig {
  my $self = shift;

  my $commands = ["cfg/dump", "cd", ];

  my $config = $self->execCommands($commands);

  return $config if $config->{success} == 0;

  my $lines = $config->{result};

  return {success => 1, config => $lines};
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
  my $command = "$self->{month}/$self->{date}/";

  $command .= $hostname ? "${hostname}_$host.tar.gz" : "$host.tar.gz";

  my $exp    = $self->{exp};
  my $result = $exp ? ($exp->match() || '') : '';

  my $connector = "cfg/ptcfg ${server} -m -mansync";
  $self->dump("执行FTP备份脚本[$connector]，备份到目标文件为 $command");

  $self->send("$connector\n");
  my @ret = $exp->expect(
    15,
    [
      qr/hit return for automatic file name/i => sub {
        $result .= $exp->before() . $exp->match();
        $self->send("$command\r");
        exp_continue;
      }
    ],
    [
      qr/Enter username for FTP/i => sub {
        $self->send("$username\r");
        $result .= $exp->before() . $exp->match();
        exp_continue;
      }
    ],
    [
      qr/Enter password for username/i => sub {
        $self->send("$password\r");
        $result .= $exp->before() . $exp->match();
        exp_continue;
      }
    ],
    [
      qr/(Display|Include) private keys/i => sub {
        $self->send($self->{passphrase} ? "y\r" : "n\r");
        $result .= $exp->before() . $exp->match();
        exp_continue;
      }
    ],
    [
      qr/(Enter|Reconfirm) passphrase/i => sub {
        $self->send("$self->{passphrase}\r");
        $result .= $exp->before() . $exp->match();
        exp_continue;
      }
    ],
    [
      qr/hit return for FTP server/i => sub {
        $result .= $exp->before() . $exp->match();
        $self->send("\r");
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
    10,
    [
      qr/^Error: Illegal operation/mi => sub {
        croak("FTP 会话丢失: username or password is wrong!");
      }
    ],
    [
      qr/Current config successfully transferred/ => sub {
        $result .= $exp->before() . $exp->match();
        $self->dump("FTP 配置备份：文件 $command 上传成功");
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
  $self->send("cd\r");

  return {success => 1, config => $result};
}

__PACKAGE__->meta->make_immutable;

1;

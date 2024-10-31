package PDK::Device::Cisco;

use utf8;
use v5.30;
use Moose;
use Expect qw(exp_continue);
use Carp   qw(croak);
use namespace::autoclean;

with 'PDK::Device::Role';


has prompt => (is => 'ro', required => 1, default => '^\s*\S+[#>]\s*$',);

has enPrompt => (is => 'ro', required => 0, default => '^\s*\S+[>]\s*$',);

has enCommand => (is => 'ro', required => 0, default => 'enable',);

sub errCodes {
  my $self = shift;

  return [
    qr/(Ambiguous|Incomplete|Unrecognized|not recognized|%Error)/mi,
    qr/(Permission denied|syntax error|authorization failed)/mi,
    qr/(Invalid (parameter|command|input)|Unknown command|Login invalid)/mi,
  ];
}

sub waitfor {
  my ($self, $prompt, $params) = @_;

  croak "当同时定义 prompt 和 params 时，'params' 必须是一个哈希引用" if $prompt && $params && ref($params) ne 'HASH';

  my $buff = "";

  $prompt //= $self->{prompt};

  my $exp = $self->{exp};

  my $exp_rule;
  if ($prompt && not defined $params) {
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
      qr/^.+more\s*.+$/mi => sub {
        $self->send(" ");
        $buff .= $exp->before();
        exp_continue;
      }
    ],
    [
      qr/\[startup-config\]\?/i => sub {
        $self->send("\r");
        $buff .= $exp->before() . $exp->match();
        exp_continue;
      }
    ],
    [
      qr/Address or name of remote host/i => sub {
        $exp->send("\r");
        $buff .= $exp->before() . $exp->match();
        exp_continue;
      }
    ],
    [
      qr/Destination filename \[/i => sub {
        $exp->send("\r");
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

  $buff =~ s/\r\n|\n+\n/\n/g;
  $buff =~ s/\x{08}+\s+\x{08}+//g;
  $buff =~ s/\x0D\[\s*#+\s*\]?\s*\d{1,2}%//g;
  $buff =~ s/\x1B\[K//g;
  $buff =~ s/\x0D//g;

  return $buff;
}

sub runCommands {
  my ($self, @commands) = @_;

  my @cmds = @commands == 1 && ref $commands[0] eq 'ARRAY' ? @{$commands[0]} : @commands;

  $self->{mode} = 'deployCommands';

  unshift @cmds, 'configure terminal' if $cmds[0] !~ /conf/i;

  push @cmds, 'copy running-config startup-config' unless $cmds[-1] =~ /(copy run|write)/i;

  $self->execCommands(@cmds);
}

sub getConfig {
  my $self = shift;

  my $commands = ["terminal width 511", "terminal length 0", "show run | exclude !Time", "copy run start", ];

  my $config = $self->execCommands($commands);

  if ($config->{success} == 0) {
    return $config;
  }
  else {
    my $lines = $config->{result};
    $lines =~ s/^\s*ntp\s+clock-period\s+\d+\s*$//mi;
    return {success => 1, config => $lines};
  }
}

sub ftpConfig {
  my ($self, $hostname, $server) = @_;

  $server ||= $ENV{PDK_FTP_SERVER};

  croak "请正确提供 FTP 服务器地址!" unless !!$server;

  if (!$self->{exp}) {
    my $login = $self->login();
    croak $login->{reason} if $login->{success} == 0;
  }

  my $host    = $self->{host};
  my $command = "copy running-config ftp://$server/$self->{month}/$self->{date}/";

  $command .= $hostname ? "$hostname\_$host.txt" : "$host.txt";

  $self->dump("正在执行FTP备份任务");
  my $result = $self->execCommands($command);
  if ($result->{success} == 0) {
    croak "[ftpConfig/配置备份异常]，$result->{reason}";
  }
  else {
    $self->dump("FTP备份任务成功执行完毕");
    return $result;
  }
}

__PACKAGE__->meta->make_immutable;
1;

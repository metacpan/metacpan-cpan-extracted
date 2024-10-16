package PDK::Device::Cisco;

use v5.30;
use Moose;
use Expect qw(exp_continue);
use Carp   qw(croak);
use namespace::autoclean;

with 'PDK::Device::Base';

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
  my ($self, $prompt) = @_;

  my $buff = "";
  $prompt //= $self->{prompt};

  my $exp = $self->{exp};
  my @ret = $exp->expect(
    45,
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

  $buff =~ s/\r\n|\n+\n/\n/g;
  $buff =~ s/\x{08}+\s+\x{08}+//g;

  $buff =~ s/\x0D\[\s*#+\s*\]?\s*\d{1,2}%//g;
  $buff =~ s/\x1B\[K//g;
  $buff =~ s/\x0D//g;

  return $buff;
}

sub runCommands {
  my ($self, $commands) = @_;

  croak "执行[runCommands]，必须提供一组待下发脚本" unless ref $commands eq 'ARRAY';

  $self->{mode} = 'deployCommands';

  if ($commands->[0] !~ /conf/i) {
    unshift @$commands, 'configure terminal';
  }

  unless ($commands->[-1] =~ /(copy run|write)/i) {
    push @$commands, 'copy running-config startup-config';
  }

  $self->execCommands($commands);
}

sub getConfig {
  my $self = shift;

  my $commands = ["terminal width 511", "terminal length 0", "show run | exclude !Time", "copy run start",];

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

  if (!$self->{exp}) {
    my $login = $self->login();
    croak $login->{reason} if $login->{success} == 0;
  }

  $server ||= $ENV{PDK_FTP_SERVER};

  my $host    = $self->{host};
  my $command = "copy running-config ftp://$server/$self->{month}/$self->{date}/";

  if (!!$hostname) {
    $command .= $hostname . '_' . $host . '.cfg';
  }
  else {
    $command .= $host . '.cfg';
  }

  $self->dump("正在执行FTP备份任务");
  my $result = $self->execCommands([$command]);
  if ($result->{success} == 0) {
    croak "执行[ftpConfig/配置备份异常]，$result->{reason}";
  }
  else {
    $self->dump("FTP备份任务成功执行完毕");
    return $result;
  }
}

__PACKAGE__->meta->make_immutable;
1;

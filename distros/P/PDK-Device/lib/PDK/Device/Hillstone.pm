package PDK::Device::Hillstone;

use v5.30;
use Moose;
use Expect qw'exp_continue';
use Carp   qw'croak';
use namespace::autoclean;

with 'PDK::Device::Base';

has prompt => (is => 'ro', required => 1, default => '^.*?(\((?:M|B|F)\))?[>#]\s*$',);

sub errCodes {
  my $self = shift;

  return [
    qr/incomplete|ambiguous|unrecognized keyword|\^-----/,
    qr/syntax error|missing argument|unknown command|^Error:/,
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
      qr/^\s*--More-- /i => sub {
        $self->send(" ");
        $buff .= $exp->before();
        exp_continue;
      }
    ],
    [
      qr/are you sure\?/i => sub {
        $self->send("y");
        $buff .= $exp->before() . $exp->match();
        exp_continue;
      }
    ],
    [
      eof => sub {
        croak("执行[waitfor/自动交互执行回显]，与设备 $self->{host} 会话丢失，连接被意外关闭！具体原因：" . $exp->before());
      }
    ],
    [
      timeout => sub {
        croak("执行[waitfor/自动交互执行回显]，与设备 $self->{host} 会话超时，请检查网络连接或服务器状态！");
      }
    ],
  ];

  splice(@{$handles}, -2, 0, $exp_rule);

  my @ret = $exp->expect($self->{timeout}, @{$handles});

  croak($ret[3]) if defined $ret[1];

  $buff =~ s/\c@\cH+\s+\cH+//g;
  $buff =~ s/\cM//g;

  return $buff;
}

sub getConfig {
  my $self = shift;

  my $commands = ["terminal width 512", "terminal length 0", "show configuration running", "save all"];

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
  my ($self, $server, $hostname, $username, $password) = @_;
  return $self->getConfig;
}

__PACKAGE__->meta->make_immutable;
1;

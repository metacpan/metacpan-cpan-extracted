package PDK::Device::Paloalto;

use utf8;
use v5.30;
use Moose;
use Expect qw(exp_continue);
use Carp   qw(croak);
use namespace::autoclean;

with 'PDK::Device::Role';

has prompt => (is => 'ro', required => 1, default => '^.*?\((?:active|passive|suspended)\)[>#]\s*$',);

sub errCodes {
  shift;

  return [qr/(Unknown command|Invalid syntax)/i, qr/^Error:/mi, ];
}

sub waitfor {
  my ($self, $prompt, $params) = @_;

  croak "当同时定义 prompt 和 params 时，'params' 必须是一个哈希引用" if $prompt && $params && ref($params) ne 'HASH';

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
      qr/^lines\s*\d+-\d+\s*$/i => sub {
        $self->send(" ");
        $buff .= $exp->before();
        exp_continue;
      }
    ],
    [
      qr/are you sure\?/i => sub {
        $self->send("y\r");
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

  $buff =~ s/ \cH//g;
  $buff =~ s/(\c[\S+)+\cM(\c[\[K)?//g;
  $buff =~ s/\cM(\c[\S+)+\c[>//g;

  return $buff;
}

sub getConfig {
  my $self = shift;

  my $commands = ["set cli pager off", "set cli config-output-format set", "configure", "show", "quit",];

  my $config = $self->execCommands($commands);

  if ($config->{success} == 0) {
    return $config;
  }
  else {
    my $lines = $config->{result};
    return {success => 1, config => $lines};
  }
}

__PACKAGE__->meta->make_immutable;
1;

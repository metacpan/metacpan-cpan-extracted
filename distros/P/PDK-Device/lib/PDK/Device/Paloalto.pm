package PDK::Device::Paloalto;

use v5.30;
use Moose;
use Expect qw(exp_continue);
use Carp   qw(croak);
use namespace::autoclean;

with 'PDK::Device::Base';

has prompt => (is => 'ro', required => 1, default => '^.*?\((?:active|passive|suspended)\)[>#]\s*$',);

sub errCodes {
  my $self = shift;

  return [qr/(Unknown command|Invalid syntax)/i, qr/^Error:/mi,];
}

sub waitfor {
  my ($self, $prompt) = @_;

  my $buff = "";
  $prompt //= $self->prompt;

  my $exp = $self->exp;

  my @ret = $exp->expect(
    10,
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
      qr/$prompt/mi => sub {
        $buff .= $exp->before() . $exp->match();
      }
    ],
  );

  croak($ret[3]) if defined $ret[1];

  $buff =~ s/ \cH//g;
  $buff =~ s/(\c[\S+)+\cM(\c[\[K)?//g;
  $buff =~ s/\cM(\c[\S+)+\c[>//g;

  return $buff;
}

sub getConfig {
  my $self = shift;

  my $commands = ["set cli pager off", "set cli config-output-format set", "configure", "show", "exit",];

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

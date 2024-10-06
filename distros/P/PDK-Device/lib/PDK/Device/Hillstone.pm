package PDK::Device::Hillstone;

use 5.030;
use strict;
use warnings;

use Moose;
use Expect qw'exp_continue';
use Carp   qw'croak';
with 'PDK::Device::Base';
use namespace::autoclean;

has prompt => (is => 'ro', required => 1, default => '^.*?(\((?:M|B|F)\))?[>#]\s*$',);

sub errCodes {
  my $self = shift;

  return [
    qr/incomplete|ambiguous|unrecognized keyword|\^-----/,
    qr/syntax error, expecting|missing argument|unknown command|^Error:/,
  ];
}

sub waitfor {
  my ($self, $prompt) = @_;

  my $buff = "";
  $prompt //= $self->{prompt};

  my $exp = $self->{exp};

  my @ret = $exp->expect(
    10,
    [
      qr/^ --More-- /mi => sub {
        $exp->send(" ");
        $buff .= $exp->before();
        exp_continue;
      }
    ],
    [
      qr/are you sure\?/mi => sub {
        $exp->send("y\r");
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

  if (defined $ret[1]) {
    croak($ret[3]);
  }

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


__PACKAGE__->meta->make_immutable;
1;

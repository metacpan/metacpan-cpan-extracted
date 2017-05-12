package Net::MPD::Response;

use strict;
use warnings;

sub new {
  my ($class, $response, @lines) = @_;

  my $self = bless {
    lines    => [ @lines ],
  };

  if (my @args = $response =~ /^ACK \[(\d+)@(\d+)\] \{(\w*)\} (.*)$/) {
    $self->{error}   = $args[0];
    $self->{line}    = $args[1];
    $self->{command} = $args[2];
    $self->{message} = $args[3];
  };

  return $self;
}

sub is_ok {
  my $self = shift;
  return $self->{error} ? undef : 1;
}

sub is_error {
  my $self = shift;
  return $self->{error} ? 1 : undef;
}

sub error {
  my $self = shift;
  return $self->{error};
}

sub line {
  my $self = shift;
  return $self->{line};
}

sub command {
  my $self = shift;
  return $self->{command};
}

sub message {
  my $self = shift;
  return $self->{message} || '';
}

sub lines {
  my $self = shift;
  return @{$self->{lines}};
}

sub make_hash {
  my $self = shift;
  my $hash = {};
  foreach my $line (@{$self->{lines}}) {
    my ($name, $value) = split /: /, $line, 2;
    $hash->{$name} = $value;
  }
  return $hash;
}

1;

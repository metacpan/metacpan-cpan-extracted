package Pipe::Tube::Find;
use strict;
use warnings;
use 5.006;

use base 'Pipe::Tube';

our $VERSION = '0.05';

use File::Find::Rule;

sub init {
    my ($self, @dirs) = @_;
    my $rule = File::Find::Rule->new;
    $rule->start('.');
    $self->{rule} = $rule;
    
    return $self;
}

sub run {
    my ($self) = @_;

  if (my $thing = $self->{rule}->match) {
    return $thing;
  } else {
    return;
  }
}

1;


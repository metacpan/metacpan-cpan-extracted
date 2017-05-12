package Pipe::Tube;
use strict;
use warnings;

use Pipe;

our $VERSION = '0.04';

sub new {
    my ($class, $pipe, @args) = @_;

    my $self = bless {}, $class;
    $self->{pipe} = $pipe;
    $self->init(@args);
}

# methods to be implemnetd in subclass:
sub init {
    return $_[0];
}

sub run {
    return;
}

sub finish {
    return;
}

sub logger {
    my ($self, $msg) = @_;
    Pipe->logger($msg, $self);
}



1;


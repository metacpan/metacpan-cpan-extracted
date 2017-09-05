package ObjectDB::Factory;

use strict;
use warnings;

our $VERSION = '3.21';

require Carp;
use ObjectDB::Util qw(load_class);

sub new {
    my $class = shift;

    my $self = {};
    bless $self, $class;

    return $self;
}

sub namespace { Carp::croak('implement') }

sub build {
    my $self   = shift;
    my $type   = shift;
    my %params = @_;

    Carp::croak('type is required') unless $type;

    my @parts = map { ucfirst } split q{ }, $type;
    my $rel_class = $self->namespace . join q{}, @parts;

    load_class $rel_class;

    return $rel_class->new(%params);
}

1;

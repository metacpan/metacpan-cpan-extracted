package ObjectDB::Related;

use strict;
use warnings;

our $VERSION = '3.28';

require Carp;

sub new {
    my $class = shift;
    my (%params) = @_;

    my $self = {};
    bless $self, $class;

    $self->{meta} = $params{meta};

    return $self;
}

sub meta { $_[0]->{meta} }
sub type { $_[0]->meta->type }

sub find_related {
    Carp::croak('find_related not supported on ' . $_[0]->type);
}

sub create_related {
    Carp::croak('create_related not supported on ' . $_[0]->type);
}

sub update_related {
    Carp::croak('update_related not supported on ' . $_[0]->type);
}

sub delete_related {
    Carp::croak('delete_related not supported on ' . $_[0]->type);
}

sub count_related {
    Carp::croak('count_related not supported on ' . $_[0]->type);
}

1;

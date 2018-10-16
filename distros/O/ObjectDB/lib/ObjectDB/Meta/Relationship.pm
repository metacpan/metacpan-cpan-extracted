package ObjectDB::Meta::Relationship;

use strict;
use warnings;

our $VERSION = '3.28';

require Carp;
use ObjectDB::Util qw(load_class);

sub new {
    my $class = shift;
    my (%params) = @_;

    my $self = {};
    bless $self, $class;

    $self->{name} = $params{name} || Carp::croak('name required');
    $self->{type} = $params{type} || Carp::croak('type required');
    $self->{orig_class} =
      $params{orig_class} || Carp::croak('orig_class required');
    $self->{class}      = $params{class};
    $self->{map}        = $params{map};
    $self->{join}       = $params{join} || 'left';
    $self->{constraint} = $params{constraint} || [];

    return $self;
}

sub name { $_[0]->{name} }
sub map  { $_[0]->{map} }

sub is_multi { 0 }

sub orig_class {
    my $self = shift;

    my $orig_class = $self->{orig_class};

    load_class $orig_class;

    return $orig_class;
}

sub class {
    my $self = shift;

    my $class = $self->{class};

    load_class $class;

    return $class;
}

1;

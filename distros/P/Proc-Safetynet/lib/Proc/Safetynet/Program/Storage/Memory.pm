package Proc::Safetynet::Program::Storage::Memory;
use strict;
use warnings;
use Carp;
use Scalar::Util qw/blessed/;

use Moose;

extends 'Proc::Safetynet::Program::Storage';

has '_children'      => (
    is                  => 'rw',
    isa                 => 'HashRef',
    required            => 1,
    default             => sub { { } },
);

sub retrieve_all {
    my $self = shift;
    my $ret = [ ];
    my $hr = $self->_children();
    foreach my $k (sort keys %$hr) {
        push @$ret, $hr->{$k};
    }
    return $ret;
}

sub retrieve {
    my $self = shift;
    my $name = shift || '';
    my $ret = undef;
    if (exists $self->_children->{$name}) {
        $ret = $self->_children->{$name};
    }
    return $ret;
}

sub add {
    my $self = shift;
    my $o = shift;
    (blessed($o) and ($o->isa('Proc::Safetynet::Program')))
        or croak "add() expects 'Proc::Safetynet::Program' instance";
    my $x = $self->retrieve( $o->name );
    (not defined $x)
        or croak "object already exists";
    $self->_children->{$o->name()} = $o;
    return $o;
}

sub remove {
    my $self = shift;
    my $name = shift;
    my $ret = undef;
    my $x = $self->retrieve( $name );
    if (defined $x) {
        $ret = delete $self->_children->{$name};    
    }
    return $ret;
}


sub commit {
    # do nothing
}


sub reload {
    # do nothing
}

1;

__END__

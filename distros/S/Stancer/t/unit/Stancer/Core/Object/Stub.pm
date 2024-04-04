package Stancer::Core::Object::Stub;

use 5.020;
use strict;
use warnings;

use Stancer::Card;
use Scalar::Util qw(blessed);

use Moo;
use MooX::Types::MooseLike::Base qw(:all);
use Stancer::Core::Types qw(coerce_datetime);

extends 'Stancer::Core::Object';

use namespace::clean;

has '+_boolean' => (
    default => sub{ [qw(boolean1 boolean2)] },
);

has '+endpoint' => (
    default => 'fake-endpoint',
);

has '+_inner_objects' => (
    default => sub{ ['card', 'object1'] },
);

has '+_integer' => (
    default => sub{ [qw(integer1 integer2)] },
);

has boolean1 => (
    is => 'rw',
    isa => Bool,
    trigger => sub { $_[0]->_add_modified('boolean1') },
);

has boolean2 => (
    is => 'rw',
    isa => Bool,
    trigger => sub { $_[0]->_add_modified('boolean2') },
);

has date => (
    is => 'rw',
    isa => InstanceOf['DateTime'],
    coerce => coerce_datetime(),
    trigger => sub { $_[0]->_add_modified('date') },
);

has string => (
    is => 'rw',
    isa => Str,
    trigger => sub { $_[0]->_add_modified('string') },
);

has integer1 => (
    is => 'rw',
    isa => Int,
    trigger => sub { $_[0]->_add_modified('integer1') },
);

has integer2 => (
    is => 'rw',
    isa => Int,
    trigger => sub { $_[0]->_add_modified('integer2') },
);

has card => (
    is => 'rw',
    isa => InstanceOf['Stancer::Card'],
    coerce => sub { (blessed($_[0]) and (blessed($_[0]) eq 'Stancer::Card')) ? $_[0] : Stancer::Card->new($_[0]) },
    trigger => sub { $_[0]->_add_modified('card') },
);

has object1 => (
    is => 'rw',
    isa => InstanceOf['Stancer::Core::Object::Stub'],
    coerce => sub { (blessed($_[0]) and (blessed($_[0]) eq 'Stancer::Core::Object::Stub')) ? $_[0] : Stancer::Core::Object::Stub->new($_[0]) },
    trigger => sub { $_[0]->_add_modified('object1') },
);

sub test_only_add_modified {
    my ($this, $name) = @_;

    $this->_add_modified($name);

    return $this;
}

sub test_only_reset_modified {
    my $this = shift;

    $this->_set__modified({});

    return $this;
}

sub test_only_set_populated {
    my ($this, $state) = @_;

    $this->_set_populated($state);

    return $this;
}

1;

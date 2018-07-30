package My::NoEnvoyAttrs;

use Moose;
with 'Model::Envoy' => { storage => {} };

has test_attribute => (
    is => 'rw',
    isa => 'Str'
);

1;

package My::EnvoyAttrs;

use Moose;
with 'Model::Envoy' => { storage => {} };

has arrayref_one => (
    is => 'rw',
    isa => 'ArrayRef[HashRef]',
    traits => ['Envoy'],
);

has arrayref_two => (
    is => 'rw',
    isa => 'ArrayRef[HashRef]',
    traits => ['Envoy'],
);

has hashref_attr => (
    is => 'rw',
    isa => 'HashRef',
    traits => ['Envoy'],
);

has array_no_envoy => (
    is => 'rw',
    isa => 'ArrayRef[HashRef]',
);

1;

package main;

use strict;
use warnings;

use Test::More;

subtest 'Include Envoy but do not use' => sub {

    ok( My::NoEnvoyAttrs->new( test_attribute => 'Testing' ), 'instantiates ok' );

};

subtest 'Exercise type coercion' => sub {

    ok( My::NoEnvoyAttrs->new(
        arrayref_one   => [ { hi => 'there' } ],
        arrayref_two   => [ { hi => 'there' } ],
        hashref_attr   =>   { hi => 'there' },
        array_no_envoy => [ { hi => 'there' } ],
    ), 'instantiates ok' );

};

done_testing;

1;
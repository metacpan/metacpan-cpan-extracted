#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

BEGIN { eval "require MooseX::ClassAttribute" or plan skip_all => "MooseX::ClassAttribute is required for this test." }

plan tests => 4;

do {
    package Human;
    use Moose;
    use MooseX::InstanceTracking;
    use MooseX::ClassAttribute;

    class_has classification => (
        is      => 'rw',
        default => 'homo sapiens',
    );

    has name => (
        is       => 'ro',
        required => 1,
    );

    __PACKAGE__->meta->make_immutable;
};

do {
    my $shawn = Human->new(name => "Shawn");
    my $dave = Human->new(name => "Dave");

    is(Human->classification, 'homo sapiens');
    is_deeply([sort Human->meta->instances], [sort $shawn, $dave]);
};

Human->classification('alces sapiens');

is(Human->classification, 'alces sapiens');
is_deeply([Human->meta->instances], []);


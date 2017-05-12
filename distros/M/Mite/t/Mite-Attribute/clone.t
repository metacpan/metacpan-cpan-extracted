#!/usr/bin/perl

use lib 't/lib';

use Test::Mite;

tests "empty clone" => sub {
    my $attr = sim_attribute;
    my $clone = $attr->clone;

    for my $method (qw(name is default)) {
        is $clone->$method, $attr->$method, $method;
    }
};

tests "clone with changes" => sub {
    my $attr = sim_attribute(
        is      => 'ro',
        default => 23
    );
    my $clone = $attr->clone( default => undef );

    for my $method (qw(name is)) {
        is $clone->$method, $attr->$method, $method;
    }

    is $clone->default, undef;
};

done_testing;

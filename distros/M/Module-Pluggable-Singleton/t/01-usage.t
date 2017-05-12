#!/usr/bin/env perl

use strict;
use warnings;
use FindBin::libs;
use Test::More;
use XT::Business;
use Data::Dump qw/pp/;

my $tests = [
    {
        label => 'Bar',
        method => 'foo',
        params => 'hello there',
    },
    {
        label => 'Bar',
        method => 'unknown',
        params => '',
        error => "Cannot call 'unknown' on 'Bar'",
    },
    {
        label => 'Baz',
        method => 'foo',
        params => '',
        error => 'Not possible to load module',
    },
];

is(scalar XT::Business->plugin, 1,
    'Found one plugin');
is(XT::Business->plugin('Bar'),'XT::Business::Plugin::Bar',
    'Correct fully qualified name');
is(XT::Business->plugin('Baz'),undef,
    'Unknown plugin');

my $rv;

foreach my $test (@{$tests}) {
    my $label = 'Bar';
    note "  call: '$test->{label}' '$test->{method}' '$test->{params}'";
    eval {
        $rv = XT::Business->call(
            $test->{label}, $test->{method}, $test->{params});
    };
    if (my $e = $@) {
        if ($test->{error}) {
            my $foo = $test->{error};

            like($e, qr/$foo/, "Matched expected error - $foo");
#            is($e =~ /$foo/, 'blah', 'Matched expected error');
#            if ($e =~ /$foo/i) {
#                warn __PACKAGE__ .": not matching error - $foo";
#            }
        } else {
            diag $e;
            is(0,1,"Error when test not expecting");
        }

    } else {
        is(defined $test->{error},'', 'Should be an error');
    }
}

done_testing;

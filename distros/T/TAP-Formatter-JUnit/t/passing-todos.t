#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 6;
use TAP::Harness;
use IO::Scalar;

###############################################################################
# TEST: passing TODOs are normally treated as failure condition.
passing_todo_default_fail: {
    my $results = undef;
    my $fh      = IO::Scalar->new(\$results);
    my $harness = TAP::Harness->new( {
        formatter_class => 'TAP::Formatter::JUnit',
        stdout          => $fh,
    } );
    $harness->runtests('t/data/tests/todo');

    ok $results, 'Ran test with passing TODO';
    like $results, qr/<testsuite[^>]+errors="1"/, '... with one error';
    like $results, qr/TodoTestSucceeded/, '... passing TODO';
}

###############################################################################
# TEST: over-ride allows for passing TODOs to be treated as a pass.
passing_todo_ok: {
    local $ENV{ALLOW_PASSING_TODOS} = 1;

    my $results = undef;
    my $fh      = IO::Scalar->new(\$results);
    my $harness = TAP::Harness->new( {
        formatter_class => 'TAP::Formatter::JUnit',
        stdout          => $fh,
    } );
    $harness->runtests('t/data/tests/todo');

    ok $results, 'Re-ran test with passing TODO';
    like $results, qr/<testsuite[^>]+errors="0"/, '... with NO errors';
    unlike $results, qr/TodoTestSucceeded/, '... passing TODO was OK';
}

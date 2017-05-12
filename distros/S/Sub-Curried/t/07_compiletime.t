#!/usr/bin/perl
use strict; use warnings;
use Data::Dumper;

use Test::More tests=>6;

use Sub::Curried;

sub test_eval;

SANITY: {
    test_eval 'curry greet ($what) { "Hello $what" }; greet()',
              'world',
              'Hello world',    
              'Called with no args ()';

    test_eval 'sub greet2; curry greet2 ($what) { "Hello $what" }; greet2',
              'world',
              'Hello world',
              'Called with no parens, predeclared';

    test_eval 'curry greet3 ($what) { "Hello $what" }; greet3',
              'world',
              'Hello world',
              'Called as bareword';
}

sub test_eval {
    my ($code, $arg, $expected, $description) = @_;
    $description ||= '';
    my $fn = eval $code;
    SKIP: {
        if (ok defined $fn, "$description - compiled") {
            my $result = $fn->($arg);
            is ($result, $expected, "$description - called OK");
        } else {
            diag $@;
            skip 'No function to call', 1;
        }
    }
}

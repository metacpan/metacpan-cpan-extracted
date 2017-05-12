#!/usr/bin/env perl
# vim: ts=8 sts=4 et sw=4 sr sta

use Test::Aggregate;
my $other_test_dir = 't_aggregate/controllers';
my $tests = Test::Aggregate->new( {
    dirs => $other_test_dir
});
$tests->run;

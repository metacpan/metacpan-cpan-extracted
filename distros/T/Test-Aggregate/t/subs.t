#!/usr/bin/perl

#use lib '../Test-Simple-0.86/lib';
use strict;
use warnings;

use lib 'lib', 't/lib';
use Test::Aggregate;

my $dump = 'done_testing.t';
my $tests = Test::Aggregate->new(
    {
        dirs     => 'aggtests',
        matching => qr/subs/,
#        dump     => $dump,
    }
);
$tests->run;
my $tests_run = Test::Builder->new->current_test;
is $tests_run, 1,
  '... and we should only run as many tests as are in the matching tests';
#unlink $dump or warn "Cannot unlink ($dump): $!";

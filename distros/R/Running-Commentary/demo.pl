#! /usr/bin/env perl
use strict;
use warnings;
use autodie;
use 5.018;

use Running::Commentary; # {fail => 'failobj'};

my $problem_solved;
my $subsubtest;

# run_with -critical, -silent;
#run_with -critical;
run_with -colour => { DONE => 'green', FAILED => 'red on_yellow', OUTPUT => 'blue' };
#run_with -nocolour;

{
    run_with -noncritical;
    run 'A quiet test'    => 'echo "ere"';
    my $result = run 'A quiet problem' => 'hdshadasasdkj';
    say $result;
}

run 'Setting up (slowly)' => 'sleep 2';
run 'Listing'             => 'ls -l';

$subsubtest = run 'A sub-test' => sub{
    run 'Setting up (slowly)' => 'sleep 2';
    run 'Listing'             => 'ls -l';
    run 'Cleaning up subtest' => 'sleep 2';

    run 'A sub-sub-test' => sub{
#        run -showall;
        run 'Setting up (slowly)' => 'sleep 2';
        run 'Listing'             => 'ls -l *.pl';
        run 'Date-stamping'       => 'date';
        run 'Cleaning up subtest' => 'sleep 2';
    };
};

run 'Cleaning up all' => 'sleep 2';
run 'Closing down'    => 'sleep 2';

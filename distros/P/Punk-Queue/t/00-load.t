#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

# The XS bootstrap is the thing under test here: a POD-only .pm that failed
# to load its shared library still `use`s cleanly and only falls over later,
# somewhere much less obvious.

use_ok('Punk::Queue')                        or BAIL_OUT('no Punk::Queue');
use_ok('Punk::Queue::Backend');
use_ok('Punk::Queue::Backend::SQLite');
use_ok('Punk::Queue::Job');

ok(defined $Punk::Queue::VERSION, "VERSION is set ($Punk::Queue::VERSION)");

for my $m (qw(new migrate task enqueue dequeue perform job_info
              finish_job fail_job backend dbh)) {
    ok(Punk::Queue->can($m), "Punk::Queue can $m");
}

for my $m (qw(dbh migrate now clock_delta has_returning enqueue job_info)) {
    ok(Punk::Queue::Backend->can($m), "Punk::Queue::Backend can $m");
}

ok(Punk::Queue::Backend::SQLite->can('dequeue'),
   'the SQLite backend has its own dequeue');
ok(Punk::Queue::Backend::SQLite->isa('Punk::Queue::Backend'),
   'and inherits the shared surface');

for my $m (qw(id task queue args notes finish fail info)) {
    ok(Punk::Queue::Job->can($m), "Punk::Queue::Job can $m");
}

# Every method above should be an XSUB, not a Perl stub - the .pm files in
# this dist carry POD and nothing else, and a method that quietly became
# Perl would be a real regression rather than a style point.
SKIP: {
    require B;
    skip 'B not available', 3 unless defined &B::svref_2object;
    no strict 'refs';
    for my $full (qw(Punk::Queue::enqueue
                     Punk::Queue::Backend::now
                     Punk::Queue::Job::id)) {
        ok(B::svref_2object(\&{$full})->XSUB, "$full is an XSUB");
    }
}

diag("Punk::Queue $Punk::Queue::VERSION, Perl $], $^X");

done_testing();

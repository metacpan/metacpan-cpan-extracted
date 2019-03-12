#!/usr/bin/perl -w
# DESCRIPTION: Perl ExtUtils: Type 'make test' to test this package
#
# Copyright 2007-2019 by Wilson Snyder.  This program is free software;
# you can redistribute it and/or modify it under the terms of either the GNU
# Lesser General Public License Version 3 or the Perl Artistic License Version 2.0.
######################################################################

use Test::More;
use strict;

use Time::HiRes qw(gettimeofday usleep tv_interval sleep time);

BEGIN { plan tests => 4 }
BEGIN { require "./t/test_utils.pl"; }

BEGIN { $Parallel::Forker::Debug = 1; }

use Parallel::Forker;
ok(1, "use");

######################################################################

my $fork = new Parallel::Forker(use_sig_child=>0);
ok(1, "new");

# Not required in old versions, so make sure we still work
#$SIG{CHLD} = sub { Parallel::Forker::sig_child($fork); };  # Not method, as is less stuff for a handler to do
$SIG{TERM} = sub { $fork->kill_tree_all('TERM') if $fork && $fork->in_parent; die "Quitting...\n"; };
ok(1, "sig");

my $p1 = $fork->schedule(label=>'p1',
			 run_on_start => sub {
			     print "p1 starting... $$\n";
			     for my $i (1..10) { print "p1 ==> $i\n"; usleep(100*1000);}
			     exit(0);
			 },
			 run_on_finish => sub {
			     print "p1 done... $$\n";
			     for my $i (1..10) { print "p1 ==> $i\n";}},
			 );

my $p2 = $fork->schedule(label=>'p2',
			 run_on_start => sub {
			     print "p2 starting... $$\n";
			     for my $i (1..10) { print "p2 ==> $i\n"; usleep(100*1000);}
			     exit(0);
			 },
			 run_on_finish => sub {
			     print "p2 done... $$\n";
			     for my $i (1..10) { print "p2 ==> $i\n";}},
			 );

my $p3 = $fork->schedule(label=>'p3',
			 run_on_start => sub {
			     print "p3 starting... $$\n";
			     for my $i (1..10) { print "p3 ==> $i\n";} exit(0);},
			 run_on_finish => sub {
			     print "p3 done... $$\n";
			     for my $i (1..10) { print "p3 ==> $i\n";}},
			 #run_after => ['p1 | p2'],
			 );

$fork->ready_all();
$fork->wait_all();

print "ALL DONE ==> $$\n";
ok(1, "done");

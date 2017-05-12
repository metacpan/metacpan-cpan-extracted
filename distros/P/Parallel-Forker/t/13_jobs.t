#!/usr/bin/perl -w
# DESCRIPTION: Perl ExtUtils: Type 'make test' to test this package
#
# Copyright 2003-2017 by Wilson Snyder.  This program is free software;
# you can redistribute it and/or modify it under the terms of either the GNU
# Lesser General Public License Version 3 or the Perl Artistic License Version 2.0.
######################################################################

use Test::More;
use strict;

BEGIN { plan tests => 4 }
BEGIN { require "./t/test_utils.pl"; }

BEGIN { $Parallel::Forker::Debug = 1; }

use Parallel::Forker;
ok(1, "use");

######################################################################

a_test();

sub a_test {
    my $fork = new Parallel::Forker (use_sig_child=>1);
    $fork->max_proc(3);

    $SIG{CHLD} = sub { Parallel::Forker::sig_child($fork); };
    $SIG{TERM} = sub { ok(0); $fork->kill_tree_all('TERM') if $fork && $fork->in_parent; die "Quitting...\n"; };
    ok(1, "sig");

    my $Max_Running=0;
    for (my $i=0; $i<8; $i++) {
	$fork->schedule(
			run_on_start => sub {
			    sleep 1;
			},
			run_on_finish => sub {
			    my $running=0;
			    foreach my $proc ($fork->running()) {   # Loop on each running child
				$running++;
			    }
			    $Max_Running = $running+1 if $running>$Max_Running;
			},
			);
    }

    # Run them
    $fork->ready_all();
    $fork->wait_all();
    ok(1, "ready");
    print "Maximum jobs = $Max_Running\n";
    is($Max_Running, $fork->{max_proc}, "max_proc");
}

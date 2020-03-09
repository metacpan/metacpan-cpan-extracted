#!/usr/bin/perl -w
# DESCRIPTION: Perl ExtUtils: Type 'make test' to test this package
#
# Copyright 2007-2020 by Wilson Snyder.  This program is free software;
# you can redistribute it and/or modify it under the terms of either the GNU
# Lesser General Public License Version 3 or the Perl Artistic License Version 2.0.

use strict;
use Test::More;
BEGIN { eval "use Devel::Leak;"; }  # Optional
BEGIN { eval "use Data::Dumper;"; $Data::Dumper::Indent=1; }  # Optional

BEGIN { plan tests => 2 }
BEGIN { require "./t/test_utils.pl"; }

use Parallel::Forker;

 SKIP:
{
    if (!$ENV{PARALLELFORKER_AUTHOR_SITE} || $ENV{HARNESS_FAST}) {
	# It's somewhat sensitive unless there's a lot of loops,
	# and lots of loops is too slow for users to deal with.
	warn "(skip author only test)\n";
	skip("leaked, but author only test",2);
    }

    my $mem = get_memory_usage();
    my $loops = 50;  # At least 10
    my $mem_end; my $mem_mid;
    my $handle;
    for (my $i=0; $i<$loops; $i++) {
	test();
	my $newmem = get_memory_usage();
	my $delta = $newmem - $mem;
	printf "$i: Memory %6.3f MB  Alloced %6.3f MB\n"
	    , $newmem/1024/1024, $delta/1024/1024 if $delta;
	$mem_mid = $newmem if $i==int($loops/2)-1;
	$mem_end = $newmem if $i==$loops-1;

	# The Devel checks must complete before $mem_mid is sampled, as they use memory
	if (0 && $Devel::Leak::VERSION) {
	    Devel::Leak::NoteSV($handle)  if $i==int($loops/2)-4;
	    Devel::Leak::CheckSV($handle) if $i==int($loops/2)-3;
	    #warn "EXITING" if $i==int($loops/2)-3;
	}

	$mem = $newmem;
    }
    ok(1, "init");

    if ($mem == 0) {
	skip("get_memory_usage isn't supported",1);
    } elsif ($mem_end <= $mem_mid) {
	ok(1,"leaks");
    } else {
	warn "%Warning: Leaked ",int(($mem_end-$mem_mid)/($loops/2))," bytes per subtest\n";
	ok(0,"leaks");
    }
}

######################################################################

sub test {
    my $forker = Parallel::Forker->new;

    $forker->schedule(
	name => "ONE",
	run_on_start => sub { return 1; },
	);

    $forker->schedule(
	name => "TWO",
	run_on_start => sub { return 1; },
	run_after => ["ONE"],
	);

    $forker->ready_all;
    #print Dumper($forker);
}

#!perl -w
use strict;

# $Id: waitstat.t,v 1.3 1999-10-21 12:43:58-04 roderick Exp $
#
# Copyright (c) 1997 Roderick Schertler.  All rights reserved.  This
# program is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.

BEGIN {
    $| = 1;
    print "1..20\n";
}

use Proc::WaitStat	qw(waitstat waitstat_reuse waitstat_die close_die);
use IPC::Signal		qw(sig_num);

sub ok {
    my ($n, $result, @info) = @_;
    if ($result) {
    	print "ok $n\n";
    }
    else {
    	print "not ok $n\n";
	print "# ", @info, "\n" if @info;
    }
}

my $test_func;

sub test {
    my ($n, $expect, @args) = @_;
    my $result = $test_func->(@args);
    ok $n, $expect eq $result, "$expect != $result, args @args";
}

$test_func = \&waitstat;
ok 1, prototype($test_func) eq '$';					#';
test 2, '0', 0;
test 3, 'killed (SIGHUP)', sig_num 'HUP';
test 4, '1',  1 << 8;
test 5, '23', 23 << 8;
test 6, '255', 255 << 8;

$test_func = \&waitstat_reuse;
ok 7, prototype($test_func) eq '$';					#';
test 8, 0, 0;
test 9, 129, 1;
test 10, 1, 1 << 8;
test 11, 23, 23 << 8;
test 12, 255, 255 << 8;

ok 13, prototype('waitstat_die') eq '$$';
eval { waitstat_die 0, 'program' };
ok 14, $@ eq '', $@;
eval { waitstat_die 1, 'program' };
ok 15, $@ =~ /^Non-zero/, $@;

# This also tests some of the different forms a filehandle can take when
# passed to close_die().
use vars qw(*TRUE); # squelch warning
ok 16, prototype('close_die') eq '*$';					#';
ok 17, open(TRUE, '|true');
eval { close_die TRUE, 'true' };
ok 18, $@ eq '', $@;
ok 19, open(FALSE, '|false');
eval { close_die *FALSE, 'false' };
ok 20, $@ =~ /^Error closing false:/, $@;

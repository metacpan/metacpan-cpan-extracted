#!perl -w
use strict;

# $Id: test.t,v 1.1 2000-09-23 21:23:56-04 roderick Exp $
#
# Copyright (c) 2000 Roderick Schertler.  All rights reserved.  This
# program is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.

my ($Expect, $Got, $Exit);

BEGIN {
    $Expect	= 13;
    $Got	= 0;
    $Exit	= 0;

    $| = 1;
    print "1..$Expect\n";
}

use Proc::SafePipe;

sub ok {
    my ($result, @info) = @_;
    $Got++;
    if ($result) {
    	print "ok $Got\n";
    }
    else {
    	$Exit = 1;
    	print "not ok $Got", @info ? (' # ', @info) : (), "\n";
    }
}

my ($fh, $pid, $s, $r, @l);

eval { popen_noshell };			ok $@ ne '';
eval { popen_noshell 'r' };		ok $@ ne '';
eval { popen_noshell 'x', 'y' };	ok $@ ne '';

$fh = popen_noshell 'r', 'echo', 'foo';
ok $fh;
$s = join '', <$fh>;
ok $s eq "foo\n", $s;
ok close($fh), "close \$! $! \$? $?";

($fh, $pid) = popen_noshell 'w', $^X, '-ne', '0';
ok $pid;
ok print $fh "one\n";
ok print $fh "two\n";
ok close($fh), "close \$! $! \$? $?";

$s = backtick_noshell 'echo', '*';
ok $s eq "*\n";

@l = backtick_noshell $^X, '-lwe', 'print 1; print 2;';
ok @l == 2 && $l[0] eq "1\n" && $l[1] eq "2\n", @l;

# Make sure that it doesn't split a command with no arguments.

{
    local $SIG{__DIE__} = sub { exit 23 };
    $s = backtick_noshell 'echo oops';
    ok $? == 23 * 256 && $s eq '', "\$? $? output [$s]";
}

$Exit = 1 if $Got != $Expect;
exit $Exit;

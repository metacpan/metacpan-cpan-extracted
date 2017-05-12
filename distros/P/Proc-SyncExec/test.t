#!perl -w
use strict;

# $Id: test.t,v 1.3 2000/09/24 02:28:23 roderick Exp $
#
# Copyright (c) 2000 Roderick Schertler.  All rights reserved.  This
# program is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.

my ($Expect, $Got, $Exit, $Parent_pid);

BEGIN {
    $Expect	= 16;
    $Got	= 0;
    $Exit	= 0;
    $Parent_pid	= $$;

    $| = 1;
    print "1..$Expect\n";
}

sub ok {
    my ($result, @info) = @_;
    $Got++;
    if ($result) {
    	print "ok $Got\n";
    }
    else {
    	$Exit = 1;
	my ($pkg, $file, $line) = caller;
    	print "not ok $Got at $file:$line", @info ? (' # ', @info) : (), "\n";
    }
}

END {
    if ($$ == $Parent_pid) {
	ok $Got+1 == $Expect,
	    "wrong number of tests, got ", 1+$Got, " not $Expect";
	$? = $Exit;
    }
}

use Proc::SyncExec	qw(fork_retry sync_exec sync_open);
use POSIX		qw(EACCES ENOENT);

my ($fh, $pid, $s, $r, @l);

eval { fork_retry or exit };
ok $@ eq '', $@;

$pid = sync_exec 'this better not exist', 23;
ok !defined $pid, $pid;
ok $! == ENOENT, $!;

$pid = sync_exec '/';
ok !defined $pid, $pid;
ok $! == EACCES, $!;

$pid = sync_exec 'true; exit 23';
ok $pid, $!;
$r = waitpid $pid, 0;
ok $r == $pid, $r;
ok $? == 23 * 256, $?;

close READ; # squelch used only once warning
$pid = sync_open *READ, 'this-better-not-exist-either foo|';
ok !defined $pid, $pid;
ok $! == ENOENT, $!;

$pid = sync_open *WRITE, "|$^X -we 'exit <STDIN>'";
ok $pid, $!;
$s = 23;
ok print(WRITE $s), $!;
ok close(WRITE), $!;
ok waitpid($pid, 0) == $pid, $!;
ok $? == $s * 256, $?;

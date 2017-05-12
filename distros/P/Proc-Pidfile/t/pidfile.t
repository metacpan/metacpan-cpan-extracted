#!/bin/env perl -w
# vim:filetype=perl

use 5.006;
use strict;
use warnings;

use Test::More tests => 24;
BEGIN { require_ok( 'Proc::Pidfile' ); }
my ( $err, $obj, $pidfile, $ppid, $pid );
# test for simple pidfile creation and destruction
$obj = Proc::Pidfile->new();
$pidfile = $obj->pidfile();
ok( -e $pidfile, "pidfile created" );
undef $obj;
ok( ! -e $pidfile, "pidfile destroyed" );
# test for expicit pidfile path creation and destruction
$pidfile = '/tmp/Proc-Pidfile.test.pid';
unlink( $pidfile ) if -e $pidfile;
$obj = Proc::Pidfile->new( pidfile => $pidfile );
is( $obj->pidfile(), $pidfile, "temp pidfile matches" );
ok( -e $pidfile, "temp pidfile created" );
undef $obj;
ok( ! -e $pidfile, "temp pidfile destroyed" );
# check pid in pidfile is correct
$obj = Proc::Pidfile->new();
$pidfile = $obj->pidfile();
ok( open( FH, $pidfile ), "open pidfile" );
$pid = <FH>;
chomp( $pid );
ok( close( FH ), "close pidfile" );
is( $pid, $$, "pid correct" );
undef $obj;
# check that a spawned child process ignores pidfile
$obj = Proc::Pidfile->new();
$pid = fork;
if ( $pid == 0 ) { undef $obj; exit(0); }
ok( defined( $pid ), "fork successful" );
is( $pid, waitpid( $pid, 0 ), "child exited" );
ok( $? >> 8 == 0, "child ignored parent's pidfile" );
ok( -e $pidfile, "child ignored pidfile" );
undef $obj;
ok( ! -e $pidfile, "parent destroyed pidfile" );

# This doesn't work in 5.14+, because if code calls die/croak
# inside a DESTROY, then if you an eval { } round that,
# you don't get $@ set as you might expect.
# check that removed pidfile exception is thrown
# TODO: {
#    local $TODO = "doesn't work in 5.14+, need to think about this...";
#    eval {
#        my $pp = Proc::Pidfile->new();
#        $pidfile = $pp->pidfile();
#        unlink( $pidfile );
#        # undef $pp;
#    };
#    $err = $@; undef $@;
#    like( $err, qr/pidfile $pidfile doesn't exist/, "die on removed pidfile" );
#}

# check that child spots and ignores existing pidfile
$obj = Proc::Pidfile->new();
$ppid = $$;
$pid = fork;
if ( $pid == 0 )
{
    $obj = Proc::Pidfile->new();
    exit( 0 );
}
ok( defined( $pid ), "fork successful" );
is( $pid, waitpid( $pid, 0 ), "child exited" );
ok( $? >> 8 != 0, "child spotted existing pidfile" );
$pid = fork;
if ( $pid == 0 )
{
    $obj = Proc::Pidfile->new( silent => 1 );
    exit( 2 );
}
ok( defined( $pid ), "fork successful" );
is( $pid, waitpid( $pid, 0 ), "silent child exited" );
is( $? >> 8, 0, "child spotted and ignored existing pidfile" );
# check that bogus or zombie pidfile is ignored
$pidfile = '/tmp/Proc-Pidfile.test.pid';
unlink( $pidfile ) if -e $pidfile;
ok( open( FH, ">$pidfile" ), "open pidfile" );

$pid = find_unused_pid();

BAIL_OUT("Can't find unused pid -- this shouldn't happen!") if !defined($pid);

print FH $pid;
close( FH );
eval { $obj = Proc::Pidfile->new( pidfile => $pidfile ); };
$err = $@; undef $@;
ok( ! $err, "bogus pidfile ignored" );
undef $obj;
# check that pidfile created by somebody else works ...
$pidfile = '/tmp/Proc-Pidfile.test.pid';
unlink( $pidfile ) if -e $pidfile;
ok( open( FH, ">$pidfile" ), "open pidfile" );

$pid = find_pid_in_use_by_someone_else();

SKIP: {
    skip("can't find appropriate pid in use on this OS", 1)
        unless defined($pid);

    print FH $pid;
    close( FH );
    eval { $obj = Proc::Pidfile->new( pidfile => $pidfile ); };
    $err = $@; undef $@;
    like( $err, qr/already running: $pid/, "other users pid" );
    undef $obj;
}

sub find_unused_pid
{
    my $pid = 1;

    if ($^O eq 'riscos') {
        require Proc::ProcessTable;
        my $table = Proc::ProcessTable->new()->table;
        my %processes = map { $_->pid => $_ } @$table;

        $pid++ while $pid != 0 && exists($processes{$pid});
    }
    else {
        $pid++ while $pid != 0 && (kill(0, $pid) || $!{'EPERM'});
    }

    return undef if $pid == 0;
    return $pid;
}

sub find_pid_in_use_by_someone_else
{
    my $pid = 1;

    if ($^O eq 'riscos') {
        require Proc::ProcessTable;
        my $table = Proc::ProcessTable->new()->table;
        my %processes = map { $_->pid => $_ } @$table;

        $pid++ until $pid == 0 || (    exists($processes{$pid})
                                   and $processes{$pid}->uid != $<);
    }
    else {
        $pid++ until $pid == 0 || (!kill(0, $pid) && $!{'EPERM'});
    }
    return undef if $pid == 0;
    return $pid;
}


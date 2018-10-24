#!/bin/env perl -wT
# vim:filetype=perl

use 5.006;
use strict;
use warnings;
use File::Spec::Functions qw/ tmpdir catfile /;

# A quick google said that this is the default value for maxpid
# and if we can't find a pid in the first 32k, I suspect we won't
# find one at all.
$0 = "Proc-Pidfile-Test-$$";
my $MAXPID          = 32768;
my $TMPDIR          = tmpdir();
my $DEFAULT_PIDFILE = catfile($TMPDIR, "Proc-Pidfile-Test-$$.pid");

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
# $pidfile = '/tmp/Proc-Pidfile.test.pid';
$pidfile = catfile($TMPDIR, "Proc-Pidfile.test.pid");

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
    $obj = Proc::Pidfile->new(retries => 0);
    exit( 0 );
}
ok( defined( $pid ), "fork successful" );
is( $pid, waitpid( $pid, 0 ), "child exited" );
ok( $? >> 8 != 0, "child spotted existing pidfile" );
$pid = fork;
if ( $pid == 0 )
{
    $obj = Proc::Pidfile->new( silent => 1, retries => 0 );
    exit( 2 );
}
ok( defined( $pid ), "fork successful" );
is( $pid, waitpid( $pid, 0 ), "silent child exited" );
is( $? >> 8, 0, "child spotted and ignored existing pidfile" );

# check that bogus or zombie pidfile is ignored

$pid = find_unused_pid();
SKIP: {
    skip("can't find unused pid", 2) unless defined($pid);

    $pidfile = $DEFAULT_PIDFILE;
    unlink( $pidfile ) if -e $pidfile;
    ok( open( FH, ">$pidfile" ), "open pidfile" );

    print FH $pid;
    close( FH );
    eval { $obj = Proc::Pidfile->new( pidfile => $pidfile, retries => 0 ); };
    $err = $@; undef $@;
    ok( ! $err, "bogus pidfile ignored" );
    undef $obj;
}

# check that pidfile created by somebody else works ...

$pid = find_pid_in_use_by_someone_else();

SKIP: {
    skip("can't find appropriate pid in use on this OS", 2)
        unless defined($pid);

    $pidfile = $DEFAULT_PIDFILE;
    unlink( $pidfile ) if -e $pidfile;
    ok( open( FH, ">$pidfile" ), "open pidfile" );

    print FH $pid;
    close( FH );
    eval { $obj = Proc::Pidfile->new( pidfile => $pidfile, retries => 0 ); };
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

        $pid++ while $pid <= $MAXPID && exists($processes{$pid});
    }
    else {
        $pid++ while $pid <= $MAXPID && (kill(0, $pid) || $!{'EPERM'});
    }

    return undef if $pid > $MAXPID;
    return $pid;
}

sub find_pid_in_use_by_someone_else
{
    my $pid = 1;

    if ($^O eq 'riscos') {
        require Proc::ProcessTable;
        my $table = Proc::ProcessTable->new()->table;
        my %processes = map { $_->pid => $_ } @$table;

        $pid++ until $pid > $MAXPID || (    exists($processes{$pid})
                                        and $processes{$pid}->uid != $<);
    }
    else {
        $pid++ until $pid > $MAXPID || (!kill(0, $pid) && $!{'EPERM'});
    }
    return undef if $pid > $MAXPID;
    return $pid;
}


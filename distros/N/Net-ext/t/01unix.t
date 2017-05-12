#!perl -w

# rcsid: "@(#) $Id: 01unix.t,v 1.12 1999/08/04 04:59:29 spider Exp $"

BEGIN {
    unshift @INC, './xlib','../xlib' if $] < 5.004_05;
}

use Test;
use Config ();
use strict;

# Special-case the constants we need later
sub Net::Gen::SOMAXCONN () ;
sub Net::Gen::SOCK_STREAM () ;
BEGIN { package Net::Gen; *::SOCK_STREAM = \&SOCK_STREAM;}

# Just in case, because of problems with some OSes, don't die on SIGPIPE.
$SIG{PIPE} = 'IGNORE';

# Start defining the tests as subroutines, and using BEGIN blocks to
# populate the test vector.  This way, we can call plan() in a BEGIN block
# near the end of the file, and get the count of tests in an automated
# fashion.  I hate having to try to keep a count in sync with the tests
# themselves.  Note that this still depends on leaving the `use' statements
# for the modules to be tested to the bitter end, as well, so that the
# plan() call will spit out the expected number of tests *before* we run
# the risk of unsuccessful DynaLoader calls.

my @testvec;			# list of code refs to call
my %testvals;			# hash (indexed by stringified code ref)
				# of test results so far -- used if test_bar()
				# should be skipped if test_foo() failed
				# e.g.:  skip(!$testvals{\&test_foo}, ....);

my @endav;			# list of coderefs to call in an END block,
				# since some versions of perl won't let us
				# have more than one END in a given package

my %todos;			# hash (indexed by stringified code ref)
				# with keys indicating routines which
				# are expected to fail -- used to build
				# the `todo' parameter to plan()

END { for my $endcv (@endav) { $endcv->() } }

# Note that ok() and skip() return their `ok-ness', so that test
# routines can just propagate that return back out to the actual
# test driver, which will `remember' it in %testvals.

my $ok;				# continuation flag
my $failures = 0;

sub tdriver ()			# run the code refs in @testvec
{
    for my $cv (@testvec) {
	$ok = $cv->();
	$testvals{"$cv"} = $ok;
	$ok || $failures++;
    }
}

sub ptest ()			# print out the test name
{
    my $who = (caller(1))[3];
    $who =~ s/^.*:://;
    print "# $who\n";
}

sub xerror ()			# get int & string parts of $!
{
    "(errno=".($!+0)."): $!";
}

sub okval ($)			# get printable value instead of C<undef>
{
    defined($_[0]) ? $_[0] : '<undef>';
}


# start of test routines


# Rather than do lots of little BEGIN {push @testvec, \&t_...} blocks,
# wrap the whole test region in a single BEGIN.  It doesn't change
# how most of the subs are compiled, and it's (slightly) more efficient.

BEGIN {

# Can't #define here (reliably, anyway), so abuse some `static my' values.

my $sockname = 'srvr';

my $srvr;			# server socket we're using
my $clnt;			# client socket we're using
my $acpt;			# secondary (accept()ing) server socket

# get a server socket to use
sub t_open_srvr_dgram {
    ptest;
    unlink $sockname;
    $srvr = 'Net::UNIX::Server'->new($sockname);
    my $srvok = $srvr && $srvr->isbound;
    push(@endav, sub { unlink $sockname}) if $srvok;
    ok okval $srvok, 1, xerror;
}
push @testvec, \&t_open_srvr_dgram;

# get a client to talk to the server
sub t_open_clnt_dgram {
    ptest;
    $clnt = 'Net::UNIX'->new($sockname);
    ok okval($clnt && $clnt->isconnected), 1, xerror;
}
push @testvec, \&t_open_clnt_dgram;

# not worth trying to proceed if can't open the sockets
sub t_dgram_both_open {
    exit 1	unless $testvals{\&t_open_clnt_dgram}
		       && $testvals{\&t_open_srvr_dgram};
    ptest;
    ok 1;
}
push @testvec, \&t_dgram_both_open;

# send a hello
my $sentmsg;
sub t_send_hello_dgram {
    ptest;
    $sentmsg = "Wowsers!";
    my $sendok = $clnt->send($sentmsg);
    ok okval $sendok, length $sentmsg, xerror;
}
push @testvec, \&t_send_hello_dgram;

# check receipt
sub t_chk_hello_dgram {
    ptest;
    my $gotmsg = ($ok ? $srvr->recv(40) : "<error>");
    ok $gotmsg, $sentmsg;
}
push @testvec, \&t_chk_hello_dgram;

# fail to reply
sub t_chk_noreply_dgram {
    ptest;
    $sentmsg = "Sorry, chief.";
    my $sendok = $srvr->send($sentmsg);
    ok !$sendok;
}
push @testvec, \&t_chk_noreply_dgram;

# check close status
sub t_chk_closes_dgram {
    ptest;
    ok okval($srvr->close && $clnt->close), 1, xerror;
}
push @testvec, \&t_chk_closes_dgram;

# get a new server for stream sockets
sub t_open_srvr_strm {
    ptest;
    unlink $sockname;
    $srvr = 'Net::UNIX::Server'->new($sockname, {'type' => SOCK_STREAM,
					         'timeout' => 0});
    $ok = $srvr && $srvr->isbound && $srvr->didlisten;
    ok okval $ok, Net::Gen::SOMAXCONN, xerror;
}
push @testvec, \&t_open_srvr_strm;

# get a new unconnected client for stream sockets
sub t_open_clnt_strm {
    ptest;
    $clnt = 'Net::UNIX'->new({type => SOCK_STREAM});
    $clnt ? ok($clnt) : ok('<undef>',1,xerror);
}
push @testvec, \&t_open_clnt_strm;

# bug out if can't open stream sockets
sub t_stream_both_open {
    exit 1 unless $testvals{\&t_open_srvr_strm}
		  && $testvals{\&t_open_clnt_strm};
    ptest;
    ok 1;
}
push @testvec, \&t_stream_both_open;

# issue a connect request for the client
my $connok;
sub t_clnt_iconn_strm {
    ptest;
    $connok = $clnt->connect($sockname, {'timeout'=>0});
    $ok = $connok || $clnt->isconnecting;
    ok okval $ok, 1, xerror;
}
push @testvec, \&t_clnt_iconn_strm;

# accept the client connection (and drop the listener)
sub t_srvr_accept_strm {
    ptest;
    $acpt = $srvr->accept;
    ok okval($acpt && $srvr->close), 1, xerror;
}
push @testvec, \&t_srvr_accept_strm;

# finish the client connect if it was pending
sub t_clnt_fconn_strm {
    ptest;
    $ok = $connok || $clnt->connect($sockname, {'timeout'=>1});
    ok okval $ok, 1, xerror;
}
push @testvec, \&t_clnt_fconn_strm;

# send a greeting
sub t_srvr_greet_strm {
    ptest;
    $sentmsg = "Wowsers!\n";	# a full line for checks below
    ok okval $acpt->send($sentmsg), length($sentmsg), xerror;
}
push @testvec, \&t_srvr_greet_strm;

# check receipt
sub t_clnt_greeted_strm {
    ptest;
    my $gotmsg = $clnt->getline;
    ok $gotmsg, $sentmsg;
}
push @testvec, \&t_clnt_greeted_strm;

# reply
sub t_clnt_reply_strm {
    ptest;
    $sentmsg = "Gadget!\n";
    ok okval $clnt->send($sentmsg), length($sentmsg), xerror;
}
push @testvec, \&t_clnt_reply_strm;

# check return receipt
sub t_srvr_greeted_strm {
    ptest;
    my $gotmsg = $acpt->getline;
    ok $gotmsg, $sentmsg;
}
push @testvec, \&t_srvr_greeted_strm;

# check close statuses
sub t_close_both_strm {
    ptest;
    $ok = $acpt->close && $clnt->close;
    ok okval $ok, 1, xerror;
}
push @testvec, \&t_close_both_strm;

# be sure we survive DESTROY
sub t_destroy_ok {
    ptest;
    $acpt = $srvr = $clnt = undef; # force the DESTROY call
    ok 1;
}
push @testvec, \&t_destroy_ok;

}	# end of BEGIN block for the test routines


# last test routine above this point


BEGIN {
    $| = 1;
# optional %Config::Config test here to skip the module
    unless ($Config::Config{i_sysun}) {
	print "1..0\n";
	exit 0;
    }
# Here's the boilerplate for calling plan().
    my (@todos, $i);
    for ($i = 0;  $i < @testvec;  $i++) {
	push @todos, $i		if exists $todos{$testvec[$i]};
    }
    plan tests => scalar @testvec, todo => \@todos;
}

# Any required `use' statements for the modules under test go here.

use Net::UNIX::Server;
use Net::UNIX;
use Net::Gen;

# Finally, run the driver.

tdriver;

exit($failures ? 1 : 0);


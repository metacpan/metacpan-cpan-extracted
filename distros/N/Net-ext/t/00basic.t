#!perl -w

# rcsid: "@(#) $Id: 00basic.t,v 1.12 1999/08/04 04:59:16 spider Exp $"

BEGIN {
    unshift @INC, './xlib','../xlib' if $] < 5.004_05;
}

use Test;
#use Config ();
use strict;


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
    !$failures;
}

sub ptest ()			# print out the test name
{
    my $who = (caller(1))[3];
    $who =~ s/^.*:://;
    print "# $who\n";
}


# start of test routines


# Rather than do lots of little BEGIN {push @testvec, \&t_...} blocks,
# wrap the whole test region in a single BEGIN.  It doesn't change
# how most of the subs are compiled, and it's (slightly) more efficient.

# Note that all these tests exit if they fail.
# We're testing some rather basic capabilities here, and they should
# all succeed.

BEGIN {

my $u;				# server socket
my $u2;				# client socket
my $port;			# server port
my $srvaddr;			# server address
my ($msg, $sender);
my (@recaddr, $setport);

# Get a server socket.
sub t_srvr_new {
    ptest;
    $ok = $u = Net::UDP->new;
    ok $ok;
}
push @testvec, \&t_srvr_new;

# Now set it up to be bound.
sub t_srvr_setport {
    return unless $ok;
    ptest;
    $ok = $u->setparams({thisport=>0});
    ok $ok;
}
push @testvec, \&t_srvr_setport;

# Try to do the bind.
sub t_srvr_bind {
    return unless $ok;
    ptest;
    $ok = $u->bind;
    ok $ok;
}
push @testvec, \&t_srvr_bind;

# Make sure we get the bound port back.
sub t_srvr_getport {
    return unless $ok;
    ptest;
    $port = $u->getparam('lclport');
    $srvaddr = $u->getparam('srcaddr');
    $ok = $port && $srvaddr;
    ok $ok;
}
push @testvec, \&t_srvr_getport;

# Get a second socket, so we can try passing messages around.
sub t_clnt_new {
    return unless $ok;
    ptest;
    $ok = $u2 = Net::UDP->new;
    ok $ok;
}
push @testvec, \&t_clnt_new;

# If all is OK so far, try exchanging some simple messages.  Send one first.
sub t_clnt_send {
    return unless $ok;
    ptest;
    $ok = $u2->send("ABCDEF", 0, $srvaddr);
    ok $ok;
}
push @testvec, \&t_clnt_send;

# Be sure we know the client's address now.
sub t_clnt_getport {
    return unless $ok;
    ptest;
    $u2->getsockinfo;
    $ok = $setport = $u2->getparam('lclport');
    ok $ok;
}
push @testvec, \&t_clnt_getport;

# Try to be sure we won't block if we try to receive it.
sub t_srvr_select {
    return unless $ok;
    ptest;
    my $fhvec = $u->fhvec;
    my $recok = select($fhvec, undef, undef, 1);
    $ok = $recok && $u->select(1, 0, 0, 1); # also test select method
    ok $ok;
}
push @testvec, \&t_srvr_select;

# Now try to read it.
sub t_srvr_recv {
    return unless $ok;
    ptest;
    $ok = ($msg = $u->recv(40, 0, $sender)) && $sender;
    ok $ok;
}
push @testvec, \&t_srvr_recv;

# Validate the sender information.
sub t_srvr_valaddr {
    return unless $ok;
    ptest;
    @recaddr = $u->_addrinfo($sender);
#    $setport = $u2->getparam('lclport');
    $ok = ($setport == $recaddr[3]);
    ok $ok;
}
push @testvec, \&t_srvr_valaddr;

# Validate the message.
sub t_srvr_valmsg {
    return unless $ok;
    ptest;
    $ok = ($msg eq "ABCDEF");
    ok $ok;
}
push @testvec, \&t_srvr_valmsg;

# Now send one back, defaulting the reply address.
sub t_srvr_reply {
    return unless $ok;
    ptest;
    $ok = $u->send("GHIJK");
    ok $ok;
}
push @testvec, \&t_srvr_reply;

# Don't block forever on the receive attempt.
sub t_clnt_select {
    return unless $ok;
    ptest;
    $ok = $u2->select(1,0,0,30);
    ok $ok;
}
push @testvec, \&t_clnt_select;

# Validate the receipt.
sub t_clnt_recv {
    return unless $ok;
    ptest;
    $ok = ($msg = $u2->recv(40, 0, $sender)) && $sender;
    ok $ok;
}
push @testvec, \&t_clnt_recv;

# Validate the addressing.
sub t_clnt_valaddr {
    return unless $ok;
    ptest;
    @recaddr = $u2->_addrinfo($sender);
    $ok = ($recaddr[3] == $port);
    ok $ok;
}
push @testvec, \&t_clnt_valaddr;

# Validate the contents
sub t_clnt_valmsg {
    return unless $ok;
    ptest;
    $ok = ($msg eq "GHIJK");
    ok $ok;
}
push @testvec, \&t_clnt_valmsg;

# Ensure we survive DESTROY calls.
sub t_cleanup {
    return unless $ok;
    ptest;
    $u = $u2 = undef;
    ok 1;
}
push @testvec, \&t_cleanup;

}	# end of BEGIN block for the test routines


# last test routine above this point


BEGIN {
    $| = 1;
# optional %Config::Config test here to skip the module
#    unless ($Config::Config{i_sysun}) {
#	print "1..0\n";
#	exit 0;
#    }
# Here's the boilerplate for calling plan().
    my (@todos, $i);
    for ($i = 0;  $i < @testvec;  $i++) {
	push @todos, $i		if exists $todos{$testvec[$i]};
    }
    plan tests => scalar @testvec, todo => \@todos;
}

# Any required `use' statements for the modules under test go here.

use Net::Gen;
use Net::TCP;
use Net::TCP::Server;
use Net::UDP;

# Finally, run the driver.

exit !tdriver;

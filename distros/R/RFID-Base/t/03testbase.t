#!/usr/bin/perl -w

use strict;

use IO::Socket;

use Test::More tests => 9;

BEGIN {
    use_ok('RFID::Reader::TestBase');
};

package RFID::Reader::TestBase::Derived;
our @ISA = qw(RFID::Reader::TestBase RFID::Reader);
sub new { bless({}, $_[0])->_init() }
sub _process_input { $_[0]->_add_output(@_[1..$#_]); ''; } # echo

package main;

my $test = RFID::Reader::TestBase::Derived->new;
ok($test);

# Test the basics
ok($test->_writebytes("hello there","\0","hello again\n")==24);
ok($test->_readbytes(5) eq "hello");
ok($test->_readuntil("\0") eq " there");
ok($test->_readuntil("\n") eq "hello again");

# Now do a quick test of the server.
my($s1,$s2)=IO::Socket->socketpair(AF_UNIX,SOCK_STREAM,PF_UNSPEC)
    or die "Couldn't create socket pair: $!\n";
my $pid;
if (!defined($pid = fork()))
{
    die "fork error: $!\n";
}
elsif (!$pid)
{
    # Child
    close($s1);
    $s2->autoflush(1);
    # Ignore errors, since we'll be killed by a TERM signal.
    eval {
    $test->run($s2,$s2);
    };
    exit(0);
}

# Parent
eval {
    $SIG{ALRM}=sub { die "Timed out\n" };
    alarm(20); # Maximum time we'll wait.
    $s1->autoflush(1);
    ok(print $s1 "This is a test\n");
    ok(<$s1> eq "This is a test\n");
 };
if ($@) { warn "Server tests failed: $@\n" };

kill 'TERM', $pid;

ok(1);



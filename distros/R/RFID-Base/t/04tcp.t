#!/usr/bin/perl -w

use strict;
use IO::Socket::INET;

use Test::More tests => 9;
BEGIN {
    use_ok('RFID::Reader::TCP');
    use_ok('RFID::Reader::TestBase');
}

package RFID::Reader::TestBase::Derived;
our @ISA = qw(RFID::Reader::TestBase RFID::Reader);
sub new { bless({}, $_[0])->_init() }
sub _process_input { $_[0]->_add_output(@_[1..$#_]); ''; } # echo

package main;

my $test = RFID::Reader::TestBase::Derived->new;
ok($test);


my $listen = IO::Socket::INET->new(Proto => 'TCP',
				   Listen => 5,
				   LocalAddr => 0,
				   )
    or die "Couldn't create listening socket: $!\n";
my $port = $listen->sockport;




# Start up a server.
our $pid;
if ($pid = fork)
{
    # Parent
}
elsif (!defined($pid))
{
    # Error
    die "Fork error: $!\n";
}
else
{
    # Child
    $SIG{TERM}=sub { exit(0); }; # This is a normal exit.

    # Wrap in eval to avoid spewing errors when we're TERMed.
    eval {
	if (my $sock = $listen->accept)
    {
	$sock->autoflush(1);
	$test->run($sock,$sock);
    }
    };
    exit(0);
}

# Parent
close($listen);
our $obj;
eval {
    sleep(1);
    $SIG{ALRM}=sub { die "Timed out\n" };
    alarm(20); # Maximum time we'll wait.
    $obj = RFID::Reader::TCP->new(PeerAddr => 'localhost', 
				  PeerPort => $port,
				  Debug => $ENV{RFID_DEBUG},
				  );
    ok($obj);
    isa_ok($obj,'RFID::Reader::TCP');
    
    ok($obj->_writebytes("hello there\0hello again\n")==24);
    ok($obj->_readbytes(5) eq "hello");
    ok($obj->_readuntil("\0") eq " there");
    ok($obj->_readuntil("\n") eq "hello again");
};
warn $@ if $@;

undef $obj;

kill 'TERM',$pid;


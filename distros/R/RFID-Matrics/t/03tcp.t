#!/usr/bin/perl -w

use strict;

use Test::More tests => 22;
use RFID::Matrics::Reader::TCP;
use RFID::Matrics::Reader::Test;
use RFID::Matrics::Tag qw(tagcmp);
use IO::Socket::INET;

my $test = RFID::Matrics::Reader::Test->new(
					    Debug => $ENV{MATRICS_DEBUG},
					    node => 4,
					    antenna => 1,
					    )
    or die "Couldn't create test object\n";
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
    # Suppress errors since otherwise we get error messages on
    # Windows.
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
    $obj = RFID::Matrics::Reader::TCP->new(PeerAddr => 'localhost', 
					   PeerPort => $port,
					   Debug => $ENV{MATRICS_DEBUG},
					   node => 4,
					   antenna => 1,
					   );
    isa_ok($obj,'RFID::Matrics::Reader::TCP');
    isa_ok($obj,'RFID::Matrics::Reader');
    
    do 't/readertest.pl'
	or die "Couldn't do t/readertest.pl: $@/$!\n";
};

warn $@ if $@;
undef $obj; # Required to prevent hangs on Windows

kill 'TERM',$pid;

1;

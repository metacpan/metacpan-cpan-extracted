#!/usr/bin/perl -Tw

use strict;

use IO::Socket;
use Scalar::Util qw(tainted);
use Fcntl;

use Test::More;

use constant SERIAL_NEEDS => "Need Unix, interceptty, and Device::SerialPort to test serial driver";
use constant SERIAL_COUNT => 6;

BEGIN {
    if ($^O eq 'MSWin32' or $ENV{SKIP_TAINT})
    {
	plan skip_all => 'taint+fork broken on your platform';
    }
    else
    {
	plan tests => 16;
    }
}


BEGIN {
    use_ok('RFID::Reader::TestBase');
    use_ok('RFID::Reader::TCP');
    use_ok('RFID::Reader::Serial');
};

our($pid, $read, $obj);
our $tainted = $ENV{PATH};

# We're just testing, so untaint blindly.
$ENV{PATH} =~ /^(.*)$/;
$ENV{PATH}=$1;

# Basic test
package RFID::Reader::TestBase::Derived;
our @ISA = qw(RFID::Reader::TestBase RFID::Reader);
sub new { bless({}, $_[0])->_init() }
sub _process_input { $_[0]->_add_output(@_[1..$#_]); ''; } # echo

package main;
$obj = RFID::Reader::TestBase::Derived->new;
ok($obj);

eval
{
    $obj->_writebytes($tainted);
};
ok($@ =~ /taint/);
ok($obj->_writebytes("bytes")==5);
ok(($read = $obj->_readbytes(5)) eq 'bytes');
#ok(tainted($read));

# Now test with TCP.
# Start up a server.
my $listen = IO::Socket::INET->new(Proto => 'TCP',
				   Listen => 5,
				   LocalAddr => 0,
				   )
    or die "Couldn't create listening socket: $!\n";
my $port = $listen->sockport;
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
	    $obj->run($sock,$sock);
	}
    };
    exit(0);
}

# Parent
close($listen);
eval {
    sleep(1);
    $SIG{ALRM}=sub { die "Timed out\n" };
    alarm(20); # Maximum time we'll wait.
    $obj = RFID::Reader::TCP->new(PeerAddr => 'localhost', 
				  PeerPort => $port,
				  Debug => $ENV{RFID_DEBUG},
				  Timeout => 20
				  );
    ok($obj);
    isa_ok($obj,'RFID::Reader::TCP');
    eval
    {
	$obj->_writebytes($tainted);
    };
    ok($@ =~ /taint/i);
};
warn $@ if $@;

undef $obj;

kill 'TERM',$pid;

# Finally test with serial

SKIP: {
    eval 'use Device::SerialPort';
    $@ and skip SERIAL_NEEDS, SERIAL_COUNT;
    my $interceptty_version = `interceptty -V 2>/dev/null`;
    if ($? or $interceptty_version !~ /^(0.[4-9]|[1-9])/) 
    {
	skip SERIAL_NEEDS, SERIAL_COUNT;
    }
# Start up a server.
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
	my($s1,$s2)=IO::Socket->socketpair(AF_UNIX,SOCK_STREAM,PF_UNSPEC)
	    or die "Couldn't create socket pair: $!\n";
	$s1->autoflush(1);
	$s2->autoflush(1);
	my $pid2;
	if (!defined($pid2 = fork))
	{
	    die "fork error: $!\n";
	}
	elsif (!$pid2)
	{
	    # Child
	    close($s1)
		or die "Couldn't close socket: $!";
	    fcntl $s2, F_SETFD, 0;
	    exec('interceptty','-q','='.$s2->fileno,'./t/test.tty')
		or die "exec error: $!\n";
	}
	# Parent
	close($s2)
	    or die "Couldn't close socket: $!";
	my $obj = RFID::Reader::TestBase::Derived->new;
	$obj->run($s1,$s1);
    }

    eval {
	# Parent
	sleep(1);
	$SIG{ALRM}=sub { die "Timed out\n" };
	alarm(20); # Maximum time we'll wait.
	my $com = Device::SerialPort->new('./t/test.tty')
	    or die "Couldn't create COM device!\n";
	$obj = RFID::Reader::Serial->new(Port => $com,
					 Debug => $ENV{RFID_DEBUG},
					 );
	ok($obj);
	isa_ok($obj,'RFID::Reader::Serial');
	eval
	{
	    $obj->_writebytes($tainted);
	};
	ok($@ =~ /taint/);
	ok($obj->_writebytes("bytes")==5);
	ok(($read = $obj->_readbytes(5)) eq 'bytes');
	ok(tainted($read));
    };
    warn $@ if $@;
    
    
    kill 'TERM',$pid;
    wait;
} # SKIP

1;

#!/usr/bin/perl -w

use strict;

use Test::More;
use RFID::Reader::Serial;
use RFID::Reader::TestBase;;
use Fcntl;
use IO::Socket;

my $tainted = $ENV{PATH};

# We're just testing, so untaint blindly.
$ENV{PATH} =~ /^(.*)$/;
$ENV{PATH}=$1;

use constant NEED_STUFF => "Need Unix, interceptty, and Device::SerialPort to test serial driver";

eval 'use Device::SerialPort';
$@ and plan skip_all => NEED_STUFF;
my $interceptty_version = `interceptty -V 2>/dev/null`;
if ($? or $interceptty_version !~ /^(0.[4-9]|[1-9])/) 
{
    plan skip_all => NEED_STUFF;
}

plan tests => 6;

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
    package RFID::Reader::TestBase::Derived;
    our @ISA = qw(RFID::Reader::TestBase RFID::Reader);
    sub new { bless({}, $_[0])->_init(@_[1..$#_]) }
    sub _process_input { $_[0]->_add_output(@_[1..$#_]); ''; } # echo
    
    package main;
    
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
    my $test = RFID::Reader::TestBase::Derived->new;
    $test->run($s1,$s1);
}

our $obj;
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

    my $s = "hello there\0hello again\n";
    ok($obj->_writebytes($s)==length($s));

    ok($obj->_readbytes(5) eq "hello");
    ok($obj->_readuntil("\0") eq " there");
    ok($obj->_readuntil("\n") eq "hello again");

};
warn $@ if $@;


kill 'TERM',$pid;
wait;

1;

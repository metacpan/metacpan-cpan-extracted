#!/usr/bin/perl -w

use strict;

use Test::More;
use RFID::Alien::Reader::Serial;
use RFID::Alien::Reader::Test;
use RFID::EPC::Tag;

eval 'use Device::SerialPort';
$@ and plan skip_all => 'Need Device::SerialPort to test serial driver.';
my $interceptty_version = `interceptty -V 2>/dev/null`;
if ($? or $interceptty_version !~ /^(0.[4-9]|[1-9])/) 
{
    plan skip_all => "Need interceptty version 0.4 or higher to test serial driver.";
}
# We should make sure we're using a version of interceptty that
# supports this, too.

plan tests => 41;

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
    exec('interceptty','!perl -Iblib/lib -MRFID::Alien::Reader::Test -e "RFID::Alien::Reader::Test->new()->run();"','./t/test.tty')
	or die "exec error: $!\n";
    # Never reached.
}

our $obj;
eval {
    # Parent
    sleep(1);
    $SIG{ALRM}=sub { die "Timed out\n" };
    alarm(20); # Maximum time we'll wait.
    my $com = Device::SerialPort->new('./t/test.tty')
	or die "Couldn't create COM device!\n";
    $obj = RFID::Alien::Reader::Serial->new(Port => $com,
					    Debug => $ENV{ALIEN_DEBUG},
					    );
    isa_ok($obj,'RFID::Alien::Reader::Serial');
    isa_ok($obj,'RFID::Alien::Reader');
    
    do 't/readertest.pl'
	or die "Couldn't do t/readertest.pl: $@/$!\n";
};

warn $@ if $@;

kill 'TERM',$pid;
wait;

1;

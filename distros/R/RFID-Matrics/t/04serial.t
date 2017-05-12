#!/usr/bin/perl -w

use strict;

use Test::More;
use RFID::Matrics::Reader::Serial;
use RFID::Matrics::Reader::Test;
use RFID::Matrics::Tag qw(tagcmp);

eval 'use Device::SerialPort';
$@ and plan skip_all => 'Need Device::SerialPort (and a Unix-like system) to test serial driver.';
my $interceptty_version = `interceptty -V 2>/dev/null`;
if ($? or $interceptty_version !~ /^(0.[4-9]|[1-9])/) 
{
    plan skip_all => "Need interceptty version 0.4 or higher to test serial driver.";
}

plan tests => 22;

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
    exec('interceptty','!perl -Iblib/lib -MRFID::Matrics::Reader::Test -e "RFID::Matrics::Reader::Test->new()->run();"','./t/test.tty')
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
    $obj = RFID::Matrics::Reader::Serial->new(Port => $com,
					      Debug => $ENV{MATRICS_DEBUG},
					      node => 4,
					      antenna => 1,
					    );
    isa_ok($obj,'RFID::Matrics::Reader::Serial');
    isa_ok($obj,'RFID::Matrics::Reader');
    
    do 't/readertest.pl'
	or die "Couldn't do t/readertest.pl: $@/$!\n";
};

warn $@ if $@;

kill 'TERM',$pid;
wait;

1;

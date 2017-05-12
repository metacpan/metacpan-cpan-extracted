#!/usr/bin/perl -w

# Written by Scott Gifford <gifford@umich.edu>
# Copyright (C) 2004 The Regents of the University of Michigan.
# See the file LICENSE included with the distribution for license
# information.

use strict;

use Getopt::Std;

use RFID::Matrics::Reader;
use RFID::Matrics::Reader::Serial;
use RFID::Matrics::Reader::TCP;

BEGIN {
    # Try to load these; if they fail we'll detect it later.
    # Doing it outside of a BEGIN block makes Win32::SerialPort spew
    # errors.
    eval 'use Win32::SerialPort';
    eval 'use Device::SerialPort';
}

use constant TAG_TIMEOUT => 10;
use constant CMD_TIMEOUT => 15;
use constant POLL_TIME => 0;
use constant DEFAULT_NODE => 4;

our($debug, $node, @ant, $polltime);
our %opt;
getopts("h:c:n:a:p:d",\%opt)
    or die "Usage: $0 [-cd]\n";
$debug=$opt{d}||$ENV{MATRICS_DEBUG};
$node=$opt{n}||DEFAULT_NODE;
if ($opt{a})
{
    @ant = (split(/,/,$opt{a}));
}
$polltime=defined($opt{p})?$opt{p}:POLL_TIME;
$| = 1;

our($com,$reader);

END {
    if ($com)
    {
	$com->purge_all();
    }
    if ($reader)
    {
	$reader->finish()
	    or warn "Couldn't stop constant read: $!\n";
    }
    if ($com)
    {
	$com->close()
	    or warn "Couldn't close COM port: $!\n";
    }
}

# Uncaught signals don't call END blocks.
for my $sig (grep { exists $SIG{$_} } qw(INT TERM BREAK HUP))
{
    $SIG{$sig} = sub { exit(1); };
}

if ($opt{c})
{
    if ($INC{'Win32/SerialPort.pm'})
    {
	$com = Win32::SerialPort->new($opt{c})
	        or die "Couldn't open COM port '$opt{c}': $^E\n";
    }
    elsif ($INC{'Device/SerialPort.pm'})
    {
	$com = Device::SerialPort->new($opt{c})
	        or die "Couldn't open COM device '$opt{c}'!\n";
    }
    else
    {
	die "Couldn't find either Win32::SerialPort or Device::SerialPort!\n";
    }
    
    $reader = RFID::Matrics::Reader::Serial->new(Port => $com,
						 Node => $node,
						 Debug => $debug,
						 Timeout => CMD_TIMEOUT,
						 @ant?(AntennaSequence => \@ant, Antenna => $ant[0]):(),
						 )
	or die "Couldn't create RFID reader object: $!\n";
}
elsif ($opt{h})
{
    my($addr,$port);
    if ($opt{h} =~ /^([\w.-]+):(\d+)$/)
    {
	($addr,$port)=($1,$2);
    }
    else
    {
	$addr = $opt{h};
	$port = 4001;
    }
    
    $reader = RFID::Matrics::Reader::TCP->new(PeerAddr => $addr,
					      PeerPort => $port,
					      Node => $node,
					      Debug => $debug,
					      Timeout => CMD_TIMEOUT,
					      @ant?(AntennaSequence => \@ant, Antenna => $ant[0]):(),
					      )
	or die "Couldn't create RFID reader object: $!\n";
}
else
{
    die "Must specify -c comport or -h hostname:port\n";
}

# Set up antennas
$reader->set(PowerLevel => 0xff,
	     Environment => 4,
	     ) == 0
    or die "Couldn't set reader options!\n";

# Now start polling
while(1)
{
    warn "Polling...\n";
    my $time = time;
    foreach my $tag ($reader->readtags)
    {
	my %ti = $tag->get('ID','Type','Antenna');
	$ti{epc_type}||='none';
	print "ISEE $ti{Type}.$ti{ID} FROM matrics.$node.$ti{Antenna} AT $time TIMEOUT ",TAG_TIMEOUT,"\n";
    }
    sleep($polltime);
}

# Nothing below here is ever reached (exits on signal)



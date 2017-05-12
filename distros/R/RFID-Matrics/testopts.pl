#!/usr/bin/perl -w

# Test some options on a real Matrics reader.

use strict;

use Getopt::Std;
use RFID::Matrics::Reader;

use constant TAG_TIMEOUT => 10;
use constant CMD_TIMEOUT => 15;
use constant POLL_TIME => 0;
use constant DEFAULT_NODE => 4;

our %opt;
BEGIN {
    getopts("h:c:l:n:a:d",\%opt)
	or die "Usage: $0 [-cd]\n";
    if ($opt{c} and $^O eq 'MSWin32')
    {
	eval '
              use Win32::Serialport;
              use RFID::Matrics::Reader::Serial;
        ';
    }
    elsif ($opt{h})
    {
	eval 'use RFID::Matrics::Reader::TCP;';
    }
}

our($debug, $node, @ant, $login, $password);
$debug=$opt{d}||$ENV{ALIEN_DEBUG};
$node=$opt{n}||DEFAULT_NODE;
if ($opt{a})
{
    @ant = (split(/,/,$opt{a}));
}
else
{
    @ant = (1);
}

if ($opt{l})
{
    open(LOGIN,"< $opt{l}")
	or die "Couldn't open login information file '$opt{l}': $!\n";
    chomp($login=<LOGIN>);
    chomp($password=<LOGIN>);
    close(LOGIN)
	or die "Couldn't close login information file '$opt{l}': $!\n";
}

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
    $com = Win32::SerialPort->new($opt{c})
	or die "Couldn't open COM port '$opt{c}': $^E\n";
    $reader = RFID::Matrics::Reader::Serial->new(Port => $com,
						 Debug => $debug,
						 Timeout => CMD_TIMEOUT,
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
					      node => $node,
					      antenna => $ant[0],
					      debug => $debug,
					      Timeout => CMD_TIMEOUT,
					      Login => $login,
					      Password => $password,
					      AntennaSequence => \@ant,
					    )
	or die "Couldn't create RFID reader object: $!\n";
}
else
{
    die "Must specify -c comport or -h hostname:port\n";
}

my @get = (qw(PowerLevel PowerLevel_Antenna1 PowerLevel_Antenna2 
	      PowerLevel_Antenna3 PowerLevel_Antenna4
	      Mask
	      ReaderVersion ReaderSerialNum
	      ));
foreach my $g (@get)
{
    print "$g: ",scalar($reader->get($g)),"\n";
}

# Test settings
my @test = (
#	    Mask => '01/8',
#	    Mask => '02/8',
#	    Mask => '80/8',
#	    Mask => '01deadbee/40',
#	    Mask => 'ff/8',
#	    Mask => '00/8',
#	    Mask => '',
	    PowerLevel => 0,
	    PowerLevel => 10,
	    PowerLevel => 50,
	    PowerLevel => 100,
	    PowerLevel_Antenna1 => 0,
	    PowerLevel_Antenna1 => 10,
	    PowerLevel_Antenna1 => 50,
	    PowerLevel_Antenna1 => 100,
	    PowerLevel_Antenna4 => 0,
	    PowerLevel_Antenna4 => 10,
	    PowerLevel_Antenna4 => 50,
	    PowerLevel_Antenna4 => 100,
	    Environment => 0,
	    Environment => 1,
	    Environment => 2,
	    Environment => 3,
	    Environment => 4,
	    Environment_Antenna3 => 0,
	    Environment_Antenna3 => 1,
	    Environment_Antenna3 => 2,
	    Environment_Antenna3 => 3,
	    Environment_Antenna3 => 4,

	    );
my $errs = 0;

while (@test)
{
    my $var = shift @test;
    my $val = shift @test;
    my $expect = $val;
    
    warn "*** Testing setting $var to ",mkstr($val),"\n";
    my $orig = $reader->get($var);
    if (!defined($orig))
    {
	warn "Couldn't get original value for '$var'\n";
	$errs++;
	next;
    }
    if (ref $val)
    {
	if (defined($val->[1]))
	{
	    $expect = $val->[1];
	}
	else
	{
	    $expect = $val->[0];
	}
	$val=$val->[0];
    }
    if ($reader->set($var => $val) != 0)
    {
	$errs++;
	warn "couldn't set $var to '$val'!\n";
    }
    my $t = $reader->get($var);
    if (mkstr($t) ne mkstr($expect))
    {
	$errs++;
	warn "$var has wrong value: expected '".mkstr($expect)."', got '".mkstr($t)."'!\n";
    }
    if ($reader->set($var => $orig) != 0)
    {
	$errs++;
	warn "Couldn't reset option '$var' to original value '$orig'!\n";
    }
    $t = $reader->get($var);
    if (mkstr($t) ne mkstr($orig))
    {
	$errs++;
	warn "$var has wrong value: expected '".mkstr($orig)."', got '".mkstr($t)."'!\n";
    }
    warn "$var='$val' ok!\n";
}

warn "$errs errors occured.\n";

exit(0);

warn "Rebooting reader!!\n";
$reader->reboot;


sub mkstr
{
    my($v)=@_;

    if (!defined($v)) { return '(undef)' }
    elsif (ref($v))
    {
	if (ref($v) eq 'ARRAY')
	{
	    return join(",",@$v);
	}
	elsif (ref($v) eq 'HASH')
	{
	    return join(",",map { "$_ => $v->{$_}" } sort keys %$v);
	}
	else
	{
	    die "Couldn't stringify $v\n";
	}
    }
    else
    {
	$v;
    }
}

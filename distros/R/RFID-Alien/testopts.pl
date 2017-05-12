#!/usr/bin/perl -w

# Test some options on a real Alien reader.

use strict;

use Getopt::Std;
use RFID::Alien::Reader;

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
              use RFID::Alien::Reader::Serial;
        ';
    }
    elsif ($opt{h})
    {
	eval 'use RFID::Alien::Reader::TCP;';
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
    @ant = (0);
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
    $reader = RFID::Alien::Reader::Serial->new(Port => $com,
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
    
    $reader = RFID::Alien::Reader::TCP->new(PeerAddr => $addr,
					    PeerPort => $port,
					    node => $node,
					    antenna => $ant[0],
					    debug => $debug,
					    Timeout => CMD_TIMEOUT,
					    Login => $login,
					    Password => $password,
					    )
	or die "Couldn't create RFID reader object: $!\n";
}
else
{
    die "Must specify -c comport or -h hostname:port\n";
}

# Test settings
my @test = (
#	    mask => ['abcdef','ABCDEF/24'],
	    mask => '',
#	    mask => 'DEAD/16',
#	    mask => '1234/16/24',
#	    AcqCycles => 100,
#	    AcqEnterWakeCount => 50,
#	    AcqCount => 25,
#	    AcqSleepCount => 12,
#	    AcqExitWakeCount => 6,
	    PersistTime => 100,
	    PersistTime => 0,
	    PersistTime => -1,
	    AcquireMode => ['Global Scroll','Global Scroll (Multiplier=0A)'],
	    AcquireMode => ['Inventory', 'Inventory (Hex Mode=21)'],
	    time => 1086379031,
	    time => 1086379031 + 86400,
	    time => 1086379031 - 86400,
	    AntennaSequence => [[1,0]],
	    AntennaSequence => [[1,0]],
	    AntennaSequence => [0],
	    AntennaSequence => [1],
	    AntennaSequence => [0,[0]],
	    AntennaSequence => [1,[1]],
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

warn "Rebooting reader!!\n";
$reader->reboot;

exit(0);

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

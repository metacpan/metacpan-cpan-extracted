#!/usr/bin/perl -w

use strict;

use Getopt::Std;
use RFID::Alien::Reader;
use RFID::Alien::Reader::Serial;
use RFID::Alien::Reader::TCP;

sub usage
{
  die <<EOF;
@{_}Usage: $0 (-h host[:port] OR -c comport) [-l loginfile] [-n name] [-a ant1[,ant2[,ant3[,ant4]]]] [-p polltime] [-d] [-r] [-q]
    -h: Host or host:port to connect to via TCP
    -c: COM port (COM1 on Windows, /dev/ttyS0 on Linux, etc.)
    -l: File containing username on first line and password on second
    -n: Name to be reported in output messages (default "alien")
    -a: Comma-seperated list of antennas to use, numbered from 0
    -p: Poll time (sleep between scans)
    -d: Debug output
    -r: Restart if anything goes wrong
    -q: Quiet mode; only output tag sightings.
EOF
  ;
}

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
use constant DEFAULT_NAME => 'alien';

our %opt;
getopts("h:c:l:n:a:p:drq",\%opt)
    or die "Usage: $0 [-cd]\n";

our($debug, $name, @ant, $login, $password, $polltime);
$debug=$opt{d}||$ENV{ALIEN_DEBUG};
$name=$opt{n}||DEFAULT_NAME;
if ($opt{a})
{
    @ant = (split(/,/,$opt{a}));
}
else
{
    @ant = (0);
}
$polltime=defined($opt{p})?$opt{p}:POLL_TIME;

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
	  or $opt{q} or warn "Couldn't stop constant read: $!\n";
    }
    if ($com)
    {
	$com->close()
	  or $opt{q} or warn "Couldn't close COM port: $!\n";
    }
}

# Uncaught signals don't call END blocks.
for my $sig (grep { exists $SIG{$_} } qw(INT TERM BREAK HUP))
{
    $SIG{$sig} = sub { exit(1); };
}

unless ($opt{c} || $opt{h})
{
  usage("Must specify -c comport or -h hostname:port\n");
}

do {
  eval {
  
    if ($opt{c}) {
      if ($INC{'Win32/SerialPort.pm'}) {
	$com = Win32::SerialPort->new($opt{c})
	  or die "Couldn't open COM port '$opt{c}': $^E\n";
      } elsif ($INC{'Device/SerialPort.pm'}) {
	$com = Device::SerialPort->new($opt{c})
	  or die "Couldn't open COM device '$opt{c}'!\n";
      } else {
	die "Couldn't find either Win32::SerialPort or Device::SerialPort!\n";
      }
      $reader = RFID::Alien::Reader::Serial->new(Port => $com,
						 Debug => $debug,
						 Timeout => CMD_TIMEOUT,
						)
	or die "Couldn't create RFID reader object: $!\n";
    } elsif ($opt{h}) {
      my($addr,$port);
      if ($opt{h} =~ /^([\w.-]+):(\d+)$/) {
	($addr,$port)=($1,$2);
      } else {
	$addr = $opt{h};
	$port = 4001;
      }
    
      $reader = RFID::Alien::Reader::TCP->new(PeerAddr => $addr,
					      PeerPort => $port,
					      Debug => $debug,
					      Timeout => CMD_TIMEOUT,
					      Login => $login,
					      Password => $password,
					     )
	or die "Couldn't create RFID reader object: $!\n";
    } else {
      # Should never happen
      die "Must specify -c comport or -h hostname:port\n";
    }

    my $ver = $reader->get('ReaderVersion');
    print "Reader version: $ver"
      unless ($opt{q});

    $reader->set(PersistTime => 0) == 0
      or die "Couldn't set PersistTime to 0!\n";
    $reader->set(AcquireMode => 'Inventory') == 0
      or die "Couldn't set AcquireMode to Global Scroll!\n";
    $reader->set(AntennaSequence => \@ant) == 0
      or die "Couldn't set antenna sequence!\n";
    $reader->set(TagListAntennaCombine => 'OFF') == 0
      or die "Couldn't set TagListAntennaCombine!\n";

    # Now start polling
    while (1) {
      print "Scanning for tags\n"
	unless ($opt{q});
      my @pp = $reader->readtags();
      my $now = time
	if (@pp);
      foreach my $tag (@pp) {
	my %ti = $tag->get('ID','Type','Antenna');
	$ti{epc_type}||='none';
	print "ISEE $ti{Type}.$ti{ID} FROM $name.$ti{Antenna} AT $now TIMEOUT ",TAG_TIMEOUT,"\n";
      }
      sleep($polltime);
    }
  };
  if ($@) {
    !$opt{q}
        and warn "Communications problem: $@\n";
  }
  $opt{r}
      and warn "Restarting...\n";
} while ($opt{r}); # auto-restart


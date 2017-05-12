#!/usr/local/bin/perl

use strict;

use Getopt::Std;

use UniLog qw(:levels :options :facilities nosyslog);
use Net::Socket::NonBlock;

# Autoflush on
$| = 1;

my $Usage = "Usage: $0 -p <LocalPort> -h <RemoteHost:RemotePort> [-d] [-f] [-l <LogFile>]\n\t-d is enabling debug information printing\n\t-f is disabling self-daemonising";

my %Config = ();

getopts("p:h:dfl:", \%Config);

(defined($Config{'p'}) && defined($Config{'h'}))
	or die "$Usage\n";

$Config{'f'} = $Config{'f'} || ($^O =~ m/win32/i);

# Configure logger
my $Logger=UniLog->new(Ident    => $0,
                       Options  => LOG_PID|LOG_CONS|LOG_NDELAY,
                       Facility => LOG_DAEMON,
                       Level    => $Config{'d'} ? LOG_DEBUG : LOG_INFO,
                       LogFile  => $Config{'l'},
                       StdErr   => (!$Config{'l'}),
                      );

my $SockNest = Net::Socket::NonBlock->new(SelectT  => 0.1, SilenceT => 0)
	or Die(1, "Error creating sockets nest: $@");

$SockNest->Listen(LocalPort => $Config{'p'},
                  Proto     => 'tcp',
                  Accept    => \&NewConnection,
                  SilenceT  => 0,
                  Listen    => 10,)
	or Die(2, "Could not listen on port \"$Config{'p'}\": $@");

my %ConPool = ();

print "$0 started\n";

# Daemonize process if needed
if (!$Config{'f'})
	{
	$SIG{PIPE} = "IGNORE";
	my $Pid=fork
		or Die(3, "Could not fork: \"$!\". Exiting.");
	($Pid == 0)
		or exit 0;
	POSIX::setsid()
		or Die(4, "Could not detach from terminal: \"$!\". Exiting.");
	$Logger->StdErr(0);
	};

my $WaitForDataAnswer = 0;
my $DataStage = 0;

while($SockNest->IO())
	{
	my $ClnSock = undef;
	my $SrvSock = undef;
	while (($ClnSock, $SrvSock) = each(%ConPool))
		{
		my $Str = undef;
		my $ClientID = $SockNest->PeerAddr($ClnSock).':'.$SockNest->PeerPort($ClnSock);
		while($Str = $SockNest->Read($ClnSock))
			{
			if ($DataStage && !$Config{'d'})
				{ $Logger->Message(LOG_INFO, "$ClientID length %s", length($Str)); }
			else
				{ $Logger->Message(LOG_INFO, "$ClientID from %s", SafeStr($Str)); };
			
			if    (!$DataStage && ($Str =~ m/\A\s*data(\s+.*)?\n\Z/i))
				{ $WaitForDataAnswer = 1; }
			elsif ($DataStage && ($Str =~ m/\A\.\r?\n\Z/i))
				{ $DataStage = 0; }

			$SockNest->Puts($SrvSock, $Str);
			};
		if (!defined($Str))
			{
			$Logger->Message(LOG_INFO, "$ClientID client closed");
			$SockNest->Close($ClnSock);
			$SockNest->Close($SrvSock);
			delete($ConPool{$ClnSock});
			next;
			};
		while($Str = $SockNest->Read($SrvSock))
			{
			if ($WaitForDataAnswer && ($Str =~ m/\A\s*354(\s+.*)?\n\Z/i))
				{ $DataStage = 1; };
			$WaitForDataAnswer = 0;

			$Logger->Message(LOG_INFO, "$ClientID to %s", SafeStr($Str));
			$SockNest->Puts($ClnSock, $Str);
			};
		if (!defined($Str))
			{
			$Logger->Message(LOG_INFO, "$ClientID server closed");
			$SockNest->Close($ClnSock);
			$SockNest->Close($SrvSock);
			delete($ConPool{$ClnSock});
			next;
			};
		};
	};           	

sub NewConnection
	{
	my $ClnSock = $_[0];

	my $ClientID = $SockNest->PeerAddr($ClnSock).':'.$SockNest->PeerPort($ClnSock);
	
	$ConPool{$ClnSock} = $SockNest->Connect(PeerAddr => $Config{'h'}, Proto => 'tcp',);
	
	if (!$ConPool{$ClnSock})
		{
	        $Logger->Message(LOG_INFO, "$ClientID can not connect to $Config{'h'}");
		delete($ConPool{$ClnSock});
		return;
		};
	$Logger->Message(LOG_INFO, "$ClientID new connection");
	return 1;
	};

sub Die
	{
	my $ExitCode = shift;
	$Logger->StdErr(1);
	$Logger->Message(LOG_ERR, shift, @_);
	exit $ExitCode;
	};

sub SafeStr
	{
	my $Str = shift
		or return '!UNDEF!';
	$Str =~ s{ ([\x00-\x1f\xff]) } { sprintf("\\x%2.2X", ord($1)) }gsex;
	return $Str;
	};

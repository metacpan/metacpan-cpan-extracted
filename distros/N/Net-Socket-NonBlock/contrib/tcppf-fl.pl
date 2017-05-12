# TCP port forwarder with logging
# Works on Win32!

use strict;

use Carp qw(carp croak cluck confess);
use Net::Socket::NonBlock;
use IO::File;

my $LocalPort   = shift
	or die "Usage: $0 <LocalPort> <RemoteHost:RemotePort> [LogFile]\n";
my $RemoteHost  = shift
	or die "Usage: $0 <LocalPort> <RemoteHost:RemotePort> [LogFile]\n";
my $glLogFName = shift;

my $SockNest = Net::Socket::NonBlock->new(SelectT  => 0.1,
                                          SilenceT => 0,
			                  debug    => $^W,
                                         )
	or die "Error creating sockets nest: $@\n";

# Autoflush on
$| = 1;

$SockNest->Listen(LocalPort      => $LocalPort,
                  Proto          => 'tcp',
                  Accept         => \&NewConnection,
                  SilenceT       => 0,
                  Listen         => 10,
                 )
	or die "Could not listen on port \"$LocalPort\": $@\n";

my %ConPool = ();
#my %Buffers = ();

print "$0 started\n";

my $Flag = 0;
my @PP = ('|', '/', '-', '\\');
print STDERR ' ';

while($SockNest->IO())
	{
	my $Pstr = '';
	my $ClnSock = undef;
	my $Info    = undef;
	while (($ClnSock, $Info) = each(%ConPool))
		{
		print STDERR chr(8).$PP[$Flag]; $Flag++; if ($Flag > $#PP) { $Flag = 0; };
		my $Fstr = '';
		my $Str = undef;
		my $ClientID = sprintf("%15.15s:%-5.5s", $SockNest->PeerAddr($ClnSock), $SockNest->PeerPort($ClnSock));
		while(($Str = $SockNest->Read($ClnSock)) && length($Str))
			{
			$Pstr .= "    $ClientID From CLIENT ".SafeStr($Str)."\n";
			$Fstr .= "    From CLIENT ".SafeStr($Str)."\n";
			$SockNest->Puts($Info->{'SrvSock'}, $Str);
			};
		if (!defined($Str))
			{
			$Pstr .= "    $ClientID CLIENT closed: $@\n"; 
			$Fstr .= "    CLIENT closed: $@\n";
			if ($Info->{'File'})
				{
				print {$Info->{'File'}} localtime()."\n".$Fstr;
				$Info->{'File'}->close();
				};
			$SockNest->Close($Info->{'SrvSock'});
			$SockNest->Close($ClnSock);
			delete($ConPool{$ClnSock});
			#delete($Buffers{$ClnSock});
			next;
			};
		while(($Str = $SockNest->Read($Info->{'SrvSock'})) && length($Str))
			{
			$Pstr .= "    $ClientID From SERVER ".SafeStr($Str)."\n";
			$Fstr .= "    From SERVER ".SafeStr($Str)."\n";
			#push(@{$Buffers{$ClnSock}}, $Str);
			$SockNest->Puts($ClnSock, $Str);
			};
		if (!defined($Str))
			{
			$Pstr .= "    $ClientID SERVER closed: $@\n";
			$Fstr .= "    SERVER closed: $@\n"; 
			if ($Info->{'File'})
				{
				print {$Info->{'File'}} localtime()."\n".$Fstr;
				$Info->{'File'}->close();
				};
			$SockNest->Close($Info->{'SrvSock'});
			$SockNest->Close($ClnSock);
			delete($ConPool{$ClnSock});
			#delete($Buffers{$ClnSock});
			next;
			};
		if (length($Fstr) && $Info->{'File'})
			{ print {$Info->{'File'}} localtime()."\n".$Fstr; };
		};
	if (length($Pstr))
		{ print localtime()."\n".$Pstr; };
	};           	

sub NewConnection
	{
	my $ClnSock = $_[0];

	if (defined($glLogFName))
		{
		my $LogFName = $glLogFName.'-'.$SockNest->PeerAddr($ClnSock).'-'.$SockNest->PeerPort($ClnSock);
		print "\$LogFName : \"$LogFName\"\n";
		$ConPool{$ClnSock}->{'File'} = IO::File->new($LogFName, '>>')
			or confess "Can not open file \"".SafeStr($LogFName)."\" for append: $!\n";
		autoflush {$ConPool{$ClnSock}->{'File'}} 1;
		}
	if ($ConPool{$ClnSock}->{'File'}) { print {$ConPool{$ClnSock}->{'File'}} localtime()." CLIENT CONNECTED\n"; };

	$ConPool{$ClnSock}->{'SrvSock'} = $SockNest->Connect(PeerAddr => $RemoteHost, Proto => 'tcp',);
	
	if (!defined($ConPool{$ClnSock}->{'SrvSock'}))
		{
		warn "Can not connect to \"$RemoteHost\": $@\n";
		if ($ConPool{$ClnSock}->{'File'}) { $ConPool{$ClnSock}->{'File'}->close(); };
		delete($ConPool{$ClnSock});
		return;
		};

	if ($ConPool{$ClnSock}->{'File'}) { print {$ConPool{$ClnSock}->{'File'}} localtime()." SERVER $RemoteHost CONNECTED\n"; };

	return 1;
	};

sub SafeStr
	{
	my $Str = shift
		or return '!UNDEF!';
	$Str =~ s{ ([\x00-\x1f\xff]) } { sprintf("\\x%2.2X", ord($1)) }gsex;
	return $Str;
	};

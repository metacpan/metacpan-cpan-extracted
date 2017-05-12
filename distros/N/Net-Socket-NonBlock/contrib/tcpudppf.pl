# TCP-UDP port forwarder with logging
# Works on Win32!

use strict;

use Net::Socket::NonBlock;

my $LocalAddr   = shift
	or die "Usage: $0 <LocalAddr:LocalPort> <RemoteHost:RemotePort>\n";
my $RemoteHost  = shift
	or die "Usage: $0 <LocalAddr:LocalPort> <RemoteHost:RemotePort>\n";

my $SockNest = Net::Socket::NonBlock->new(SelectT    => 0.01,
                                          debug      => $^W,
                                         )
	or die "Error creating sockets nest: $@\n";

# Autoflush on
$| = 1;

my $TcpSrv = $SockNest->Listen(LocalAddr => $LocalAddr,
                               Proto     => 'tcp',
                               Accept    => \&NewTcpCon,
                               Listen    => 10,
                               SitenceT  => 0,
                               ClientsST => 30,
                              )
	or die "Could not listen TCP on \"$LocalAddr\": $@\n";
	
my $UdpSrv = $SockNest->Listen(LocalAddr => $LocalAddr,
                               Proto     => 'udp',
                               SilenceT  => 0,
                              )
	or die "Could not listen UDP on \"$LocalAddr\": $@\n";

my %TcpPool = ();
my @UdpPool = ();

my $UdpPoolSize = 50;
my $UdpReuseTO  = 10;

my $RunIndex = 0;
for(; $RunIndex < $UdpPoolSize; $RunIndex++)
	{
	$UdpPool[$RunIndex]->{'Sock'} = $SockNest->Connect(PeerAddr => $RemoteHost,
	                                                   Proto    => 'udp',)
		or die "Can not create UDP socket: $@\n";

	$UdpPool[$RunIndex]->{'Addr'} = undef;
	$UdpPool[$RunIndex]->{'Port'} = undef;
	$UdpPool[$RunIndex]->{'Time'} = 0;
	};
$RunIndex = 0;

my $PacketsReceived = 0;
my $PacketsSent     = 0;
my $PacketsDrop     = 0;

while($SockNest->IO())
	{
	my $Pstr = '';
	my $ClnSock = undef;
	my $SrvSock = undef;
	while (($ClnSock, $SrvSock) = each(%TcpPool))
		{
		my $Str = undef;
		my $ClientID = sprintf("%15.15s:%-5.5s", $SockNest->PeerAddr($ClnSock), $SockNest->PeerPort($ClnSock));
		while(($Str = $SockNest->Read($ClnSock)) && length($Str))
			{
			$Pstr .= "  $ClientID CLIENT TCP ".SafeStr($Str)."\n";
			$SockNest->Puts($SrvSock, $Str);
			};
		if (!defined($Str))
			{
			my $Info = $SockNest->Properties($SrvSock);
			$SockNest->Close($ClnSock);
			$SockNest->Close($SrvSock);
			delete($TcpPool{$ClnSock});
			$Pstr .= "  $ClientID CLIENT TCP closed. ".$Info->{'BytesIn'}."/".$Info->{'BytesOut'}." bytes in/out. Closing connection.\n";
			next;
			};
		while(($Str = $SockNest->Read($SrvSock)) && length($Str))
			{
			$Pstr .= "  $ClientID SERVER TCP ".SafeStr($Str)."\n";
			$SockNest->Puts($ClnSock, $Str);
			};
		if (!defined($Str))
			{
			my $Info = $SockNest->Properties($ClnSock);
			$SockNest->Close($ClnSock);
			$SockNest->Close($SrvSock);
			delete($TcpPool{$ClnSock});
			$Pstr .= "  $ClientID SERVER TCP closed. ".$Info->{'BytesIn'}."/".$Info->{'BytesOut'}." bytes in/out. Closing connection.\n";
			next;
			};
		};
	
	while(1)
		{
		my @Datagram = $SockNest->Recv($UdpSrv);

		if (!defined($Datagram[0]))
			{ die "Unexpected death of UDP listening socket. Exiting\n"; };
		
		if (!length($Datagram[0]))
			{
			if (length($Datagram[1].$Datagram[2]))
				{
				my $FwdAddr = $Datagram[1].':'.$Datagram[2];
				print STDERR "Empty message for \"$FwdAddr\"\n";
				}
			else
				{
				last;
				};
			};

		$PacketsReceived++;

		my $ClientID = sprintf("%15.15s:%-5.5s", $Datagram[1], $Datagram[2]);
		$Pstr .= "  $ClientID CLIENT UDP ".SafeStr($Datagram[0])."\n";

		my $Age = time() - $UdpPool[$RunIndex]->{'Time'};
		if ($Age > $UdpReuseTO)
			{
			#print STDERR "UdpPool\[$RunIndex\]: age $Age\n";
			my $UdpSock = $UdpPool[$RunIndex]->{'Sock'}
				or die "Undefined socket UdpPool\[$RunIndex\]\n";
			$SockNest->Puts($UdpSock, $Datagram[0]);
			$UdpPool[$RunIndex]->{'Addr'} = $Datagram[1];
			$UdpPool[$RunIndex]->{'Port'} = $Datagram[2];
			$UdpPool[$RunIndex]->{'Time'} = time();
			$RunIndex++;
			($RunIndex < scalar(@UdpPool))
				or $RunIndex = 0;
			}
		else
			{
			$PacketsDrop++;
			print STDERR "UdpPool\[$RunIndex\]: age $Age. Totaly $PacketsDrop packets droped\n";
			};
		};
	
	foreach (@UdpPool)
		{
		my $FwdAddr = $_->{'Addr'}
			or next;
		my $FwdPort = $_->{'Port'}
			or next;
		my $UdpSock = $_->{'Sock'}
			or die "Undefined socket in the UdpPool\n";
		my $ClientID = sprintf("%15.15s:%-5.5s", $FwdAddr, $FwdPort);
		while(1)
			{
			my @Datagram = $SockNest->Recv($UdpSock);

			defined($Datagram[0])
				or die "Unexpected death of UDP pool socket. Exiting\n";

			if (!length($Datagram[0]))
				{ last; };
			
			$Pstr .= "  $ClientID SERVER UDP ".SafeStr($Datagram[0])."\n";
			$SockNest->Puts($UdpSrv, $Datagram[0], $FwdAddr, $FwdPort);

			$PacketsSent++;
			};
		};
	
	if (length($Pstr))
		{ print localtime()."\n".$Pstr; };
	};           	

sub NewTcpCon
	{
	my $ClnSockID = $_[0];

	$TcpPool{$ClnSockID} = $SockNest->Connect(PeerAddr => $RemoteHost,
	                                          SilenceT => 30,
	                                          Proto    => 'tcp',);
	
	if (!defined($TcpPool{$ClnSockID}))
		{
		warn "Can not connect to \"$RemoteHost\" by TCP: $@\n";
		delete($TcpPool{$ClnSockID});
		return;
		};

	return $TcpPool{$ClnSockID};
	};

sub SafeStr
	{
	my $Str = shift
		or return '!UNDEF!';
	$Str =~ s{ ([\x00-\x1f\xff\\]) } { sprintf("\\x%2.2X", ord($1)) }gsex;
	return $Str;
	};


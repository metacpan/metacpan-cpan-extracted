use IO::Socket;
use Net::MDNS::Server ':all';
my $ifc = join "", `/sbin/ifconfig`;
$ifc =~ m/addr:(\d+\.\d+\.\d+\.\d+)/s;
my $ip = $1;
print "Got ip $ip\n";
my $hostname = `hostname`;
chomp $hostname;
print "Got hostname: $hostname\n";

print "Services offered\n";
for my $port (1..7000)
{
my $connection = IO::Socket::INET->new( 
                        Proto     => "tcp",
                        PeerAddr  => 'localhost',
                        PeerPort  => $port,
                   );
                   if ( $connection) 
                   { 
											my $portname = getservbyport($port, "tcp");
											if ( $portname )
											{
												service($hostname, $ip, $port, $portname, "tcp");
											print "Advertising service: $portname for port $port \n";
											}
}

}

while (1)
	{
		process_network_events();
	}

=head1 NAME

mdns_ports - Automatically detects and advertises services to the mDNS network

=head1 SYNOPSIS

	mycomputer:/root# perl ports.pl


=head1 ABSTRACT

	Detects running network services and advertises them to the mDNS network

=head1 DESCRIPTION

	Run this program.  It will scan your local computer (and trigger any portscan detectors you have running).  Then it will answer any multicast DNS queries for that port.  In effect, it advertises your current running network programs using the multicast DNS system.

=head1 SEE ALSO

The RFC is still in draft form, so do a web search for "multicst DNS"

=head1 AUTHOR

Jepri, jepri@perlmonk.org


=head1 COPYRIGHT AND LICENSE

Copyright 2003 by Jepri

This library is free software; you can redistribute it and/or modify
it under the same terms of the GPL. 

=cut

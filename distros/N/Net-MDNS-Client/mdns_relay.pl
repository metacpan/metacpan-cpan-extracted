#!/usr/bin/perl -w

use Net::DNS::Nameserver;
use Net::MDNS::Client ':all';
use strict;

sub reply_handler
	{
		my ($qname, $qclass, $qtype) = @_;
		my ($rcode, @ans, @auth, @add);
			my $query;

	if ($qtype eq "A")
		{
			if ($qname =~ /\.$/ )
				#Query is a fully qualified domain name and we shouldn't tamper.
				{ 
					if ( $qname =~ /local\./)
						#Query is for our domain name
						{$query = $qname;}
					else
						#We can't resolve this one, pass it on
						{
							print "\nQuery is not for us, passing it on\n";
							$rcode = "SERVFAIL";
						        return ($rcode, \@ans, \@auth, \@add);
						}
				}
			else
				{
					if ( $qname =~ /local$/ )
						#Query is for the right domain, but without the final full stop, which we add
						{ $query = $qname."."; }
					else
						#Query might be a hostname, add .local. to the end and try it anyway.
						{ $query = $qname.'.local.'; }
				}
			print "\nSending query !$query! to the multicast network\n";
			query("ip by hostname", $query);
			my $t = time();
			while(time()-$t<1)
				{
					if(process_network_events()) 
						{
							print "Retreiving value for query $query\n";
							my %res = get_ip("ip by hostname", $query);
							print "Found a value:  ", $res{ip}, "\n";
							if ($res{ip})
								{
									print "Found ip !$res{ip}!\n";
									my ($ttl, $rdata) = ($res{ttl}, $res{ip});
									push @ans, Net::DNS::RR->new("$qname $ttl $qclass $qtype $rdata");
									$rcode = "NOERROR";
									#cancel_query($query, "ip by hostname");
									return ($rcode, \@ans, \@auth, \@add);
								}
							}
						}
				}
			my %res = get_ip("ip by hostname", $query);
			if ($res{ip})
				{
					print "Found ip !$res{ip}!\n";
					my ($ttl, $rdata) = ($res{ttl}, $res{ip});
					push @ans, Net::DNS::RR->new("$qname $ttl $qclass $qtype $rdata");
					$rcode = "NOERROR";
					#cancel_query($query, "ip by hostname");
					return ($rcode, \@ans, \@auth, \@add);
				}
			else
				{ print "Unable to get ip address, sending SERVFAIL\n";$rcode = "SERVFAIL"; 
			#cancel_query($query, "ip by hostname");
			return ($rcode, \@ans, \@auth, \@add);}
		}

sub get_ip
	{
		my ($query_type, $query) = @_;
		my %res;
		#Ensure we are at the start of the list
		while (1)
		{
		last unless get_a_result("ip by hostname", $query);
		}
		%res = get_a_result($query_type, $query);
		print "Found a value:  ", join(", ", %res), "\n";
		return %res;
	}

my $ns = Net::DNS::Nameserver->new (
																			LocalPort			=>	53,
																			ReplyHandler	=>	\&reply_handler,
																			Verbose				=>	1,
																		);


if ($ns)
	{$ns->main_loop;}
else
	{die "Couldn't create nameserver object.\n";}

=head1 NAME

mdns_relay - Relays ordinary DNS queries into the multicast DNS system

=head1 SYNOPSIS

	mycomputer:/root# perl mdns_relay.pl


=head1 ABSTRACT

	Relays ordinary DNS queries into the multicast DNS system

=head1 DESCRIPTION

	Run this program as root, and add a line "nameserver 127.0.0.1" to the top of your /etc/resolv.conf file.  The nameserver line must be the first nameserver line in your resolv.conf file.  This program will check the multicast DNS system for the hostname you typed in.  If it can't find it, it will pretend to fail rather than send back a 'not found' error, and your computer will move to the next DNS server.  If a real DNS server is first it will always return a 'not found' error, so your request will never be sent to the multicast DNS system.

=head1 SEE ALSO

The RFC is still in draft form, so do a web search for "multicst DNS"

=head1 AUTHOR

Jepri, jepri@perlmonk.org (Perl and C wrappers)


=head1 COPYRIGHT AND LICENSE

Copyright 2003 by Jepri (wrappers)

This library is free software; you can redistribute it and/or modify
it under the same terms of the GPL. 

=cut

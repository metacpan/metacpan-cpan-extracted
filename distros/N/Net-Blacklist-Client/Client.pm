package Net::Blacklist::Client;

# Many thanks to Asher Blum <asher@wildspark.com> for the original
# Net::RBLClient, from which this module unashamedly steals.

use strict;
use warnings;

use IO::Socket;
use Time::HiRes qw(time);
use Net::DNS::Packet;

use vars qw($VERSION $ip_re $domain_re);
$ip_re = qr(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3});
$domain_re = qr([a-zA-Z0-9-]{1,63}(?:\.[a-zA-Z0-9-]{1,63})*\.[a-zA-Z0-9]{1,6});

$VERSION = '0.3';

sub new {
	my($class, %args) = @_;
	my $self = {
		lists_domain	=> [ lists_domain() ],
		lists_ip		=> [ lists_ip() ],
		query_txt		=> 1,
		max_time		=> 8,
		timeout			=> 1,
		max_hits		=> 1000,
		max_replies		=> 1000,
		udp_maxlen		=> 4000,
		server			=> 'resolv.conf',
	};
	bless($self, $class);

	foreach my $key (keys %args) {
		defined($self->{$key}) or die "Invalid key: $key";
		$self->{$key} = $args{$key}; 
	}

	# Read the contents of resolv.conf and set the server to the first
	# nameserver we find listed, if the server is set to 'resolv.conf'
	if ($self->{server} eq 'resolv.conf'){
		open my $resolv_fh, '/etc/resolv.conf' or die "Can't open resolv.conf: $!";
		local $/;
		my $resolv = <$resolv_fh>;

		if ($resolv =~ /^nameserver\s+($ip_re)/m){
			$self->{server} = $1;
		}else{
			die "No nameserver found in resolv.conf; specify a nameserver IP in constructor";
		}
	}
	return $self;
}

sub lookup_domain{
	my ($self, $domain) = @_;
	die "Do not recognise domain '$domain'" unless $domain =~ /^$domain_re$/;
	return $self->lookup_all(lc($domain), $self->{lists_domain});
}
sub lookup_ip{
	my ($self, $ip) = @_;
	die "Do not recognise IP address '$ip'" unless $ip =~ /^$ip_re$/;
	my $reverse_ip = join '.', reverse split(/\./, $ip);
	return $self->lookup_all($reverse_ip, $self->{lists_ip});
}

sub lookup_all{
	my ($self, $partial, $lists) = @_;
	foreach my $list (@$lists){
		my $query = join '.', ($partial, $list);

		# Send the A lookup
		$self->send_packet_a($query);

		# optionally send the TXT lookup
		if ($self->{query_txt}){
			$self->send_packet_txt($query);
		}
	}
	return $self->collect_responses;
}

sub collect_responses{
	my ($self) = @_;

	my $hits = my $replies = 0;
	my $deadline = time + $self->{max_time};
	my $results = {};

	# Continue receiving packets until:
	# * There are no more pending
	# * The timeout is exceeded
	# * Max hits or max replies are met
	while ($self->{_pending} > 0 && time < $deadline) {
		my $msg = '';
		eval{
			local $SIG{ALRM} = sub{ die "alarm time out" };
			alarm $self->{timeout};
			$self->sock->recv($msg, $self->{udp_maxlen}) || die "recv: $!";
			alarm 0;
			1;
		};
		if ($msg){
			my ($domain, $res, $type) = decode_packet($msg);
			if (defined $type && $type eq 'TXT' && $self->{query_txt}) {
				$results->{$domain}{txt} = $res;
			}elsif ($res){
				$replies++;
				$hits++ if $res;
				if ($self->{query_txt}){
					$results->{$domain}{a} = $res;
				}else{
					$results->{$domain} = $res;
				}
				return 1 if $hits >= $self->{max_hits} ||
							$replies >= $self->{max_replies};
			}
			$self->{_pending}--;
		}
	}
	$self->{_pending} = 0;
	return $results;
}


sub decode_packet{
	# takes a raw DNS response packet
	# returns domain, response
	my $data = shift;
	my $packet = Net::DNS::Packet->new(\$data);
	my @answer = $packet->answer;
	{
		my ($res, $domain, $type);
		foreach my $answer (@answer) {
			{
				# removed $answer->answerfrom because it caused an error
				# with some types of answers

				my $name = lc $answer->name;
				#warn "Packet contained answers to different domains ($domain != $name)"
				#	if defined $domain && $name ne $domain;
				$domain = $name;
			}
			$domain =~ s/^\d+\.\d+\.\d+\.\d+\.//;
			$type = $answer->type;
			$res = $type eq 'A'     ? inet_ntoa($answer->rdata)  :
				   $type eq 'CNAME' ?   cleanup($answer->rdata)  :
				   $type eq 'TXT'   ? (defined $res && "$res; ")
									  . $answer->txtdata         :
				   '?';
			last unless $type eq 'TXT';
		}
		return $domain, $res, $type if defined $res;
	}
	
	# OK, there were no answers -
	# need to determine which domain
	# sent the packet.

	my @question = $packet->question;
	foreach my $question(@question) {
		my $domain = $question->qname;
		$domain =~ s/^\d+\.\d+\.\d+\.\d+\.//;
		return ($domain, undef);
	}
}

sub cleanup {
	# remove control chars and stuff
	$_[ 0 ] =~ tr/a-zA-Z0-9./ /cs;;
	$_[ 0 ];
}


# Packet generation
sub send_packet_a{
	my ($self, $query) = @_;
	$self->send_packet($query, 'A');
}
sub send_packet_txt{
	my ($self, $query) = @_;
	$self->send_packet($query, 'TXT', 'IN');
}
sub send_packet{
	my ($self, $query, @pkt_args) = @_;
	my ($packet, $error) = Net::DNS::Packet->new($query, @pkt_args);
	die "Cannot build DNS query for $query, type $pkt_args[0]: $error" unless $packet;
	$self->sock->send($packet->data) || die "Could not sent $pkt_args[0] packet for query '$query': $!";
	$self->{_pending}++;
}

# returns a UDP socket connected to the specified server
sub sock{
	my ($self) = @_;
	$self->{_sock} ||= IO::Socket::INET->new(
		Proto     => 'udp',
		PeerPort  => 53,
		PeerAddr  => $self->{server},
	) or die "Failed to create UDP client";
	return $self->{_sock};
}


# Lists of lists..

sub lists_domain{
	return qw(
		multi.uribl.com
		multi.surbl.org
	);
}

sub lists_ip{
	return qw(
		0spam.fusionzero.com
		dnsbl.ahbl.org
		opm.blitzed.org
		cbl.abuseat.org
		bl.csma.biz
		sbl.csma.biz
		dnsbl.cyberlogic.net
		bl.deadbeef.com
		spamsources.dnsbl.info
		dnsbl.net.au
		t1.dnsbl.net.au
		dun.dnsrbl.net
		spam.dnsrbl.net
		list.dsbl.org
		unconfirmed.dsbl.org
		multihop.dsbl.org
		spamsources.fabel.dk
		blackholes.five-ten-sg.com
		hil.habeas.com
		blocked.hilli.dk
		blackholes.intersil.net
		ipwhois.rfc-ignorant.org
		dnsbl.jammconsulting.com
		3y.spam.mrs.kithrup.com
		relays.bl.kundenserver.de
		spamguard.leadmon.net
		relays.nether.net
		unsure.nether.net
		combined.njabl.org
		no-more-funn.moensted.dk
		dnsbl.antispam.or.id
		relays.ordb.org
		psbl.surriel.com
		dnsbl.rangers.eu.org
		access.redhawk.org
		dnsbl.regedit64.net
		relays.visi.com
		sbbl.they.com
		sbl.spamhaus.org
		xbl.spamhaus.org
		rbl.snark.net
		dnsbl.solid.net
		dnsbl.sorbs.net
		blacklist.spambag.org
		bl.spamcannibal.org
		bl.spamcop.net
		map.spam-rbl.com
		bl.spamthwart.com
		l1.spews.dnsbl.sorbs.net
		l2.spews.dnsbl.sorbs.net
		block.dnsbl.sorbs.net
		bl.technovision.dk
		blackholes.uceb.org
		dnsbl-1.uceprotect.net
		dnsbl-2.uceprotect.net
		virbl.dnsbl.bit.nl
		vox.schpider.com
		db.wpbl.info
		ubl.unsubscore.com
		dnsbl.tqmcube.com
		abuse.rfc-ignorant.org
		bogusmx.rfc-ignorant.org
		dsn.rfc-ignorant.org
		postmaster.rfc-ignorant.org
		whois.rfc-ignorant.org
		ex.dnsbl.org
		in.dnsbl.org
		unconfirmed.dsbl.org
		list.dsbl.org
	);
}

=head1 NAME

Net::Blacklist::Client - Queries multiple RBLs or URIBLs in parallel.

=head1 SYNOPSIS

	use Net::Blacklist::Client;
	my $rbl = Net::Blacklist::Client->new;
	my $result = $rbl->lookup_ip('127.0.0.2');
	foreach my $list (keys %$result){
		printf "%s: %s (%s)\n", $list, $result->{$list}->{a}, $result->{$list}->{txt};
	}

=head1 DESCRIPTION

This module is used to discover what RBL's are listing a particular IP
address.  It parallelizes requests for fast response.

This module is heavily based on L<Net::RBLClient> by Asher Blum. It adds
an updated list of RBLs and removes many dead ones, the ability to look
up domains in domain-specific RBLs, and changes the output format.
Although it is very similar and does the same job, due to the changes in
the output formats, it is not suitable as a drop-in replacement.

An RBL, or Realtime Blackhole List, is a list of IP addresses meeting some
criteria such as involvement in Unsolicited Bulk Email.  Each RBL has
its own criteria for addition and removal of addresses.  If you want to
block email or other traffic to/from your network based on one or more
RBLs, you should carefully study the behavior of those RBLs before and
during such blocking.

=head1 CONSTRUCTOR

=over 4

=item new( [ARGS] )

Takes an optional hash of arguments:

=over 4

=item lists_ip

An arraref of domains representing IP address RBL root domains. Each element
in the array should be a string representing the root domain for the RBL you
wish to use, for example 'bl.spamcop.net' is the root domain of Spamcop's
blacklist. Use this if you want to query a specific list of RBLs - if this
argument is omitted, a large list of default RBLs is used.

=item lists_domain

Similar to lists_ip, but these are used when querying domains with
lookup_domain. Note that IP and domain RBLs are usually separate, so using
a list of IP RBLs to check domains is a bad plan. Currently, the URIBL and
SURBL services are used by default.

=item query_txt

This option controls whether Net::Blacklist::Client looks up corresponding
TXT records. The TXT record is used by many RBL's store additional
information about the reason for including an IP address or links to pages
that contain such information.

Default: True

=item max_time

The maximum time in seconds that the lookup function should take.  In fact,
the function can take up to C<max_time + timeout> seconds.  Max_time need
not be integer.  Of course, if the lookup returns due to max_time, some
DNS replies will be missed.

Default: 8 seconds.

=item timeout

The maximum time in seconds spent awaiting each DNS reply packet.  The
only reason to change this is if C<max_time> is decreased to a small value.

Default: 1 second.

=item max_hits

A hit is an affirmative response, stating that the IP address is on a certain
list.  If C<max_hits> hits are received, C<lookup()> returns immediately.
This lets the calling program save time.

Default: 1000 (effectively out of the picture).

=item max_replies

A reply from an RBL could be affirmative or negative.  Either way, it counts
towards C<max_replies>.  C<Lookup()> returns when C<max_replies> replies
have been received.

=item udp_maxlen

The maximum number of bytes read from a DNS reply packet.  There's probably
no reason to change this.

Default: 4000

=item server

The local nameserver to use for all queries.  Should be either a resolvable
hostname or a dotted quad IP address.

By default, the first nameserver in /etc/resolv.conf will be used.

=back

=head1 METHODS

=item lookup_ip( IPADDR )

Lookup one IP address on all RBL's previously defined.  The IP address
must be expressed in dotted quad notation, like '1.2.3.4'.  C<lookup_ip>
returns a reference to a hash with each list the IP appears on as keys.
The values depend on the status of the C<query_txt> constructor option, if
it is enabled, than a the value of the hash returned by C<lookup_ip> will
by a hashref with the keys C<a> and C<txt>, containing the A and TXT
records returned by the RBL. If it is disabled then the value is simply
set to the IP address returned by the A record request.

=item lookup_domain( DOMAIN )

Exactly the same as C<lookup_ip>, except it accepts a domain, and uses
a different list of domain-specific RBLs. The hash reference returned is
in exactly the same format.

=back

=head1 AUTHOR

Dan Thomas E<lt>F<dan@cpan.org>E<gt>

Based on L<Net::RBLClient> by Asher Blum E<lt>F<asher@wildspark.com>E<gt>

=head1 COPYRIGHT

Copyright (C) 2007 Dan Thomas. The original Net::RBLClient is Copyright
(C) 2002 Asher Blum. All rights reserved.

This code is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

1;

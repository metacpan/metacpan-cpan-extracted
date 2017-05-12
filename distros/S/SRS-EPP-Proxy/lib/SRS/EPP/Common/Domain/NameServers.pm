package SRS::EPP::Common::Domain::NameServers;
{
  $SRS::EPP::Common::Domain::NameServers::VERSION = '0.22';
}

use Moose::Role;

requires 'make_response';

# Given a list of EPP nameservers, translate it into a list of SRS nameservers
#  If a HostObj is found in the EPP list (which is not supported) then an
#  exception is returned with an appropriate error response that can be returned
#  to the client (created via the required method 'make_response'.
# This might be a slightly unusual interface, but it means the generation of the
#  response is consistent across consumers of this role
# TODO: in hindsight, perhaps we should split this into validate/translate methods,
#  similar to SRS::EPP::Common::Contact
sub translate_ns_epp_to_srs {
	my $self = shift;
	my @ns = @_;

	my @ns_objs;
	foreach my $ns (@ns) {
		unless ($ns->isa('XML::EPP::Domain::HostAttr')) {
			die $self->make_response(
				Error => (
					code => 2102,
					exception => XML::EPP::Error->new(
						value => $ns,
						reason => 'hostObj not supported',
						)
					)
			);
		}

		my $ips = $ns->addrs;

		# We reject any requests that have more than 1 ip address, as the SRS
		#  doesn't really support that (altho an ipv4 and ipv6 address are allowed)
		my %translated_ips;
		foreach my $ip (@$ips) {
			my $type = $ip->ip;
			if ($translated_ips{$type}) {
				die $self->make_response(
					Error => (
						code => 2102,
						exception => XML::EPP::Error->new(
							value => $ns->name,
							reason =>
								'multiple addresses for a nameserver of the same ip version not supported',
							)
						)
				);
			}

			$translated_ips{$type} = $ip->value;
		}

		push @ns_objs, XML::SRS::Server->new(
			fqdn => $ns->name,
			($translated_ips{v4} ? (ipv4_addr => $translated_ips{v4}) : ()),
			($translated_ips{v6} ? (ipv6_addr => $translated_ips{v6}) : ()),
		);
	}

	return @ns_objs;
}

sub translate_ns_srs_to_epp {
	my $self = shift;
	my @ns = @_;

	my @nameservers;
	foreach my $srs_ns (@ns) {
		my ($ipv4addr, $ipv6addr);
		$ipv4addr = XML::EPP::Host::Address->new(
			value => $srs_ns->ipv4_addr,
			ip => 'v4',
		) if $srs_ns->ipv4_addr;

		$ipv6addr = XML::EPP::Host::Address->new(
			value => $srs_ns->ipv6_addr,
			ip => 'v6',
		) if $srs_ns->ipv6_addr;

		push @nameservers, XML::EPP::Domain::HostAttr->new(
			name => $srs_ns->fqdn,
			addrs => [
				$ipv4addr // (),
				$ipv6addr // (),
			],
		);
	}

	return scalar @ns != 1 ? @nameservers : $nameservers[0];

}

1;

package Net::DNS::DomainController::Discovery;

use 5.006;
use strict;
use warnings;
use Carp;

=head1 NAME

Net::DNS::DomainController::Discovery - Discover Microsoft Active Directory domain controllers via DNS queries

=head1 VERSION

Version 1.00

=cut

our $VERSION = '1.00';

=head1 SYNOPSIS

Issues DNS requests to provide a list of hostnames and IP addresses of the Microsoft
Active Directory domain controllers.

    use Net::DNS::DomainController::Discovery;

    my $foo = Net::DNS::DomainController::Discovery::domain_controllers('fabrikam.com');
    ...

Multiple domain names can be specified:

    my $foo = Net::DNS::DomainController::Discovery::domain_controllers('fabrikam.com', 'contoso.com');

This module works only if the Active Directory domain controllers are registed with the domain name system (DNS).

=cut

use Exporter qw(import);
our @EXPORT_OK = qw(domain_controllers srv_to_name srv_fqdn_list fqdn_to_ipaddr);

use Net::DNS::Resolver;

our $TestResolver;

=head2 domain_controllers

Use this function to obtain a list of Active Domain controllers registered in the DNS
for the domain names given as arguments.

Returns a nested array of (domain name, hostname, ip address) tuples that contain all 
the Active Directory domain controllers serving the domain name if registered in the DNS.

If the domain does not contain any Active Domain domain controller service records,
no entries for the domain are returned.

No records are returned for the domain controller names which do resolve neither
to an IPv4 nor IPv6 address.

=cut

sub domain_controllers {

	croak "Active Directory domain name not provided" unless (@_);

	my $resolver;

	# uncoverable branch false
	if (defined $TestResolver) {
		$resolver = $TestResolver;	
	} else {
		$resolver = Net::DNS::Resolver->new();
	}

	my @dc; 
	foreach my $domain_name (@_) {
		foreach my $fqdn (srv_fqdn_list( $resolver, dc_to_srv( $domain_name ))) {
			foreach my $addr (fqdn_ipaddr_list( $resolver, 'AAAA', $fqdn )) {
				push @dc, [ $domain_name, $fqdn, $addr ];
			}
			foreach my $addr (fqdn_ipaddr_list( $resolver, 'A', $fqdn )) {
				push @dc, [ $domain_name, $fqdn, $addr ];
			}
		}
	}
	return @dc;
}
=head1 INTERNAL SUBROUTINES

=head2 srv_to_name

Extract server name from the SRV response.

=cut

sub srv_to_name {
	my $rr = shift;
	if ( ! $rr ) {
		confess "Need Net::DNS::RR record";
	}
	if ( $rr->type ne 'SRV' ) {
		croak "Need Net::DNS::RR::SRV record (got \"". ${rr}->type . "\")";
	}
	return $rr->target;	
}

=head2 srv_fqdn_list

Query SRV records and return server names if any.

=cut

sub srv_fqdn_list {
	my ($resolver, $domain_name) = @_;
	my $resp = $resolver->query( $domain_name, 'SRV' );
	my @dc_name_list;

	if ( $resp ) {
		return map {  srv_to_name($_) }  $resp->answer;
	} else {
		return ();
	}
}

=head2 fqdn_to_ipaddr

Extract IP addresses from the resolver response.

=cut

sub fqdn_to_ipaddr {
	my $rr = shift;
	if ( ! $rr ) {
		confess "Need Net::DNS::RR record";
	}
	if ( $rr->type ne 'A' && $rr->type ne 'AAAA' ) {
		croak "Need Net::DNS::RR::A or AAAA record (got \"" . ${rr}->type . "\")";
	}
	return $rr->address;
}

=head2 fqdn_ipaddr_list

Resolver server names using the appropriate record for the address family requested.
C<$type> parameter should be set C<A> for IPv4, C<AAAA> for IPv6).

=cut

sub fqdn_ipaddr_list {
	my ($resolver, $type, $fqdn) = @_;
	my $resp = $resolver->query( $fqdn, $type );
	my @dc_ip_list;
	
	if ( $resp ) {
		return map {  fqdn_to_ipaddr($_) }  $resp->answer;
	} else {
		return ()
	}
}

=head2 dc_to_srv

Validate the domain name and add the magic string for the Active Directory domain controllers.

=cut

sub dc_to_srv {
	croak "Active Directory domain name not provided" unless (@_);
	croak "Active Directory domain name not defined" unless $_[0];
	croak "Invalid domain name: \"$_[0]\"" unless $_[0] =~ /\A\b((?=[a-z0-9-]{1,63}\.)(xn--)?[a-z0-9]+(-[a-z0-9]+)*\.)+[a-z]{2,63}\Z/;
	return '_ldap._tcp.dc._msdcs.' . $_[0] . '.'
}

=head1 AUTHOR

Marcin CIESLAK, C<< <saperski at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-net-dns-domaincontroller-discovery at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-DNS-DomainController-Discovery>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

Microsoft has a documentation how the Active Directory domain controllers should register themselves in the DNS:

Microsoft Active Directory Technical Specifications [MS-ADTS]
Section 6.3.2.3 SRV Records
Published 14 February 2019 at L<https://docs.microsoft.com/en-us/openspecs/windows_protocols/ms-adts/c1987d42-1847-4cc9-acf7-aab2136d6952>

Archived on 23 March 2020: L<http://archive.today/6NUSR>

You can find documentation for this module with the perldoc command.

    perldoc Net::DNS::DomainController::Discovery

You can also look for information at:

=over 4

=item * Source code repository

L<https://repo.or.cz/Net-DNS-DomainController-Discovery.git>

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Net-DNS-DomainController-Discovery>

=item * CPAN search engine

L<https://metacpan.org/release/Net-DNS-DomainController-Discovery>

=back


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2020 by Marcin CIESLAK.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

1; # End of Net::DNS::DomainController::Discovery

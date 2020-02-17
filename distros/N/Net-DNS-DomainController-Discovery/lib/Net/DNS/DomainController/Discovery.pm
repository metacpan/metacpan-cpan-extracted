package Net::DNS::DomainController::Discovery;

use 5.006;
use strict;
use warnings;
use Carp;

=head1 NAME

Net::DNS::DomainController::Discovery - Discover Microsoft Active Directory domain controllers via DNS queries

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';


=head1 SYNOPSIS

Issues DNS requests to provide a list of hostnames and IP addresses of the Microsoft
Active Directory domain controllers.

    use Net::DNS::DomainController::Discovery;

    my $foo = Net::DNS::DomainController::Discovery->domain_controllers('fabrikam.com');
    ...

=cut

use Exporter qw(import);
our @EXPORT_OK = qw(domain_controllers srv_to_name srv_fqdn_list fqdn_to_ipaddr);

use Net::DNS::Resolver;

our $TestResolver;

=head1 SUBROUTINES/METHODS

=head2 srv_to_name

Extract server name from the SRV response

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

=cut

sub srv_fqdn_list {
	my ($resolver, $domain_name) = @_;
	my $resp = $resolver->query( $domain_name, 'SRV' );
	my @dc_name_list;

	if ( ! $resp ) {
		croak "No SRV records in \"$domain_name\"";
	}
	@dc_name_list = map {  srv_to_name($_) }  $resp->answer;
}

=head2 fqdn_to_ipaddr

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

=cut

sub fqdn_ipaddr_list {
	my ($resolver, $fqdn) = @_;
	my $resp = $resolver->query( $fqdn, 'A' );
	my @dc_ip_list;

	if ( ! $resp ) {
		croak "No A records in \"$fqdn\"";
	}
	@dc_ip_list= map {  fqdn_to_ipaddr($_) }  $resp->answer;
}

=head2 dc_to_srv

=cut

sub dc_to_srv {
	return '_ldap._tcp.dc._msdcs.' . $_[0] . '.'
}

=head2 domain_controllers

=cut

sub domain_controllers {

	croak "Active Directory domain name not provided ($#_)" if $#_ < 1;

	shift;
	my $domain_name = shift;

	my $resolver;
	if (defined $TestResolver) {
		$resolver = $TestResolver;	
	} else {
		$resolver = Net::DNS::Resolver->new();
	}

	my @dc; 
		
	foreach my $fqdn (srv_fqdn_list( $resolver, dc_to_srv( $domain_name ))) {
		foreach my $addr (fqdn_ipaddr_list( $resolver, $fqdn )) {
			push @dc, [ $domain_name, $fqdn, $addr ];
		}
	}
	return @dc;
}

=head1 AUTHOR

Marcin CIESLAK, C<< <saperski at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-net-dns-domaincontroller-discovery at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-DNS-DomainController-Discovery>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::DNS::DomainController::Discovery

You can also look for information at:

=over 4

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

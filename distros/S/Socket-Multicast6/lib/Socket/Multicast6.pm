package Socket::Multicast6;

use strict;
use warnings;
use vars qw(@ISA $VERSION);
use Carp;

our $VERSION = '0.04';

require XSLoader;
XSLoader::load('Socket::Multicast6', $VERSION);

require Exporter;
our @ISA = qw(Exporter);


my @export_ipv4 = qw(
		IP_MULTICAST_IF
		IP_MULTICAST_TTL
		IP_MULTICAST_LOOP
		IP_ADD_MEMBERSHIP
		IP_DROP_MEMBERSHIP
		IP_ADD_SOURCE_MEMBERSHIP
		IP_DROP_SOURCE_MEMBERSHIP
		pack_ip_mreq
		pack_ip_mreq_source
	);

my @export_ipv6 = qw(
		IPV6_MULTICAST_IF
		IPV6_MULTICAST_HOPS
		IPV6_MULTICAST_LOOP
		IPV6_JOIN_GROUP
		IPV6_LEAVE_GROUP
		pack_ipv6_mreq
	);

my @export_independent = qw(
		MCAST_JOIN_GROUP
		MCAST_BLOCK_SOURCE
		MCAST_UNBLOCK_SOURCE
		MCAST_LEAVE_GROUP
		MCAST_JOIN_SOURCE_GROUP
		MCAST_LEAVE_SOURCE_GROUP
	);

our %EXPORT_TAGS = (
	'ipv4' => [ @export_ipv4 ],
	'ipv6' => [ @export_ipv6 ],
	'independent' => [ @export_independent ],
	'all' => [ @export_ipv4, @export_ipv6, @export_independent ],
);


our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = ( );

sub AUTOLOAD {
	# This AUTOLOAD is used to 'autoload' constants from the constant()
	# XS function.  If a constant is not found then control is passed
	# to the AUTOLOAD in AutoLoader.
	
	my $constname;
	our $AUTOLOAD;
	($constname = $AUTOLOAD) =~ s/.*:://;
	croak "&Socket::Multicast6::constant not defined" if $constname eq 'constant';
	my ($error, $val) = constant($constname);
	if ($error) {
		if ($error =~  /is not a valid/) {
			$AutoLoader::AUTOLOAD = $AUTOLOAD;
			goto &AutoLoader::AUTOLOAD;
		} else {
			croak $error;
		}
	}
	no strict 'refs';
	*$AUTOLOAD = sub { $val };
	goto &$AUTOLOAD;
}



1;
__END__

=head1 NAME

Socket::Multicast6 - Constructors and constants for IPv4 and IPv6 multicast socket operations.

=head1 SYNOPSIS

  use Socket::Multicast6 qw(:all);

  my $ip = getprotobyname( 'ip' );
  
  my $ip_mreq = pack_ip_mreq( inet_aton( $mcast_addr ), inet_aton( $if_addr ) );

  my $ipv6_mreq = pack_ipv6_mreq( inet_pton( AF_INET6, $mcast6_addr ), $if_index );

  setsockopt( $sock, $ip, IP_ADD_MEMBERSHIP, $ip_mreq )
    or die( "setsockopt IP_ADD_MEMBERSHIP failed: $!" );

  setsockopt( $sock, $ip, IP_DROP_MEMBERSHIP, $ip_mreq )
    or die( "setsockopt IP_DROP_MEMBERSHIP failed: $!" );

  setsockopt( $sock, $ip, IP_MULTICAST_LOOP, pack( 'C', $loop ) )
    or die( "setsockopt IP_MULTICAST_LOOP failed: $!" );

  setsockopt( $sock, $ip, IP_MULTICAST_TTL, pack( 'C', $ttl ) )
    or die( "setsockopt IP_MULTICAST_TTL failed: $!" );

=head1 DESCRIPTION

This module is used to gain access to constants and utility functions
used when manipulating multicast socket attributes.

For simple, object-oriented way of doing the same thing, take a look 
at L<IO::Socket::Multicast6> or L<IO::Socket::Multicast>.


=head1 EXPORTS

By default nothing is exported, you can use the 'ipv4', 'ipv6' and 'independent' to 
export a specific protocol family, or 'all' to export all symbols.


=head1 FUNCTIONS

=item $ip_mreq = pack_ip_mreq(MCAST_ADDR, IF_ADDR)

=item $ip_mreq_source = pack_ip_mreq_source(MCAST_ADDR, SOURCE_ADDR, IF_ADDR)

=item $ipv6_mreq = pack_ipv6_mreq(MCAST6_ADDR, IF_INDEX)


=head1 CONSTANTS

=over

=item IP_MULTICAST_IF

=item IP_MULTICAST_TTL

=item IP_MULTICAST_LOOP

=item IP_ADD_MEMBERSHIP

=item IP_DROP_MEMBERSHIP

=item IP_ADD_SOURCE_MEMBERSHIP

=item IP_DROP_SOURCE_MEMBERSHIP

=item IPV6_MULTICAST_IF

=item IPV6_MULTICAST_HOPS

=item IPV6_MULTICAST_LOOP

=item IPV6_JOIN_GROUP

=item IPV6_LEAVE_GROUP

=item MCAST_JOIN_GROUP

=item MCAST_BLOCK_SOURCE

=item MCAST_UNBLOCK_SOURCE

=item MCAST_LEAVE_GROUP

=item MCAST_JOIN_SOURCE_GROUP

=item MCAST_LEAVE_SOURCE_GROUP

=back


=head1 SEE ALSO

L<IO::Socket::Multicast6> (The easier, object-oriented way)

=head1 AUTHOR

Based on L<Socket::Multicast> by Jonathan Steinert, E<lt>hachi@cpan.orgE<gt>
Socket::Multicast6 by Nicholas J Humfrey, E<lt>njh@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 Nicholas J Humfrey
Copyright (C) 2006 Jonathan Steinert

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.6.1 or,
at your option, any later version of Perl 5 you may have available.

=cut

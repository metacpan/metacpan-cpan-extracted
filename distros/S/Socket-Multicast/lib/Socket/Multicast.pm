package Socket::Multicast;
use strict;
use warnings;

use Carp;

our $VERSION = '0.01';
our $XS_VERSION = $VERSION;
$VERSION = eval $VERSION;

require XSLoader;
XSLoader::load('Socket::Multicast', $XS_VERSION);

require Exporter;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( 'all' => [ qw(
	IP_MULTICAST_IF
	IP_MULTICAST_TTL
	IP_MULTICAST_LOOP
	IP_ADD_MEMBERSHIP
	IP_DROP_MEMBERSHIP
	pack_ip_mreq
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw();

sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.  If a constant is not found then control is passed
    # to the AUTOLOAD in AutoLoader.

    my $constname;
    our $AUTOLOAD;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    croak "&Socket::Multicast::constant not defined" if $constname eq 'constant';
    my ($error, $val) = constant($constname);
    if ($error) {
	if ($error =~  /is not a valid/) {
	    $AutoLoader::AUTOLOAD = $AUTOLOAD;
	    goto &AutoLoader::AUTOLOAD;
	} else {
	    croak $error;
	}
    }
    {
	no strict 'refs';
	# Fixed between 5.005_53 and 5.005_61
#	if ($] >= 5.00561) {
#	    *$AUTOLOAD = sub () { $val };
#	}
#	else {
	    *$AUTOLOAD = sub { $val };
#	}
    }
    goto &$AUTOLOAD;
}


# Preloaded methods go here.

1;
__END__

=head1 NAME

Socket::Multicast - Constructors and constants for multicast socket operations.

=head1 SYNOPSIS

  use Socket::Multicast qw(:all);

  my $ip = getprotobyname( 'ip' );
  
  my $ip_mreq = pack_ip_mreq( inat_aton( $mcast_addr ), inet_aton( $if_addr ) );

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
used when manipulating multicast socket attributes. This module allows you to do
the same things as IO::Socket::Multicast, but this is the long way.

=head1 FUNCTIONS

=head2 IP_MREQ = pack_ip_mreq MCAST_ADDR, IF_ADDR

=head1 CONSTANTS

=head2 IP_MULTICAST_IF

=head2 IP_MULTICAST_TTL

=head2 IP_MULTICAST_LOOP

=head2 IP_ADD_MEMBERSHIP

=head2 IP_DROP_MEMBERSHIP

=head1 SEE ALSO

IO::Socket::Multicast (The fast way)

=head1 AUTHOR

Jonathan Steinert, E<lt>hachi@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Jonathan Steinert

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut

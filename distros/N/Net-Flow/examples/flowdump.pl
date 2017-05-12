use strict;
use warnings;

use Net::Flow qw(decode);
use Net::Flow::Constants qw(
	%informationElementsByName
	%informationElementsById
);
use IO::Socket::INET;

my $receive_port = 4739;				# IPFIX port
my $packet;
my %TemplateArrayRefs;
my $sock = IO::Socket::INET->new(
	LocalPort => $receive_port,
	Proto     => 'udp'
);

my $sender;
while ( $sender = $sock->recv( $packet, 0xFFFF ) ) {
	my ($sender_port, $sender_addr) = unpack_sockaddr_in($sender);
	$sender_addr = inet_ntoa($sender_addr);

	my ( $HeaderHashRef, $FlowArrayRef, $ErrorsArrayRef ) = ();

	# template ids are per src, destination, and observation domain.
	# Ideally the module will handle this, but the current API doesn't
	# really allow for this.  For now you are on your own.
	my ($version, $observationDomainId, $sourceId) = unpack('nx10N2', $packet);
	my $stream_id;
	if ($version == 9) {
		$stream_id = "$sender_port, $sender_addr, $sourceId";
	} else {
		$stream_id = "$sender_port, $sender_addr, $observationDomainId";
	}
	$TemplateArrayRefs{$stream_id} ||= [];
	my $TemplateArrayRef = $TemplateArrayRefs{$stream_id};
	( $HeaderHashRef, $TemplateArrayRef, $FlowArrayRef, $ErrorsArrayRef ) = Net::Flow::decode( \$packet, $TemplateArrayRef );

	grep { print "$_\n" } @{$ErrorsArrayRef} if ( @{$ErrorsArrayRef} );

	print "\n- Header Information -\n";
	foreach my $Key ( sort keys %{$HeaderHashRef} ) {
		printf ' %s = %3d' . "\n", $Key, $HeaderHashRef->{$Key};
	}

	foreach my $TemplateRef ( @{$TemplateArrayRef} ) {
		print "\n-- Template Information --\n";

		foreach my $TempKey ( sort keys %{$TemplateRef} ) {
			if ( $TempKey eq 'Template' ) {
				printf '  %s = ' . "\n", $TempKey;
				foreach my $Ref ( @{ $TemplateRef->{Template} } ) {
					foreach my $Key ( keys %{$Ref} ) {
						printf '   %s=%s', $Key, $Ref->{$Key};
					}
					print "\n";
				}
			} else {
				printf '  %s = %s' . "\n", $TempKey, $TemplateRef->{$TempKey};
			}
		}
	}

	foreach my $FlowRef ( @{$FlowArrayRef} ) {
		print "\n-- Flow Information --\n";

		foreach my $Id ( sort keys %{$FlowRef} ) {
			my $name = $informationElementsById{$Id}->{name} // "$Id";
			if ( $Id eq 'SetId' ) {
				print "  $Id=$FlowRef->{$Id}\n" if defined $FlowRef->{$Id};
			} elsif ( ref $FlowRef->{$Id} ) {
				printf '  Id=%s Value=', $name;
				foreach my $Value ( @{ $FlowRef->{$Id} } ) {
					printf '%s,', unpack( 'H*', $Value );
				}
				print "\n";
			} else {
				printf '  Id=%s Value=%s' . "\n", $name, unpack( 'H*', $FlowRef->{$Id} );
			}
		}
	}
}


1;

__END__


# Local Variables: ***
# mode:CPerl ***
# cperl-indent-level:2 ***
# perl-indent-level:2 ***
# tab-width: 2 ***
# indent-tabs-mode: t ***
# End: ***
#
# vim: ts=2 sw=2 noexpandtab

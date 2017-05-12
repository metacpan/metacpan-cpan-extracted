use strict;
use warnings;
use Net::Flow qw(decode encode);
use Net::Flow::Constants qw(
	%informationElementsByName
	%informationElementsById
);
use IO::Socket::INET;

my $receive_port = 2055;
my $send_port    = 4739;				# IPFIX port

sub get_IE_id { return $informationElementsByName{$_[0]}->{elementId}; }

my $packet;
my $TemplateRef;
my $MyTemplateRef = {
	SetId      => 0,
	TemplateId => 300,
	Template   => [
		{ Length => 4, Id  => get_IE_id( 'sourceIPv4Address' )},
		{ Length => 4, Id  => get_IE_id( 'destinationIPv4Address' )},
		{ Length => 4, Id  => get_IE_id( 'packetDeltaCount' )},
		{ Length => 4, Id  => get_IE_id( 'octetDeltaCount' )},
		{ Length => 2, Id  => get_IE_id( 'sourceTransportPort' )},
		{ Length => 2, Id  => get_IE_id( 'destinationTransportPort' )},
		{ Length => 1, Id  => get_IE_id( 'protocolIdentifier' )},
		{ Length => 1, Id  => get_IE_id( 'ipClassOfService' )},
		{ Length => 4, Id  => 34},    # samplingInterval  (not in IANA)
		{ Length => 4, Id  => 35},    # samplingAlgorithm (not in IANA)
	],
};

my @MyTemplates = ($MyTemplateRef);

my $EncodeHeaderHashRef = {
	SourceId   => 0,    # optional
	VersionNum => 9,
};

my $r_sock = IO::Socket::INET->new(
	LocalPort => $receive_port,
	Proto     => 'udp'
);

my $s_sock = IO::Socket::INET->new(
	PeerAddr => '127.0.0.1',
	PeerPort => $send_port,
	Proto    => 'udp'
);

while ( $r_sock->recv( $packet, 0xFFFF ) ) {

	my $PktsArrayRef;

	my ( $HeaderHashRef, undef, $FlowArrayRef, $ErrorsArrayRef ) = Net::Flow::decode( \$packet, undef );
	$HeaderHashRef->{SamplingInterval} //= 0;
	$HeaderHashRef->{SamplingMode} //= 0;

	grep { print "$_\n" } @{$ErrorsArrayRef} if ( @{$ErrorsArrayRef} );

	foreach my $HashRef ( @{$FlowArrayRef} ) {
		$HashRef->{SetId} = 300;
		$HashRef->{'34'} = pack( 'N', $HeaderHashRef->{SamplingInterval} );
		$HashRef->{'35'} = pack( 'N', $HeaderHashRef->{SamplingMode} );
	}

	$EncodeHeaderHashRef->{SysUpTime} = $HeaderHashRef->{SysUpTime};
	$EncodeHeaderHashRef->{UnixSecs}  = $HeaderHashRef->{UnixSecs};

	( $EncodeHeaderHashRef, $PktsArrayRef, $ErrorsArrayRef )
		= Net::Flow::encode( $EncodeHeaderHashRef, \@MyTemplates, $FlowArrayRef, 1400 );

	grep { print "$_\n" } @{$ErrorsArrayRef} if ( @{$ErrorsArrayRef} );

	foreach my $Ref ( @{$PktsArrayRef} ) {
		$s_sock->send($$Ref);
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

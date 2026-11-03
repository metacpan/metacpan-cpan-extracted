package TestCerts;

# Makes a CA and certificates signed by it for tests, written as PEM
# files in a directory.

use strict;
use warnings;
use IO::Socket::SSL::Utils qw(CERT_create PEM_cert2file PEM_key2file PEM_cert2string);

# Writes ca.pem, then for each name given, $name.pem, $name.key, and
# $name-chain.pem with the CA after it. Each name is a hash ref of
# name, days it is good for, and names it covers.
#
# Returns a hash ref of name to the path without the extension.
sub make {
	my ( $dir, @certs ) = @_;

	my ( $ca_cert, $ca_key )
		= CERT_create( CA => 1, subject => { commonName => 'Test CA' }, not_after => time + 86400 * 365 );
	PEM_cert2file( $ca_cert, $dir . '/ca.pem' );
	my %paths = ( ca => $dir . '/ca' );
	foreach my $cert (@certs) {
		my ( $leaf_cert, $leaf_key ) = CERT_create(
			subject         => { commonName => $cert->{names}[0] },
			subjectAltNames => [ map { /\A[0-9.]+\z/ ? [ IP => $_ ] : [ DNS => $_ ] } @{ $cert->{names} } ],
			issuer          => [ $ca_cert, $ca_key ],
			not_after       => time + 86400 * $cert->{days} + 3600,
			purpose         => 'server',
		);
		my $path = $dir . '/' . $cert->{name};
		PEM_cert2file( $leaf_cert, $path . '.pem' );
		PEM_key2file( $leaf_key, $path . '.key' );
		chmod( 0600, $path . '.key' );
		open( my $fh, '>', $path . '-chain.pem' ) or die($!);
		print $fh PEM_cert2string($leaf_cert) . PEM_cert2string($ca_cert);
		close($fh);
		$paths{ $cert->{name} } = $path;
	} ## end foreach my $cert (@certs)

	return \%paths;
} ## end sub make

1;

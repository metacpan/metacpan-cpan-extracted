package Net::ACME2::Challenge::tls_alpn_01;

use strict;
use warnings;

=encoding utf-8

=head1 NAME

Net::ACME2::Challenge::tls_alpn_01

=head1 DESCRIPTION

This module is instantiated by L<Net::ACME2::Authorization> and is a
subclass of L<Net::ACME2::Challenge>.

This module is EXPERIMENTAL, subject to finalization of the challenge
method described at L<https://datatracker.ietf.org/doc/draft-ietf-acme-tls-alpn/>.

=cut

use parent qw( Net::ACME2::Challenge );

use constant {
    _VALIDITY_DELTA => 2 * 86400,
};

=head1 METHODS

=head2 I<CLASS>->KEY()

Returns the private key (in PEM format) that is used to sign the
certificates that this module generates. The key does not need to be kept
secret; it’s just here because TLS implementations want it.

=cut

# NB: tls-alpn-01 doesn’t set any requirement for the key that signs
# the certificate. prime256v1 will get us the smallest certificate in
# the least amount of time. There’s no need to protect the key itself.
use constant KEY => <<END;
-----BEGIN PRIVATE KEY-----
MIGHAgEAMBMGByqGSM49AgEGCCqGSM49AwEHBG0wawIBAQQg+ja8vtIRQUTb11MC
elKer3JSgd3SYqNuSpQO+wTSkLGhRANCAATM+733J/pbsQASVQm08GoqHX4B7TKS
jijjtiQfzx/O9Dbr982LcWk1eaiYL/s3gzy5zodiIWu82PmorYkyJzLf
-----END PRIVATE KEY-----
END

# This will depend on the key length.
use constant _SIGNATURE_ALGORITHM => 'sha256';

=head2 I<OBJ>->create_certificate( $ACME, $DOMAIN )

Returns an X.509 certificate that you can use to complete the challenge.

The certificate is given in PEM encoding; L<Crypt::Format> can easily
convert it to DER if you prefer.

=cut

sub create_certificate {
    my ($self, $acme, $domain) = @_;

    die "Need a domain!" if !$domain;

    require Crypt::Perl::PK;
    require Crypt::Perl::X509v3;
    require Digest::SHA;

    my $priv_key = Crypt::Perl::PK::parse_key( KEY() );

    my $now = time;

    my $key_authz = $acme->make_key_authorization($self);

    my $key_authz_sha = Digest::SHA::sha256($key_authz);

    my @name = ( [ commonName => $domain ] );

    my $cert = Crypt::Perl::X509v3->new(
        key => $priv_key->get_public_key(),
        subject => \@name,
        issuer => \@name,
        not_after => $now + _VALIDITY_DELTA(),
        not_before => $now - _VALIDITY_DELTA(),
        extensions => [
            [ subjectAltName => [ dNSName => $domain ] ],
            [ 'acmeValidation-v1' => Digest::SHA::sha256($key_authz) ],
        ],
    );

    $cert->sign( $priv_key, _SIGNATURE_ALGORITHM() );

    return $cert->to_pem();
}

1;

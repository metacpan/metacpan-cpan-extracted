package Net::OAuth::SignatureMethod::RSA_SHA1;
use warnings;
use strict;
use MIME::Base64;

# RFC 5849 3.4.3 mandates RSASSA-PKCS1-v1_5 with SHA-1. Crypt::OpenSSL::RSA
# defaults have drifted (SHA-256 since 0.29_01, PSS padding since 0.35), so
# pin both rather than inheriting whatever the installed version prefers.
sub _apply_rfc5849_defaults {
    my $key = shift;
    for my $method (qw(use_sha1_hash use_pkcs1_padding)) {
        next unless UNIVERSAL::can($key, $method);
        eval { $key->$method; 1 }
            or die "Your Crypt::OpenSSL::RSA cannot do $method, which OAuth "
                 . "RSA-SHA1 requires (RFC 5849 3.4.3): $@";
    }
    return $key;
}

sub sign {
    my $self = shift;
    my $request = shift;
	my $key = shift || $request->signature_key;
    die '$request->signature_key must be an RSA key object (e.g. Crypt::OpenSSL::RSA) that can sign($text)'
        unless UNIVERSAL::can($key, 'sign');
    _apply_rfc5849_defaults($key);
    return encode_base64($key->sign($request->signature_base_string), "");
}

sub verify {
    my $self = shift;
    my $request = shift;
    my $key = shift || $request->signature_key;
    die 'You must pass an RSA key object (e.g. Crypt::OpenSSL::RSA) that can verify($text,$sig)'
        unless UNIVERSAL::can($key, 'verify');
    _apply_rfc5849_defaults($key);
    return $key->verify($request->signature_base_string, decode_base64($request->signature));
}

=head1 NAME

Net::OAuth::SignatureMethod::RSA_SHA1 - RSA_SHA1 Signature Method for OAuth protocol

=head1 SEE ALSO

L<Net::OAuth>, L<http://oauth.net>

=head1 AUTHOR

Originally by Keith Grennan <foss@nearlyfree.org>

Currently maintained by Robert Rothenberg <perl@rhizomnic.com>

=head1 COPYRIGHT & LICENSE

Copyright 2007-2012, 2024-2026 Keith Grennan

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;

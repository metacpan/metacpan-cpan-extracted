package Net::OAuth::SignatureMethod::HMAC_SHA256;

use warnings;
use strict;

use base 'Net::OAuth::SignatureMethod';

use Carp;
use Digest::SHA  ();
use MIME::Base64 ();

sub sign {
    my $self = shift;
    my $request = shift;
    croak "Cannot use a blank signature_key" unless length( $request->signature_key || "" ) > 0;
    my $hmac_digest = Digest::SHA::hmac_sha256(
        $request->signature_base_string, $request->signature_key
    );
    return MIME::Base64::encode_base64($hmac_digest, '');
}

sub verify {
    my $self = shift;
    my $request = shift;
    return $self->secure_compare( $request->signature, $self->sign($request) );
}

=head1 NAME

Net::OAuth::SignatureMethod::HMAC_SHA256 - HMAC_SHA256 Signature Method for OAuth protocol

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

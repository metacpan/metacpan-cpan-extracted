use strict;
use warnings;
package Net::SAML2::Binding::POST;

use Moose;

our $VERSION = '0.49';

# ABSTRACT: Net::SAML2::Binding::POST - HTTP POST binding for SAML


use Net::SAML2::XML::Sig;
use MIME::Base64 qw/ decode_base64 /;
use Crypt::OpenSSL::Verify;


has 'cert_text' => (isa => 'Str', is => 'ro');
has 'cacert' => (isa => 'Maybe[Str]', is => 'ro');


sub handle_response {
    my ($self, $response) = @_;

    # unpack and check the signature
    my $xml = decode_base64($response);
    my $xml_opts = { x509 => 1 };
    $xml_opts->{ cert_text } = $self->cert_text if ($self->cert_text);
    $xml_opts->{ exclusive } = 1;
    $xml_opts->{ no_xml_declaration } = 1;
    my $x = Net::SAML2::XML::Sig->new($xml_opts);
    my $ret = $x->verify($xml);
    die "signature check failed" unless $ret;

    if ($self->cacert) {
        my $cert = $x->signer_cert
            or die "Certificate not provided and not in SAML Response, cannot validate";

        my $ca = Crypt::OpenSSL::Verify->new($self->cacert, { strict_certs => 0, });
        if ($ca->verify($cert)) {
            return sprintf("%s (verified)", $cert->subject);
        } else {
            return 0;
        }
    }

    return 1;
}

__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::SAML2::Binding::POST - Net::SAML2::Binding::POST - HTTP POST binding for SAML

=head1 VERSION

version 0.49

=head1 SYNOPSIS

  my $post = Net::SAML2::Binding::POST->new(
    cacert => '/path/to/ca-cert.pem'
  );
  my $ret = $post->handle_response(
    $saml_response
  );

=head1 NAME

Net::SAML2::Binding::POST - HTTP POST binding for SAML2

=head1 METHODS

=head2 new( )

Constructor. Returns an instance of the POST binding.

Arguments:

=over

=item B<cacert>

path to the CA certificate for verification

=back

=head2 handle_response( $response )

Decodes and verifies the response provided, which should be the raw
Base64-encoded response, from the SAMLResponse CGI parameter.

=head1 AUTHOR

Chris Andrews  <chrisa@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Chris Andrews and Others, see the git log.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

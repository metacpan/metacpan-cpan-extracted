use strict;
use warnings;
package Net::SAML2::Binding::POST;
our $VERSION = '0.74'; # VERSION

use Moose;
use Carp qw(croak);

# ABSTRACT: HTTP POST binding for SAML


use Net::SAML2::XML::Sig;
use MIME::Base64 qw/ decode_base64 /;
use Crypt::OpenSSL::Verify;
use MIME::Base64;
use URI::Escape;

with 'Net::SAML2::Role::VerifyXML';


has 'cert_text' => (isa => 'Str', is => 'ro');
has 'cacert' => (isa => 'Maybe[Str]', is => 'ro');

has 'cert' => (isa => 'Str', is => 'ro', required => 0, predicate => 'has_cert');
has 'key'  => (isa => 'Str', is => 'ro', required => 0, predicate => 'has_key');


sub handle_response {
    my ($self, $response) = @_;

    # unpack and check the signature
    my $xml = decode_base64($response);

    $self->verify_xml(
        $xml,
        no_xml_declaration => 1,
        $self->cert_text ? (
            cert_text => $self->cert_text
        ) : (),
        $self->cacert ? (
            cacert => $self->cacert
        ) : (),

    );
    return $xml;
}


sub sign_xml {
    my ($self, $request) = @_;

    croak("Need to have a cert specified") unless $self->has_cert;
    croak("Need to have a key specified") unless $self->has_key;

    my $signer = XML::Sig->new({
                        key => $self->key,
                        cert => $self->cert,
                        no_xml_declaration => 1,
                    }
                );

    my $signed_message = $signer->sign($request);

    # saml-schema-protocol-2.0.xsd Schema hack
    #
    # The real fix here is to fix XML::Sig to accept a XPATH to
    # place the signature in the correct location.  Or use XML::LibXML
    # here to do so
    #
    # The protocol schema defines a sequence which requires the order
    # of the child elements in a Protocol based message:
    #
    # The dsig:Signature (should it exist) MUST follow the saml:Issuer
    #
    # 1: saml:Issuer
    # 2: dsig:Signature
    #
    # Seems like an oversight in the SAML schema specifiation but...

    $signed_message =~ s!(<dsig:Signature.*?</dsig:Signature>)!!s;
    my $signature = $1;
    $signed_message =~ s/(<\/saml\d*:Issuer>)/$1$signature/;

    my $encoded_request = encode_base64($signed_message, "\n");

    return $encoded_request;

}
__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::SAML2::Binding::POST - HTTP POST binding for SAML

=head1 VERSION

version 0.74

=head1 SYNOPSIS

  my $post = Net::SAML2::Binding::POST->new(
    cacert => '/path/to/ca-cert.pem'
  );
  my $xml = $post->handle_response(
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

    my $xml = $self->handle_response($response);

Decodes and verifies the Base64-encoded SAMLResponse CGI parameter.
Returns the decoded response as XML.

=head2 sign_xml( $request )

Sign and encode the SAMLRequest.

=head1 AUTHORS

=over 4

=item *

Chris Andrews  <chrisa@cpan.org>

=item *

Timothy Legge <timlegge@gmail.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by Venda Ltd, see the CONTRIBUTORS file for others.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

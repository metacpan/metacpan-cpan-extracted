use strict;
use warnings;
package Net::SAML2::Binding::POST;
our $VERSION = '0.64'; # VERSION

use Moose;

# ABSTRACT: Net::SAML2::Binding::POST - HTTP POST binding for SAML


use Net::SAML2::XML::Sig;
use MIME::Base64 qw/ decode_base64 /;
use Crypt::OpenSSL::Verify;

with 'Net::SAML2::Role::VerifyXML';


has 'cert_text' => (isa => 'Str', is => 'ro');
has 'cacert' => (isa => 'Maybe[Str]', is => 'ro');


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

__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::SAML2::Binding::POST - Net::SAML2::Binding::POST - HTTP POST binding for SAML

=head1 VERSION

version 0.64

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

package Net::SAML2::Binding::POST;
use Moose;
use MooseX::Types::Moose qw/ Str /;

=head1 NAME

Net::SAML2::Binding::POST - HTTP POST binding for SAML2

=head1 SYNOPSIS

  my $post = Net::SAML2::Binding::POST->new;
  my $ret = $post->handle_response(
    $saml_response
  );

=head1 METHODS

=cut

use Net::SAML2::XML::Sig;
use MIME::Base64 qw/ decode_base64 /;
use Crypt::OpenSSL::VerifyX509;

=head2 new()

Constructor. Returns an instance of the POST binding. 

No arguments.

=cut

has 'cacert' => (isa => Str, is => 'ro', required => 1);

=head2 handle_response($response)

Decodes and verifies the response provided, which should be the raw
Base64-encoded response, from the SAMLResponse CGI parameter. 

=cut

sub handle_response {
    my ($self, $response) = @_;

    # unpack and check the signature
    my $xml = decode_base64($response);
    my $x = Net::SAML2::XML::Sig->new({ x509 => 1 });
    my $ret = $x->verify($xml);
    die "signature check failed" unless $ret;

    # verify the signing certificate
    my $cert = $x->signer_cert;
    my $ca = Crypt::OpenSSL::VerifyX509->new($self->cacert);
    $ret = $ca->verify($cert);

    if ($ret) {
        return sprintf("%s (verified)", $cert->subject);
    }
    return;
}

__PACKAGE__->meta->make_immutable;

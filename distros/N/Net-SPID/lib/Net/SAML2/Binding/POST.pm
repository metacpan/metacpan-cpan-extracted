package Net::SAML2::Binding::POST;
$Net::SAML2::Binding::POST::VERSION = '0.12';
use strict;
use warnings;

use Moose;
use MooseX::Types::Moose qw/ Str /;


use Net::SAML2::XML::Sig;
use MIME::Base64 qw/ decode_base64 /;
use Crypt::OpenSSL::VerifyX509;


has 'cert_text' => (isa => Str, is => 'ro', required => 0);
has 'cacert' => (isa => 'Maybe[Str]', is => 'ro', required => 0);


sub handle_response {
    my ($self, $response) = @_;

    # unpack and check the signature
    my $xml = decode_base64($response);
    my $xml_opts = { x509 => 1 };
    $xml_opts->{ cert_text } = $self->cert_text if ($self->cert_text);
    my $x = Net::SAML2::XML::Sig->new($xml_opts);
    my $ret = $x->verify($xml);
    die "signature check failed" unless $ret;
    
    if ($self->cacert) {
        my $cert = $x->signer_cert
            or die "Certificate not provided and not in SAML Response, cannot validate";
    
        my $ca = Crypt::OpenSSL::VerifyX509->new($self->cacert);
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

Net::SAML2::Binding::POST

=head1 VERSION

version 0.12

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

Alessandro Ranellucci <aar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Alessandro Ranellucci.

This is free software, licensed under:

  The (three-clause) BSD License

=cut

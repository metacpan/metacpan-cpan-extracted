package Net::SAML2::Binding::Redirect;
$Net::SAML2::Binding::Redirect::VERSION = '0.12';
use strict;
use warnings;

use Moose;
use MooseX::Types::Moose qw/ Str /;
use MooseX::Types::URI qw/ Uri /;


use MIME::Base64 qw/ encode_base64 decode_base64 /;
use IO::Compress::RawDeflate qw/ rawdeflate /;
use IO::Uncompress::RawInflate qw/ rawinflate /;
use URI;
use URI::QueryParam;
use Crypt::OpenSSL::RSA;
use Crypt::OpenSSL::X509;
use File::Slurp qw/ read_file /;


has 'key'   => (isa => Str, is => 'ro', required => 1);
has 'cert'  => (isa => Str, is => 'ro', required => 1);
has 'url'   => (isa => Uri, is => 'ro', required => 1, coerce => 1);
has 'param' => (isa => Str, is => 'ro', required => 1);


sub sign {
    my ($self, $request, $relaystate) = @_;

    my $input = "$request";
    my $output = '';

    rawdeflate \$input => \$output;
    my $req = encode_base64($output, '');

    my $u = URI->new($self->url);
    $u->query_param($self->param, $req);
    $u->query_param('RelayState', $relaystate) if defined $relaystate;
    $u->query_param('SigAlg', 'http://www.w3.org/2000/09/xmldsig#rsa-sha1');

    my $key_string = read_file($self->key);
    my $rsa_priv = Crypt::OpenSSL::RSA->new_private_key($key_string);

    my $to_sign = $u->query;
    my $sig = encode_base64($rsa_priv->sign($to_sign), '');
    $u->query_param('Signature', $sig);

    my $url = $u->as_string;
    return $url;
}


sub verify {
    my ($self, $url) = @_;
    my $u = URI->new($url);
        
    # verify the response
    my $sigalg = $u->query_param('SigAlg');
    die "can't verify '$sigalg' signatures"
         unless $sigalg eq 'http://www.w3.org/2000/09/xmldsig#rsa-sha1';

    my $cert = Crypt::OpenSSL::X509->new_from_string($self->cert);
    my $rsa_pub = Crypt::OpenSSL::RSA->new_public_key($cert->pubkey);
        
    my $sig = decode_base64($u->query_param_delete('Signature'));
    my $signed = $u->query;
    die "bad sig" unless $rsa_pub->verify($signed, $sig);

    # unpack the SAML request
    my $deflated = decode_base64($u->query_param($self->param));
    my $request = '';
    rawinflate \$deflated => \$request;
        
    # unpack the relaystate
    my $relaystate = $u->query_param('RelayState');

    return ($request, $relaystate);
}

__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::SAML2::Binding::Redirect

=head1 VERSION

version 0.12

=head1 SYNOPSIS

  my $redirect = Net::SAML2::Binding::Redirect->new(
    key => 'sign-nopw-cert.pem',
    url => $sso_url,
    param => 'SAMLRequest',
    cacert => '/path/to/cac-cert.pem'
  );

  my $url = $redirect->sign($authnreq);

  # or

  my $redirect = Net::SAML2::Binding::Redirect->new(
    cert => $idp_cert,
    param => 'SAMLResponse',
  );
 
  my $ret = $redirect->verify($url);

=head1 NAME

Net::SAML2::Binding::Redirect

=head1 METHODS

=head2 new( ... )

Constructor. Creates an instance of the Redirect binding. 

Arguments:

=over

=item B<key>

signing key (for creating Redirect URLs)

=item B<cert>

IdP's signing cert (for verifying Redirect URLs)

=item B<url>

IdP's SSO service url for the Redirect binding

=item B<param>

query param name to use (SAMLRequest, SAMLResponse)

=back

=head2 sign( $request, $relaystate )

Signs the given request, and returns the URL to which the user's
browser should be redirected.

Accepts an optional RelayState parameter, a string which will be
returned to the requestor when the user returns from the
authentication process with the IdP.

=head2 verify( $url )

Decode a Redirect binding URL. 

Verifies the signature on the response.

=head1 AUTHOR

Alessandro Ranellucci <aar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Alessandro Ranellucci.

This is free software, licensed under:

  The (three-clause) BSD License

=cut

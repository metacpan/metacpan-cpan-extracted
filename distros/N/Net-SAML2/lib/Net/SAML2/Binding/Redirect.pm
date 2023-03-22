package Net::SAML2::Binding::Redirect;
use Moose;

our $VERSION = '0.67'; # VERSION

use Carp qw(croak);
use Crypt::OpenSSL::RSA;
use Crypt::OpenSSL::X509;
use File::Slurper qw/ read_text /;
use IO::Compress::RawDeflate qw/ rawdeflate /;
use IO::Uncompress::RawInflate qw/ rawinflate /;
use MIME::Base64 qw/ encode_base64 decode_base64 /;
use MooseX::Types::URI qw/ Uri /;
use Net::SAML2::Types qw(signingAlgorithm SAMLRequestType);
use URI::Encode qw/uri_decode/;
use URI::Escape qw(uri_unescape);
use URI::QueryParam;
use URI;

# ABSTRACT: Net::SAML2::Binding::Redirect - HTTP Redirect binding for SAML



has 'cert' => (isa => 'ArrayRef[Str]', is => 'ro', required => 0, predicate => 'has_cert');
has 'url'  => (isa => Uri, is => 'ro', required => 0, coerce => 1, predicate => 'has_url');
has 'key'  => (isa => 'Str', is => 'ro', required => 0, predicate => 'has_key');

has 'insecure'  => (isa => 'Bool', is => 'ro', default => 0 );

has 'param' => (
    isa      => SAMLRequestType,
    is       => 'ro',
    required => 0,
    default  => 'SAMLRequest'
);

has 'sig_hash' => (
    isa      => signingAlgorithm,
    is       => 'ro',
    required => 0,
    default  => 'sha1'
);

has debug => (
   is => 'ro',
   isa => 'Bool',
   required => 0,
);


sub BUILD {
    my $self = shift;

    if ($self->param eq 'SAMLRequest') {
        croak("Need to have an URL specified") unless $self->has_url;
        croak("Need to have a key specified") unless $self->has_key || $self->insecure;
    }
    elsif ($self->param eq 'SAMLResponse') {
        croak("Need to have a cert specified") unless $self->has_cert;
    }
}

# BUILDARGS

# Earlier versions expected the cert to be a string.  However, metadata
# can include multiple signing certificates so the $idp->cert is now
# expected to be an arrayref to the certificates.  To avoid breaking existing
# applications this changes the the cert to an arrayref if it is not
# already an array ref.

around BUILDARGS => sub {
    my $orig = shift;
    my $self = shift;

    my %params = @_;
    if ($params{cert} && ref($params{cert}) ne 'ARRAY') {
            $params{cert} = [$params{cert}];
    }

    return $self->$orig(%params);
};


sub get_redirect_uri {
    my $self    = shift;
    my $request = shift;

    if (!defined $request) {
        croak("Unable to create redirect URI without a request");
    }

    my $relaystate = shift;

    my $input  = "$request";
    my $output = '';

    rawdeflate \$input => \$output;
    my $req = encode_base64($output, '');

    my $uri = URI->new($self->url);
    $uri->query_param($self->param, $req);
    $uri->query_param('RelayState', $relaystate) if defined $relaystate;

    return $uri->as_string if $self->insecure;
    return $self->_sign_redirect_uri($uri);
}

sub _sign_redirect_uri {
    my $self = shift;
    my $uri  = shift;

    my $key_string = read_text($self->key);
    my $rsa_priv = Crypt::OpenSSL::RSA->new_private_key($key_string);

    my $method = "use_" . $self->sig_hash . "_hash";
    $rsa_priv->$method;

    $uri->query_param('SigAlg',
        $self->sig_hash eq 'sha1'
        ? 'http://www.w3.org/2000/09/xmldsig#rsa-sha1'
        : 'http://www.w3.org/2001/04/xmldsig-more#rsa-' . $self->sig_hash);

    my $to_sign = $uri->query;
    my $sig = encode_base64($rsa_priv->sign($to_sign), '');
    $uri->query_param('Signature', $sig);
    return $uri->as_string;
}


sub sign {
    my $self = shift;

    if ($self->insecure) {
        croak("Cannot sign an insecure request!");
    }

    return $self->get_redirect_uri(@_);
}


sub verify {
    my ($self, $url) = @_;

    # This now becomes the query string
    $url =~ s#^.*\?##;

    my %params = map { split(/=/, $_, 2) } split(/&/, $url);

    my $sigalg = uri_unescape($params{SigAlg});

    my $encoded_sig = uri_unescape($params{Signature});
    my $sig = decode_base64($encoded_sig);

    my @signed_parts;
    for my $p ($self->param, qw(RelayState SigAlg)) {
        push @signed_parts, join('=', $p, $params{$p}) if exists $params{$p};
    }
    my $signed = join('&', @signed_parts);

    $self->_verify($sigalg, $signed, $sig);

    # unpack the SAML request
    my $deflated = decode_base64(uri_unescape($params{$self->param}));
    my $request = '';
    rawinflate \$deflated => \$request;

    # unpack the relaystate
    my $relaystate = uri_unescape($params{'RelayState'});
    return ($request, $relaystate);
}

sub _verify {
    my ($self, $sigalg, $signed, $sig) = @_;

    foreach my $crt (@{$self->cert}) {
        my $cert = Crypt::OpenSSL::X509->new_from_string($crt);
        my $rsa_pub = Crypt::OpenSSL::RSA->new_public_key($cert->pubkey);

        if ($sigalg eq 'http://www.w3.org/2001/04/xmldsig-more#rsa-sha256') {
            $rsa_pub->use_sha256_hash;
        } elsif ($sigalg eq 'http://www.w3.org/2001/04/xmldsig-more#rsa-sha224') {
            $rsa_pub->use_sha224_hash;
        } elsif ($sigalg eq 'http://www.w3.org/2001/04/xmldsig-more#rsa-sha384') {
            $rsa_pub->use_sha384_hash;
        } elsif ($sigalg eq 'http://www.w3.org/2001/04/xmldsig-more#rsa-sha512') {
            $rsa_pub->use_sha512_hash;
        } elsif ($sigalg eq 'http://www.w3.org/2000/09/xmldsig#rsa-sha1') {
            $rsa_pub->use_sha1_hash;
        }
        else {
            warn "Unsupported Signature Algorithim: $sigalg, defaulting to sha256" if $self->debug;
        }

        return 1 if $rsa_pub->verify($signed, $sig);

        warn "Unable to verify with " . $cert->subject if $self->debug;
    }

    croak("Unable to verify the XML signature");
}

__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::SAML2::Binding::Redirect - Net::SAML2::Binding::Redirect - HTTP Redirect binding for SAML

=head1 VERSION

version 0.67

=head1 SYNOPSIS

  my $redirect = Net::SAML2::Binding::Redirect->new(
    key     => '/path/to/SPsign-nopw-key.pem',		# Service Provider (SP) private key
    url     => $sso_url,							# Service Provider Single Sign Out URL
    param   => 'SAMLRequest' OR 'SAMLResponse',		# Type of request
    cert    => $idp->cert('signing')				# Identity Provider (IdP) certificate
    sig_hash => 'sha1', 'sha224', 'sha256', 'sha384', 'sha512'  # Signature to sign request
  );

  my $url = $redirect->sign($authnreq);

  my $ret = $redirect->verify($url);

=head1 METHODS

=head2 new( ... )

Constructor. Creates an instance of the Redirect binding.

Arguments:

=over

=item B<key>

The SP's (Service Provider) also known as your application's signing key
that your application uses to sign the AuthnRequest.  Some IdPs may not
verify the signature.

Usually required when B<param> is C<SAMLRequest>.

If you don't want to sign the request, you can pass C<< insecure => 1
>> and not provide a key; in this case, C<sign> will return a
non-signed URL.

=item B<cert>

IdP's (Identity Provider's) certificate that is used to verify a signed
Redirect from the IdP.  It is used to verify the signature of the Redirect
response.
Required with B<param> being C<SAMLResponse>.

=item B<url>

IdP's SSO (Single Sign Out) service url for the Redirect binding
Required with B<param> being C<SAMLRequest>.

=item B<param>

query param name to use (SAMLRequest, SAMLResponse)
Defaults to C<SAMLRequest>.

=item B<sig_hash>

RSA hash to use to sign request

Supported:

sha1, sha224, sha256, sha384, sha512

Defaults to C<sha1>.

=item B<debug>

Output extra debugging information

=back

=for Pod::Coverage BUILD

=head2 get_redirect_uri($authn_request, $relaystate)

Get the redirect URI for a given request, and returns the URL to which the
user's browser should be redirected.

Accepts an optional RelayState parameter, a string which will be
returned to the requestor when the user returns from the
authentication process with the IdP.

The request is signed unless the the object has been instantiated with
C<<insecure => 1>>.

=head2 sign( $request, $relaystate )

Signs the given request, and returns the URL to which the user's
browser should be redirected.

Accepts an optional RelayState parameter, a string which will be
returned to the requestor when the user returns from the
authentication process with the IdP.

Returns the signed (or unsigned) URL for the SAML2 redirect

=head2 verify( $query_string )

Decode a Redirect binding URL.

Verifies the signature on the response.

Requires the *raw* query string to be passed, because L<URI> parses and
re-encodes URI-escapes in uppercase (C<%3f> becomes C<%3F>, for instance),
which leads to signature verification failures if the other party uses lower
case (or mixed case).

Returns an ARRAY of containing the verified request and relaystate (if it exists).
Croaks on errors.

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

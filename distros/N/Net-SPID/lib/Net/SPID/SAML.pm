package Net::SPID::SAML;
$Net::SPID::SAML::VERSION = '0.12';
use Moo;

use Carp;
use MIME::Base64 qw(decode_base64);
use Net::SAML2;
use Net::SPID::SAML::Assertion;
use Net::SPID::SAML::AuthnRequest;
use Net::SPID::SAML::IdP;
use Net::SPID::SAML::LogoutRequest;
use Net::SPID::SAML::LogoutResponse;
use URI::Escape qw(uri_escape);

has 'sp_entityid'   => (is => 'ro', required => 1);
has 'sp_key_file'   => (is => 'ro', required => 1);
has 'sp_cert_file'  => (is => 'ro', required => 1);
has 'sp_acs_url'    => (is => 'ro', required => 0);
has 'sp_acs_index'  => (is => 'ro', required => 0);
has 'sp_attr_index' => (is => 'ro', required => 0);
has 'cacert_file'   => (is => 'ro', required => 0);
has '_idp'          => (is => 'ro', default => sub { {} });
has '_sp'           => (is => 'lazy');

extends 'Net::SPID';

sub _build__sp {
    my ($self) = @_;
    
    return Net::SAML2::SP->new(
        id               => $self->sp_entityid,
        url              => 'xxx',
        key              => $self->sp_key_file,
        cert             => $self->sp_cert_file,
        cacert           => $self->cacert_file,
        org_name         => 'xxx',
        org_display_name => 'xxx',
        org_contact      => 'xxx',
    );
}

# TODO: generate the actual SPID button.
sub get_button {
    my ($self, $url_cb) = @_;
    
    # If $url_cb is a sprintf pattern, turn it into a callback.
    if (!ref $url_cb) {
        my $pattern = $url_cb;
        $url_cb = sub {
            sprintf $pattern, uri_escape(shift);
        };
    }
    
    my $html = '';
    foreach my $idp_id (sort keys %{$self->_idp}) {
        $html .= sprintf qq!<p><a href="%s">Log In (%s)</a></p>\n!,
            $url_cb->($idp_id), $idp_id;
    }
    return $html;
}

sub load_idp_metadata {
    my ($self, $dir) = @_;
    
    $self->load_idp_from_xml_file($_) for glob "$dir/*.xml";
}

sub load_idp_from_xml_file {
    my ($self, $xml_file) = @_;
    
    # slurp XML from file
    my $xml = do { local $/ = undef; open my $fh, '<', $xml_file; scalar <$fh> };
    
    return $self->load_idp_from_xml($xml);
}

sub load_idp_from_xml {
    my ($self, $xml) = @_;
    
    my $idp = Net::SPID::SAML::IdP->new_from_xml(
        _spid   => $self,
        xml     => $xml,
        cacert  => $self->cacert_file,
    );
    $self->_idp->{$idp->entityid} = $idp;
    
    if ($self->cacert_file) {
        # TODO: verify IdP certificate and return 0 if invalid
    }
    
    # Since we only support HTTP-Redirect SSO and SLO requests, warn user if the loaded
    # Identity Provider does not expose such bindings (they are not mandatory).
    warn sprintf "IdP '%s' does not have a HTTP-Redirect SSO binding", $idp->entityid,
        if !$idp->sso_url('urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect');
    warn sprintf "IdP '%s' does not have a HTTP-Redirect SLO binding", $idp->entityid,
        if !$idp->slo_url('urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect');
    
    return 1;
}

sub idps {
    my ($self) = @_;
    
    return $self->_idp;
}

sub get_idp {
    my ($self, $idp_entityid) = @_;
    
    return $self->_idp->{$idp_entityid};
}

sub parse_assertion {
    my ($self, $payload, $in_response_to) = @_;
    
    my $xml = decode_base64($payload);
    print STDERR $xml;
    
    # verify signature and CA
    my $post = Net::SAML2::Binding::POST->new(
        cacert => $self->cacert_file,
    );
    $post->handle_response($payload)
        or croak "Failed to parse SAML LogoutResponse";
    
    # parse assertion
    my $assertion = Net::SAML2::Protocol::Assertion->new_from_xml(
        xml => $xml,
    );
    
    my $a = Net::SPID::SAML::Assertion->new(
        _spid       => $self,
        _assertion  => $assertion,
        xml         => $xml,
    );
    
    # Validate audience and timestamps. This will throw an exception in case of failure.
    $a->validate($in_response_to);
    
    return $a;
}

sub parse_logoutresponse {
    my ($self, $payload, $in_response_to) = @_;
    
    my $xml = decode_base64($payload);
    print STDERR $xml;
    
    # verify signature and CA
    my $post = Net::SAML2::Binding::POST->new(
        cacert => $self->cacert_file,
    );
    $post->handle_response($payload)
        or croak "Failed to parse SAML LogoutResponse";
    
    # parse message
    my $response = Net::SAML2::Protocol::LogoutResponse->new_from_xml(
        xml => $xml,
    );
    
    # validate response
    croak "Invalid SAML LogoutResponse"
        if !$response->valid($in_response_to);
    
    return Net::SPID::SAML::LogoutResponse->new(
        _spid       => $self,
        _logoutres  => $response,
        xml         => $xml,
    );
}

sub parse_logoutrequest {
    my ($self, $payload) = @_;
    
    my $xml = decode_base64($payload);
    print STDERR $xml;
    
    # verify signature and CA
    my $post = Net::SAML2::Binding::POST->new(
        cacert => $self->cacert_file,
    );
    $post->handle_response($payload)
        or croak "Failed to parse SAML LogoutResponse";
    
    # parse message
    my $request = Net::SAML2::Protocol::LogoutRequest->new_from_xml(
        xml => $xml,
    );
    
    return Net::SPID::SAML::LogoutRequest->new(
        _spid       => $self,
        _logoutreq  => $request,
        xml         => $xml,
    );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::SPID::SAML

=head1 VERSION

version 0.12

=head1 SYNOPSIS

    use Net::SPID;
    
    my $spid = Net::SPID->new(
        sp_entityid     => 'https://www.prova.it/',
        sp_key_file     => 'sp.key',
        sp_cert_file    => 'sp.pem',
    );
    
    # load Identity Providers
    $spid->load_idp_metadata('idp_metadata/');
    # or:
    $spid->load_idp_from_xml_file('idp_metadata/prova.xml');
    # or:
    $spid->load_idp_from_xml($metadata_xml);
    
    # generate an AuthnRequest
    my $authnreq = $idp->authnrequest(
        acs_index   => 0,   # index of AssertionConsumerService as per our SP metadata
        attr_index  => 1,   # index of AttributeConsumingService as per our SP metadata
        level       => 1,   # SPID level
    );
    
    # prepare a HTTP-Redirect binding
    my $url = $authnreq->redirect_url;

=head1 ABSTRACT

This Perl module is aimed at implementing SPID Service Providers and Attribute Authorities. L<SPID|https://www.spid.gov.it/> is the Italian digital identity system, which enables citizens to access all public services with single set of credentials. This module provides a layer of abstraction over the SAML protocol by exposing just the subset required in order to implement SPID authentication in a web application. In addition, it will be able to generate the HTML code of the SPID login button and enable developers to implement an Attribute Authority.

This module is not bound to any particular web framework, so you'll have to do some plumbing yourself in order to route protocol messages over HTTP (see the F<example/> directory for a full working example).
On top of this module, plugins for web frameworks can be developed in order to achieve even more API abstraction.

See L<README.md> for a full feature list with details about SPID compliance.

=head1 CONSTRUCTOR

The preferred way to instantiate this class is to call C<Net::SPID->new(protocol => 'saml', ...)> instead of calling C<Net::SPID::SAML->new(...)> directly.

=head2 new

=over

=item I<sp_entityid>

(Required.) The entityID value for this Service Provider. According to SPID regulations, this should be a URI.

=item I<sp_key_file>

(Required.) The absolute or relative file path to our private key file.

=item I<sp_cert_file>

(Required.) The absolute or relative file path to our certificate file.

=item I<sp_acs_url>

(Optional.) The default value to use for C<AssertionConsumerServiceURL> in AuthnRequest. This is the URL where the user will be redirected (via GET or POST) by the Identity Provider after Single Sign-On. This must be one of the URLs contained in our Service Provider metadata. Note that this can be overridden using the L</acs_url> argument when generating the AuthnRequest. Using this default value is only convenient when you have a simple application that only exposes a single C<AssertionConsumerService>.

=item I<sp_acs_index>

(Optional.) The default value to use for C<AssertionConsumerServiceIndex> in AuthnRequest. As an alternative to specifying the URL explicitely in each AuthnRequest using L<sp_acs_url> or L<acs_url>, a numeric index referring to the URL(s) specified in the Service Provider metadata can be supplied. Note that this can be overridden using the L</acs_index> argument when generating the AuthnRequest. Using this default value is only convenient when you have a simple application that only exposes a single C<AssertionConsumerService>.

=item I<sp_attr_index>

(Optional.) The default value to use for C<AttributeConsumingServiceIndex> in AuthnRequest. This refers to the C<AttributeConsumingService> specified in the Service Provider metadata. Note that this can be overridden using the L</attr_index> argument when generating the AuthnRequest. Using this default value is only convenient when you have a simple application that only uses a single C<AttributeConsumingService>.

=back

=head1 METHODS

=head2 get_button

This method generates the HTML markup for the SPID login button:

    my $html = $spid->get_button(sub {
        return '/spid-login?idp=' . $_[0];
    });
    my $html = $spid->get_button('/spid-login?idp=%s');

The first argument can be a subroutine which will get passed the clicked IdP entityID and will need to return the full URL. As an alternative a string can be supplied, which will be handled as a format argument for a C<sprintf()> call.

=head2 load_idp_metadata

This method accepts the absolute or relative path to a directory and loads one or multiple Identity Providers by reading all its files having a C<.xml> suffix.

    $spid->load_idp_metadata('idp_metadata/');

=head2 load_idp_from_xml_file

This method accepts the absolute or relative path to a XML file containing metadata of an Identity Provider and loads it.

    $spid->load_idp_from_xml_file('idp_metadata/prova.xml');

=head2 load_idp_from_xml

This method accepts a scalar containing the XML metadata of an Identity Provider and loads it. This is useful in case you store metadata in a database.

    $spid->load_idp_from_xml($xml);

=head2 idps

This method returns a hashref of loaded Identity Providers as L<Net::SPID::SAML::IdP> objects, having their C<entityID>s as keys.

    my %idps = %{$spid->idps};

=head2 get_idp

This method accepts an entityID and returns the corresponding L<Net::SPID::SAML::IdP> object if any, or undef.

    my $idp = $spid->get_idp('https://www.prova.it/');

=head2 parse_assertion

This method accepts a XML payload and parses it as a Response/Assertion, returning a L<Net::SPID::SAML::Assertion> object. Validation is performed (see the documentation for the L<Net::SPID::SAML::Assertion/validate> method), so this method may throw an exception.
A second argument can be supplied, containing the C<ID> of the request message; in this case validation will also check the C<InResponseTo> attribute.

    my $assertion = $spid->parse_assertion($xml, $request_id);

=head2 parse_logoutresponse

This method accepts a XML payload and parses it as a LogoutResponse, returning a L<Net::SPID::SAML::LogoutResponse> object. Validation is performed, so this method may throw an exception.
A second argument can be supplied, containing the C<ID> of the request message; in this case validation will also check the C<InResponseTo> attribute.

    my $response = $spid->parse_logoutresponse($xml, $request_id);

=head2 parse_logoutrequest

This method accepts a XML payload and parses it as a LogoutRequest, returning a L<Net::SPID::SAML::LogoutRequest>. Use this to handle third-party-initiated logout procedures. Validation is performed, so this method may throw an exception.

    my $request = $spid->parse_logoutrequest($xml);

=head1 AUTHOR

Alessandro Ranellucci <aar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Alessandro Ranellucci.

This is free software, licensed under:

  The (three-clause) BSD License

=cut

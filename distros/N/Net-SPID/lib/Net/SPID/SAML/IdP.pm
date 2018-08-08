package Net::SPID::SAML::IdP;
$Net::SPID::SAML::IdP::VERSION = '0.15';
use Moo;

has '_spid' => (is => 'ro', required => 1, weak_ref => 1);  # Net::SPID::SAML

has 'xml'           => (is => 'ro', required => 1);
has 'entityID'      => (is => 'ro', required => 1);
has 'cert'          => (is => 'ro', required => 1);
has 'sso_urls'      => (is => 'ro', default => sub { {} });
has 'sloreq_urls'   => (is => 'ro', default => sub { {} });
has 'slores_urls'   => (is => 'ro', default => sub { {} });

use Carp;
use Crypt::OpenSSL::X509;
use Mojo::XMLSig;
use XML::XPath;

sub new_from_xml {
    my ($class, %args) = @_;

    my $xpath = XML::XPath->new(xml => $args{xml});
    $xpath->set_namespace('md', 'urn:oasis:names:tc:SAML:2.0:metadata');
    $xpath->set_namespace('ds', 'http://www.w3.org/2000/09/xmldsig#');
    
    if ($xpath->findnodes('/md:EntityDescriptor/dsig:Signature')->size > 0) {
        # TODO: validate certificate against a known CA
        Mojo::XMLSig::verify($args{xml})
            or croak "Signature verification failed";
    }
    
    $args{entityID} = $xpath->findvalue('/md:EntityDescriptor/@entityID')->value;
    
    $args{sso_urls} //= {};
    for my $sso ($xpath->findnodes('/md:EntityDescriptor/md:IDPSSODescriptor/md:SingleSignOnService')){
        my $binding = $sso->getAttribute('Binding');
        $args{sso_urls}{$binding} = $sso->getAttribute('Location');
    }

    $args{sloreq_urls} //= {};
    $args{slores_urls} //= {};
    for my $slo ($xpath->findnodes('/md:EntityDescriptor/md:IDPSSODescriptor/md:SingleLogoutService')) {
        my $binding = $slo->getAttribute('Binding');
        $args{sloreq_urls}{$binding} = $slo->getAttribute('Location');
        $args{slores_urls}{$binding} = $slo->getAttribute('Location') // $slo->getAttribute('ResponseLocation');
    }
    
    for my $certnode ($xpath->findnodes('/md:EntityDescriptor/md:IDPSSODescriptor/md:KeyDescriptor[@use="signing"]/ds:KeyInfo/ds:X509Data/ds:X509Certificate/text()')) {
        my $cert = $certnode->getValue;
        
        # rewrap the base64 data from the metadata; it may not
        # be wrapped at 64 characters as PEM requires
        $cert =~ s/\s//g;
        $cert = join "\n", $cert =~ /.{1,64}/gs;
        
        # form a PEM certificate
        $args{cert} = Crypt::OpenSSL::X509->new_from_string(
            "-----BEGIN CERTIFICATE-----\n$cert\n-----END CERTIFICATE-----\n",
            Crypt::OpenSSL::X509::FORMAT_PEM,
        );
    }

    return $class->new(%args);
}

sub authnrequest {
    my ($self, %args) = @_;
    
    return Net::SPID::SAML::Out::AuthnRequest->new(
        _spid       => $self->_spid,
        _idp        => $self,
        %args,
    );
}

sub logoutrequest {
    my ($self, %args) = @_;
    
    return Net::SPID::SAML::Out::LogoutRequest->new(
        _spid       => $self->_spid,
        _idp        => $self,
        %args,
    );
}

sub logoutresponse {
    my ($self, %args) = @_;
    
    return Net::SPID::SAML::Out::LogoutResponse->new(
        _spid       => $self->_spid,
        _idp        => $self,
        %args,
    );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::SPID::SAML::IdP

=head1 VERSION

version 0.15

=head1 SYNOPSIS

    use Net::SPID;
    
    # get an IdP
    my $idp = $spid->get_idp('https://www.prova.it/');
    
    # generate an AuthnRequest
    my $authnreq = $idp->authnrequest(
        #acs_url    => 'https://...',   # URL of AssertionConsumerServiceURL to use
        acs_index   => 0,   # index of AssertionConsumerService as per our SP metadata
        attr_index  => 1,   # index of AttributeConsumingService as per our SP metadata
        level       => 1,   # SPID level
    );

    # generate a LogoutRequest
    my $logoutreq = $idp->logoutrequest(session => $spid_session);
    
    # generate a LogoutResponse
    my $logoutres = $idp->logoutresponse(in_response_to => $logoutreq->id, status => 'success');

=head1 ABSTRACT

This class represents an Identity Provider.

=head1 CONSTRUCTOR

=head2 new_from_xml

This constructor takes the metadata in XML form and parses it into a Net::SPID::SAML::IdP object:

    my $idp = Net::SPID::SAML::IdP->new_from_xml(xml => $xml);

If the metadata is signed, this method will croak in case the signature is not valid.

Note that you don't usually need to construct this object manually. You load metadata using the methods offered by L<Net::SPID::SAML> and then you retrieve the IdP you need using L<Net::SPID::SAML/get_idp>.

=head1 METHODS

=head2 authnrequest

This method generates an AuthnRequest addressed to this Identity Provider. Note that this method does not perform any network call, it just generates a L<Net::SPID::SAML::Out::AuthnRequest> object.

    my $authnrequest = $idp->authnrequest(
        #acs_url    => 'https://...',   # URL of AssertionConsumerServiceURL to use
        acs_index   => 0,   # index of AssertionConsumerService as per our SP metadata
        attr_index  => 1,   # index of AttributeConsumingService as per our SP metadata
        level       => 1,   # SPID level
    );

The following arguments can be supplied to C<authnrequest()>:

=over

=item I<acs_url>

The value to use for C<AssertionConsumerServiceURL> in AuthnRequest. This is the URL where the user will be redirected (via GET or POST) by the Identity Provider after Single Sign-On. This should be one of the URLs configured in the L<Net::SPID/sp_assertionconsumerservice> parameter at initialization time, otherwise the Response will not be validated. If omitted, the first configured one will be used.

=item I<acs_index>

The value to use for C<AssertionConsumerServiceIndex> in AuthnRequest. As an alternative to specifying the URL explicitely in each AuthnRequest using L<acs_url>, a numeric index referring to the URL(s) specified in the Service Provider metadata can be supplied. Make sure the corresponding URL is listed in the L<Net::SPID/sp_assertionconsumerservice> parameter, otherwise the response will not be validated.

=item I<attr_index>

(Optional.) The value to use for C<AttributeConsumingServiceIndex> in AuthnRequest. This refers to the C<AttributeConsumingService> specified in the Service Provider metadata. If omitted, no attributes will be requested at all.

=item I<level>

(Optional.) The SPID level requested (as an integer; can be 1, 2 or 3). If omitted, 1 will be used.

=back

=head2 logoutrequest

This method generates a LogoutRequest addressed to this Identity Provider. Note that this method does not perform any network call, it just generates a L<Net::SPID::SAML::LogoutRequest> object.

    my $logoutreq = $idp->logoutrequest(session => $spid_session);

The following arguments can be supplied to C<logoutrequest()>:

=over

=item I<session_index>

The L<Net::SPID::Session> object (originally returned by L<Net::SPID::SAML/parse_response> through a L<Net::SPID::SAML::In::Response> object) representing the SPID session to close.

=back

=head2 logoutresponse

This method generates a LogoutResponse addressed to this Identity Provider. You usually need to generate a LogoutResponse when user initiated a logout on another Service Provider (or from the Identity Provider itself) and thus you got a LogoutRequest from the Identity Provider. Note that this method does not perform any network call, it just generates a L<Net::SPID::SAML::LogoutResponse> object.

    my $logoutres = $idp->logoutresponse(
        status          => 'success',
        in_response_to  => $logoutreq->id,
    );

The following arguments can be supplied to C<logoutresponse()>:

=over

=item I<status>

This can be either C<success>, C<partial>, C<requester> or C<responder> according to the SAML specs.

=back

=head2 cert

Returns the signing certificate for this Identity Provider as a L<Crypt::OpenSSL::X509> object.

=head2 xml

Returns the XML representation of this Identity Provider's metadata.

=head2 entityID

Returns the entityID of this Identity Provider.

=head2 sso_urls

Hashref of SingleSignOnService bindings, whose keys are the binding methods (C<urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST> or C<urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect>) and values contain the URLs.

=head2 sloreq_urls

Hashref of SingleLogoutService bindings to be used for sending C<LogoutRequest> messages. Keys are the binding methods (C<urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST> or C<urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect>) and values contain the URLs.

=head2 slores_urls

Hashref of SingleLogoutService bindings to be used for sending C<LogoutResponse> messages. Keys are the binding methods (C<urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST> or C<urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect>) and values contain the URLs.

=head1 AUTHOR

Alessandro Ranellucci <aar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Alessandro Ranellucci.

This is free software, licensed under:

  The (three-clause) BSD License

=cut

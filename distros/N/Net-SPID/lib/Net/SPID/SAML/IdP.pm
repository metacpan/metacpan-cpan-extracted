package Net::SPID::SAML::IdP;
$Net::SPID::SAML::IdP::VERSION = '0.12';
use Moo;

extends 'Net::SAML2::IdP';
has '_spid' => (is => 'ro', required => 1, weak_ref => 1);  # Net::SPID::SAML

use Carp;

sub authnrequest {
    my ($self, %args) = @_;
    
    my $authnreq = $self->_spid->_sp->authn_request(
        $self->sso_url('urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect'),
        $self->format,  # always urn:oasis:names:tc:SAML:2.0:nameid-format:transient
    );
    
    if (defined $args{acs_url} || defined $self->_spid->sp_acs_url) {
        $authnreq->assertion_url($args{acs_url} // $self->_spid->sp_acs_url);
    } elsif (defined $args{acs_index} || defined $self->_spid->sp_acs_index) {
        $authnreq->assertion_index($args{acs_index} // $self->_spid->sp_acs_index);
    } else {
        croak "sp_acs_url or sp_acs_index are required\n";
    }
    
    if (defined $args{attr_index} || defined $self->_spid->sp_attr_index) {
        $authnreq->attribute_index($args{attr_index} // $self->_spid->sp_attr_index);
    }
    
    $authnreq->protocol_binding('HTTP-POST');
    $authnreq->issuer_namequalifier($self->_spid->sp_entityid);
    $authnreq->issuer_format('urn:oasis:names:tc:SAML:2.0:nameid-format:entity');
    $authnreq->nameidpolicy_format('urn:oasis:names:tc:SAML:2.0:nameid-format:transient');
    $authnreq->AuthnContextClassRef([ 'https://www.spid.gov.it/SpidL' . ($args{level} // 1) ]);
    $authnreq->RequestedAuthnContext_Comparison($args{comparison} // 'minimum');
    $authnreq->ForceAuthn(1) if ($args{level} // 1) > 1;
    
    return Net::SPID::SAML::AuthnRequest->new(
        _spid       => $self->_spid,
        _idp        => $self,
        _authnreq   => $authnreq,
    );
}

sub logoutrequest {
    my ($self, %args) = @_;
    
    my $req = $self->_spid->_sp->logout_request(
        $self->sso_url('urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect'),
        $args{session}->nameid,
        $self->format,  # always urn:oasis:names:tc:SAML:2.0:nameid-format:transient
        $args{session}->session,
    );
    
    return Net::SPID::SAML::LogoutRequest->new(
        _spid       => $self->_spid,
        _idp        => $self,
        _logoutreq  => $req,
    );
}

sub logoutresponse {
    my ($self, %args) = @_;
    
    my $res = $self->_spid->_sp->logout_response(
        # FIXME: what is the correct Destination for a LogoutResponse?
        $self->sso_url('urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST'),
        'success',
        $args{in_response_to},
    );
    
    if ($args{status} && $args{status} eq 'partial') {
        $res->status($res->status_uri('requester'));
        $res->substatus($res->status_uri('partial'));
    }
    
    return Net::SPID::SAML::LogoutResponse->new(
        _spid       => $self->_spid,
        _idp        => $self,
        _logoutres  => $res,
    );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::SPID::SAML::IdP

=head1 VERSION

version 0.12

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

This method is not supposed to be instantiated directly. Use the C<Net::SPID::SAML/get_idp> method in L<Net::SPID::SAML>.

=head1 METHODS

=head2 authnrequest

This method generates an AuthnRequest addressed to this Identity Provider. Note that this method does not perform any network call, it just generates a L<Net::SPID::SAML::AuthnRequest> object.

    my $authnrequest = $idp->authnrequest(
        #acs_url    => 'https://...',   # URL of AssertionConsumerServiceURL to use
        acs_index   => 0,   # index of AssertionConsumerService as per our SP metadata
        attr_index  => 1,   # index of AttributeConsumingService as per our SP metadata
        level       => 1,   # SPID level
    );

The following arguments can be supplied to C<authnrequest()>:

=over

=item I<acs_url>

The value to use for C<AssertionConsumerServiceURL> in AuthnRequest. This is the URL where the user will be redirected (via GET or POST) by the Identity Provider after Single Sign-On. This must be one of the URLs contained in our Service Provider metadata. This is required if L<acs_index> is not set, but it can be omitted if the L<Net::SPID/sp_acs_url> option was set in L<Net::SPID>.

=item I<acs_index>

The value to use for C<AssertionConsumerServiceIndex> in AuthnRequest. As an alternative to specifying the URL explicitely in each AuthnRequest using L<acs_url>, a numeric index referring to the URL(s) specified in the Service Provider metadata can be supplied. It can be omitted if the L<Net::SPID/sp_acs_index> option was set in L<Net::SPID>. This is required if L<acs_url> is not set, but it can be omitted if the L<Net::SPID/acs_index> option was set in L<Net::SPID>.

=item I<attr_index>

(Optional.) The value to use for C<AttributeConsumingServiceIndex> in AuthnRequest. This refers to the C<AttributeConsumingService> specified in the Service Provider metadata. If omitted, the L<Net::SPID/sp_attr_index> option set in L<Net::SPID> will be used. If that was not set, no attributes will be requested at all.

=item I<level>

(Optional.) The SPID level requested (as an integer; can be 1, 2 or 3). If omitted, 1 will be used.

=back

=head2 logoutrequest

This method generates a LogoutRequest addressed to this Identity Provider. Note that this method does not perform any network call, it just generates a L<Net::SPID::SAML::LogoutRequest> object.

    my $logoutreq = $idp->logoutrequest(session => $spid_session);

The following arguments can be supplied to C<logoutrequest()>:

=over

=item I<session>

The L<Net::SPID::Session> object (originally returned by L<Net::SPID::SAML/parse_assertion> through a L<Net::SPID::SAML::Assertion> object) representing the SPID session to close.

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

=head1 AUTHOR

Alessandro Ranellucci <aar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Alessandro Ranellucci.

This is free software, licensed under:

  The (three-clause) BSD License

=cut

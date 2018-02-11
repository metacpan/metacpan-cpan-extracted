package Net::SPID::SAML::AuthnRequest;
$Net::SPID::SAML::AuthnRequest::VERSION = '0.12';
use Moo;

has '_spid' => (is => 'ro', required => 1, weak_ref => 1);  # Net::SPID::SAML

# Net::SPID::SAML::IdP object
has '_idp' => (
    is          => 'ro',
    required    => 1,
);

# Net::SAML2::Protocol::AuthnRequest object
has '_authnreq' => (
    is          => 'ro',
    required    => 1,
    handles     => [qw(id)],
);

use Carp;

sub xml {
    my ($self) = @_;
    
    return $self->_authnreq->as_xml;
}

sub redirect_url {
    my ($self, %args) = @_;
    
    my $xml = $self->_authnreq->as_xml;
    print STDERR $xml, "\n";
    
    # Check that this IdP offers a HTTP-Redirect SSO binding
    # (current SPID specs do not enforce its presence, and an IdP
    # might only have a HTTP-POST binding).
    croak sprintf "IdP '%s' does not have a HTTP-Redirect SSO binding", $self->_idp->entityid,
        if !$self->_idp->sso_url('urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect');
    
    my $redirect = $self->_spid->_sp->sso_redirect_binding($self->_idp, 'SAMLRequest');
    return $redirect->sign($xml, $args{relaystate});
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::SPID::SAML::AuthnRequest

=head1 VERSION

version 0.12

=head1 SYNOPSIS

    use Net::SPID;
    
    # initialize our SPID object
    my $spid = Net::SPID->new(...);
    
    # get an IdP
    my $idp = $spid->get_idp('https://www.prova.it/');
    
    # generate an AuthnRequest
    my $authnreq = $idp->authnrequest(
        acs_index   => 0,   # index of AssertionConsumerService as per our SP metadata
        attr_index  => 1,   # index of AttributeConsumingService as per our SP metadata
        level       => 1,   # SPID level
    );
    
    my $url = $authnreq->redirect_url;

=head1 ABSTRACT

This class represents an AuthnRequest.

=head1 CONSTRUCTOR

This class is not supposed to be instantiated directly. You can craft an AuthnRequest by calling the L<Net::SPID::SAML::IdP/authnrequest> method on a L<Net::SPID::SAML::IdP> object.

=head1 METHODS

=head2 xml

This method returns the raw message in XML format (signed).

    my $xml = $authnreq->xml;

=head2 redirect_url

This method returns the full URL of the Identity Provider where user should be redirected in order to initiate their Single Sign-On. In SAML words, this implements the HTTP-Redirect binding.

    my $url = $authnreq->redirect_url(relaystate => 'foobar');

The following arguments can be supplied:

=over

=item I<relaystate>

(Optional.) An arbitrary payload can be written in this argument, and it will be returned to us along with the Response/Assertion. Please note that since we're passing this in the query string it can't be too long otherwise the URL will be truncated and the request will fail. Also note that this is transmitted in clear-text.

=back

=head1 AUTHOR

Alessandro Ranellucci <aar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Alessandro Ranellucci.

This is free software, licensed under:

  The (three-clause) BSD License

=cut

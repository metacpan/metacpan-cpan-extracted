package Net::SPID::SAML::LogoutRequest;
$Net::SPID::SAML::LogoutRequest::VERSION = '0.12';
use Moo;

has '_spid' => (is => 'ro', required => 1, weak_ref => 1);  # Net::SPID::SAML
has 'xml'   => (is => 'ro', required => 1);

# Net::SPID::SAML::IdP object
has '_idp' => (
    is          => 'ro',
    required    => 1,
);

# Net::SAML2::Protocol::LogoutRequest object
has '_logoutreq' => (
    is          => 'ro',
    required    => 1,
    handles     => [qw(id)],
);

use Carp;

sub redirect_url {
    my ($self) = @_;
    
    my $xml = $self->_logoutreq->as_xml;
    print STDERR $xml, "\n";
    
    # Check that this IdP offers a HTTP-Redirect SLO binding.
    croak sprintf "IdP '%s' does not have a HTTP-Redirect SLO binding", $self->_idp->entityid,
        if !$self->_idp->slo_url('urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect');
    
    my $redirect = $self->_spid->_sp->slo_redirect_binding($self->_idp, 'SAMLRequest');
    return $redirect->sign($xml);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::SPID::SAML::LogoutRequest

=head1 VERSION

version 0.12

=head1 SYNOPSIS

    use Net::SPID;
    
    # initialize our SPID object
    my $spid = Net::SPID->new(...);
    
    # get an IdP
    my $idp = $spid->get_idp('https://www.prova.it/');
    
    # generate a LogoutRequest
    my $logoutreq = $idp->logoutrequest(
        session => $spid_session,
    );
    my $url = $logoutreq->redirect_url;
    
    # parse a LogoutRequest
    my $logutreq = $spid->parse_logoutrequest;

=head1 ABSTRACT

This class represents a LogoutRequest. You may need to generate this request in case you're initiating a logout procedure on behalf of your user, or you may need to parse a logout request in case the user initiated a logout procedure elsewhere and an Identity Provider is requesting logout to you.

=head1 CONSTRUCTOR

This class is not supposed to be instantiated directly. You can get one by calling L<Net::SPID::SAML::IdP/logoutrequest> or L<Net::SPID::SAML/parse_logoutrequest>.

=head1 METHODS

=head2 xml

This method returns the raw message in XML format (signed).

    my $xml = $logoutreq->xml;

=head2 redirect_url

This method returns the full URL of the Identity Provider where user should be redirected in order to initiate their Single Sign-On. In SAML words, this implements the HTTP-Redirect binding.

    my $url = $logoutreq->redirect_url;

=head1 AUTHOR

Alessandro Ranellucci <aar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Alessandro Ranellucci.

This is free software, licensed under:

  The (three-clause) BSD License

=cut

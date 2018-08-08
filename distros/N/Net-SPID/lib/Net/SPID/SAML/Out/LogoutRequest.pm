package Net::SPID::SAML::Out::LogoutRequest;
$Net::SPID::SAML::Out::LogoutRequest::VERSION = '0.15';
use Moo;

extends 'Net::SPID::SAML::Out::Base';

has 'session' => (is => 'ro', required => 1);

use Carp;

sub xml {
    my ($self, %args) = @_;
    
    $args{binding} //= 'urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect';
    
    my ($x, $saml, $samlp) = $self->SUPER::xml;

    my $req_attrs = {
        ID              => $self->ID,
        IssueInstant    => $self->IssueInstant->strftime('%FT%TZ'),
        Version         => '2.0',
        Destination     => $self->_idp->sloreq_urls->{$args{binding}},
    };
    $x->startTag([$samlp, 'LogoutRequest'], %$req_attrs);
    
    $x->dataElement([$saml, 'Issuer'], $self->_spid->sp_entityid,
        Format          => 'urn:oasis:names:tc:SAML:2.0:nameid-format:entity',
        NameQualifier   => $self->_spid->sp_entityid,
    );
    
    if ($args{signature_template}) {
        $x->raw($self->_signature_template($self->ID));
    }
    
    $x->dataElement([$saml, 'NameID'], $self->session->nameid, 
        Format => 'urn:oasis:names:tc:SAML:2.0:nameid-format:transient',
        NameQualifier => $self->_idp->entityID);
    
    $x->dataElement([$samlp, 'SessionIndex'], $self->session->session_index);
    
    $x->endTag(); #LogoutRequest
    $x->end();
    
    return $x->to_string;
}

sub redirect_url {
    my ($self, %args) = @_;
    
    my $url = $self->_idp->sloreq_urls->{'urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect'}
        or croak "No HTTP-Redirect binding is available for Single Logout";
    return $self->SUPER::redirect_url($url, %args);
}

sub post_form {
    my ($self, %args) = @_;
    
    my $url = $self->_idp->sloreq_urls->{'urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST'}
        or croak "No HTTP-POST binding is available for Single Logout";
    return $self->SUPER::post_form($url, %args);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::SPID::SAML::Out::LogoutRequest

=head1 VERSION

version 0.15

=head1 SYNOPSIS

    use Net::SPID;
    
    # initialize our SPID object
    my $spid = Net::SPID->new(...);
    
    # get an IdP
    my $idp = $spid->get_idp($spid_session->idp_id);
    
    # generate a LogoutRequest
    my $logoutreq = $idp->logoutrequest(
        session => $spid_session,
    );
    my $url = $logoutreq->redirect_url;

=head1 ABSTRACT

This class represents an outgoing LogoutRequest. You can use it to generate such a request in case you're initiating a logout procedure on behalf of your user.

=head1 CONSTRUCTOR

This class is not supposed to be instantiated directly. You can craft a LogoutRequest by calling the L<Net::SPID::SAML::IdP/logoutrequest> method on a L<Net::SPID::SAML::IdP> object.

=head1 METHODS

=head2 xml

This method generates the message in XML format.

    my $xml = $logoutreq->xml;

=head2 redirect_url

This method returns the full URL of the Identity Provider where user should be redirected in order to initiate their Single Logout. In SAML words, this implements the HTTP-Redirect binding.

    my $url = $logoutreq->redirect_url;

=head2 post_form

This method returns an HTML page with a JavaScript auto-post command that submits the request to the Identity Provider in order to initiate their Single Logout. In SAML words, this implements the HTTP-POST binding.

    my $html = $logoutreq->post_form;

=for Pod::Coverage BUILD

=head1 AUTHOR

Alessandro Ranellucci <aar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Alessandro Ranellucci.

This is free software, licensed under:

  The (three-clause) BSD License

=cut

package Net::SPID::SAML::Out::LogoutResponse;
$Net::SPID::SAML::Out::LogoutResponse::VERSION = '0.15';
use Moo;

extends 'Net::SPID::SAML::Out::Base';

has 'status' => (is => 'rw', default => sub { 'success' }); # success/failure/partial
has 'in_response_to' => (is => 'rw', required => 1);

use Carp;

sub xml {
    my ($self, %args) = @_;
    
    $args{binding} //= 'urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect';
    
    my ($x, $saml, $samlp) = $self->SUPER::xml;

    my $req_attrs = {
        ID              => $self->ID,
        IssueInstant    => $self->IssueInstant->strftime('%FT%TZ'),
        Version         => '2.0',
        Destination     => $self->_idp->slores_urls->{$args{binding}},
        InResponseTo    => $self->in_response_to,
    };
    $x->startTag([$samlp, 'LogoutResponse'], %$req_attrs);
    
    $x->dataElement([$saml, 'Issuer'], $self->_spid->sp_entityid,
        Format          => 'urn:oasis:names:tc:SAML:2.0:nameid-format:entity',
        NameQualifier   => $self->_spid->sp_entityid,
    );
    
    if ($args{signature_template}) {
        $x->raw($self->_signature_template($self->ID));
    }
    
    $x->startTag([$samlp, 'Status']);
    if ($self->status eq 'success') {
        $x->dataElement([$samlp, 'StatusCode'], undef, Value => 'urn:oasis:names:tc:SAML:2.0:status:Success');
    } elsif ($self->status eq 'failure') {
        # FIXME: what should we send in this case?
    } elsif ($self->status eq 'partial') {
        # FIXME: is it correct to send PartialLogout in this case?
        $x->startTag([$samlp, 'StatusCode'], undef, Value => 'urn:oasis:names:tc:SAML:2.0:status:Requester');
        $x->dataElement([$samlp, 'StatusCode'], undef, Value => 'urn:oasis:names:tc:SAML:2.0:status:PartialLogout');
        $x->endTag(); #StatusCode
    }
    $x->endTag(); #Status
    
    $x->endTag(); #LogoutResponse
    $x->end();
    
    return $x->to_string;
}

sub redirect_url {
    my ($self, %args) = @_;
    
    my $url = $self->_idp->slores_urls->{'urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect'}
        or croak "No HTTP-POST binding is available for Single Logout";
    return $self->SUPER::redirect_url($url, %args);
}

sub post_form {
    my ($self, %args) = @_;
    
    my $url = $self->_idp->slores_urls->{'urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST'}
        or croak "No HTTP-POST binding is available for Single Logout";
    return $self->SUPER::post_form($url, %args);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::SPID::SAML::Out::LogoutResponse

=head1 VERSION

version 0.15

=head1 SYNOPSIS

    use Net::SPID;
    
    # generate a LogoutResponse
    my $logoutres = $idp->logoutresponse(
        status          => 'success',
        in_response_to  => $logoutreq->id,
    );
    my $url = $logoutres->redirect_url;

=head1 ABSTRACT

This class represents an outgoing LogoutResponse. You need to craft such a response in case you received a LogoutRequest from the Identity Provider, thus during an IdP-initiated logout.

=head1 CONSTRUCTOR

This class is not supposed to be instantiated directly. You can get one by calling L<Net::SPID::SAML::IdP/logoutresponse> on the L<Net::SPID::SAML::IdP> object or by calling L<Net::SPID::SAML::In::LogoutRequest/make_response> on the L<Net::SPID::SAML::In::LogoutRequest>.

=head1 METHODS

=head2 xml

This method returns the raw message in XML format (signed).

    my $xml = $logoutreq->xml;

=head2 redirect_url

This method returns the full URL of the Identity Provider where user should be redirected in order to continue their Single Logout. In SAML words, this implements the HTTP-Redirect binding.

    my $url = $logoutres->redirect_url;

=head2 post_form

This method returns an HTML page with a JavaScript auto-post command that submits the request to the Identity Provider in order to complete their Single Logout. In SAML words, this implements the HTTP-POST binding.

    my $html = $logoutres->post_form;

=head2 success

This method parses the status code and returns C<success>, C<partial> or C<0>.

=head1 AUTHOR

Alessandro Ranellucci <aar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Alessandro Ranellucci.

This is free software, licensed under:

  The (three-clause) BSD License

=cut

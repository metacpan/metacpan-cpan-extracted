package Net::SPID::SAML::Out::AuthnRequest;
$Net::SPID::SAML::Out::AuthnRequest::VERSION = '0.15';
use Moo;

extends 'Net::SPID::SAML::Out::Base';

has 'acs_url'       => (is => 'rw', required => 0);
has 'acs_index'     => (is => 'rw', required => 0);
has 'attr_index'    => (is => 'rw', required => 0);
has 'level'         => (is => 'rw', required => 0, default => sub { 1 });
has 'comparison'    => (is => 'rw', required => 0, default => sub { 'minimum' });

use Carp qw(croak);

sub xml {
    my ($self, %args) = @_;
    
    $args{binding} //= 'urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect';
    
    my ($x, $saml, $samlp) = $self->SUPER::xml;

    my $req_attrs = {
        ID              => $self->ID,
        IssueInstant    => $self->IssueInstant->strftime('%FT%TZ'),
        Version         => '2.0',
        Destination     => $self->_idp->sso_urls->{$args{binding}},
        ForceAuthn      => ($self->level > 1) ? 'true' : 'false',
    };
    if (defined (my $acs_url = $self->acs_url // $self->_spid->sp_assertionconsumerservice->[0])) {
        $req_attrs->{AssertionConsumerServiceURL} = $acs_url;
        $req_attrs->{ProtocolBinding} = 'urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST';
    } elsif (defined (my $acs_index = $self->acs_index // 0)) {
        $req_attrs->{AssertionConsumerServiceIndex} = $acs_index;
    }
    if (defined $self->attr_index) {
        $req_attrs->{AttributeConsumingServiceIndex} = $self->attr_index;
    }
    $x->startTag([$samlp, 'AuthnRequest'], %$req_attrs);
    
    $x->dataElement([$saml, 'Issuer'], $self->_spid->sp_entityid,
        Format          => 'urn:oasis:names:tc:SAML:2.0:nameid-format:entity',
        NameQualifier   => $self->_spid->sp_entityid,
    );
    
    if ($args{signature_template}) {
        $x->raw($self->_signature_template($self->ID));
    }
    
    $x->dataElement([$samlp, 'NameIDPolicy'], undef, 
        Format => 'urn:oasis:names:tc:SAML:2.0:nameid-format:transient');
    
    $x->startTag([$samlp, 'RequestedAuthnContext'], Comparison => $self->comparison);
    $x->dataElement([$saml, 'AuthnContextClassRef'], 'https://www.spid.gov.it/SpidL' . $self->level);
    $x->endTag();
    
    $x->endTag(); #AuthnRequest
    $x->end();
    
    return $x->to_string;
}

sub redirect_url {
    my ($self, %args) = @_;
    
    my $url = $self->_idp->sso_urls->{'urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect'}
        or croak "No HTTP-Redirect binding is available for Single Sign-On";
    return $self->SUPER::redirect_url($url, %args);
}

sub post_form {
    my ($self, %args) = @_;
    
    my $url = $self->_idp->sso_urls->{'urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST'}
        or croak "No HTTP-POST binding is available for Single Sign-On";
    return $self->SUPER::post_form($url, %args);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::SPID::SAML::Out::AuthnRequest

=head1 VERSION

version 0.15

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

This class represents an outgoing AuthnRequest.

=head1 CONSTRUCTOR

This class is not supposed to be instantiated directly. You can craft an AuthnRequest by calling the L<Net::SPID::SAML::IdP/authnrequest> method on a L<Net::SPID::SAML::IdP> object.

=head1 METHODS

=head2 xml

This method generates the message in XML format.

    my $xml = $authnreq->xml;

=head2 redirect_url

This method returns the full URL of the Identity Provider where user should be redirected in order to initiate their Single Sign-On. In SAML words, this implements the HTTP-Redirect binding.

    my $url = $authnreq->redirect_url(relaystate => 'foobar');

The following arguments can be supplied:

=over

=item I<relaystate>

(Optional.) An arbitrary payload can be written in this argument, and it will be returned to us along with the Response/Assertion. Please note that since we're passing this in the query string it can't be too long otherwise the URL will be truncated and the request will fail. Also note that this is transmitted in clear-text and that you are responsible for making sure the value is coupled with this AuthnRequest either cryptographycally or by using a lookup table on your side.

=back

=head2 post_form

This method returns an HTML page with a JavaScript auto-post command that submits the request to the Identity Provider in order to initiate their Single Sign-On. In SAML words, this implements the HTTP-POST binding.

    my $html = $authnreq->post_form(relaystate => 'foobar');

The following arguments can be supplied:

=over

=item I<relaystate>

(Optional.) An arbitrary payload can be written in this argument, and it will be returned to us along with the Response/Assertion. Please note that this is not signed and it's transmitted in clear-text; you are responsible for signing it and making sure the value is coupled with this AuthnRequest either cryptographycally or by using a lookup table on your side.

=back

=for Pod::Coverage BUILD

=head1 AUTHOR

Alessandro Ranellucci <aar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Alessandro Ranellucci.

This is free software, licensed under:

  The (three-clause) BSD License

=cut

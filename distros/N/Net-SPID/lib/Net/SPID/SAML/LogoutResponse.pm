package Net::SPID::SAML::LogoutResponse;
$Net::SPID::SAML::LogoutResponse::VERSION = '0.12';
use Moo;

has '_spid' => (is => 'ro', required => 1, weak_ref => 1);  # Net::SPID::SAML
has 'xml'   => (is => 'ro', required => 1);                 # original unparsed XML

# Net::SAML2::Protocol::LogoutResponse object
has '_logoutres' => (
    is          => 'ro',
    required    => 1,
    handles     => [qw(id)],
);

use Carp;

sub redirect_url {
    my ($self) = @_;
    
    my $xml = $self->_logoutres->as_xml;
    print STDERR $xml, "\n";
    
    # Check that this IdP offers a HTTP-Redirect SLO binding.
    croak sprintf "IdP '%s' does not have a HTTP-Redirect SLO binding", $self->_idp->entityid,
        if !$self->_idp->slo_url('urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect');
    
    # TODO: make sure slo_redirect_binding() uses ResponseLocation is any.
    my $redirect = $self->_spid->_sp->slo_redirect_binding($self->_idp, 'SAMLResponse');
    return $redirect->sign($xml);
}

# Returns 'success', 'partial', or 0.
sub success {
    my ($self) = @_;
    
    return $self->_logoutres->substatus eq $self->_logoutres->status_uri('partial')
        ? 'partial'
        : $self->_logoutres->success ? 'success' : 0;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::SPID::SAML::LogoutResponse

=head1 VERSION

version 0.12

=head1 SYNOPSIS

    use Net::SPID;
    
    # initialize our SPID object
    my $spid = Net::SPID->new(...);
    
    # generate a LogoutResponse
    my $logoutres = $idp->logoutresponse(
        status          => 'success',
        in_response_to  => $logoutreq->id,
    );
    my $url = $logoutreq->redirect_url;
    
    # parse a LogoutResponse
    my $logutres = $spid->parse_logoutresponse;

=head1 ABSTRACT

This class represents a LogoutResponse. You may need to parse such a response in case you initiated a logout procedure on behalf of your user and you're getting the result from the Identity Provider, or you may need to generate a logout response in case the user initiated a logout procedure elsewhere and an Identity Provider is requested logout to you.

=head1 CONSTRUCTOR

This class is not supposed to be instantiated directly. You can get one by calling L<Net::SPID::SAML::IdP/logoutresponse> or L<Net::SPID::SAML/parse_logoutresponse>.

=head1 METHODS

=head2 xml

This method returns the raw message in XML format (signed).

    my $xml = $logoutreq->xml;

=head2 redirect_url

This method returns the full URL of the Identity Provider where user should be redirected in order to continue their Single Logout. In SAML words, this implements the HTTP-Redirect binding.

    my $url = $logoutres->redirect_url;

=head2 success

This method parses the status code and returns C<success>, C<partial> or C<0>.

=head1 AUTHOR

Alessandro Ranellucci <aar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Alessandro Ranellucci.

This is free software, licensed under:

  The (three-clause) BSD License

=cut

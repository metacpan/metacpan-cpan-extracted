package Net::SPID::SAML::In::LogoutResponse;
$Net::SPID::SAML::In::LogoutResponse::VERSION = '0.15';
use Moo;

use Carp qw(croak);

extends 'Net::SPID::SAML::In::Base';

has 'StatusCode' => (is => 'lazy', builder => sub {
    $_[0]->xpath->findvalue('/samlp:LogoutResponse/samlp:Status/samlp:StatusCode/@Value')->value
});

has 'StatusCode2' => (is => 'lazy', builder => sub {
    $_[0]->xpath->findvalue('/samlp:LogoutResponse/samlp:Status/samlp:StatusCode/samlp:StatusCode/@Value')->value
});

has 'status' => (is => 'lazy', builder => sub {
    my ($sc, $sc2) = ($_[0]->StatusCode, $_[0]->StatusCode2);
    $sc eq 'urn:oasis:names:tc:SAML:2.0:status:Success'
        ? 'success'
        : $sc2 eq 'urn:oasis:names:tc:SAML:2.0:status:PartialLogout'
            ? 'partial'
            : croak "Invalid status '$sc'/'$sc2'";
});

sub validate {
    my ($self, %args) = @_;
    
    $self->SUPER::validate(%args) or return 0;
    
    my $xpath = $self->xpath;
    
    # if message is signed, validate that signature;
    # otherwise validate $args{URL}
    $self->_validate_post_or_redirect($args{URL});
    
    croak "Missing 'in_response_to' argument for validate()"
        if !defined $args{in_response_to};
    
    croak sprintf "Invalid InResponseTo: '%s' (expected: '%s')",
        $self->InResponseTo, $args{in_response_to}
        if $self->InResponseTo ne $args{in_response_to};
    
    croak sprintf "Invalid Destination: '%s'", $self->Destination
        if !grep { $_ eq $self->Destination } keys %{$self->_spid->sp_singlelogoutservice};
    
    return 1;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::SPID::SAML::In::LogoutResponse

=head1 VERSION

version 0.15

=head1 SYNOPSIS

    use Net::SPID;
    
    # initialize our SPID object
    my $spid = Net::SPID->new(...);
    
    # parse a LogoutResponse
    my $logoutres = $spid->parse_logoutresponse($payload, $url, $in_response_to);

=head1 ABSTRACT

This class represents an incoming LogoutResponse. You can use this to parse the response coming from the Identity Provider after you sent a LogoutRequest for a SP-initiated logout.

=head1 CONSTRUCTOR

This class is not supposed to be instantiated directly. You can get one by calling L<Net::SPID::SAML/parse_logoutresponse>.

=head1 METHODS

=head2 xml

This method returns the raw message in XML format.

    my $xml = $logoutres->xml;

=head2 validate

This method performs validation of the incoming message according to the SPID rules. In case of success it returns a true value; in case of failure it will die with the relevant error.

    eval { $logoutres->validate(in_response_to => $logout_req_ID) };
    if ($@) {
        warn "Bad LogoutResponse: $@";
    }

The C<in_response_to> argument is required in order to perform the mandatory security check.

=head2 status

This method returns I<success>, I<failure> or I<partial> according to the status code returned by the Identity Provider.

    my $result = $logoutres->status;

=head1 AUTHOR

Alessandro Ranellucci <aar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Alessandro Ranellucci.

This is free software, licensed under:

  The (three-clause) BSD License

=cut

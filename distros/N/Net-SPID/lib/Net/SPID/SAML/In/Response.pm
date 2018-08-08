package Net::SPID::SAML::In::Response;
$Net::SPID::SAML::In::Response::VERSION = '0.15';
use Moo;

extends 'Net::SPID::SAML::In::Base';

my %fields = qw(
    NameID                  /samlp:Response/saml:Assertion/saml:Subject/saml:NameID
    SessionIndex            /samlp:Response/saml:Assertion/saml:AuthnStatement/@SessionIndex
    Assertion_Issuer        /samlp:Response/saml:Assertion/saml:Issuer
    Assertion_Audience      /samlp:Response/saml:Assertion/saml:Conditions/saml:AudienceRestriction/saml:Audience
    Assertion_InResponseTo  /samlp:Response/saml:Assertion/saml:Subject/saml:SubjectConfirmation/saml:SubjectConfirmationData/@InResponseTo
    Assertion_Recipient     /samlp:Response/saml:Assertion/saml:Subject/saml:SubjectConfirmation/saml:SubjectConfirmationData/@Recipient
    StatusCode              /samlp:Response/samlp:Status/samlp:StatusCode/@Value
    StatusCode2             /samlp:Response/samlp:Status/samlp:StatusCode/samlp:StatusCode/@Value
    StatusMessage           /samlp:Response/samlp:Status/samlp:StatusMessage/text()
);

# generate accessors for all the above fields
foreach my $f (keys %fields) {
    has $f => (is => 'lazy', builder => sub {
        $_[0]->xpath->findvalue($fields{$f})->value
    });
}

has 'NotBefore' => (is => 'lazy', builder => sub {
    DateTime::Format::XSD->parse_datetime
        ($_[0]->xpath->findvalue('/samlp:Response/saml:Assertion/saml:Conditions/@NotBefore')->value)
});

has 'NotOnOrAfter' => (is => 'lazy', builder => sub {
    DateTime::Format::XSD->parse_datetime
        ($_[0]->xpath->findvalue('/samlp:Response/saml:Assertion/saml:Conditions/@NotOnOrAfter')->value)
});

has 'SubjectConfirmationData_NotOnOrAfter' => (is => 'lazy', builder => sub {
    DateTime::Format::XSD->parse_datetime
        ($_[0]->xpath->findvalue('/samlp:Response/saml:Assertion/saml:Subject/saml:SubjectConfirmation/saml:SubjectConfirmationData/@NotOnOrAfter')->value)
});

has 'spid_level' => (is => 'lazy', builder => sub {
    my $classref = $_[0]->xpath->findvalue('/samlp:Response/saml:Assertion/saml:AuthnStatement/saml:AuthnContext/saml:AuthnContextClassRef')->value
        or return undef;
    $classref =~ /SpidL(\d)$/ or return undef;
    return $1;
});

has 'attributes' => (is => 'lazy', builder => sub {
    return {
        map { $_->getAttribute('Name') => $_->findnodes("*[local-name()='AttributeValue']")->[0]->string_value }
            $_[0]->xpath->findnodes("/samlp:Response/saml:Assertion/saml:AttributeStatement/saml:Attribute"),
    }
});

use Carp;
use Crypt::OpenSSL::RSA;
use DateTime;
use DateTime::Format::XSD;
use Mojo::XMLSig;

sub validate {
    my ($self, %args) = @_;
    
    $self->SUPER::validate(%args) or return 0;
    
    my $xpath = $self->xpath;
    
    # TODO: validate IssueInstant
    
    croak "Missing 'in_response_to' argument for validate()"
        if !defined $args{in_response_to};
    
    croak sprintf "Invalid InResponseTo: '%s' (expected: '%s')",
        $self->InResponseTo, $args{in_response_to}
        if $self->InResponseTo ne $args{in_response_to};
    
    croak sprintf "Invalid Destination: '%s'", $self->Destination
        if !grep { $_ eq $self->Destination } @{$self->_spid->sp_assertionconsumerservice};
    
    if ($self->success) {
        # We expect to have an <Assertion> element
        
        croak sprintf "Response/Issuer (%s) does not match Assertion/Issuer (%s)",
            $self->Issuer, $self->Assertion_Issuer
            if $self->Issuer ne $self->Assertion_Issuer;
    
        croak sprintf "Invalid Audience: '%s' (expected: '%s')",
            $self->Assertion_Audience, $self->_spid->sp_entityid
            if $self->Assertion_Audience ne $self->_spid->sp_entityid;
    
        croak sprintf "Invalid InResponseTo: '%s' (expected: '%s')",
            $self->Assertion_InResponseTo, $args{in_response_to}
            if $self->Assertion_InResponseTo ne $args{in_response_to};
    
        # this validates all the signatures in the given XML, and requires that at least one exists
        my $pubkey = Crypt::OpenSSL::RSA->new_public_key($self->_idp->cert->pubkey);
        Mojo::XMLSig::verify($self->xml, $pubkey)
            or croak "Signature verification failed";
    
        # SPID regulations require that Assertion is signed, while Response can be not signed
        croak "Response/Assertion is not signed"
            if $xpath->findnodes('/samlp:Response/saml:Assertion/dsig:Signature')->size == 0;
    
        my $now = DateTime->now;
    
        # exact match is ok
        croak sprintf "Invalid NotBefore: '%s' (now: '%s')",
            $self->NotBefore->iso8601, $now->iso8601
            if DateTime->compare($now, $self->NotBefore) < 0;
    
        # exact match is *not* ok
        croak sprintf "Invalid NotOnOrAfter: '%s' (now: '%s')",
            $self->NotOnOrAfter->iso8601, $now->iso8601
            if DateTime->compare($now, $self->NotOnOrAfter) > -1;
    
        # exact match is *not* ok
        croak sprintf "Invalid SubjectConfirmationData/NotOnOrAfter: '%s' (now: '%s')",
            $self->SubjectConfirmationData_NotOnOrAfter->iso8601, $now->iso8601
            if DateTime->compare($now, $self->SubjectConfirmationData_NotOnOrAfter) > -1;
    
        croak "Invalid SubjectConfirmationData/\@Recipient'"
            if !grep { $_ eq $self->Assertion_Recipient } @{$self->_spid->sp_assertionconsumerservice};
    
        croak "Mismatch between Destination and SubjectConfirmationData/\@Recipient"
            if $self->Destination ne $self->Assertion_Recipient;
    } else {
        # Authentication failed, so we expect no <Assertion> element.
    }
    
    return 1;
}

sub success {
    my ($self) = @_;
    
    return $self->StatusCode eq 'urn:oasis:names:tc:SAML:2.0:status:Success';
}

sub spid_session {
    my ($self) = @_;
    
    return undef if !$self->success;
    
    return Net::SPID::Session->new(
        idp_id          => $self->Issuer,
        nameid          => $self->NameID,
        session_index   => $self->SessionIndex,
        attributes      => $self->attributes,
        level           => $self->spid_level,
        assertion_xml   => $self->xml,
    );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::SPID::SAML::In::Response

=head1 VERSION

version 0.15

=head1 SYNOPSIS

    use Net::SPID;
    
    # initialize our SPID object
    my $spid = Net::SPID->new(...);
    
    # parse a response from an Identity Provider and validate it
    my $assertion = eval {
        $spid->parse_response($saml_response_xml, $authnreq_id);
    };
    die "Invalid assertion: $@" if $@;
    
    # read the SPID level
    print "SPID Level: ", $assertion->spid_level, "\n";
    
    # get a Net::SPID::Session object (serializable for later reuse, such as logout)
    my $session = $assertion->spid_session;

=head1 ABSTRACT

This class represents an incoming SPID Response/Assertion message. We get such messages either after an AuthnRequest (Single Sign-On) or after an AttributeQuery.

=head1 CONSTRUCTOR

This class is not supposed to be instantiated directly. It is returned by L<Net::SPID::SAML/parse_response>.

=head1 METHODS

=head2 xml

This method returns the raw assertion in its XML format.

    my $xml = $assertion->xml;

=head2 validate

On success it returns a true value. On failure it will throw an exception.

    eval {
        $assertion->validate(
            in_response_to  => $authnrequest_id,
            acs_url         => $acs_url,
        );
    };
    die "Invalid assertion: $@" if $@;

The following arguments are expected:

=over

=item I<in_response_to>

This must be the ID of the AuthnRequest we sent, which you should store in the user's session in order to supply it to this method. It will be used for checking that the I<InResponseTo> field of the assertion matches our request.

=back

=head2 success

This method returns true if authentication succeeded (and thus we got an assertion from the Identity Provider). In case of failure, you can call the L<StatusCode> method for more details.

=head2 spid_level

This method returns the SPID level asserted by the Identity Provider, as an integer (1, 2 or 3). Note that this may not coincide with the level requested in the AuthnRequest.

=head2 spid_session

This method returns a L<Net::SPID::Session> object populated with information from this Assertion. It's serializable and you might want to store it for later reuse (i.e. for generating a logout request).

=head2 attributes

This method returns a hashref containing the attributes.

=head2 StatusCode

This method returns the SAML response StatusCode.

=head1 AUTHOR

Alessandro Ranellucci <aar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Alessandro Ranellucci.

This is free software, licensed under:

  The (three-clause) BSD License

=cut

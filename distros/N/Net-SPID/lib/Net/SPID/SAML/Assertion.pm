package Net::SPID::SAML::Assertion;
$Net::SPID::SAML::Assertion::VERSION = '0.12';
use Moo;

has '_spid'         => (is => 'ro', required => 1, weak_ref => 1);  # Net::SPID::SAML
has '_assertion'    => (is => 'ro', required => 1);                 # Net::SAML2::Protocol::Assertion
has 'xml'           => (is => 'ro', required => 1);                 # original unparsed XML

use Carp;
use DateTime;

sub validate {
    my ($self, $in_response_to) = @_;
    
    croak sprintf "Invalid Audience: '%s' (expected: '%s')",
        $self->_assertion->audience, $self->_spid->sp_entityid
        if !$self->valid_audience;
    
    if (defined $in_response_to) {
        croak sprintf "Invalid InResponseTo: '%s' (expected: '%s')",
            $self->_assertion->in_response_to, $in_response_to
            if defined $in_response_to && !$self->valid_in_response_to($in_response_to);
    }
    
    croak sprintf "Invalid NotBefore: '%s' (now: '%s')",
        $self->_assertion->not_before, DateTime->now->iso8601
        if !$self->valid_not_before;
    
    croak sprintf "Invalid NotAfter: '%s' (now: '%s')",
        $self->_assertion->not_after, DateTime->now->iso8601
        if !$self->valid_not_after;
    
    return 1;
}

sub valid_audience {
    my ($self) = @_;
    
    return $self->_assertion->audience eq $self->_spid->sp_entityid;
}

sub valid_in_response_to {
    my ($self, $in_response_to) = @_;
    
    return $in_response_to eq $self->_assertion->in_response_to;
}

sub valid_not_before {
    my ($self) = @_;
    
    # exact match is ok
    return DateTime->compare(DateTime->now, $self->_assertion->not_before) > -1;
}

sub valid_not_after {
    my ($self) = @_;
    
    # exact match is *not* ok
    return DateTime->compare($self->_assertion->not_after, DateTime->now) > 0;
}

sub spid_level {
    my ($self) = @_;
    
    if ($self->_assertion->AuthnContextClassRef->[0]) {
        $self->_assertion->AuthnContextClassRef->[0] =~ /SpidL(\d)$/;
        return $1;
    }
    
    return undef;
}

sub spid_session {
    my ($self) = @_;
    
    return Net::SPID::Session->new(
        idp_id          => $self->_assertion->issuer->as_string,
        nameid          => $self->_assertion->nameid,
        session         => $self->_assertion->session,
        attributes      => $self->_assertion->attributes,
        level           => $self->spid_level,
        xml             => $self->xml,
    );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::SPID::SAML::Assertion

=head1 VERSION

version 0.12

=head1 SYNOPSIS

    use Net::SPID;
    
    # initialize our SPID object
    my $spid = Net::SPID->new(...);
    
    # parse a response from an Identity Provider
    my $assertion = eval {
        $spid->parse_assertion($saml_response_xml, $authnreq_id);
    };
    
    # perform validation
    die "Invalid assertion!" if !$assertion->validate($our_entityid, $request_id);
    
    # read the SPID level
    print "SPID Level: ", $assertion->spid_level, "\n";
    
    # get a Net::SPID::Session object (serializable for later reuse, such as logout)
    my $session = $assertion->spid_session;

=head1 ABSTRACT

This class represents a SPID Response/Assertion message. We get such messages either after an AuthnRequest (Single Sign-On) or after an AttributeQuery.

=head1 CONSTRUCTOR

This class is not supposed to be instantiated directly. It is returned by L<Net::SPID::SAML/parse_assertion>.

=head1 METHODS

=head2 xml

This method returns the raw assertion in its XML format.

    my $xml = $assertion->xml;

=head2 validate

This method performs validation by calling all of the C<valid_*> methods described below.

On success it returns a true value. On failure it will throw an exception.

    eval {
        $assertion->validate($request_id);
    };
    die "Invalid assertion: $@" if $@;

=head2 valid_audience

This method checks that the C<Audience> attribute equals our entityID and returns a boolean value.

    die "Invalid audience" if !$assertion->valid_audience;

=head2 valid_in_response_to

This method checks that the C<InResponseTo> attribute equals the supplied request ID and returns a boolean value.

    die "Invalid InResponseTo" if !$assertion->in_response_to($request_id);

=head2 valid_not_before

This method checks that the C<NotBefore> condition contained in the assertion is compatible with the current timestamp and returns a boolean value.

    die "Invalid NotBefore" if !$assertion->valid_not_before;

=head2 valid_not_after

This method checks that the C<NotAfter> condition contained in the assertion is compatible with the current timestamp and returns a boolean value.

    die "Invalid NotBefore" if !$assertion->valid_not_after;

=head2 spid_level

This method returns the SPID level asserted by the Identity Provider, as an integer (1, 2 or 3). Note that this may not coincide with the level requested in the AuthnRequest.

=head2 spid_session

This method returns a L<Net::SPID::Session> object populated with information from this Assertion. It's serializable and you might want to store it for later reuse (i.e. for generating a logout request).

=head1 AUTHOR

Alessandro Ranellucci <aar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Alessandro Ranellucci.

This is free software, licensed under:

  The (three-clause) BSD License

=cut

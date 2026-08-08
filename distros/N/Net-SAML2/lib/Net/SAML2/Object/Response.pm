package Net::SAML2::Object::Response;
use Moose;

our $VERSION = '0.89'; # VERSION

use overload '""' => 'to_string';

# ABSTRACT: A response object

use MooseX::Types::DateTime qw/ DateTime /;
use MooseX::Types::Common::String qw/ NonEmptySimpleStr /;
use DateTime;
use DateTime::HiRes;
use DateTime::Format::XSD;
use Net::SAML2::XML::Util qw/ no_comments /;
use Net::SAML2::XML::Sig;
use Net::SAML2::Protocol::Assertion;
use XML::Enc;
use XML::LibXML::XPathContext;
use List::Util qw(first);
use URN::OASIS::SAML2 qw(STATUS_SUCCESS URN_ASSERTION URN_PROTOCOL);
use Carp qw(croak);

with 'Net::SAML2::Role::ProtocolMessage';


has _dom => (
    is       => 'ro',
    isa      => 'XML::LibXML::Node',
    init_arg => 'dom',
    required => 1,
);

has status => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has substatus => (
    is        => 'ro',
    isa       => 'Str',
    required  => 0,
    predicate => 'has_substatus',
);

has assertions => (
    is       => 'ro',
    isa      => 'XML::LibXML::NodeList',
    required => 0,
    predicate => 'has_assertions',
);

has 'cacert'     => (
    isa => 'Str',
    is => 'ro',
    required => 0);

has 'cert_text'  => (
    isa => 'Str',
    is => 'ro',
    required => 0);

has 'insecure_trust_embedded_cert' => (
    isa       => 'Bool',
    is        => 'ro',
    default   => 0,
);

has 'require_signed_response' => (
    isa       => 'Bool',
    is        => 'ro',
    default   => 0,
);

# BUILDARGS

around BUILDARGS => sub {
    my $orig = shift;
    my $self = shift;

    my %params = @_;
    unless ($params{cacert}
         || $params{cert_text}
         || $params{insecure_trust_embedded_cert}) {
        croak(
            "Net::SAML2::Object::Response->new() requires 'cacert' or "
          . "'cert_text' on the object to verify SAML response signatures. "
          . "To explicitly disable signature verification (test/dev only) "
          . ", pass insecure_trust_embedded_cert => 1 to new()."
        );
    }

    return $self->$orig(%params);
};


sub new_from_xml {
    my $self = shift;
    my %args = @_;

    my $xml            = no_comments($args{xml});
    my $destination    = delete $args{destination};
    my $cacert         = delete $args{cacert};
    my $cert_text      = delete $args{cert_text};
    my $insecure_trust_embedded_cert    = delete $args{insecure_trust_embedded_cert};

    # The default may change in the future
    my $require_signed_response         = delete $args{require_signed_response} // 0;

    my $xpath = XML::LibXML::XPathContext->new($xml);
    $xpath->registerNs('saml',  URN_ASSERTION);
    $xpath->registerNs('samlp', URN_PROTOCOL);
    $xpath->registerNs('dsig',  'http://www.w3.org/2000/09/xmldsig#');

    my $actual_destination = $xpath->findvalue(
        '/samlp:Response/@Destination | /samlp:ArtifactResponse/@Destination');
    if (defined $destination && $destination ne $actual_destination) {
        croak(sprintf("Response Destination (%s) does not match expected value (%s)",
                $actual_destination,
                $destination)
        );
    }

    my $response = $xpath->findnodes('/samlp:Response|/samlp:ArtifactResponse');
    croak("Unable to parse response") unless $response->size;
    $response = $response->get_node(1);

    # require_signed_response only applies to front-channel Responses.
    #
    # ArtifactResponse is retrieved by the SP over a mutually authenticated
    # TLS back-channel (the SP initiates the connection to the IdP's known
    # artifact resolution endpoint), so transport already authenticates it
    # and it is exempt from this check.

    my $is_artifact = $response->nodePath eq '/samlp:ArtifactResponse';

    if ($require_signed_response && !$is_artifact) {
        my $signature = $xpath->findnodes('/samlp:Response/dsig:Signature', $response);
        # FIXME: should check that a Response-level Signature cryptographically
        # validates and it actually covers this Response - Assertion verification
        # happens downstream.
        if ($signature->size != 1) {
            croak "Net::SAML2::Object::Response requires that the Response "
                . "include exactly one Signature.  Pass `require_signed_response` = 0 "
                . "to allow unsigned Responses";
        }
    }

    my $code_path = 'samlp:Status/samlp:StatusCode';
    if ($is_artifact) {
      $code_path = "samlp:Response/$code_path";
    }

    my $status = $xpath->findnodes($code_path, $response);
    croak("Unable to parse status from response") unless $status->size;

    my $status_node = $status->get_node(1);
    $status = $status_node->getAttribute('Value');

    my $substatus = $xpath->findvalue('samlp:StatusCode/@Value', $status_node);

    my $nodes = $xpath->findnodes('//saml:EncryptedAssertion|//saml:Assertion', $response);

    return $self->new(
        dom    => $xml,
        status => $status,
        $substatus ? ( substatus => $substatus) : (),
        issuer => $xpath->findvalue('saml:Issuer', $response),
        id     => $response->getAttribute('ID'),
        in_response_to => $response->getAttribute('InResponseTo'),
        $nodes->size ? (assertions => $nodes) : (),
        $cacert ? (cacert => $cacert) : (),
        $cert_text ? (cert_text => $cert_text) : (),
        $insecure_trust_embedded_cert ? (insecure_trust_embedded_cert => $insecure_trust_embedded_cert) : (),
        require_signed_response => $require_signed_response,
    );
}


sub to_string {
    my $self = shift;
    return $self->_dom->toString;
}


sub to_assertion {
    my $self = shift;
    my %args = @_;

    if (!$self->has_assertions) {
        croak("There are no assertions found in the response object");
    }

    # Propagate the trust configuration from the Response so the Assertion
    # inherits the same trust anchor.  Without this the caller would have to
    # supply cacert (or insecure_trust_embedded_cert) a second time, and a
    # Response built with a trust anchor could silently produce an Assertion
    # built with none.  Caller-supplied %args still override these defaults.
    return Net::SAML2::Protocol::Assertion->new_from_xml(
        $self->cacert ? (cacert => $self->cacert) : (),
        $self->cert_text ? (cert_text => $self->cert_text) : (),
        $self->insecure_trust_embedded_cert
            ? (insecure_trust_embedded_cert => $self->insecure_trust_embedded_cert)
            : (),
        %args,
        xml => $self->to_string,
    );
}

1;


__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::SAML2::Object::Response - A response object

=head1 VERSION

version 0.89

=head1 SYNOPSIS

    use Net::SAML2::Object::Response;

    my $xml = ...;
    my $response = Net::SAML2::Object::Response->new_from_xml(xml => $xml);

    if (!$response->is_success) {
        warn "Got a response but isn't successful";

        my $status = $response->status;
        my $substatus = $response->substatus;

        warn "We got a $status back with the following sub status $substatus";
    }
    else {
        $response->to_assertion(
            # See Net::SAML2::Protocol::Assertion->new_from_xml for the other
            # construction options
            key_file => ...,
            key_name => ...,
        )
    }

=head1 DESCRIPTION

A generic response object to be able to deal with an response from the IdP. If
the status is successful you can grab an assertion and continue your flow.

=head1 ATTRIBUTES

=head2 status

Returns the status of the response

=head2 substatus

Returns the sub status of the response

=head2 assertions

Returns the nodes of the assertion

=head2 cacert

path to the CA certificate for verification.  Trusts the certificate
embedded in the document once it chains to this CA.

One of C<cacert> or C<cert_text> is required for ensuring that the
Response is properly validated.

=head2 cert_text

text form of the IdP signing certificate (FORMAT_PEM).  Pins that exact
certificate instead of accepting anything that chains to a CA, and is
propagated to the Assertion by C<to_assertion> exactly as C<cacert> is.
See L<Net::SAML2::Protocol::Assertion/new_from_xml>.

=head2 insecure_trust_embedded_cert

Boolean, default false. When true, C<to_assertion> proceeds with
no pre-configured trust anchor (every embedded signing certificate
is accepted). B<This disables effective signature verification and
is intended only for local testing.> Production deployments must
leave this false and supply C<cacert> or C<cert_text>.

=head1 METHODS

=head2 $self->new_from_xml(xml => $xml, destination => $destination)

Creates the response object based on the response XML

=head2 $self->to_string

Stringify the object to the full response XML

=head2 $self->to_assertion(%args)

Create a L<Net::SAML2::Protocol::Assertion> from the response. See
L<Net::SAML2::Protocol::Assertion/new_from_xml> for more.

=head1 AUTHOR

Timothy Legge <timlegge@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Venda Ltd, see the CONTRIBUTORS file for others.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

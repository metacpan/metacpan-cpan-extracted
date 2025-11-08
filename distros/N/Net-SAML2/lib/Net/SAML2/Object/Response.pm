package Net::SAML2::Object::Response;
use Moose;

our $VERSION = '0.83'; # VERSION

use overload '""' => 'to_string';

# ABSTRACT: A response object

use MooseX::Types::DateTime qw/ DateTime /;
use MooseX::Types::Common::String qw/ NonEmptySimpleStr /;
use DateTime;
use DateTime::HiRes;
use DateTime::Format::XSD;
use Net::SAML2::XML::Util qw/ no_comments /;
use Net::SAML2::XML::Sig;
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


sub new_from_xml {
    my $self = shift;
    my %args = @_;

    my $xml = no_comments($args{xml});

    my $xpath = XML::LibXML::XPathContext->new($xml);
    $xpath->registerNs('saml',  URN_ASSERTION);
    $xpath->registerNs('samlp', URN_PROTOCOL);

    my $response = $xpath->findnodes('/samlp:Response|/samlp:ArtifactResponse');
    croak("Unable to parse response") unless $response->size;
    $response = $response->get_node(1);

    my $code_path = 'samlp:Status/samlp:StatusCode';
    if ($response->nodePath eq '/samlp:ArtifactResponse') {
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

    return Net::SAML2::Protocol::Assertion->new_from_xml(%args,
        xml => $self->to_string,);
}

1;


__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::SAML2::Object::Response - A response object

=head1 VERSION

version 0.83

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

=head1 METHODS

=head2 $self->new_from_xml(xml => $xml)

Creates the response object based on the response XML

=head2 $self->to_string

Stringify the object to the full response XML

=head2 $self->to_assertion(%args)

Create a L<Net::SAML2::Protocol::Assertion> from the response. See
L<Net::SAML2::Protocol::Assertion/new_from_xml> for more.

=head1 AUTHORS

=over 4

=item *

Chris Andrews  <chrisa@cpan.org>

=item *

Timothy Legge <timlegge@gmail.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Venda Ltd, see the CONTRIBUTORS file for others.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

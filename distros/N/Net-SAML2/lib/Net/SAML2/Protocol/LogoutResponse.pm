package Net::SAML2::Protocol::LogoutResponse;
use Moose;
our $VERSION = '0.84'; # VERSION

use MooseX::Types::URI qw/ Uri /;
use Net::SAML2::XML::Util qw/ no_comments /;
use Net::SAML2::Util qw/ deprecation_warning /;
use XML::LibXML::XPathContext;

with 'Net::SAML2::Role::ProtocolMessage';

# ABSTRACT: SAML2 LogoutResponse Protocol object


has 'status'          => (isa      => 'Str', is => 'ro', required => 1);
has 'substatus'      => (isa      => 'Str', is => 'ro', required => 0);
has '+in_response_to' => (required => 1);

# Remove response_to/substatus after 6 months from now (april 18th 2024)
around BUILDARGS => sub {
    my $orig = shift;
    my $self = shift;
    my %args = @_;

    if (my $irt = delete $args{response_to}) {
        $args{in_response_to} = $irt;
        deprecation_warning(
            "Please use in_response_to instead of response_to");
    }

    return $self->$orig(%args);
};


sub response_to {
    my $self = shift;
    deprecation_warning("Please use in_response_to instead of response_to");
    return $self->in_response_to;
}


sub new_from_xml {
    my ($class, %args) = @_;

    my $dom = no_comments($args{xml});

    my $xpath = XML::LibXML::XPathContext->new($dom);
    $xpath->registerNs('saml', 'urn:oasis:names:tc:SAML:2.0:assertion');
    $xpath->registerNs('samlp', 'urn:oasis:names:tc:SAML:2.0:protocol');

    my $self = $class->new(
        id          => $xpath->findvalue('/samlp:LogoutResponse/@ID'),
        in_response_to => $xpath->findvalue('/samlp:LogoutResponse/@InResponseTo'),
        destination => $xpath->findvalue('/samlp:LogoutResponse/@Destination'),
        session     => $xpath->findvalue('/samlp:LogoutResponse/samlp:SessionIndex'),
        issuer      => $xpath->findvalue('/samlp:LogoutResponse/saml:Issuer'),
        status      => $xpath->findvalue('/samlp:LogoutResponse/samlp:Status/samlp:StatusCode/@Value'),
        substatus  => $xpath->findvalue('/samlp:LogoutResponse/samlp:Status/samlp:StatusCode/samlp:StatusCode/@Value'),
    );

    return $self;
}


sub as_xml {
    my ($self) = @_;

    my $x = XML::Generator->new(':pretty');
    my $saml  = ['saml' => 'urn:oasis:names:tc:SAML:2.0:assertion'];
    my $samlp = ['samlp' => 'urn:oasis:names:tc:SAML:2.0:protocol'];

    $x->xml(
        $x->LogoutResponse(
            $samlp,
            { ID => $self->id,
              Version => '2.0',
              IssueInstant => $self->issue_instant,
              Destination => $self->destination,
              InResponseTo => $self->in_response_to },
            $x->Issuer(
                $saml,
                $self->issuer,
            ),
            $x->Status(
                $samlp,
                $x->StatusCode(
                    $samlp,
                    { Value => $self->status },
                )
            )
        )
    );
}

__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::SAML2::Protocol::LogoutResponse - SAML2 LogoutResponse Protocol object

=head1 VERSION

version 0.84

=head1 SYNOPSIS

    my $logout_req = Net::SAML2::Protocol::LogoutResponse->new(
        issuer          => $issuer,
        destination     => $destination,
        status          => $status,
        in_response_to  => $in_response_to,
    );

=head1 DESCRIPTION

This object deals with the LogoutResponse messages from SAML. It implements the
role L<Net::SAML2::Role::ProtocolMessage>.

=head1 METHODS

=head2 new( ... )

Constructor. Returns an instance of the LogoutResponse object.

Arguments:

=over

=item B<issuer>

SP's identity URI (required)

=item B<destination>

IdP's identity URI

=item B<status>

Response status (required)

=item B<substatus>

The sub status

=item B<in_response_to>

Request ID we're responding to (required);

=back

=head2 response_to()

Deprecated use B<in_response_to>

=head2 new_from_xml( ... )

Create a LogoutResponse object from the given XML.

Arguments:

=over

=item B<xml>

XML data

=back

=head2 as_xml( )

Returns the LogoutResponse as XML.

=head1 SEE ALSO

=head2 L<Net::SAML2::Roles::ProtocolMessage>

=head1 AUTHOR

Timothy Legge <timlegge@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Venda Ltd, see the CONTRIBUTORS file for others.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

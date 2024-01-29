package Net::SAML2::Protocol::LogoutRequest;
use Moose;

our $VERSION = '0.76'; # VERSION

use MooseX::Types::Common::String qw/ NonEmptySimpleStr /;
use MooseX::Types::URI qw/ Uri /;
use Net::SAML2::XML::Util qw/ no_comments /;
use XML::Generator;
use URN::OASIS::SAML2 qw(:urn);
use XML::LibXML::XPathContext;

with 'Net::SAML2::Role::ProtocolMessage';

# ABSTRACT: SAML2 LogoutRequest Protocol object


has 'session'       => (isa => NonEmptySimpleStr, is => 'ro', required => 1);
has 'nameid'        => (isa => NonEmptySimpleStr, is => 'ro', required => 1);
has 'nameid_format' => (
    isa       => NonEmptySimpleStr,
    is        => 'ro',
    required  => 0,
    predicate => 'has_nameid_format'
);
has 'destination' => (
    isa       => NonEmptySimpleStr,
    is        => 'ro',
    required  => 0,
    predicate => 'has_destination'
);

has sp_provided_id => (
    isa       => NonEmptySimpleStr,
    is        => 'ro',
    required  => 0,
    predicate => 'has_sp_provided_id'
);

has affiliation_group_id => (
    isa       => NonEmptySimpleStr,
    is        => 'ro',
    required  => 0,
    predicate => 'has_affiliation_group_id'
);

has name_qualifier => (
    isa       => NonEmptySimpleStr,
    is        => 'ro',
    required  => 0,
    predicate => 'has_name_qualifier'
);
has include_name_qualifier =>
    (isa => 'Bool', is => 'ro', required => 0, default => 0);

around BUILDARGS => sub {
    my $orig = shift;
    my $self = shift;
    my %args = @_;

    if ($args{nameid_format} && $args{nameid_format} eq 'urn:oasis:names:tc:SAML:2.0:nameidformat:persistent') {
        $args{include_name_qualifier} = 1;
    }

    return $self->$orig(%args);
};



sub new_from_xml {
    my ($class, %args) = @_;

    my $dom = no_comments($args{xml});

    my $xpath = XML::LibXML::XPathContext->new($dom);
    $xpath->registerNs('saml',  URN_ASSERTION);
    $xpath->registerNs('samlp', URN_PROTOCOL);

    my %params = (
        id          => $xpath->findvalue('/samlp:LogoutRequest/@ID'),
        session     => $xpath->findvalue('/samlp:LogoutRequest/samlp:SessionIndex'),
        issuer      => $xpath->findvalue('/samlp:LogoutRequest/saml:Issuer'),
        nameid      => $xpath->findvalue('/samlp:LogoutRequest/saml:NameID'),
        destination => $xpath->findvalue('/samlp:LogoutRequest/@Destination'),
    );

    my $nameid_format
        = $xpath->findvalue('/samlp:LogoutRequest/saml:NameID/@Format');

    $params{nameid_format} = $nameid_format
        if NonEmptySimpleStr->check($nameid_format);

    $params{include_name_qualifier} = $args{include_name_qualifier}
        if $args{include_name_qualifier};

    return $class->new(%params);
}


sub as_xml {
    my $self = shift;

    my $x     = XML::Generator->new(':pretty=0');
    my $saml  = ['saml'  => URN_ASSERTION];
    my $samlp = ['samlp' => URN_PROTOCOL];


    $x->xml(
        $x->LogoutRequest(
            $samlp,
            {
                ID           => $self->id,
                IssueInstant => $self->issue_instant,
                $self->has_destination
                ? (Destination => $self->destination)
                : (),
                Version => '2.0'
            },
            $x->Issuer($saml, $self->issuer),
            $x->NameID(
                $saml,
                {
                    $self->has_nameid_format
                    ? (Format => $self->nameid_format)
                    : (),
                    $self->has_sp_provided_id ? (
                        SPProvidedID => $self->sp_provided_id
                    ) : (),
                    $self->include_name_qualifier
                    ? (
                        $self->has_name_qualifier
                        ? (NameQualifier => $self->name_qualifier)
                        : ($self->has_destination ? (NameQualifier => $self->destination) : ()),
                        SPNameQualifier =>
                        $self->has_affiliation_group_id ? $self->affiliation_group_id : $self->issuer
                        )
                    : (),
                },
                $self->nameid
            ),
            $x->SessionIndex($samlp, $self->session),
        )
    );
}

__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::SAML2::Protocol::LogoutRequest - SAML2 LogoutRequest Protocol object

=head1 VERSION

version 0.76

=head1 SYNOPSIS

  my $logout_req = Net::SAML2::Protocol::LogoutRequest->new(
    issuer      => $issuer,
    destination => $destination,
    nameid      => $nameid,
    session     => $session,
  );

=head1 METHODS

=head2 new( ... )

Constructor. Returns an instance of the LogoutRequest object.

Arguments:

=over

=item B<session>

Session to log out

=item B<nameid>

NameID of the user to log out

=item B<destination>

IdP's identity URI this is required for a signed message but likely should be
sent regardless

=back

The following options alter the output of the NameID element

=over

=item B<nameid_format>

When supplied adds the Format attribute to the NameID

=item B<sp_provided_id>

When supplied adds the SPProvidedID attribute to the NameID

=item B<include_name_qualifier>

Tell the module to include the NameQualifier and SPNameQualifier attributes in
the NameID. Defaults to false unless the B<nameid_format> equals
C<urn:oasis:names:tc:SAML:2.0:nameidformat:persistent>

=item B<name_qualifier>

When supplied sets the NameQualifier attribute. When not supplied, this
defaults to the destination.

=item B<affiliation_group_id>

When supplied sets the SPNameQualifier attribute. When not supplied, this
defaults to the issuer.

=back

=head2 new_from_xml( ... )

Create a LogoutRequest object from the given XML.

Arguments:

=over

=item B<xml>

XML data

=back

=head2 as_xml( )

Returns the LogoutRequest as XML.

=head1 AUTHORS

=over 4

=item *

Chris Andrews  <chrisa@cpan.org>

=item *

Timothy Legge <timlegge@gmail.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Venda Ltd, see the CONTRIBUTORS file for others.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

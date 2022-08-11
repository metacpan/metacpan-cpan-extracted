use strict;
use warnings;
package Net::SAML2::Protocol::LogoutRequest;
our $VERSION = '0.57'; # VERSION

use Moose;
use MooseX::Types::Common::String qw/ NonEmptySimpleStr /;
use MooseX::Types::URI qw/ Uri /;
use Net::SAML2::XML::Util qw/ no_comments /;
use XML::Generator;

with 'Net::SAML2::Role::ProtocolMessage';

# ABSTRACT: SAML2 LogoutRequest Protocol object


has 'session'       => (isa => NonEmptySimpleStr, is => 'ro', required => 1);
has 'nameid'        => (isa => NonEmptySimpleStr, is => 'ro', required => 1);
has 'nameid_format' => (isa => NonEmptySimpleStr, is => 'ro', required => 0);
has 'destination'   => (isa => NonEmptySimpleStr, is => 'ro', required => 0);


sub new_from_xml {
    my ($class, %args) = @_;

    my $dom = no_comments($args{xml});

    my $xpath = XML::LibXML::XPathContext->new($dom);
    $xpath->registerNs('saml', 'urn:oasis:names:tc:SAML:2.0:assertion');
    $xpath->registerNs('samlp', 'urn:oasis:names:tc:SAML:2.0:protocol');

    my %params = (
        id            => $xpath->findvalue('/samlp:LogoutRequest/@ID'),
        session       => $xpath->findvalue('/samlp:LogoutRequest/samlp:SessionIndex'),
        issuer        => $xpath->findvalue('/samlp:LogoutRequest/saml:Issuer'),
        nameid        => $xpath->findvalue('/samlp:LogoutRequest/saml:NameID'),
        destination   => $xpath->findvalue('/samlp:LogoutRequest/@Destination'),
    );

    my $nameid_format = $xpath->findvalue('/samlp:LogoutRequest/saml:NameID/@Format');
    if ( $nameid_format ne '' ) { $params{nameid_format} = $nameid_format; }

    my $self = $class->new(
        %params
    );

    return $self;
}


sub as_xml {
    my ($self) = @_;

    my $x = XML::Generator->new(':pretty');
    my $saml  = ['saml' => 'urn:oasis:names:tc:SAML:2.0:assertion'];
    my $samlp = ['samlp' => 'urn:oasis:names:tc:SAML:2.0:protocol'];

    $x->xml(
        $x->LogoutRequest(
            $samlp,
            { ID => $self->id,
              IssueInstant => $self->issue_instant,
              Destination => $self->destination,
              Version => '2.0' },
            $x->Issuer(
                $saml,
                $self->issuer,
            ),
            $x->NameID(
                $saml,
                { Format => $self->nameid_format,
                  NameQualifier => $self->destination,
                  SPNameQualifier => $self->issuer },
                $self->nameid,
            ),
            $x->SessionIndex(
                $samlp,
                $self->session,
            ),
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

version 0.57

=head1 SYNOPSIS

  my $logout_req = Net::SAML2::Protocol::LogoutRequest->new(
    issuer      => $issuer,
    destination => $destination,
    nameid      => $nameid,
    session     => $session,
  );

=head1 NAME

Net::SAML2::Protocol::LogoutRequest - the SAML2 LogoutRequest object

=head1 METHODS

=head2 new( ... )

Constructor. Returns an instance of the LogoutRequest object.

Arguments:

=over

=item B<session>

session to log out

=item B<nameid>

NameID of the user to log out

=item B<nameid_format>

NameIDFormat to specify

=item B<issuer>

SP's identity URI

=item B<destination>

IdP's identity URI this is required for a signed message but likely should be
sent regardless

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

=head1 AUTHOR

Chris Andrews  <chrisa@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Chris Andrews and Others, see the git log.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

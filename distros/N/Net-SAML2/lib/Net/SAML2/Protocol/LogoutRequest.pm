package Net::SAML2::Protocol::LogoutRequest;
use Moose;
use MooseX::Types::Common::String qw/ NonEmptySimpleStr /;
use MooseX::Types::URI qw/ Uri /;

with 'Net::SAML2::Role::ProtocolMessage';

=head1 NAME

Net::SAML2::Protocol::LogoutRequest - the SAML2 LogoutRequest object

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

 * session - the session to log out
 * nameid - the NameID of the user to log out
 * nameid_format - the NameIDFormat to specify
 * issuer - the SP's identity URI
 * destination -  the IdP's identity URI

=cut

has 'session'       => (isa => NonEmptySimpleStr, is => 'ro', required => 1);
has 'nameid'        => (isa => NonEmptySimpleStr, is => 'ro', required => 1);
has 'nameid_format' => (isa => NonEmptySimpleStr, is => 'ro', required => 1);
has 'issuer'        => (isa => Uri, is => 'ro', required => 1, coerce => 1);
has 'destination'   => (isa => Uri, is => 'ro', required => 1, coerce => 1);

=head2 new_from_xml

Create a LogoutRequest object from the given XML.

=cut

sub new_from_xml {
    my ($class, %args) = @_;

    my $xpath = XML::XPath->new( xml => $args{xml} );
    $xpath->set_namespace('saml', 'urn:oasis:names:tc:SAML:2.0:assertion');
    $xpath->set_namespace('samlp', 'urn:oasis:names:tc:SAML:2.0:protocol');

    my $self = $class->new(
        id            => $xpath->findvalue('/samlp:LogoutRequest/@ID')->value,
        session       => $xpath->findvalue('/samlp:LogoutRequest/samlp:SessionIndex')->value,
        issuer        => $xpath->findvalue('/samlp:LogoutRequest/saml:Issuer')->value,
        nameid        => $xpath->findvalue('/samlp:LogoutRequest/saml:NameID')->value,
        nameid_format => $xpath->findvalue('/samlp:LogoutRequest/saml:NameID/@Format')->value,
        destination   => $xpath->findvalue('/samlp:LogoutRequest/saml:NameID/@NameQualifier')->value,
    );

    return $self;
}

=head2 as_xml()

Returns the LogoutRequest as XML.

=cut

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

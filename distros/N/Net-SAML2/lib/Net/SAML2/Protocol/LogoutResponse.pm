package Net::SAML2::Protocol::LogoutResponse;
use Moose;
use MooseX::Types::Moose qw/ Str /;
use MooseX::Types::URI qw/ Uri /;

with 'Net::SAML2::Role::ProtocolMessage';

=head1 NAME

Net::SAML2::Protocol::LogoutResponse - the SAML2 LogoutResponse object

=head1 SYNOPSIS

  my $logout_req = Net::SAML2::Protocol::LogoutResponse->new(
    issuer      => $issuer,
    destination => $destination,
    status      => $status,
    response_to => $response_to,
  );

=head1 METHODS

=head2 new( ... )

Constructor. Returns an instance of the LogoutResponse object.

Arguments:

 * issuer - the SP's identity URI
 * destination -  the IdP's identity URI
 * status - the response status
 * response_to - the request ID we're responding to

=cut

has 'issuer'      => (isa => Uri, is => 'ro', required => 1, coerce => 1);
has 'destination' => (isa => Uri, is => 'ro', required => 1, coerce => 1);
has 'status'      => (isa => Str, is => 'ro', required => 1);
has 'response_to' => (isa => Str, is => 'ro', required => 1);

=head2 new_from_xml

Create a LogoutResponse object from the given XML.

=cut

sub new_from_xml {
    my ($class, %args) = @_;
     
    my $xpath = XML::XPath->new( xml => $args{xml} );
    $xpath->set_namespace('saml', 'urn:oasis:names:tc:SAML:2.0:assertion');
    $xpath->set_namespace('samlp', 'urn:oasis:names:tc:SAML:2.0:protocol');

    my $self = $class->new(
        id          => $xpath->findvalue('/samlp:LogoutResponse/@ID')->value,
        response_to => $xpath->findvalue('/samlp:LogoutResponse/@InResponseTo')->value,
        destination => $xpath->findvalue('/samlp:LogoutResponse/@Destination')->value,
        session     => $xpath->findvalue('/samlp:LogoutResponse/samlp:SessionIndex')->value,
        issuer      => $xpath->findvalue('/samlp:LogoutResponse/saml:Issuer')->value,
        status      => $xpath->findvalue('/samlp:LogoutResponse/samlp:Status/samlp:StatusCode/@Value')->value,
    );

    return $self;
}

=head2 as_xml()

Returns the LogoutResponse as XML.

=cut

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
              InResponseTo => $self->response_to },
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

=head2 success

Returns true if the Response's status is Success.

=cut

sub success {
    my ($self) = @_;
    return 1 if $self->status eq $self->status_uri('success');
    return 0;
}

__PACKAGE__->meta->make_immutable;

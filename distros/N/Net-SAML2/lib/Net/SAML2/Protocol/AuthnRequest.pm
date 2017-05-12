package Net::SAML2::Protocol::AuthnRequest;
use Moose;
use MooseX::Types::Moose qw /Str /;
use MooseX::Types::URI qw/ Uri /;
use MooseX::Types::Common::String qw/ NonEmptySimpleStr /;

with 'Net::SAML2::Role::ProtocolMessage';

=head1 NAME

Net::SAML2::Protocol::AuthnRequest - SAML2 AuthnRequest object

=head1 SYNOPSIS

  my $authnreq = Net::SAML2::Protocol::AuthnRequest->new(
    issueinstant => DateTime->now,
    issuer       => $self->{id},
    destination  => $destination,
  );

=head1 METHODS

=cut

=head2 new( ... )

Constructor. Creates an instance of the AuthnRequest object. 

Arguments:

 * issuer - the SP's identity URI
 * destination - the IdP's identity URI

=cut

has 'issuer'        => (isa => Uri, is => 'ro', required => 1, coerce => 1);
has 'destination'   => (isa => Uri, is => 'ro', required => 1, coerce => 1);
has 'nameid_format' => (isa => NonEmptySimpleStr, is => 'ro', required => 1);

=head2 as_xml()

Returns the AuthnRequest as XML.

=cut

sub as_xml {
    my ($self) = @_;

    my $x = XML::Generator->new(':pretty');
    my $saml  = ['saml' => 'urn:oasis:names:tc:SAML:2.0:assertion'];
    my $samlp = ['samlp' => 'urn:oasis:names:tc:SAML:2.0:protocol'];

    $x->xml(
        $x->AuthnRequest(
            $samlp,
            { Destination => $self->destination,
              ID => $self->id,
              IssueInstant => $self->issue_instant,
              ProviderName => "My SP's human readable name.",
              Version => '2.0' },
            $x->Issuer(
                $saml,
                $self->issuer,
            ),
            $x->NameIDPolicy(
                $samlp,
                { AllowCreate => '1',
                  Format => $self->nameid_format },
            )
        )
    );
}

__PACKAGE__->meta->make_immutable;

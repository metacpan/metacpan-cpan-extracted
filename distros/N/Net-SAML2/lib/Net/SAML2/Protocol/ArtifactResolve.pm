package Net::SAML2::Protocol::ArtifactResolve;
use Moose;
use MooseX::Types::Moose qw/ Str /;
use MooseX::Types::URI qw/ Uri /;

with 'Net::SAML2::Role::ProtocolMessage';

=head1 NAME

Net::SAML2::Protocol::ArtifactResolve - ArtifactResolve protocol class.

=head1 SYNOPSIS

  my $resolver = Net::SAML2::Binding::ArtifactResolve->new(
    issuer => 'http://localhost:3000',
  );

  my $response = $resolver->resolve(params->{SAMLart});

=head1 METHODS

=cut

=head2 new( ... )

Constructor. Returns an instance of the ArtifactResolve request for
the given issuer and artifact.

Arguments:

 * issuer - the issuing SP's identity URI
 * artifact - the artifact to be resolved
 * destination - the IdP's identity URI

=cut

has 'artifact'    => (isa => Str, is => 'ro', required => 1);
has 'issuer'      => (isa => Uri, is => 'ro', required => 1, coerce => 1);
has 'destination' => (isa => Uri, is => 'ro', required => 1, coerce => 1);


=head2 as_xml

Returns the ArtifactResolve request as XML.

=cut

sub as_xml {
    my ($self) = @_;

    my $x = XML::Generator->new(':pretty');
    my $saml  = ['saml' => 'urn:oasis:names:tc:SAML:2.0:assertion'];
    my $samlp = ['samlp' => 'urn:oasis:names:tc:SAML:2.0:protocol'];

    $x->xml(
        $x->ArtifactResolve(
            $samlp,
            { ID => $self->id,
              IssueInstant => $self->issue_instant,
              Destination => $self->destination,
              ProviderName => "My SP's human readable name.",
              Version => '2.0' },
            $x->Issuer(
                $saml,
                $self->issuer,
            ),
            $x->Artifact(
                $samlp,
                $self->artifact,
            ),
        )
    );
}

__PACKAGE__->meta->make_immutable;

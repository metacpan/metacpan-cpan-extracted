package Net::SAML2::Protocol::ArtifactResolve;
use Moose;
our $VERSION = '0.81'; # VERSION

use MooseX::Types::URI qw/ Uri /;
use URN::OASIS::SAML2 qw(:urn);

with 'Net::SAML2::Role::ProtocolMessage';

# ABSTRACT: ArtifactResolve protocol class



has 'issuer'      => (isa => 'Str', is => 'ro', required => 1);
has 'destination' => (isa => 'Str', is => 'ro', required => 1);
has 'artifact'    => (isa => 'Str', is => 'ro', required => 1);
has 'provider' => (
    isa       => 'Str',
    is        => 'ro',
    required  => 0,
    predicate => 'has_provider',
);


sub as_xml {
    my $self = shift;

    my $x = XML::Generator->new(':pretty');
    my $saml  = ['saml' => URN_ASSERTION ];
    my $samlp = ['samlp' => URN_PROTOCOL ];

    $x->xml(
        $x->ArtifactResolve(
            $samlp,
            { ID => $self->id,
              IssueInstant => $self->issue_instant,
              Destination => $self->destination,
              $self->has_provider ? (
                  ProviderName => $self->provider,
              ) : (),
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

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::SAML2::Protocol::ArtifactResolve - ArtifactResolve protocol class

=head1 VERSION

version 0.81

=head1 SYNOPSIS

    my $resolver = Net::SAML2::Protocol::ArtifactResolve->new(
        artifact    => 'yourartifact',
        destination => $idp->art_url('urn:oasis:names:tc:SAML:2.0:bindings:SOAP'), # https://idp.example.net/idp
        issuer      => $sp->id, # https://you.example.com/auth/saml
    );

    my $binding = Net::SAML2::Binding::SOAP->new(...);
    $binding->request($resolved->as_xml);

=head1 METHODS

=head2 new(%args)

    my $resolver = Net::SAML2::Protocol::ArtifactResolve->new(
        artifact    => 'yourartifact',
        destination => $idp->art_url('urn:oasis:names:tc:SAML:2.0:bindings:SOAP'), # https://idp.example.net/idp
        issuer      => $sp->id, # https://you.example.com/auth/saml
    );

Constructor. Returns an instance of the ArtifactResolve request for
the given issuer and artifact.

Arguments:

=over

=item B<issuer>

Issuing SP's identity URI

=item B<artifact>

Artifact to be resolved

=item B<destination>

IdP's identity URI

=item B<provider>

IdP's provider name

=back

=head2 as_xml()

Returns the ArtifactResolve request as XML.

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

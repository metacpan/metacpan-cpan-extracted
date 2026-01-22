package SBOM::CycloneDX::Declarations::Claim;

use 5.010001;
use strict;
use warnings;
use utf8;

use SBOM::CycloneDX::BomRef;
use SBOM::CycloneDX::List;

use Types::Standard qw(Str InstanceOf HashRef);
use Types::TypeTiny qw(ArrayLike);

use Moo;
use namespace::autoclean;

extends 'SBOM::CycloneDX::Base';

has bom_ref => (
    is     => 'rw',
    isa    => InstanceOf ['SBOM::CycloneDX::BomRef'],
    coerce => sub { ref($_[0]) ? $_[0] : SBOM::CycloneDX::BomRef->new($_[0]) }
);

# Array of bom-ref
has target => (is => 'rw', isa => ArrayLike [Str], default => sub { SBOM::CycloneDX::List->new });

has predicate => (is => 'rw', isa => Str);

# Array of bom-ref
has mitigation_strategies => (is => 'rw', isa => ArrayLike [Str], default => sub { SBOM::CycloneDX::List->new });

has reasoning => (is => 'rw', isa => Str);

# Array of bom-ref
has evidence => (is => 'rw', isa => ArrayLike [Str], default => sub { SBOM::CycloneDX::List->new });

# Array of bom-ref
has counter_evidence => (is => 'rw', isa => ArrayLike [Str], default => sub { SBOM::CycloneDX::List->new });

has external_references => (
    is      => 'rw',
    isa     => ArrayLike [InstanceOf ['SBOM::CycloneDX::ExternalReferences']],
    default => sub { SBOM::CycloneDX::List->new }
);

has signature => (is => 'rw', isa => HashRef);

sub TO_JSON {

    my $self = shift;

    my $json = {};

    $json->{'bom-ref'}            = $self->bom_ref               if $self->bom_ref;
    $json->{target}               = $self->target                if @{$self->target};
    $json->{predicate}            = $self->predicate             if $self->predicate;
    $json->{mitigationStrategies} = $self->mitigation_strategies if @{$self->mitigation_strategies};
    $json->{reasoning}            = $self->reasoning             if $self->reasoning;
    $json->{evidence}             = $self->evidence              if @{$self->evidence};
    $json->{counterEvidence}      = $self->counter_evidence      if @{$self->counter_evidence};
    $json->{externalReferences}   = $self->external_references   if @{$self->external_references};
    $json->{signature}            = $self->signature             if $self->signature;

    return $json;

}

1;

=encoding utf-8

=head1 NAME

SBOM::CycloneDX::Declarations::Claim - Claim

=head1 SYNOPSIS

    SBOM::CycloneDX::Declarations::Claim->new();


=head1 DESCRIPTION

L<SBOM::CycloneDX::Declarations::Claim> provides the claim object.

=head2 METHODS

L<SBOM::CycloneDX::Declarations::Claim> inherits all methods from L<SBOM::CycloneDX::Base>
and implements the following new ones.

=over

=item SBOM::CycloneDX::Declarations::Claim->new( %PARAMS )

Properties:

=over

=item * C<bom_ref>, An identifier which can be used to reference the object
elsewhere in the BOM. Every C<bom_ref> must be unique within the BOM.

=item * C<counter_evidence>, The list of `bom-ref` to counterEvidence that
supports this claim.

=item * C<evidence>, The list of `bom-ref` to evidence that supports this
claim.

=item * C<external_references>, External references provide a way to document
systems, sites, and information that may be relevant but are not included
with the BOM. They may also establish specific relationships within or
external to the BOM.

=item * C<mitigation_strategies>, The list of  `bom-ref` to the evidence
provided describing the mitigation strategies. Each mitigation strategy
should include an explanation of how any weaknesses in the evidence will be
mitigated.

=item * C<predicate>, The specific statement or assertion about the target.

=item * C<reasoning>, The written explanation of why the evidence provided
substantiates the claim.

=item * C<signature>, Enveloped signature in JSON Signature Format (JSF)
(L<https://cyberphone.github.io/doc/security/jsf.html>).

=item * C<target>, The `bom-ref` to a target representing a specific system,
application, API, module, team, person, process, business unit, company,
etc...  that this claim is being applied to.

=back

=item $claim->bom_ref

=item $claim->counter_evidence

=item $claim->evidence

=item $claim->external_references

=item $claim->mitigation_strategies

=item $claim->predicate

=item $claim->reasoning

=item $claim->signature

=item $claim->target

=back


=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/giterlizzi/perl-SBOM-CycloneDX/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/giterlizzi/perl-SBOM-CycloneDX>

    git clone https://github.com/giterlizzi/perl-SBOM-CycloneDX.git


=head1 AUTHOR

=over 4

=item * Giuseppe Di Terlizzi <gdt@cpan.org>

=back


=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2025-2026 by Giuseppe Di Terlizzi.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

package SBOM::CycloneDX::Declarations::Map;

use 5.010001;
use strict;
use warnings;
use utf8;

use SBOM::CycloneDX::List;

use Types::Standard qw(Str InstanceOf);
use Types::TypeTiny qw(ArrayLike);

use Moo;
use namespace::autoclean;

extends 'SBOM::CycloneDX::Base';

# Like bom-ref
has requirement => (is => 'rw', isa => Str);

# array of bom-ref
has claims => (is => 'rw', isa => ArrayLike [Str], default => sub { SBOM::CycloneDX::List->new });

# array of bom-ref
has counter_claims => (is => 'rw', isa => ArrayLike [Str], default => sub { SBOM::CycloneDX::List->new });

has conformance => (is => 'rw', isa => InstanceOf ['SBOM::CycloneDX::Declarations::Conformance']);
has confidence  => (is => 'rw', isa => InstanceOf ['SBOM::CycloneDX::Declarations::Confidence']);


sub TO_JSON {

    my $self = shift;

    my $json = {};

    $json->{requirement}   = $self->requirement    if $self->requirement;
    $json->{claims}        = $self->claims         if @{$self->claims};
    $json->{counterClaims} = $self->counter_claims if @{$self->counter_claims};
    $json->{conformance}   = $self->conformance    if $self->conformance;
    $json->{confidence}    = $self->confidence     if $self->confidence;

    return $json;

}

1;

=encoding utf-8

=head1 NAME

SBOM::CycloneDX::Declarations::Map - Map

=head1 SYNOPSIS

    SBOM::CycloneDX::Declarations::Map->new();


=head1 DESCRIPTION

L<SBOM::CycloneDX::Declarations::Map> provide the groupg of requirements to
claims and the attestors declared conformance and confidence thereof.

=head2 METHODS

L<SBOM::CycloneDX::Declarations::Map> inherits all methods from L<SBOM::CycloneDX::Base>
and implements the following new ones.

=over

=item SBOM::CycloneDX::Declarations::Map->new( %PARAMS )

Properties:

=over

=item C<claims>, The list of `bom-ref` to the claims being attested to.

=item C<confidence>, The confidence of the claim meeting the requirement.

=item C<conformance>, The conformance of the claim meeting a requirement.

=item C<counter_claims>, The list of  `bom-ref` to the counter claims being
attested to.

=item C<requirement>, The `bom-ref` to the requirement being attested to.

=back

=item $map->claims

=item $map->confidence

=item $map->conformance

=item $map->counter_claims

=item $map->requirement

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

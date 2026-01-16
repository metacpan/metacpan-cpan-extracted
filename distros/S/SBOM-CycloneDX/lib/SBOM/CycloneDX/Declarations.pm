package SBOM::CycloneDX::Declarations;

use 5.010001;
use strict;
use warnings;
use utf8;

use Types::Standard qw(Str InstanceOf HashRef);
use Types::TypeTiny qw(ArrayLike);

use Moo;
use namespace::autoclean;

extends 'SBOM::CycloneDX::Base';

has assessors => (
    is      => 'rw',
    isa     => ArrayLike [InstanceOf ['SBOM::CycloneDX::Declarations::Assessor']],
    default => sub { SBOM::CycloneDX::List->new }
);

has attestations => (
    is      => 'rw',
    isa     => ArrayLike [InstanceOf ['SBOM::CycloneDX::Declarations::Attastation']],
    default => sub { SBOM::CycloneDX::List->new }
);

has claims => (
    is      => 'rw',
    isa     => ArrayLike [InstanceOf ['SBOM::CycloneDX::Declarations::Claim']],
    default => sub { SBOM::CycloneDX::List->new }
);

has evidence => (
    is      => 'rw',
    isa     => ArrayLike [InstanceOf ['SBOM::CycloneDX::Declarations::Evidence']],
    default => sub { SBOM::CycloneDX::List->new }
);

has targets     => (is => 'rw', isa => InstanceOf ['SBOM::CycloneDX::Declarations::Targets']);
has affirmation => (is => 'rw', isa => InstanceOf ['SBOM::CycloneDX::Declarations::Affirmation']);
has signature   => (is => 'rw', isa => HashRef);

sub TO_JSON {

    my $self = shift;

    my $json = {};

    $json->{assessors}    = $self->assessors    if @{$self->assessors};
    $json->{attestations} = $self->attestations if @{$self->attestations};
    $json->{claims}       = $self->claims       if @{$self->claims};
    $json->{evidence}     = $self->evidence     if @{$self->evidence};
    $json->{targets}      = $self->targets      if $self->targets;
    $json->{affirmation}  = $self->affirmation  if $self->affirmation;
    $json->{signature}    = $self->signature    if $self->signature;

    return $json;

}

1;

=encoding utf-8

=head1 NAME

SBOM::CycloneDX::Declarations - Declarations

=head1 SYNOPSIS

    SBOM::CycloneDX::Declarations->new();


=head1 DESCRIPTION

L<SBOM::CycloneDX::Declarations> provides the list of declarations which describe
the conformance to standards. Each declaration may include attestations,
claims, and evidence.

=head2 METHODS

L<SBOM::CycloneDX::Declarations> inherits all methods from L<SBOM::CycloneDX::Base>
and implements the following new ones.

=over

=item SBOM::CycloneDX::Declarations->new( %PARAMS )

Properties:

=over

=item C<affirmation>, A concise statement affirmed by an individual
regarding all declarations, often used for third-party auditor acceptance
or recipient acknowledgment. It includes a list of authorized signatories
who assert the validity of the document on behalf of the organization.

=item C<assessors>, The list of assessors evaluating claims and determining
conformance to requirements and confidence in that assessment.

=item C<attestations>, The list of attestations asserted by an assessor
that maps requirements to claims.

=item C<claims>, The list of claims.

=item C<evidence>, The list of evidence

=item C<signature>, Enveloped signature in JSON Signature Format
(JSF) (L<https://cyberphone.github.io/doc/security/jsf.html>).

=item C<targets>, The list of targets which claims are made against.

=back

=item $declarations->affirmation

=item $declarations->assessors

=item $declarations->attestations

=item $declarations->claims

=item $declarations->evidence

=item $declarations->signature

=item $declarations->targets

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

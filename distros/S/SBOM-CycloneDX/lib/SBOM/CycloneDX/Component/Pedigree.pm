package SBOM::CycloneDX::Component::Pedigree;

use 5.010001;
use strict;
use warnings;
use utf8;

use SBOM::CycloneDX::List;

use Types::Standard qw(InstanceOf Str);
use Types::TypeTiny qw(ArrayLike);

use Moo;
use namespace::autoclean;

extends 'SBOM::CycloneDX::Base';

has ancestors => (
    is      => 'rw',
    isa     => ArrayLike [InstanceOf ['SBOM::CycloneDX::Component']],
    default => sub { SBOM::CycloneDX::List->new }
);

has descendants => (
    is      => 'rw',
    isa     => ArrayLike [InstanceOf ['SBOM::CycloneDX::Component']],
    default => sub { SBOM::CycloneDX::List->new }
);

has variants => (
    is      => 'rw',
    isa     => ArrayLike [InstanceOf ['SBOM::CycloneDX::Component']],
    default => sub { SBOM::CycloneDX::List->new }
);

has commits => (
    is      => 'rw',
    isa     => ArrayLike [InstanceOf ['SBOM::CycloneDX::Component::Commit']],
    default => sub { SBOM::CycloneDX::List->new }
);

has patches => (
    is      => 'rw',
    isa     => ArrayLike [InstanceOf ['SBOM::CycloneDX::Component::Patch']],
    default => sub { SBOM::CycloneDX::List->new }
);

has notes => (is => 'rw', isa => Str);

sub TO_JSON {

    my $self = shift;

    my $json = {};

    $json->{ancestors}   = $self->ancestors   if @{$self->ancestors};
    $json->{descendants} = $self->descendants if @{$self->descendants};
    $json->{variants}    = $self->variants    if @{$self->variants};
    $json->{commits}     = $self->commits     if @{$self->commits};
    $json->{patches}     = $self->patches     if @{$self->patches};
    $json->{notes}       = $self->notes       if $self->notes;

    return $json;

}

1;

=encoding utf-8

=head1 NAME

SBOM::CycloneDX::Component::Pedigree - Component Pedigree

=head1 SYNOPSIS

    SBOM::CycloneDX::Component::Pedigree->new();


=head1 DESCRIPTION

Component pedigree is a way to document complex supply chain scenarios where
components are created, distributed, modified, redistributed, combined with
other components, etc.
Pedigree supports viewing this complex chain from the beginning, the end,
or anywhere in the middle. It also provides a way to document variants
where the exact relation may not be known.

=head2 METHODS

L<SBOM::CycloneDX::Component::Pedigree> inherits all methods from L<SBOM::CycloneDX::Base>
and implements the following new ones.

=over

=item SBOM::CycloneDX::Component::Pedigree->new( %PARAMS )

Properties:

=over

=item * C<ancestors>, Describes zero or more components in which a component
is derived from. This is commonly used to describe forks from existing
projects where the forked version contains a ancestor node containing the
original component it was forked from. For example, Component A is the
original component. Component B is the component being used and documented
in the BOM. However, Component B contains a pedigree node with a single
ancestor documenting Component A - the original component from which
Component B is derived from.

=item * C<commits>, A list of zero or more commits which provide a trail
describing how the component deviates from an ancestor, descendant, or
variant.

=item * C<descendants>, Descendants are the exact opposite of ancestors. This
provides a way to document all forks (and their forks) of an original or
root component.

=item * C<notes>, Notes, observations, and other non-structured commentary
describing the components pedigree.

=item * C<patches>, A list of zero or more patches describing how the
component deviates from an ancestor, descendant, or variant. Patches may be
complementary to commits or may be used in place of commits.

=item * C<variants>, Variants describe relations where the relationship
between the components is not known. For example, if Component A contains
nearly identical code to Component B. They are both related, but it is
unclear if one is derived from the other, or if they share a common
ancestor.

=back

=item $pedigree->ancestors

=item $pedigree->commits

=item $pedigree->descendants

=item $pedigree->notes

=item $pedigree->patches

=item $pedigree->variants

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

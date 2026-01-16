package SBOM::CycloneDX::ReleaseNotes;

use 5.010001;
use strict;
use warnings;
use utf8;

use SBOM::CycloneDX::List;
use SBOM::CycloneDX::Timestamp;

use Types::Standard qw(Str InstanceOf);
use Types::TypeTiny qw(ArrayLike);

use Moo;
use namespace::autoclean;

extends 'SBOM::CycloneDX::Base';

has type           => (is => 'rw', isa => Str, required => 1);
has title          => (is => 'rw', isa => Str);
has featured_image => (is => 'rw', isa => Str);    # URL
has social_image   => (is => 'rw', isa => Str);
has description    => (is => 'rw', isa => Str);

has timestamp => (
    is     => 'rw',
    isa    => InstanceOf ['SBOM::CycloneDX::Timestamp'],
    coerce => sub { ref($_[0]) ? $_[0] : SBOM::CycloneDX::Timestamp->new($_[0]) }
);

has aliases => (is => 'rw', isa => ArrayLike [Str], default => sub { SBOM::CycloneDX::List->new });
has tags    => (is => 'rw', isa => ArrayLike [Str], default => sub { SBOM::CycloneDX::List->new });

has resolves => (
    is      => 'rw',
    isa     => ArrayLike [InstanceOf ['SBOM::CycloneDX::Issue']],
    default => sub { SBOM::CycloneDX::List->new }
);

has notes => (
    is      => 'rw',
    isa     => ArrayLike [InstanceOf ['SBOM::CycloneDX::Note']],
    default => sub { SBOM::CycloneDX::List->new }
);

has properties => (
    is      => 'rw',
    isa     => ArrayLike [InstanceOf ['SBOM::CycloneDX::Property']],
    default => sub { SBOM::CycloneDX::List->new }
);

sub TO_JSON {

    my $self = shift;

    my $json = {type => $self->type};

    $json->{title}         = $self->title          if $self->title;
    $json->{featuredImage} = $self->featured_image if $self->featured_image;
    $json->{socialImage}   = $self->social_image   if $self->social_image;
    $json->{description}   = $self->description    if $self->description;
    $json->{timestamp}     = $self->timestamp      if $self->timestamp;
    $json->{aliases}       = $self->aliases        if @{$self->aliases};
    $json->{tags}          = $self->tags           if @{$self->tags};
    $json->{resolves}      = $self->resolves       if @{$self->resolves};
    $json->{notes}         = $self->notes          if @{$self->notes};
    $json->{properties}    = $self->properties     if @{$self->properties};

    return $json;

}

1;

=encoding utf-8

=head1 NAME

SBOM::CycloneDX::ReleaseNotes - Specifies release notes

=head1 SYNOPSIS

    $release_notes = SBOM::CycloneDX::ReleaseNotes->new(
        type => 'major'
    );


=head1 DESCRIPTION

L<SBOM::CycloneDX::ReleaseNotes> provides the release notes.

=head2 METHODS

L<SBOM::CycloneDX::ReleaseNotes> inherits all methods from L<SBOM::CycloneDX::Base>
and implements the following new ones.

=over

=item SBOM::CycloneDX::ReleaseNotes->new( %PARAMS )

Properties:

=over

=item * C<type>, The software versioning type the release note describes.

=item * C<title>, The title of the release.

=item * C<featured_image>, The URL to an image that may be prominently displayed
with the release note.

=item * C<social_image>, The URL to an image that may be used in messaging on
social media platforms.

=item * C<description>, A short description of the release.

=item * C<timestamp>, The date and time (timestamp) when the release note was
created.

=item * C<aliases>, One or more alternate names the release may be referred to.
This may include unofficial terms used by development and marketing teams (e.g.
code names).

=item * C<tags>, Textual strings that aid in discovery, search, and retrieval of
the associated object. Tags often serve as a way to group or categorize similar
or related objects by various attributes.

=item * C<resolves>, A collection of issues that have been resolved.
See L<SBOM::CycloneDX::Issue>

=item * C<notes>, Zero or more release notes containing the locale and content.
Multiple note objects may be specified to support release notes in a wide variety
of languages. See L<SBOM::CycloneDX::Note>

=item * C<properties>, Provides the ability to document properties in a name-value
store. This provides flexibility to include data not officially supported in the
standard without having to use additional namespaces or create extensions.
Unlike key-value stores, properties support duplicate names, each potentially
having different values. Property names of interest to the general public are
encouraged to be registered in the CycloneDX Property Taxonomy. Formal
registration is optional. See L<SBOM::CycloneDX::Property>

=back

=item $release_notes->type

=item $release_notes->title

=item $release_notes->featured_image

=item $release_notes->social_image

=item $release_notes->description

=item $release_notes->timestamp

=item $release_notes->aliases

=item $release_notes->tags

=item $release_notes->resolves

=item $release_notes->notes

=item $release_notes->properties


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

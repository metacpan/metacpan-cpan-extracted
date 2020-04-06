use utf8;

package SemanticWeb::Schema::ComicStory;

# ABSTRACT: The term "story" is any indivisible

use Moo;

extends qw/ SemanticWeb::Schema::CreativeWork /;


use MooX::JSON_LD 'ComicStory';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v7.0.3';


has artist => (
    is        => 'rw',
    predicate => '_has_artist',
    json_ld   => 'artist',
);



has colorist => (
    is        => 'rw',
    predicate => '_has_colorist',
    json_ld   => 'colorist',
);



has inker => (
    is        => 'rw',
    predicate => '_has_inker',
    json_ld   => 'inker',
);



has letterer => (
    is        => 'rw',
    predicate => '_has_letterer',
    json_ld   => 'letterer',
);



has penciler => (
    is        => 'rw',
    predicate => '_has_penciler',
    json_ld   => 'penciler',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::ComicStory - The term "story" is any indivisible

=head1 VERSION

version v7.0.3

=head1 DESCRIPTION

The term "story" is any indivisible, re-printable unit of a comic,
including the interior stories, covers, and backmatter. Most comics have at
least two stories: a cover (ComicCoverArt) and an interior story.

=head1 ATTRIBUTES

=head2 C<artist>

The primary artist for a work in a medium other than pencils or digital
line art--for example, if the primary artwork is done in watercolors or
digital paints.

A artist should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Person']>

=back

=head2 C<_has_artist>

A predicate for the L</artist> attribute.

=head2 C<colorist>

The individual who adds color to inked drawings.

A colorist should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Person']>

=back

=head2 C<_has_colorist>

A predicate for the L</colorist> attribute.

=head2 C<inker>

The individual who traces over the pencil drawings in ink after pencils are
complete.

A inker should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Person']>

=back

=head2 C<_has_inker>

A predicate for the L</inker> attribute.

=head2 C<letterer>

The individual who adds lettering, including speech balloons and sound
effects, to artwork.

A letterer should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Person']>

=back

=head2 C<_has_letterer>

A predicate for the L</letterer> attribute.

=head2 C<penciler>

The individual who draws the primary narrative artwork.

A penciler should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Person']>

=back

=head2 C<_has_penciler>

A predicate for the L</penciler> attribute.

=head1 SEE ALSO

L<SemanticWeb::Schema::CreativeWork>

=head1 SOURCE

The development version is on github at L<https://github.com/robrwo/SemanticWeb-Schema>
and may be cloned from L<git://github.com/robrwo/SemanticWeb-Schema.git>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/robrwo/SemanticWeb-Schema/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018-2020 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

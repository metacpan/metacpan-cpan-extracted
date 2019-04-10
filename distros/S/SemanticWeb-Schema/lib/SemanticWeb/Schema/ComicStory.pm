use utf8;

package SemanticWeb::Schema::ComicStory;

# ABSTRACT: The term "story" is any indivisible

use Moo;

extends qw/ SemanticWeb::Schema::CreativeWork /;


use MooX::JSON_LD 'ComicStory';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v3.5.0';


has artist => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'artist',
);



has colorist => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'colorist',
);



has inker => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'inker',
);



has letterer => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'letterer',
);



has penciler => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'penciler',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::ComicStory - The term "story" is any indivisible

=head1 VERSION

version v3.5.0

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

=head2 C<colorist>

The individual who adds color to inked drawings.

A colorist should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Person']>

=back

=head2 C<inker>

The individual who traces over the pencil drawings in ink after pencils are
complete.

A inker should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Person']>

=back

=head2 C<letterer>

The individual who adds lettering, including speech balloons and sound
effects, to artwork.

A letterer should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Person']>

=back

=head2 C<penciler>

The individual who draws the primary narrative artwork.

A penciler should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Person']>

=back

=head1 SEE ALSO

L<SemanticWeb::Schema::CreativeWork>

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

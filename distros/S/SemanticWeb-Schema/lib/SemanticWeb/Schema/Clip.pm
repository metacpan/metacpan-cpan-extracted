use utf8;

package SemanticWeb::Schema::Clip;

# ABSTRACT: A short TV or radio program or a segment/part of a program.

use Moo;

extends qw/ SemanticWeb::Schema::CreativeWork /;


use MooX::JSON_LD 'Clip';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v3.8.1';


has actor => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'actor',
);



has actors => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'actors',
);



has clip_number => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'clipNumber',
);



has director => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'director',
);



has directors => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'directors',
);



has music_by => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'musicBy',
);



has part_of_episode => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'partOfEpisode',
);



has part_of_season => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'partOfSeason',
);



has part_of_series => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'partOfSeries',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::Clip - A short TV or radio program or a segment/part of a program.

=head1 VERSION

version v3.8.1

=head1 DESCRIPTION

A short TV or radio program or a segment/part of a program.

=head1 ATTRIBUTES

=head2 C<actor>

An actor, e.g. in tv, radio, movie, video games etc., or in an event.
Actors can be associated with individual items or with a series, episode,
clip.

A actor should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Person']>

=back

=head2 C<actors>

An actor, e.g. in tv, radio, movie, video games etc. Actors can be
associated with individual items or with a series, episode, clip.

A actors should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Person']>

=back

=head2 C<clip_number>

C<clipNumber>

Position of the clip within an ordered group of clips.

A clip_number should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Integer']>

=item C<Str>

=back

=head2 C<director>

A director of e.g. tv, radio, movie, video gaming etc. content, or of an
event. Directors can be associated with individual items or with a series,
episode, clip.

A director should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Person']>

=back

=head2 C<directors>

A director of e.g. tv, radio, movie, video games etc. content. Directors
can be associated with individual items or with a series, episode, clip.

A directors should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Person']>

=back

=head2 C<music_by>

C<musicBy>

The composer of the soundtrack.

A music_by should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::MusicGroup']>

=item C<InstanceOf['SemanticWeb::Schema::Person']>

=back

=head2 C<part_of_episode>

C<partOfEpisode>

The episode to which this clip belongs.

A part_of_episode should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Episode']>

=back

=head2 C<part_of_season>

C<partOfSeason>

The season to which this episode belongs.

A part_of_season should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::CreativeWorkSeason']>

=back

=head2 C<part_of_series>

C<partOfSeries>

The series to which this episode or season belongs.

A part_of_series should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::CreativeWorkSeries']>

=back

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

This software is Copyright (c) 2018-2019 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

use utf8;

package SemanticWeb::Schema::RadioSeries;

# ABSTRACT: CreativeWorkSeries dedicated to radio broadcast and associated online delivery.

use Moo;

extends qw/ SemanticWeb::Schema::CreativeWorkSeries /;


use MooX::JSON_LD 'RadioSeries';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v8.0.0';


has actor => (
    is        => 'rw',
    predicate => '_has_actor',
    json_ld   => 'actor',
);



has actors => (
    is        => 'rw',
    predicate => '_has_actors',
    json_ld   => 'actors',
);



has contains_season => (
    is        => 'rw',
    predicate => '_has_contains_season',
    json_ld   => 'containsSeason',
);



has director => (
    is        => 'rw',
    predicate => '_has_director',
    json_ld   => 'director',
);



has directors => (
    is        => 'rw',
    predicate => '_has_directors',
    json_ld   => 'directors',
);



has episode => (
    is        => 'rw',
    predicate => '_has_episode',
    json_ld   => 'episode',
);



has episodes => (
    is        => 'rw',
    predicate => '_has_episodes',
    json_ld   => 'episodes',
);



has music_by => (
    is        => 'rw',
    predicate => '_has_music_by',
    json_ld   => 'musicBy',
);



has number_of_episodes => (
    is        => 'rw',
    predicate => '_has_number_of_episodes',
    json_ld   => 'numberOfEpisodes',
);



has number_of_seasons => (
    is        => 'rw',
    predicate => '_has_number_of_seasons',
    json_ld   => 'numberOfSeasons',
);



has production_company => (
    is        => 'rw',
    predicate => '_has_production_company',
    json_ld   => 'productionCompany',
);



has season => (
    is        => 'rw',
    predicate => '_has_season',
    json_ld   => 'season',
);



has seasons => (
    is        => 'rw',
    predicate => '_has_seasons',
    json_ld   => 'seasons',
);



has trailer => (
    is        => 'rw',
    predicate => '_has_trailer',
    json_ld   => 'trailer',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::RadioSeries - CreativeWorkSeries dedicated to radio broadcast and associated online delivery.

=head1 VERSION

version v8.0.0

=head1 DESCRIPTION

CreativeWorkSeries dedicated to radio broadcast and associated online
delivery.

=head1 ATTRIBUTES

=head2 C<actor>

An actor, e.g. in tv, radio, movie, video games etc., or in an event.
Actors can be associated with individual items or with a series, episode,
clip.

A actor should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Person']>

=back

=head2 C<_has_actor>

A predicate for the L</actor> attribute.

=head2 C<actors>

An actor, e.g. in tv, radio, movie, video games etc. Actors can be
associated with individual items or with a series, episode, clip.

A actors should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Person']>

=back

=head2 C<_has_actors>

A predicate for the L</actors> attribute.

=head2 C<contains_season>

C<containsSeason>

A season that is part of the media series.

A contains_season should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::CreativeWorkSeason']>

=back

=head2 C<_has_contains_season>

A predicate for the L</contains_season> attribute.

=head2 C<director>

A director of e.g. tv, radio, movie, video gaming etc. content, or of an
event. Directors can be associated with individual items or with a series,
episode, clip.

A director should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Person']>

=back

=head2 C<_has_director>

A predicate for the L</director> attribute.

=head2 C<directors>

A director of e.g. tv, radio, movie, video games etc. content. Directors
can be associated with individual items or with a series, episode, clip.

A directors should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Person']>

=back

=head2 C<_has_directors>

A predicate for the L</directors> attribute.

=head2 C<episode>

An episode of a tv, radio or game media within a series or season.

A episode should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Episode']>

=back

=head2 C<_has_episode>

A predicate for the L</episode> attribute.

=head2 C<episodes>

An episode of a TV/radio series or season.

A episodes should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Episode']>

=back

=head2 C<_has_episodes>

A predicate for the L</episodes> attribute.

=head2 C<music_by>

C<musicBy>

The composer of the soundtrack.

A music_by should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::MusicGroup']>

=item C<InstanceOf['SemanticWeb::Schema::Person']>

=back

=head2 C<_has_music_by>

A predicate for the L</music_by> attribute.

=head2 C<number_of_episodes>

C<numberOfEpisodes>

The number of episodes in this season or series.

A number_of_episodes should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Integer']>

=back

=head2 C<_has_number_of_episodes>

A predicate for the L</number_of_episodes> attribute.

=head2 C<number_of_seasons>

C<numberOfSeasons>

The number of seasons in this series.

A number_of_seasons should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Integer']>

=back

=head2 C<_has_number_of_seasons>

A predicate for the L</number_of_seasons> attribute.

=head2 C<production_company>

C<productionCompany>

The production company or studio responsible for the item e.g. series,
video game, episode etc.

A production_company should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Organization']>

=back

=head2 C<_has_production_company>

A predicate for the L</production_company> attribute.

=head2 C<season>

A season in a media series.

A season should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::CreativeWorkSeason']>

=item C<Str>

=back

=head2 C<_has_season>

A predicate for the L</season> attribute.

=head2 C<seasons>

A season in a media series.

A seasons should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::CreativeWorkSeason']>

=back

=head2 C<_has_seasons>

A predicate for the L</seasons> attribute.

=head2 C<trailer>

The trailer of a movie or tv/radio series, season, episode, etc.

A trailer should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::VideoObject']>

=back

=head2 C<_has_trailer>

A predicate for the L</trailer> attribute.

=head1 SEE ALSO

L<SemanticWeb::Schema::CreativeWorkSeries>

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

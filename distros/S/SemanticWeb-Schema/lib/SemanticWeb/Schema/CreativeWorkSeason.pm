use utf8;

package SemanticWeb::Schema::CreativeWorkSeason;

# ABSTRACT: A media season e

use Moo;

extends qw/ SemanticWeb::Schema::CreativeWork /;


use MooX::JSON_LD 'CreativeWorkSeason';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v5.0.1';


has actor => (
    is        => 'rw',
    predicate => '_has_actor',
    json_ld   => 'actor',
);



has director => (
    is        => 'rw',
    predicate => '_has_director',
    json_ld   => 'director',
);



has end_date => (
    is        => 'rw',
    predicate => '_has_end_date',
    json_ld   => 'endDate',
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



has number_of_episodes => (
    is        => 'rw',
    predicate => '_has_number_of_episodes',
    json_ld   => 'numberOfEpisodes',
);



has part_of_series => (
    is        => 'rw',
    predicate => '_has_part_of_series',
    json_ld   => 'partOfSeries',
);



has production_company => (
    is        => 'rw',
    predicate => '_has_production_company',
    json_ld   => 'productionCompany',
);



has season_number => (
    is        => 'rw',
    predicate => '_has_season_number',
    json_ld   => 'seasonNumber',
);



has start_date => (
    is        => 'rw',
    predicate => '_has_start_date',
    json_ld   => 'startDate',
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

SemanticWeb::Schema::CreativeWorkSeason - A media season e

=head1 VERSION

version v5.0.1

=head1 DESCRIPTION

A media season e.g. tv, radio, video game etc.

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

=head2 C<end_date>

C<endDate>

=for html <p>The end date and time of the item (in <a
href="http://en.wikipedia.org/wiki/ISO_8601">ISO 8601 date format</a>).<p>

A end_date should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_end_date>

A predicate for the L</end_date> attribute.

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

=head2 C<number_of_episodes>

C<numberOfEpisodes>

The number of episodes in this season or series.

A number_of_episodes should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Integer']>

=back

=head2 C<_has_number_of_episodes>

A predicate for the L</number_of_episodes> attribute.

=head2 C<part_of_series>

C<partOfSeries>

The series to which this episode or season belongs.

A part_of_series should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::CreativeWorkSeries']>

=back

=head2 C<_has_part_of_series>

A predicate for the L</part_of_series> attribute.

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

=head2 C<season_number>

C<seasonNumber>

Position of the season within an ordered group of seasons.

A season_number should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Integer']>

=item C<Str>

=back

=head2 C<_has_season_number>

A predicate for the L</season_number> attribute.

=head2 C<start_date>

C<startDate>

=for html <p>The start date and time of the item (in <a
href="http://en.wikipedia.org/wiki/ISO_8601">ISO 8601 date format</a>).<p>

A start_date should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_start_date>

A predicate for the L</start_date> attribute.

=head2 C<trailer>

The trailer of a movie or tv/radio series, season, episode, etc.

A trailer should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::VideoObject']>

=back

=head2 C<_has_trailer>

A predicate for the L</trailer> attribute.

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

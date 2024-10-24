use utf8;

package SemanticWeb::Schema::Movie;

# ABSTRACT: A movie.

use Moo;

extends qw/ SemanticWeb::Schema::CreativeWork /;


use MooX::JSON_LD 'Movie';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v9.0.0';


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



has country_of_origin => (
    is        => 'rw',
    predicate => '_has_country_of_origin',
    json_ld   => 'countryOfOrigin',
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



has duration => (
    is        => 'rw',
    predicate => '_has_duration',
    json_ld   => 'duration',
);



has music_by => (
    is        => 'rw',
    predicate => '_has_music_by',
    json_ld   => 'musicBy',
);



has production_company => (
    is        => 'rw',
    predicate => '_has_production_company',
    json_ld   => 'productionCompany',
);



has subtitle_language => (
    is        => 'rw',
    predicate => '_has_subtitle_language',
    json_ld   => 'subtitleLanguage',
);



has title_eidr => (
    is        => 'rw',
    predicate => '_has_title_eidr',
    json_ld   => 'titleEIDR',
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

SemanticWeb::Schema::Movie - A movie.

=head1 VERSION

version v9.0.0

=head1 DESCRIPTION

A movie.

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

=head2 C<country_of_origin>

C<countryOfOrigin>

The country of the principal offices of the production company or
individual responsible for the movie or program.

A country_of_origin should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Country']>

=back

=head2 C<_has_country_of_origin>

A predicate for the L</country_of_origin> attribute.

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

=head2 C<duration>

=for html <p>The duration of the item (movie, audio recording, event, etc.) in <a
href="http://en.wikipedia.org/wiki/ISO_8601">ISO 8601 date format</a>.<p>

A duration should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Duration']>

=back

=head2 C<_has_duration>

A predicate for the L</duration> attribute.

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

=head2 C<subtitle_language>

C<subtitleLanguage>

=for html <p>Languages in which subtitles/captions are available, in <a
href="http://tools.ietf.org/html/bcp47">IETF BCP 47 standard format</a>.<p>

A subtitle_language should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Language']>

=item C<Str>

=back

=head2 C<_has_subtitle_language>

A predicate for the L</subtitle_language> attribute.

=head2 C<title_eidr>

C<titleEIDR>

=for html <p>An <a href="https://eidr.org/">EIDR</a> (Entertainment Identifier
Registry) <a class="localLink"
href="http://schema.org/identifier">identifier</a> representing at the most
general/abstract level, a work of film or television.<br/><br/> For
example, the motion picture known as "Ghostbusters" has a titleEIDR of
"10.5240/7EC7-228A-510A-053E-CBB8-J". This title (or work) may have several
variants, which EIDR calls "edits". See <a class="localLink"
href="http://schema.org/editEIDR">editEIDR</a>.<br/><br/> Since schema.org
types like <a class="localLink" href="http://schema.org/Movie">Movie</a>
and <a class="localLink" href="http://schema.org/TVEpisode">TVEpisode</a>
can be used for both works and their multiple expressions, it is possible
to use <a class="localLink"
href="http://schema.org/titleEIDR">titleEIDR</a> alone (for a general
description), or alongside <a class="localLink"
href="http://schema.org/editEIDR">editEIDR</a> for a more edit-specific
description.<p>

A title_eidr should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_title_eidr>

A predicate for the L</title_eidr> attribute.

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

This software is Copyright (c) 2018-2020 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

use utf8;

package SemanticWeb::Schema::MusicRelease;

# ABSTRACT: A MusicRelease is a specific release of a music album.

use Moo;

extends qw/ SemanticWeb::Schema::MusicPlaylist /;


use MooX::JSON_LD 'MusicRelease';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v9.0.0';


has catalog_number => (
    is        => 'rw',
    predicate => '_has_catalog_number',
    json_ld   => 'catalogNumber',
);



has credited_to => (
    is        => 'rw',
    predicate => '_has_credited_to',
    json_ld   => 'creditedTo',
);



has duration => (
    is        => 'rw',
    predicate => '_has_duration',
    json_ld   => 'duration',
);



has music_release_format => (
    is        => 'rw',
    predicate => '_has_music_release_format',
    json_ld   => 'musicReleaseFormat',
);



has record_label => (
    is        => 'rw',
    predicate => '_has_record_label',
    json_ld   => 'recordLabel',
);



has release_of => (
    is        => 'rw',
    predicate => '_has_release_of',
    json_ld   => 'releaseOf',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::MusicRelease - A MusicRelease is a specific release of a music album.

=head1 VERSION

version v9.0.0

=head1 DESCRIPTION

A MusicRelease is a specific release of a music album.

=head1 ATTRIBUTES

=head2 C<catalog_number>

C<catalogNumber>

The catalog number for the release.

A catalog_number should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_catalog_number>

A predicate for the L</catalog_number> attribute.

=head2 C<credited_to>

C<creditedTo>

The group the release is credited to if different than the byArtist. For
example, Red and Blue is credited to "Stefani Germanotta Band", but by Lady
Gaga.

A credited_to should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Organization']>

=item C<InstanceOf['SemanticWeb::Schema::Person']>

=back

=head2 C<_has_credited_to>

A predicate for the L</credited_to> attribute.

=head2 C<duration>

=for html <p>The duration of the item (movie, audio recording, event, etc.) in <a
href="http://en.wikipedia.org/wiki/ISO_8601">ISO 8601 date format</a>.<p>

A duration should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Duration']>

=back

=head2 C<_has_duration>

A predicate for the L</duration> attribute.

=head2 C<music_release_format>

C<musicReleaseFormat>

Format of this release (the type of recording media used, ie. compact disc,
digital media, LP, etc.).

A music_release_format should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::MusicReleaseFormatType']>

=back

=head2 C<_has_music_release_format>

A predicate for the L</music_release_format> attribute.

=head2 C<record_label>

C<recordLabel>

The label that issued the release.

A record_label should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Organization']>

=back

=head2 C<_has_record_label>

A predicate for the L</record_label> attribute.

=head2 C<release_of>

C<releaseOf>

The album this is a release of.

A release_of should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::MusicAlbum']>

=back

=head2 C<_has_release_of>

A predicate for the L</release_of> attribute.

=head1 SEE ALSO

L<SemanticWeb::Schema::MusicPlaylist>

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

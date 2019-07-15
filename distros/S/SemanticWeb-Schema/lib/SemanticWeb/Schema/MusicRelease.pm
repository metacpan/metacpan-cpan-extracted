use utf8;

package SemanticWeb::Schema::MusicRelease;

# ABSTRACT: A MusicRelease is a specific release of a music album.

use Moo;

extends qw/ SemanticWeb::Schema::MusicPlaylist /;


use MooX::JSON_LD 'MusicRelease';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v3.8.1';


has catalog_number => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'catalogNumber',
);



has credited_to => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'creditedTo',
);



has duration => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'duration',
);



has music_release_format => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'musicReleaseFormat',
);



has record_label => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'recordLabel',
);



has release_of => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'releaseOf',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::MusicRelease - A MusicRelease is a specific release of a music album.

=head1 VERSION

version v3.8.1

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

=head2 C<duration>

=for html The duration of the item (movie, audio recording, event, etc.) in <a
href="http://en.wikipedia.org/wiki/ISO_8601">ISO 8601 date format</a>.

A duration should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Duration']>

=back

=head2 C<music_release_format>

C<musicReleaseFormat>

Format of this release (the type of recording media used, ie. compact disc,
digital media, LP, etc.).

A music_release_format should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::MusicReleaseFormatType']>

=back

=head2 C<record_label>

C<recordLabel>

The label that issued the release.

A record_label should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Organization']>

=back

=head2 C<release_of>

C<releaseOf>

The album this is a release of.

A release_of should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::MusicAlbum']>

=back

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

This software is Copyright (c) 2018-2019 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

use utf8;

package SemanticWeb::Schema::MusicRecording;

# ABSTRACT: A music recording (track)

use Moo;

extends qw/ SemanticWeb::Schema::CreativeWork /;


use MooX::JSON_LD 'MusicRecording';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v8.0.0';


has by_artist => (
    is        => 'rw',
    predicate => '_has_by_artist',
    json_ld   => 'byArtist',
);



has duration => (
    is        => 'rw',
    predicate => '_has_duration',
    json_ld   => 'duration',
);



has in_album => (
    is        => 'rw',
    predicate => '_has_in_album',
    json_ld   => 'inAlbum',
);



has in_playlist => (
    is        => 'rw',
    predicate => '_has_in_playlist',
    json_ld   => 'inPlaylist',
);



has isrc_code => (
    is        => 'rw',
    predicate => '_has_isrc_code',
    json_ld   => 'isrcCode',
);



has recording_of => (
    is        => 'rw',
    predicate => '_has_recording_of',
    json_ld   => 'recordingOf',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::MusicRecording - A music recording (track)

=head1 VERSION

version v8.0.0

=head1 DESCRIPTION

A music recording (track), usually a single song.

=head1 ATTRIBUTES

=head2 C<by_artist>

C<byArtist>

The artist that performed this album or recording.

A by_artist should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::MusicGroup']>

=item C<InstanceOf['SemanticWeb::Schema::Person']>

=back

=head2 C<_has_by_artist>

A predicate for the L</by_artist> attribute.

=head2 C<duration>

=for html <p>The duration of the item (movie, audio recording, event, etc.) in <a
href="http://en.wikipedia.org/wiki/ISO_8601">ISO 8601 date format</a>.<p>

A duration should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Duration']>

=back

=head2 C<_has_duration>

A predicate for the L</duration> attribute.

=head2 C<in_album>

C<inAlbum>

The album to which this recording belongs.

A in_album should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::MusicAlbum']>

=back

=head2 C<_has_in_album>

A predicate for the L</in_album> attribute.

=head2 C<in_playlist>

C<inPlaylist>

The playlist to which this recording belongs.

A in_playlist should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::MusicPlaylist']>

=back

=head2 C<_has_in_playlist>

A predicate for the L</in_playlist> attribute.

=head2 C<isrc_code>

C<isrcCode>

The International Standard Recording Code for the recording.

A isrc_code should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_isrc_code>

A predicate for the L</isrc_code> attribute.

=head2 C<recording_of>

C<recordingOf>

The composition this track is a recording of.

A recording_of should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::MusicComposition']>

=back

=head2 C<_has_recording_of>

A predicate for the L</recording_of> attribute.

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

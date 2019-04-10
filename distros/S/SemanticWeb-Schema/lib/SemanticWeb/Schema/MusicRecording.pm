use utf8;

package SemanticWeb::Schema::MusicRecording;

# ABSTRACT: A music recording (track)

use Moo;

extends qw/ SemanticWeb::Schema::CreativeWork /;


use MooX::JSON_LD 'MusicRecording';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v3.5.0';


has by_artist => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'byArtist',
);



has duration => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'duration',
);



has in_album => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'inAlbum',
);



has in_playlist => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'inPlaylist',
);



has isrc_code => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'isrcCode',
);



has recording_of => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'recordingOf',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::MusicRecording - A music recording (track)

=head1 VERSION

version v3.5.0

=head1 DESCRIPTION

A music recording (track), usually a single song.

=head1 ATTRIBUTES

=head2 C<by_artist>

C<byArtist>

The artist that performed this album or recording.

A by_artist should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Person']>

=item C<InstanceOf['SemanticWeb::Schema::MusicGroup']>

=back

=head2 C<duration>

=for html The duration of the item (movie, audio recording, event, etc.) in <a
href="http://en.wikipedia.org/wiki/ISO_8601">ISO 8601 date format</a>.

A duration should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Duration']>

=back

=head2 C<in_album>

C<inAlbum>

The album to which this recording belongs.

A in_album should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::MusicAlbum']>

=back

=head2 C<in_playlist>

C<inPlaylist>

The playlist to which this recording belongs.

A in_playlist should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::MusicPlaylist']>

=back

=head2 C<isrc_code>

C<isrcCode>

The International Standard Recording Code for the recording.

A isrc_code should be one of the following types:

=over

=item C<Str>

=back

=head2 C<recording_of>

C<recordingOf>

The composition this track is a recording of.

A recording_of should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::MusicComposition']>

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

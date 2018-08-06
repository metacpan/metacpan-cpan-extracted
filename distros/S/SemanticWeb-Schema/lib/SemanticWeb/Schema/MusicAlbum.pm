package SemanticWeb::Schema::MusicAlbum;

# ABSTRACT: A collection of music tracks.

use Moo;

extends qw/ SemanticWeb::Schema::MusicPlaylist /;


use MooX::JSON_LD 'MusicAlbum';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v0.0.1';


has album_production_type => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'albumProductionType',
);



has album_release => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'albumRelease',
);



has album_release_type => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'albumReleaseType',
);



has by_artist => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'byArtist',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::MusicAlbum - A collection of music tracks.

=head1 VERSION

version v0.0.1

=head1 DESCRIPTION

A collection of music tracks.

=head1 ATTRIBUTES

=head2 C<album_production_type>

C<albumProductionType>

Classification of the album by it's type of content: soundtrack, live
album, studio album, etc.

A album_production_type should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::MusicAlbumProductionType']>

=back

=head2 C<album_release>

C<albumRelease>

A release of this album.

A album_release should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::MusicRelease']>

=back

=head2 C<album_release_type>

C<albumReleaseType>

The kind of release which this album is: single, EP or album.

A album_release_type should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::MusicAlbumReleaseType']>

=back

=head2 C<by_artist>

C<byArtist>

The artist that performed this album or recording.

A by_artist should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::MusicGroup']>

=back

=head1 SEE ALSO

L<SemanticWeb::Schema::MusicPlaylist>

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

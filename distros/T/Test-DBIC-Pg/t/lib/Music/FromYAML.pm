package Music::FromYAML;
use warnings;
use strict;
use YAML qw( LoadFile );

use Exporter 'import';
our @EXPORT = qw( artist_from_yaml );

sub artist_from_yaml {
    my ($schema, $file) = @_;

    my $artist_albums = LoadFile($file);

    for my $this_artist (@{ $artist_albums->{artist} }) {
        my $artist = $schema->resultset('AlbumArtist')->create(
            {
                name => $this_artist->{name},
                description => $this_artist->{description}
            }
        );
        for my $this_album (@{ $this_artist->{albums} }) {
            my $album = $artist->create_related(
                'albums',
                {
                    name => $this_album->{name},
                    year => $this_album->{year},
                }
            );
            for my $this_song (@{ $this_album->{songs} }) {
                $album->create_related('songs', $this_song);
            }
        }
    }
}

1;

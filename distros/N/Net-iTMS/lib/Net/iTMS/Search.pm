package Net::iTMS::Search;
#
# Written by Thomas R. Sibley, <http://zulutango.org:82/>
#
use warnings;
use strict;

use vars '$VERSION';
$VERSION = '0.15';

use Net::iTMS::Error;

=head1 NAME

Net::iTMS::Search - Represents a simple search of the iTunes Music Store

=head1 SYNOPSIS

    use Net::iTMS::Search;

    my $search = Net::iTMS::Search->new($iTMS, $query);
    
    for my $album ($search->albums) {
        print $album->title, " by ", $album->artist->name, "\n";
    }

=head1 DESCRIPTION

Net::iTMS::Search represents a search of the iTMS and encapsulates the
associated data.  PLEASE NOTE: This simple search is currently broken due
to unresolvable changes in the iTMS.  Please use L<Net::iTMS::Search::Advanced>,
which works.

=head2 Methods

=over 12

=item new($itms, $query)

The first argument must be an instance of Net::iTMS, the second a query
string.

Returns a blessed hashref (object) for Net::iTMS::Search.

=cut
sub new {
    my ($class, $itms, $query, %prefill) = @_;
    
    my $self = bless {
        query => $query,
        error => '',
        debug => defined $itms->{debug} ? $itms->{debug} : 0,
        _itms => $itms,
    }, $class;
    
    if (%prefill) {
        $self->{$_} = $prefill{$_}
            for keys %prefill;
    }
    
    $self->_get_results;
    
    return $self;
}

=item query

Returns the query string the search is for.

=item songs

Returns an array or arrayref (depending on context) of L<Net::iTMS::Song> objects
for the songs found.

=item albums

Returns an array or arrayref (depending on context) of L<Net::iTMS::Album> objects
for the albums found.

NB: Due to an apparent limitation of the simple search in the iTMS, the maximum
number of albums returned will be four.

=cut
sub query { return $_[0]->{query} }

sub songs {
    my $self = shift;
    $self->_get_results
        if not exists $self->{songs};
    return wantarray ? @{$self->{songs}} : $self->{songs};
}

sub albums {
    my $self = shift;
    $self->_get_results
        if not exists $self->{albums};
    return wantarray ? @{$self->{albums}} : $self->{albums};
}

sub _get_results {
    my $self = shift;
    
    my $twig = $self->{_itms}->{_request}->url('search', $self->{query})
                or return undef;
    my $root = $twig->root;
    
    $self->_get_results_albums($root);
    $self->_get_results_tracks($root);

    $twig->purge;
}

sub _get_results_albums {
    my ($self, $root) = @_;

    # TODO: All this parsing will probably need to be changed like the
    #       advanced search's.

    #
    # Albums
    #
    $self->{albums} = [ ];
    
    my $sv = $root->first_child('ScrollView');
    
    my $mv = $sv->first_child('MatrixView')
                ->first_child('VBoxView')
                ->first_child('MatrixView');
    
    if (defined $mv) {
        for ($mv->first_child('VBoxView')
                ->first_child('MatrixView')
                ->first_child('MatrixView')
                ->children('VBoxView')) {

            my $album = $_->first_child('MatrixView')
                          ->first_child('ViewAlbum');

            next if not defined $album;

            my %data = (
                title => $album->att('draggingName'),
            );

            if (my $pic = $album->first_child('PictureView')) {
                $data{thumb} = {
                    height => $pic->att('height'),
                    width  => $pic->att('width'),
                    url    => $pic->att('url'),
                };
            }

            if (my $artist = $_->first_child('MatrixView')
                               ->first_child('VBoxView')
                               ->first_child('TextView')
                               ->first_child('ViewArtist')) {

                $data{artist} = $self->{_itms}->get_artist(
                                    $artist->att('id'),
                                    name => $artist->trimmed_text,
                                );

                if (my $genre = $artist->parent
                                       ->next_sibling('TextView')
                                       ->first_child('ViewGenre')) {

                    my $name = $genre->trimmed_text;
                    $name =~ s/^Genre:\s+//i;

                    $data{genre} = $self->{_itms}->get_artist(
                                        $genre->att('id'),
                                        name => $name,
                                   );
                }
            }
            
            push @{$self->{albums}},
                 $self->{_itms}->get_album(
                    $album->att('id'),
                    %data,
                 );
        }
    }
    
    $sv->delete;
}

sub _get_results_tracks {
    my ($self, $root) = @_;
    
    #
    # Tracks
    #
    my $plist = $root->first_child('TrackList')
                     ->first_child('plist')
                     ->first_child('dict')
                     ->first_child('array');
    
    $self->{songs} = [ ];
    
    for my $dict ($plist->children('dict')) {
        my %data;
        for my $key ($dict->children('key')) {
            $data{$key->trimmed_text} = $key->next_sibling('#ELT')->trimmed_text;
        }

        $data{releaseDate} =~ s/A-Za-z//g;
        $data{copyright}   =~ s/^.+\s*(?>\d{4})//;
        $data{copyright}   =~ s/\s*$//;
        
        push @{$self->{songs}},
             $self->{_itms}->get_song(
                    $data{songId},
                    title       => $data{songName},
                    album       => $self->{_itms}->get_album(
                                        $data{playlistId},
                                        title => $data{playlistName},
                                   ),
                    artist      => $self->{_itms}->get_artist(
                                        $data{artistId},
                                        name => $data{artistName},
                                   ),
                    genre       => $self->{_itms}->get_genre(
                                        $data{genreId},
                                        name => $data{genre},
                                   ),
                    year        => $data{year},
                    number      => $data{trackNumber},
                    count       => $data{trackCount},
                    disc_number => $data{discNumber},
                    disc_count  => $data{discCount},
                    explicit    => $data{explicit},
                    comments    => $data{comments},
                    copyright   => $data{copyright},
                    preview_url => $data{previewURL},
                    released    => $data{releaseDate},
                    price       => $data{priceDisplay},
                    vendor      => $data{vendorId},
                    duration    => $data{duration},
             );
    }
    
    $plist->delete;
}

=back

=head1 LICENSE

Copyright 2004, Thomas R. Sibley.

You may use, modify, and distribute this package under the same terms as Perl itself.

=head1 AUTHOR

Thomas R. Sibley, L<http://zulutango.org:82/>

=head1 SEE ALSO

L<Net::iTMS>, L<Net::iTMS::Song>, L<Net::iTMS::Artist>

=cut

42;

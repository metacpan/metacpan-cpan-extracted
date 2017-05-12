package Net::iTMS::Artist;
#
# Written by Thomas R. Sibley, <http://zulutango.org:82/>
#
use warnings;
use strict;

use vars '$VERSION';
$VERSION = '0.15';

use Net::iTMS::Error;

use overload
	'""'     => sub { shift->as_string },
	fallback => 1;

sub as_string {
    my $self = shift;
    
    return defined $self
            ? $self->name
            : undef;
}

=head1 NAME

Net::iTMS::Artist - Represents an artist in the iTunes Music Store

=head1 SYNOPSIS

    use Net::iTMS::Artist;

    my $artist = Net::iTMS::Artist->new($iTMS, $id);
    
    print "Artist: ", $artist->name, "\n";

    # $album will be a Net::iTMS::Album object
    for my $album ($artist->discography) {
        print $album->title, " (", $album->genre->name, ")\n";

        # $track will be a Net::iTMS::Song object
        for my $track ($album->tracks) {    # also $album->songs
            print "\t ", $track->number, ": ", $track->title, "\n";
        }
    }

=head1 DESCRIPTION

Net::iTMS::Artist represents an artist in the iTMS and encapsulates the
associated data.  If a piece of information hasn't been fetched from the
iTMS, it will transparently fetch and store it for later use before
returning.

If one of the methods C<id>, C<name>, C<website>, C<genre>, C<path>,
C<selected_albums>, or C<total_albums> is called, the information
for the others will be fetched in the same request.  This means, for
these methods, the first call to one will have a time hit for the
HTTP request, but subsequent calls won't.

=head2 Methods

All methods return C<undef> on error and (should) set an error message,
which is available through the C<error> method.  (Unless I note otherwise.)

=over 12

=item new($itms, $artistId)

The first argument must be an instance of Net::iTMS, the second an
iTMS artist ID.

Returns a blessed hashref (object) for Net::iTMS::Artist.

=cut
sub new {
    my ($class, $itms, $id, %prefill) = @_;
    
    my $self = bless {
        id    => $id,
        error => '',
        debug => defined $itms->{debug} ? $itms->{debug} : 0,
        _itms => $itms,
        create_album_links => undef,
    }, $class;
    
    if (%prefill) {
        $self->{$_} = $prefill{$_}
            for keys %prefill;
    }
    
    return $self;
}

=item id

Returns the ID of the artist (C<artistId>).

=item name

Returns the name of the artist.

=item website

Returns the website URL of the artist (undef if there isn't one specified).

=item genre

Returns a L<Net::iTMS::Genre> object representing the artist's primary genre.

=item path

Returns an arrayref of hashrefs representing the artist's "path" in the iTMS.
The hashrefs contain the name of the node in the path and the iTMS URL of that
node.

For example, Elliott Smith's (id = 2893902) "path" is "Alternative > Elliott Smith",
which is represented in Perl by:

    # URLs trimmed for example
    [
      {
        'url' => 'http://ax.phobos.apple.com.edgesuite.net/.../viewGenre?genreId=20',
        'name' => 'Alternative'
      },
      {
        'url' => 'http://ax.phobos.apple.com.edgesuite.net/.../viewArtist?artistId=2893902',
        'name' => 'Elliott Smith'
      }
    ]

This is pretty much only useful if you're trying to imitate the iTunes interface.

=item best_sellers

Returns an array or arrayref (depending on context) of L<Net::iTMS::Album> objects
for a selection of the best selling albums by the artist.

=item discography

=item albums

Returns an array or arrayref (depending on context) of L<Net::iTMS::Album> objects
for all the albums of the artist available on the iTMS.

=item biography

Returns an array or arrayref (depending on context) where each element is a paragraph
in the artist's iTMS bio.

Options

=over 24

=item create_album_links => '/some/url?id='

If this option is set, iTMS links to albums within the bio will be translated
into HTML links.  The albumId is prepended to the URL passed as the value
of the option.

The default is to simply ignore the links, leaving the plain text title.

=back

=item influences

Returns an array or arrayref (depending on context) of L<Net::iTMS::Album> objects
for the albums/artists which influenced the artist, according to the iTMS.

=cut
sub id { return $_[0]->{id} }

sub name {
    my $self = shift;
    $self->_get_basic_info
        if not exists $self->{name};
    return $self->{name};
}

sub genre {
    my $self = shift;
    $self->_get_basic_info
        if not exists $self->{genre};
    return $self->{genre};
}

sub website {
    my $self = shift;
    $self->_get_basic_info
        if not exists $self->{website};
    return $self->{website};
}

sub path {
    my $self = shift;
    $self->_get_basic_info
        if not exists $self->{path};
    return wantarray ? @{$self->{path}} : $self->{path};
}

sub best_sellers {
    my $self = shift;
    $self->_get_basic_info
        if not exists $self->{best_sellers};
    return wantarray ? @{$self->{best_sellers}} : $self->{best_sellers};
}

sub discography {
    my $self = shift;
    $self->_get_discography
        if not exists $self->{discography};
    return wantarray ? @{$self->{discography}} : $self->{discography};
}

sub albums { return shift->discography; }

sub biography {
    my $self = shift;
    my %opt  = @_;
    
    no warnings 'uninitialized';
    
    if ($self->{create_album_links} ne $opt{create_album_links}
          || not exists $self->{biography}) {

        use warnings 'uninitialized';
        
        $self->_get_biography($opt{create_album_links});
    }
            
    $self->{create_album_links} = defined $opt{create_album_links}
                                        ? $opt{create_album_links}
                                        : undef;
    
    return wantarray ? @{$self->{biography}} : $self->{biography};
}

sub influences {
    my $self = shift;
    $self->_get_influential_albums
        if not exists $self->{influences};
    return wantarray ? @{$self->{influences}} : $self->{influences};
}

#
# This populates the name, genre, path, website, and selected albums data
#
sub _get_basic_info {
    my $self = shift;
    
    my $twig = $self->{_itms}->{_request}->url('viewArtist', $self->id);
    
    my $root = $twig->root;
    my $path = $root->first_child('Path');
    my $sv   = $root->first_child('ScrollView');
    
    #
    # Name
    #
    $self->{name} = $path->last_child('PathElement')
                         ->att('displayName');

    #
    # Path
    #
    for my $child ($path->children('PathElement')) {
        push @{$self->{path}}, {
            name => $child->att('displayName'),
            url  => $child->trimmed_text,
        };
    }
    
    #
    # Genre
    #
    $self->{genre} = $self->{_itms}->get_genre(
                            $root->att('genreId'),
                            name => $path->first_child('PathElement')
                                         ->att('displayName')
                     );
    
    $path->delete;
    
    #
    # Website URL
    #
    my $website = $sv->first_child('MatrixView')
                     ->first_child('View')
                     ->first_child('MatrixView')
                     ->first_child('VBoxView')
                     ->first_child('OpenURL');
    
    $self->{website} = $website->att('url')
        if defined $website;
    
    #
    # Best sellers (what we select by default)
    #
    $self->{best_sellers} = $self->_get_selected_albums($twig);
    
    $sv->delete;
    $twig->purge;
}

sub _get_selected_albums {
    my ($self, $twig) = @_;

    my @albums;

    my $root = $twig->root;
    my $sv   = $root->first_child('ScrollView');
    
    my $grid = $sv->first_child('MatrixView')
                  ->first_child('View')
                  ->first_child('MatrixView')
                  ->first_child('VBoxView')
                  ->first_child('VBoxView');

    if (defined $grid) {
        for my $hbox ($grid->children('HBoxView')) {
            for my $vbox ($hbox->children('VBoxView')) {
                my $goto = $vbox->first_child('MatrixView')
                                ->first_child('GotoURL');

                next if not defined $goto;

                my $thumb = { };

                if (my $pic = $goto->first_child('PictureView')) {
                    $thumb = {
                        height => $pic->att('height'),
                        width  => $pic->att('width'),
                        url    => $pic->att('url'),
                    };
                }
                
                my ($id) = $goto->att('url') =~ /playListId=(\d+)\z/;
                
                push @albums,
                     $self->{_itms}->get_album(
                            $id,
                            title  => $goto->att('draggingName'),
                            artist => $self,
                            thumb  => $thumb,
                     );
            }
        }
    }

    return \@albums;
}

sub _get_discography {
    my $self = shift;
    
    my $twig = $self->{_itms}->{_request}->url('browseArtist', $self->id);
    my $root = $twig->root;
    
    my $plist = ($root->descendants('plist'))[0]
                      ->first_child('dict')
                      ->first_child('array');
    
    $self->{discography} = [ ];
    
    for my $dict ($plist->children('dict')) {
        my %data;
        for my $key ($dict->children('key')) {
            $data{$key->trimmed_text} = $key->next_sibling('#ELT')->trimmed_text;
        }
        
        push @{$self->{discography}},
             $self->{_itms}->get_album(
                    $data{playlistId},
                    title       => $data{playlistName},
                    artist      => $self,
             );
    }
    $plist->delete;

    $twig->purge;
}

sub _get_biography {
    my $self = shift;
    my $url  = shift;
    
    my $twig = $self->{_itms}->{_request}->url('biography', $self->id);
    my $root = $twig->root;

    my $sv = $root->first_child('ScrollView');
    
    my $tv = $sv->first_child('MatrixView')
                ->first_child('View')
                ->first_child('VBoxView')
                ->first_child('TextView');
    
    for ($tv->next_siblings('TextView')) {
        my $t = $_->first_child('SetFontStyle');
        next if not defined $t;
        
        my $text;
        if (defined $url) {
            for ($t->children('ViewAlbum')) {
                my $id = $_->att('id');
                $_->del_atts;
                $_->set_name('a');
                $_->set_att(href => "$url$id");
                $_->set_att(class => 'itms-album');
                $_->set_text($_->trimmed_text);
            }
            $text = $t->xml_string;
        } else {
            $text = $t->xml_text;
        }
        
        # Chop surrounding whitespace
        $text =~ s/^\s*//;
        $text =~ s/\s*$//;
        
        push @{$self->{biography}}, $text
            unless $text eq '' or $text eq 'Biography';
    }
    
    $sv->delete;
    $twig->purge;
}

sub _get_influential_albums {
    my $self = shift;

    my $twig = $self->{_itms}->{_request}->url('influencers', $self->id);
    my $root = $twig->root;

    my $sv = $root->first_child('ScrollView');
    
    my $mv = $sv->first_child('MatrixView')
                ->first_child('View')
                ->first_child('MatrixView')
                ->first_child('VBoxView')
                ->first_child('MatrixView');
    
    if (defined $mv) {
        for my $hbox ($mv->children('HBoxView')) {
            for my $vbox ($hbox->children('VBoxView')) {
                my $goto = $vbox->first_child('MatrixView')
                                ->first_child('GotoURL');

                next if not defined $goto;

                my %data = (
                    title => $goto->att('draggingName'),
                );
                
                if (my $pic = $goto->first_child('PictureView')) {
                    $data{thumb} = {
                        height => $pic->att('height'),
                        width  => $pic->att('width'),
                        url    => $pic->att('url'),
                    };
                }
                
                my ($id) = $goto->att('url') =~ /playListId=(\d+)\z/;
                
                my $artist = $vbox->first_child('MatrixView')
                                  ->first_child('VBoxView')
                                  ->first_child('TextView')
                                  ->first_child('SetFontStyle')
                                  ->first_child('GotoURL');
                
                if (defined $artist) {
                    my ($aid) = $artist->att('url') =~ /artistId=(\d+)\z/;
                    
                    $data{artist} = $self->{_itms}->get_artist(
                                        $aid,
                                        name => $artist->trimmed_text,
                                    );
                    
                }
                
                push @{$self->{influences}},
                     $self->{_itms}->get_album(
                            $id,
                            %data,
                     );
            }
        }
    }
    
    $sv->delete;
    $twig->purge;
}

=back

=head1 LICENSE

Copyright 2004, Thomas R. Sibley.

You may use, modify, and distribute this package under the same terms as Perl itself.

=head1 AUTHOR

Thomas R. Sibley, L<http://zulutango.org:82/>

=head1 SEE ALSO

L<Net::iTMS>, L<Net::iTMS::Album>, L<Net::iTMS::Song>, L<Net::iTMS::Genre>

=cut

42;

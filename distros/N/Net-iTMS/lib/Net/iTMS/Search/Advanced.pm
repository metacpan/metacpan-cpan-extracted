package Net::iTMS::Search::Advanced;
#
# Written by Thomas R. Sibley, <http://zulutango.org:82/>
#
use warnings;
use strict;

use vars '$VERSION';
$VERSION = '0.14';

use base 'Net::iTMS::Search';

=head1 NAME

Net::iTMS::Search::Advanced - Represents an advanced search of the iTunes Music Store

=head1 SYNOPSIS

    use Net::iTMS::Search::Advanced;

    my $search = Net::iTMS::Search::Advanced->new($iTMS, {
                        artist  => 'Elliott Smith',
                        album   => 'From a Basement on the Hill',
                        song    => 'distorted',
                 });
    
    for my $album ($search->albums) {
        print $album->title, " by ", $album->artist->name, "\n";
    }

=head1 DESCRIPTION

Net::iTMS::Search::Advanced represents an advanced search of the iTMS and
encapsulates the associated results.  It is a subclass of Net::iTMS::Search;
only changes are noted in this doc.  See the doc for Net::iTMS::Search for
the other methods available.

=head2 Methods

=over 12

=item new($itms, { artist => "U2" })

The first argument must be an instance of Net::iTMS, the second a hashref
containing at least one of the keys C<artist>, C<album>, C<song>, or
C<composer>.

Returns a blessed hashref (object) for Net::iTMS::Search::Advanced.

=item query

Returns the query hashref the search is for.

=cut

sub _get_results {
    my $self = shift;
    
    my %q;
    for (qw(artist album song composer)) {
        $q{"${_}Term"} = $self->{query}->{$_}
            if defined $self->{query}->{$_};
    }
    
    my $twig = $self->{_itms}->{_request}->url('advancedSearch', \%q)
                or return undef;
    my $root = $twig->root;
    
    $self->_get_results_albums($root);
    $self->_get_results_tracks($root);

    $twig->purge;
}

sub _get_results_albums {
    my ($self, $root) = @_;

    #
    # Albums
    #
    $self->{albums} = [ ];
    
    my $sv = $root->first_child('ScrollView');
    
    my $v = $sv->first_child('MatrixView')
               ->first_child('VBoxView');
    
    # Find the View container we want
    my $tmp;
    for ($v->children('View')) {
        if ($_->children) {
            $tmp = $_;
            last;
        }
    }
    
    my $mv;
    
    eval { $mv = $tmp->first_child('MatrixView')
                     ->first_child('MatrixView')
                     ->first_child('MatrixView'); };
    return if $@;
    
    #
    # This is mostly the same to the code in the regular search except
    # for some higher up structural changes in the XML which affect the
    # main for loop below and album fetching.
    #
    if (defined $mv) {
        for ($mv->children('VBoxView')) {
            my $album = $_->first_child('MatrixView')
                          ->first_child('GotoURL');

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
                               ->first_child('GotoURL')) {

                my ($id) = $artist->att('url') =~ /artistId=(\d+)\z/;

                $data{artist} = $self->{_itms}->get_artist(
                                    $id,
                                    name => $artist->trimmed_text,
                                );

                if (my $genre = $artist->parent
                                       ->next_sibling('TextView')
                                       ->first_child('ViewGenre')) {

                    my ($name) = $genre->trimmed_text =~ /^Genre:\s+(.+)$/i;

                    $data{genre} = $self->{_itms}->get_artist(
                                        $genre->att('id'),
                                        name => $name,
                                   );
                }
            }
            
            my ($id) = $album->att('url') =~ /playListId=(\d+)\z/;
            
            push @{$self->{albums}},
                 $self->{_itms}->get_album(
                    $id,
                    %data,
                 );
        }
    }
    
    $sv->delete;
}

=back

=head1 LICENSE

Copyright 2004, Thomas R. Sibley.

You may use, modify, and distribute this package under the same terms as Perl itself.

=head1 AUTHOR

Thomas R. Sibley, L<http://zulutango.org:82/>

=head1 SEE ALSO

L<Net::iTMS>, L<Net::iTMS::Search>, L<Net::iTMS::Song>, L<Net::iTMS::Artist>

=cut

42;

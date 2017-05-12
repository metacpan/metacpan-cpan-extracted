#! perl

use strict;
use warnings;
use utf8;

package Music::ChordBot::Opus;

=head1 NAME

Music::ChordBot::Opus - API for generating ChordBot songs.

=cut

our $VERSION = 0.01;

use parent 'Music::ChordBot::Opus::Base';

=head1 SYNOPSIS

    use Music::ChordBot::Opus;
    my $song = Music::ChordBot::Opus->new;
    $song->name("Perl Song");
    $song->tempo(120);
    $song->add_section(...);
    print $song->json, "\n";

=head1 METHODS

=head2 new [ args ]

Creates a new Music::ChordBot::Opus object.

Initial attributes may be passed as a hash.

Attributes:

=over 4

=item name

The name of the song.

=item editMode

Zero if the song has a single style, one if some sections have their
own styles.

=item tempo

The tempo in beats per minute.

=item fileType

This must be the literal string 'chordbot-song'.

=back

=cut

sub new {
    my ( $pkg, %init ) = @_;
    $init{songName} = delete $init{name} if exists $init{name};
    my $data = { fileType => "chordbot-song",
		 editMode => 0,
		 tempo => 80,
		 sections => [],
		 %init };
    bless { data => $data }, $pkg;
}

=head2 name [ value ]

Sets or gets the name of the song.

=cut

sub name     { shift->_setget( "songName", @_ ) }

=head2 tempo [ value ]

Sets or gets the tempo of the song.

=cut

sub tempo    { shift->_setget( "tempo",    @_ ) }

=head2 editmode [ value ]

Sets or gets attribute editMode. This is not normally necessary since
it is dealt with automatically.

=cut

sub editmode { shift->_setget( "editMode", @_ ) }

=head2 add_section section

Adds a new section to the song. See L<Music::ChordBot::Opus::Section>
for details on sections.

=cut

sub add_section {
    my ( $self, $section ) = @_;
    push( @{$self->{data}->{sections}}, $section->{data} );
}

# head2 _wrapup
#
# Internal helper to fix some attributes.

sub _wrapup {
    my ( $self ) = @_;

    # If there are more than one sections with a style associated,
    # editMode most be set to 1.
    my $styles = 0;
    foreach ( @{ $self->{data}->{sections} } ) {
	if ( exists $_->{style} ) {
	    if ( ++$styles > 1 ) {
		$self->editmode(1);
		last;
	    }
	}
    }
}

=head2 export [ dumpname ]

Produces a string representing the song, in Data::Dumper format.

=cut

sub export {
    my ( $self, $pretty ) = @_;
    $self->_wrapup;
    use Data::Dumper ();
    Data::Dumper->Dump( [ $self->{data} ], [ $pretty || "opus" ] );
}

=head2 json [ pretty ]

Produces a string representing the song, in JSON format, suitable
for import into the ChordBot app.

If argument is true, the JSON is pretty-printed for readability.
ChordBot doesn't mind.

=cut

sub json {
    my ( $self, $pretty ) = @_;
    $self->_wrapup;
    use JSON ();
    my $json = JSON->new;
    $json->canonical(1);
    $json = $json->pretty if $pretty;
    $json->encode($self->{data});
}

1;

=head1 SEE ALSO

L<Music::ChordBot> for general information.

L<Music::ChordBot::Song> for an easy to use API.

=head1 DISCLAIMER

There is currently NO VALIDATION of argument values. Illegal values
will result in program crashes and songs that cannot be imported, or
played, by ChordBot.

=head1 AUTHOR, COPYRIGHT & LICENSE

See L<Music::ChordBot>.

=cut

1;

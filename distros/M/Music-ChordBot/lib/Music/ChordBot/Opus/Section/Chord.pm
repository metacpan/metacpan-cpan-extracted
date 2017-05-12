#! perl

use strict;
use warnings;

package Music::ChordBot::Opus::Section::Chord;

=head1 NAME

Music::ChordBot::Opus::Section::Chord - ChordBot chords.

=cut

our $VERSION = 0.01;

use parent 'Music::ChordBot::Opus::Base';

=head1 SYNOPSIS

    use Music::ChordBot::Opus::Section::Chord;
    $chord = Music::ChordBot::Section::Chord->new;
    $chord->root("C");
    $chord->type("Min7");
    $chord->duration(4);

or

    $chord = Music::ChordBot::Section::Chord->new("C Min7 4");

or

    $chord = Music::ChordBot::Section::Chord->new("C", "Min7", 4);


=head1 METHODS

=head2 new [ args ]

Creates a new Music::ChordBot::Opus::Section::Chord object.

The chord key, type and duration may be passed as arguments to the
constructor, either as three separate values, or as a string
containing these values space separated.

Attributes:

=over 4

=item root

The root (key) of the chord.

=item bass

An added bass note of the chord.

=item type

The type, e.g., "Maj" (major), "Min" (minor), "7" (seventh) and so on.

=item duration

The duration, in beats.

=item inversion

Thee inversion, if applicable.

=cut

sub new {
    my $pkg = shift;
    my $data = {};
    if ( @_ == 1 ) {
	@_ = split( ' ', $_[0] );
    }
    if ( @_ == 3 ) {
	$data->{root} = shift;
	if ( $data->{root} =~ /^(.+)\/(.*)/ ) {
	    $data->{bass} = $2;
	    $data->{root} = $1;
	}
	$data->{type} = shift;
	$data->{duration} = 0+shift;
    }
    bless { data => $data }, $pkg;
}

=head2 root bass type duration inversion

Accessors can be used to set and/or get these attributes.

=cut

sub root      { shift->_setget( "root",      @_ ) }
sub bass      { shift->_setget( "bass",      @_ ) }
sub type      { shift->_setget( "type",      @_ ) }
sub duration  { shift->_setget( "duration",  @_ ) }
sub inversion { shift->_setget( "inversion", @_ ) }

=head1 AUTHOR, COPYRIGHT & LICENSE

See L<Music::ChordBot>.

=cut

1;

#! perl

use strict;
use warnings;
use utf8;

package Music::ChordBot::Song;

=head1 NAME

Music::ChordBot::Song - Generate ChordBot songs.

=head1 SYNOPSIS

    use Music::ChordBot::Song;
    song "All Of Me";
    tempo 105;

    section "All Of Me 1";
    style "Chicago";

    C 4; C; E7; E7; A7; A7; Dm7; Dm7;
    E7; E7; Am7; Am7; D7; D7; Dm7; G7;

    section "All Of Me 2";
    style "Swingatron";

    C 4; C; E7; E7; A7; A7; Dm7; Dm7;
    Dm7; Ebdim7; Em7; A9; Dm7b5; G13;
    C 2; Ebdim7; Dm7; G7;

=head1 DESCRIPTION

Music::ChordBot::Song exports a number of subroutines that can be used
to construct a CordBot song. Upon program termination, the song is
written out to standard output in JSON format, suitable for import into
the ChordBot app.

=cut

our $VERSION = 0.01;

use Music::ChordBot::Opus;
use Music::ChordBot::Opus::Section;

our @EXPORT = qw( song chord section tempo style );
use base 'Exporter';

my $song;
my $section;

=head1 SUBROUTINES

=head2 song I<title>

Starts a new song with the given title.

=cut

sub song($) {
    _export() if $song;
    $song = Music::ChordBot::Opus->new( name => shift );
    undef $section;
}

=head2 tempo I<bpm>

Sets the tempo in beats per minute.

=cut

sub tempo($) {
    $song->tempo(@_);
}

=head2 section I<name>

Starts a song section. A section groups a number of bars with chords.
Each section can have a style associated although it is common to have
a single style for the whole song.

=cut

sub section($) {
    $section = Music::ChordBot::Opus::Section->new( name => shift );
    $song->add_section( $section );
}

=head2 style I<preset>

Associate the given style to the current section. For a list of
presets, see http://chordbot.com/style-lookup.php .

=cut

sub style($) {
    $section->set_style(@_);
}

=head2 chord I<key>, I<type>, I<duration>

Append a chord with given key, type and duration. Note that duration
is measured in number of beats. The three arguments may also be
specified in a single string argument, space separated.

You can specify a bass note for the chord by separating the key and
bass with a slash. E.g., C<"C/B"> denotes a C chord with B bass.

=cut

sub chord($) {
    $section->add_chord( @_ );
}

# Automatically export the song at the end of the program.
sub END {
    _export() if $song;
}

sub json { $song->json }

sub _export {
    binmode( STDOUT, ':utf8');
    print STDOUT $song->json, "\n";
}

=head1 QUICK ACCESS CHORDS

For convenience, subroutines are exported for quick access to chords.
So instead of

  chord "C", "Maj", 4;

you can also write:

  C 4;

If you omit the duration it will use the duration of the previous
 chord:

  C 4; C; F; G;		# same as C 4; C 4; F 4; G 4;

The subroutine name is the key of the chord, optionally followed by a
chord modifier. So C<C> is C major, C<Cm> is C minor, and so on.

Chord keys are A B C D E F G Ab Bb Db Eb Gb Ais Cis Dis Fis Gis.

Modifiers are m 7 m7 maj7 9 11 13 auf 7b5 m7b5 dim dim7.

=cut

my $_key = "C";
my $_mod = "Maj";
my $_dur = 4;

sub _chord {
    my ( $key, $mod, $dur ) = @_;
    $_dur = $dur if $dur;
    $section->add_chord( $key, $mod, $_dur  );
}

for my $key ( qw( A B C D E F G
		  Ab Bb Db Eb Gb
		  Ais Cis Dis Fis Gis
	    ) ) {
    my $k2 = $key =~ /^(.)is$/ ? "$1#" : $key;

    my %m = (
       ""      => "Maj",
       "m"     => "Min",
       "7"     => "7",
       "m7"    => "Min7",
       "maj7"  => "Maj7",
       "9"     => "9",
       "11"    => "11",
       "13"    => "13",
       "aug"   => "Aug",
       "7b5"   => "7(b5)",
       "m7b5"  => "Min7(b5)",
       "dim"   => "Dim",
       "dim7"  => "Dim7",
    );

    no strict 'refs';
    while ( my ($k, $t) = each( %m ) ) {
	*{ __PACKAGE__ . '::' . $key.$k } =
	  sub { &_chord( $k2, $t, $_[0] ) };
	push( @EXPORT, $key.$k );
    }
}

# Rest 'chord'.
sub NC { &_chord( "A", "Silence", $_[0] ) }
*S = \&NC;
push( @EXPORT, "S", "NC" );

=head1 DISCLAIMER

There is currently NO VALIDATION of argument values. Illegal values
will result in program crashes and songs that cannot be imported, or
played, by ChordBot.

=head1 AUTHOR, COPYRIGHT & LICENSE

See L<Music::ChordBot>.

=cut

1;

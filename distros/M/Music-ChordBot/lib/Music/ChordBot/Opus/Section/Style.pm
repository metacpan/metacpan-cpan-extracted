#! perl

use strict;
use warnings;
use utf8;

package Music::ChordBot::Opus::Section::Style;

=head1 NAME

Music::ChordBot::Opus::Section::Style- ChordBot styles.

=cut

our $VERSION = 0.01;

use parent 'Music::ChordBot::Opus::Base';

=head1 SYNOPSIS

    use Music::ChordBot::Opus::Section::Style;
    $style = Music::ChordBot::Section::Style->new;
    $style->preset("Hammered");

=cut

use Music::ChordBot::Opus::Section::Style::Track;

=head1 METHODS

=head2 new [ I<args> ]

Creates a new Music::ChordBot::Opus::Section::Style object.

Initial attributes can be passed to the constructor as a hash.

Attributes:

=over 4

=item reverb

The level of reverb effect.

=item chorus

The level of chorus effect.

=item tracks

A list (array ref) of Track objects. See
L<Music::ChordBot::Opus::Section::Style::Track> for details about
tracks.

=item beats

The number of beats per measure.

=item divider

The divider for the measure.

=back

Default is 4/4.

=cut

sub new {
    my $pkg = shift;
    my $data = { chorus => 4, reverb => 8, tracks => [], @_ };
    bless { data => $data }, $pkg;
}

=head2 chorus reverb beats divider tracks

Accessors can be used to set and/or get these attributes.

=cut

sub chorus  { shift->_setget( "chorus",  @_ ) }
sub reverb  { shift->_setget( "reverb",  @_ ) }
sub legacy  { shift->_setget( "legacy",  @_ ) }
sub beats   { shift->_setget( "beats",   @_ ) }
sub divider { shift->_setget( "divider", @_ ) }

=head2 add_track I<track>

Adds a track object to the style.

=cut

sub add_track {
    my ( $self, $track ) = @_;
    push( @{$self->{data}->{tracks}}, $track->data );
}

=head2 preset I<name>

Sets the style to one of the built-in preset values. For a list of
preset values and their descriptions, see
L<http://chordbot.com/style-lookup.php>.

=cut

my %presets;
sub preset {
    return $presets{$_[1]} if %presets;

    use JSON ();
    my $json = JSON->new;
    while ( <DATA> ) {
	my $data = $json->decode($_);
	my $preset = __PACKAGE__->new;
	$preset->chorus( $data->{chorus} ) if exists $data->{chorus};
	$preset->reverb( $data->{reverb} ) if exists $data->{reverb};
	$preset->legacy( $data->{legacy} ) if exists $data->{legacy};
	$preset->beats(  $data->{beats}  ) if exists $data->{beats};
	$preset->divider($data->{divider}) if exists $data->{divider};

	my $tracks = $data->{tracks};
	foreach my $t ( @$tracks ) {
	    $preset->add_track
	      ( Music::ChordBot::Opus::Section::Style::Track->new
		( id => $t->[0], volume => $t->[1] ) )
	}
	$presets{ $data->{name} } = $preset;
    }

    $presets{$_[1]}
}

=head1 AUTHOR, COPYRIGHT & LICENSE

See L<Music::ChordBot>.

=cut

1;

__DATA__
{"name":"Dramatica","chorus":0,"reverb":6,"tracks":[[13,7],[200,5]]}
{"name":"Hammered","chorus":4,"reverb":8,"tracks":[[95,7],[201,7]]}
{"name":"Doctored","chorus":5,"reverb":7,"tracks":[[91,7],[168,7],[144,7]]}
{"name":"Chicago","chorus":4,"reverb":8,"tracks":[[271,7],[269,7],[272,7]]}
{"name":"Strident","chorus":4,"reverb":8,"legacy":1,"tracks":[[101,7]]}
{"name":"Staged","chorus":2,"reverb":4,"legacy":1,"tracks":[[96,7],[274,7],[298,7]]}
{"name":"Bossatron","chorus":2,"reverb":7,"tracks":[[99,7],[85,7],[305,7]]}
{"name":"Swingatron","chorus":3,"reverb":6,"tracks":[[130,7],[91,7],[364,7]]}
{"name":"Tripletouch","chorus":4,"reverb":6,"legacy":1,"tracks":[[14,7]]}
{"name":"Tempered","chorus":4,"reverb":6,"legacy":1,"tracks":[[19,7]]}
{"name":"Plaino","chorus":5,"reverb":7,"legacy":1,"tracks":[[92,7]]}
{"name":"Third","chorus":2,"reverb":4,"beats":3,"divider":4,"tracks":[[117,7],[367,7]]}
{"name":"Simple Piano","chorus":4,"reverb":10,"legacy":1,"tracks":[[91,7]]}
{"name":"Serialized","chorus":5,"reverb":7,"legacy":1,"tracks":[[16,7],[204,7]]}
{"name":"Cinematique","chorus":5,"reverb":7,"legacy":1,"tracks":[[15,7],[313,5],[146,7]]}
{"name":"Carpal Tunnel","chorus":4,"reverb":7,"legacy":1,"tracks":[[94,7],[204,7]]}
{"name":"Spanner","chorus":5,"reverb":7,"legacy":1,"tracks":[[106,7]]}
{"name":"Pentagonia","chorus":3,"reverb":6,"beats":5,"divider":4,"legacy":1,"tracks":[[115,7]]}
{"name":"Pluckocaster","chorus":4,"reverb":8,"legacy":1,"tracks":[[206,7]]}
{"name":"Kubiac","chorus":4,"reverb":8,"tracks":[[158,7],[136,7],[141,7]]}
{"name":"Stringstabber","chorus":3,"reverb":6,"tracks":[[308,7],[172,5],[84,7],[143,7]]}
{"name":"Lectre","chorus":5,"reverb":7,"tracks":[[214,7],[86,7],[303,7]]}
{"name":"Plectrum","chorus":0,"reverb":8,"legacy":1,"tracks":[[209,7]]}
{"chorus":5,"name":"Governor","tracks":[[318,7],[131,7],[304,7]],"reverb":7}
{"name":"Steel Strummer","chorus":0,"reverb":9,"legacy":1,"tracks":[[321,7]]}
{"name":"Triplepicker","chorus":5,"reverb":7,"beats":3,"divider":4,"tracks":[[307,7],[286,7],[221,7]]}
{"name":"Rails","chorus":4,"reverb":8,"tracks":[[324,7],[280,7],[190,7]]}
{"name":"Balladica","chorus":4,"reverb":8,"legacy":1,"tracks":[[218,7]]}
{"name":"Cooper","chorus":4,"reverb":7,"legacy":1,"tracks":[[316,7],[86,7],[313,4],[300,7]]}
{"chorus":5,"name":"Romani","tracks":[[328,7],[82,7],[365,7]],"reverb":7}
{"chorus":5,"name":"Carambola","tracks":[[322,7],[135,7],[301,7]],"reverb":7}
{"name":"Ripe","chorus":2,"reverb":8,"tracks":[[211,7],[83,7],[145,7]]}
{"name":"Chopper","chorus":5,"reverb":7,"legacy":1,"tracks":[[323,7]]}
{"name":"Strumocaster","chorus":4,"reverb":8,"legacy":1,"tracks":[[320,7]]}
{"name":"Twangly","chorus":0,"reverb":8,"legacy":1,"tracks":[[333,7]]}
{"name":"Simple Electric","chorus":4,"reverb":8,"legacy":1,"tracks":[[316,7]]}
{"name":"Simple Acoustic","chorus":0,"reverb":12,"legacy":1,"tracks":[[317,7]]}
{"name":"Bassic","chorus":0,"reverb":4,"legacy":1,"tracks":[[276,7],[296,7]]}
{"name":"Morna","chorus":4,"reverb":6,"tracks":[[212,7],[84,7],[192,7]]}
{"name":"Syrtos","chorus":5,"reverb":7,"legacy":1,"tracks":[[325,7],[87,7],[193,7]]}
{"name":"Walker","chorus":3,"reverb":8,"tracks":[[253,7],[86,7],[366,7]]}
{"name":"Rhododendron","chorus":5,"reverb":7,"tracks":[[258,7],[278,7],[302,7]]}
{"name":"Nightly","chorus":5,"reverb":7,"legacy":1,"tracks":[[249,7],[299,7],[284,7]]}
{"chorus":5,"name":"Melmac","tracks":[[70,7],[161,7],[288,7],[148,7]],"reverb":7}
{"name":"Quasielectro","chorus":5,"reverb":7,"tracks":[[249,7],[170,7],[56,7]]}
{"name":"That 70s Organ","chorus":4,"reverb":8,"tracks":[[172,7],[186,7],[151,7]]}
{"name":"Melee Island","chorus":5,"reverb":7,"tracks":[[132,7],[191,7],[370,7]]}
{"name":"The Horror","chorus":5,"reverb":7,"legacy":1,"tracks":[[369,7],[202,7]]}
{"name":"Shuffle","chorus":2,"reverb":7,"tracks":[[269,7],[159,7],[172,7],[267,7]]}
{"name":"Langley","chorus":4,"reverb":8,"tracks":[[249,6],[281,7],[142,7]]}
{"name":"Barbeque","chorus":2,"reverb":5,"tracks":[[249,5],[160,7],[137,7],[120,7]]}
{"name":"Simple Rhodes","chorus":4,"reverb":10,"legacy":1,"tracks":[[249,7]]}
{"name":"Simple Organ","chorus":0,"reverb":10,"legacy":1,"tracks":[[172,7]]}
{"name":"Simple Mallet","chorus":5,"reverb":7,"legacy":1,"tracks":[[368,7]]}
{"chorus":5,"name":"Multipass","tracks":[[10,7],[51,7],[55,7]],"reverb":7}
{"chorus":5,"name":"Dialbot","tracks":[[4,7],[49,7],[57,7]],"reverb":7}
{"name":"Iceman","chorus":5,"reverb":7,"tracks":[[43,7],[47,7],[54,7]]}
{"name":"Electrostrings","chorus":5,"reverb":7,"legacy":1,"tracks":[[312,7],[53,7]]}
{"name":"Enigmomatic","chorus":5,"reverb":7,"tracks":[[312,5],[50,7],[58,7]]}
{"name":"Return","chorus":4,"reverb":8,"tracks":[[40,7],[313,7],[48,7],[59,7]]}
{"name":"Arp up","chorus":4,"reverb":8,"legacy":1,"tracks":[[2,7]]}
{"name":"Arp down","chorus":4,"reverb":8,"legacy":1,"tracks":[[1,7]]}
{"name":"Arp up\/down","chorus":4,"reverb":8,"legacy":1,"tracks":[[3,7]]}
{"name":"Simple Synth","chorus":4,"reverb":10,"legacy":1,"tracks":[[43,6]]}
{"name":"Krypton Choir","chorus":4,"reverb":8,"legacy":1,"tracks":[[44,7]]}
{"name":"Latinobot","chorus":2,"reverb":5,"tracks":[[100,7],[88,7],[194,7]]}

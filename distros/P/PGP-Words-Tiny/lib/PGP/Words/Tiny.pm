use 5.006;
use strict;
use warnings;

package PGP::Words::Tiny;
# ABSTRACT: Convert data to/from the PGP word list
our $VERSION = '0.002'; # VERSION

use Carp qw/croak/;
use Exporter 5.57 qw/import/;
our @EXPORT_OK = qw(encode_pgp decode_pgp encode_pgp_hex decode_pgp_hex);

my ( @even, @odd, %rev_even, %rev_odd );

sub encode_pgp {
    my $c = 0;
    return map { $c++ & 1 ? $odd[$_] : $even[$_] } unpack "C*", $_[0];
}

sub decode_pgp {
    my @input = @_ > 1 ? @_ : split " ", $_[0];
    my ( $c, @data ) = 0;
    for my $word (@input) {
        my $value = ( $c++ & 1 ? $rev_odd{ lc $word } : $rev_even{ lc $word } );
        croak "Encoding error detected at word $c ('$word')"
          unless defined $value;
        push @data, $value;
    }
    return pack "C*", @data;
}

sub encode_pgp_hex {
    my $string = shift;
    $string =~ s/^0x//i;
    return encode_pgp( pack "H*", $string );
}

sub decode_pgp_hex {
    return "0x" . unpack "H*", decode_pgp(@_);
}

#<<< No perltidy

@even = qw(
  aardvark absurd accrue acme adrift adult afflict ahead aimless
  Algol allow alone ammo ancient apple artist assume Athens atlas Aztec baboon
  backfield backward banjo beaming bedlamp beehive beeswax befriend Belfast
  berserk billiard bison blackjack blockade blowtorch bluebird bombast bookshelf
  brackish breadline breakup brickyard briefcase Burbank button buzzard cement
  chairlift chatter checkup chisel choking chopper Christmas clamshell classic
  classroom cleanup clockwork cobra commence concert cowbell crackdown cranky
  crowfoot crucial crumpled crusade cubic dashboard deadbolt deckhand dogsled
  dragnet drainage dreadful drifter dropper drumbeat drunken Dupont dwelling
  eating edict egghead eightball endorse endow enlist erase escape exceed
  eyeglass eyetooth facial fallout flagpole flatfoot flytrap fracture framework
  freedom frighten gazelle Geiger glitter glucose goggles goldfish gremlin
  guidance hamlet highchair hockey indoors indulge inverse involve island jawbone
  keyboard kickoff kiwi klaxon locale lockup merit minnow miser Mohawk mural
  music necklace Neptune newborn nightbird Oakland obtuse offload optic orca
  payday peachy pheasant physique playhouse Pluto preclude prefer preshrunk
  printer prowler pupil puppy python quadrant quiver quota ragtime ratchet
  rebirth reform regain reindeer rematch repay retouch revenge reward rhythm
  ribcage ringbolt robust rocker ruffled sailboat sawdust scallion scenic
  scorecard Scotland seabird select sentence shadow shamrock showgirl skullcap
  skydive slingshot slowdown snapline snapshot snowcap snowslide solo southward
  soybean spaniel spearhead spellbind spheroid spigot spindle spyglass stagehand
  stagnate stairway standard stapler steamship sterling stockman stopwatch stormy
  sugar surmount suspense sweatband swelter tactics talon tapeworm tempest tiger
  tissue tonic topmost tracker transit trauma treadmill Trojan trouble tumor
  tunnel tycoon uncut unearth unwind uproot upset upshot vapor village virus
  Vulcan waffle wallet watchword wayside willow woodlark Zulu
);

@odd = qw(
  adroitness adviser aftermath aggregate alkali almighty amulet
  amusement antenna applicant Apollo armistice article asteroid Atlantic
  atmosphere autopsy Babylon backwater barbecue belowground bifocals bodyguard
  bookseller borderline bottomless Bradbury bravado Brazilian breakaway
  Burlington businessman butterfat Camelot candidate cannonball Capricorn caravan
  caretaker celebrate cellulose certify chambermaid Cherokee Chicago clergyman
  coherence combustion commando company component concurrent confidence
  conformist congregate consensus consulting corporate corrosion councilman
  crossover crucifix cumbersome customer Dakota decadence December decimal
  designing detector detergent determine dictator dinosaur direction disable
  disbelief disruptive distortion document embezzle enchanting enrollment
  enterprise equation equipment escapade Eskimo everyday examine existence exodus
  fascinate filament finicky forever fortitude frequency gadgetry Galveston
  getaway glossary gossamer graduate gravity guitarist hamburger Hamilton
  handiwork hazardous headwaters hemisphere hesitate hideaway holiness hurricane
  hydraulic impartial impetus inception indigo inertia infancy inferno informant
  insincere insurgent integrate intention inventive Istanbul Jamaica Jupiter
  leprosy letterhead liberty maritime matchmaker maverick Medusa megaton
  microscope microwave midsummer millionaire miracle misnomer molasses molecule
  Montana monument mosquito narrative nebula newsletter Norwegian October Ohio
  onlooker opulent Orlando outfielder Pacific pandemic Pandora paperweight
  paragon paragraph paramount passenger pedigree Pegasus penetrate perceptive
  performance pharmacy phonetic photograph pioneer pocketful politeness positive
  potato processor provincial proximate puberty publisher pyramid quantity
  racketeer rebellion recipe recover repellent replica reproduce resistor
  responsive retraction retrieval retrospect revenue revival revolver sandalwood
  sardonic Saturday savagery scavenger sensation sociable souvenir specialist
  speculate stethoscope stupendous supportive surrender suspicious sympathy
  tambourine telephone therapist tobacco tolerance tomorrow torpedo tradition
  travesty trombonist truncated typewriter ultimate undaunted underfoot unicorn
  unify universe unravel upcoming vacancy vagabond vertigo Virginia visitor
  vocalist voyager warranty Waterloo whimsical Wichita Wilmington Wyoming
  yesteryear Yucatan
);

#>>> # no perl tidy

@rev_even{ map { lc } @even } = 0 .. $#even;
@rev_odd{ map  { lc } @odd }  = 0 .. $#odd;

1;


# vim: ts=2 sts=2 sw=2 et:

__END__

=pod

=encoding utf-8

=head1 NAME

PGP::Words::Tiny - Convert data to/from the PGP word list

=head1 VERSION

version 0.002

=head1 SYNOPSIS

  use PGP::Words::Tiny qw/encode_pgp_hex decode_pgp_hex/;

  say join " ", encode_pgp_hex("0xe582"); # "topmost Istanbul"

  say decode_pgp_hex("topmost Istanbul"); # "0xe582"

=head1 DESCRIPTION

This module converts octets to or from the
L<PGP word list|http://en.wikipedia.org/wiki/PGP_word_list>, allowing
a byte sequence to be conveyed via easily readable words.

It is similar in function to L<Crypt::OpenPGP::Words>, but without requiring
all of L<Crypt::OpenPGP>.  This module also provides decoding functions.

=head1 USAGE

The following functions are available for import.  None are imported by default.

=head2 encode_pgp

  @words = encode_pgp( $octets );

Returns a list of words drawn from the PGP word list corresponding to each octet
in the input string.  Even-position octets (starting at octet zero) are drawn from the
even word list.  Odd-position octets are drawn from the odd word list.

Proper nouns are capitalized as per the official word list.

=head2 encode_pgp_hex

  @words = encode_pgp_hex( $hex_string );

Converts a string of hex digits (with or without leading "0x") to an octet
string and returns the result of passing that octet string to C<encode_pgp>.

=head2 decode_pgp

  $octets = decode_pgp( @words );  # qw/topmost Istanbul/
  $octets = decode_pgp( $string ); # qq/topmost Istanbul/

Returns a string of octets decoded from a list of PGP words or from a
space-separated string of PGP words.  An exception is thrown if a word
is not in the PGP word list or is not in the correct even/odd position.

Input words are not case sensitive.

=head2 decode_pgp_hex

  $hex_string = decode_pgp_hex( @words );
  $hex_string = decode_pgp_hex( $string );

Returns a string of lowercase hex digits (preceded by "0x") decoded from a list
of PGP words.  It otherwise functions like C<decode_pgp>.

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/dagolden/PGP-Words-Tiny/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/dagolden/PGP-Words-Tiny>

  git clone https://github.com/dagolden/PGP-Words-Tiny.git

=head1 AUTHOR

David Golden <dagolden@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2012 by David Golden.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut

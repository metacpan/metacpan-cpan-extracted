package SMS::Ringtone::RTTTL::MIDI;
#### Package information ####
# Description and copyright:
#   See POD (i.e. perldoc SMS::Ringtone::RTTTL::MIDI).
####

use strict;
use Exporter;
use MIDI::Simple;
use SMS::Ringtone::RTTTL::MIDI;
use IO::String; # Add line "sub BINMODE {}" to this module.
our @ISA = qw(Exporter);
our @EXPORT = qw(rtttl_to_midi);
our $VERSION = '0.04';

1;

sub rtttl_to_midi {
 my $parser = shift; # SMS::Ringtone::RTTTL::Parser object
 my $patch = shift; # Instrument
 unless(defined($patch)) {
  $patch = 1; # Piano
 }
 my $ms = MIDI::Simple->new_score();
 if (length($parser->get_part_name())) {
  $ms->track_name($parser->get_part_name());
 }
 $ms->patch_change(0,$patch-1); # Set instrument on channel 0.
 $ms->set_tempo(60000000  / $parser->get_bpm()); # Microseconds per quarter note
 $ms->noop('fff','c0'); # Set max volume on channel 0.
 foreach my $nref ($parser->get_notes()) {
  # Convert RTTTL duration to MIDI ticks.
  my $ticks = ($ms->Tempo() * 4)/$nref->[0];
  if ($nref->[3] == 1) {
   $ticks *= 1.5;
  }
  elsif ($nref->[3] == 2) {
   $ticks *= 1.75;
  }
  # Write notes
  if ($nref->[1] eq 'P') {
   $ms->r("d$ticks");
  }
  else {
   my $note = uc($nref->[1]);
   $note =~ s/#/s/go;
   $ms->n("d$ticks",$note . $nref->[2]);
  }
 }
 my $midi;
 local(*OUT);
 tie *OUT, 'IO::String', \$midi;
 $ms->write_score(\*OUT);
 close(OUT);
 return $midi;
}

__END__

=head1 NAME

SMS::Ringtone::RTTTL::MIDI - convert RTTTL strings to MIDI format.

=head1 SYNOPSIS

 use SMS::Ringtone::RTTTL::Parser;
 use SMS::Ringtone::RTTTL::MIDI qw(rtttl_to_midi);

 my $rtttl = 'Flntstn:d=4,o=5,b=200:g#,c#,8p,c#6,8a#,g#,c#,' .
             '8p,g#,8f#,8f,8f,8f#,8g#,c#,d#,2f,2p,g#,c#,8p,' .
             'c#6,8a#,g#,c#,8p,g#,8f#,8f,8f,8f#,8g#,c#,d#,2c#';

 my $p = new SMS::Ringtone::RTTTL::Parser($rtttl);

 # Check for errors
 if ($p->has_errors()) {
  print "The following RTTTL errors were found:\n";
  foreach (@{$p->get_errors()}) {
   print "$_\n";
  }
  exit;
 }

 # Convert RTTTL to MIDI
 my $midi = rtttl_to_midi($p);

 # Write MIDI to file
 open(F);
 binmode(F);
 print F $midi;
 close(F);


=head1 DESCRIPTION

SMS::Ringtone::RTTTL::MIDI contains a subroutine for converting a RTTTL song into
MIDI format. See C<SMS::Ringtone::RTTTL::Parser>.


=head1 SUBROUTINES

=over 4

=item rtttl_to_midi($rtttl_parser,$patch)

This subroutine takes an C<SMS::Ringtone::RTTTL::Parser> object ($rtttl_parser) and returns MIDI data.
The parameter $patch is optional and contains the patch (instrument) to be used.
The default patch used is 1 (Piano).

=back


=head1 REFERENCE

=head2 General MIDI Instrument Patch Map

(groups sounds into sixteen families, w/8 instruments in each family)

 Prog#     Instrument               Prog#     Instrument

    (1-8        PIANO)                   (9-16      CHROM PERCUSSION)
 1         Acoustic Grand             9        Celesta
 2         Bright Acoustic           10        Glockenspiel
 3         Electric Grand            11        Music Box
 4         Honky-Tonk                12        Vibraphone
 5         Electric Piano 1          13        Marimba
 6         Electric Piano 2          14        Xylophone
 7         Harpsichord               15        Tubular Bells
 8         Clav                      16        Dulcimer

    (17-24      ORGAN)                   (25-32      GUITAR)
 17        Drawbar Organ             25        Acoustic Guitar(nylon)
 18        Percussive Organ          26        Acoustic Guitar(steel)
 19        Rock Organ                27        Electric Guitar(jazz)
 20        Church Organ              28        Electric Guitar(clean)
 21        Reed Organ                29        Electric Guitar(muted)
 22        Accoridan                 30        Overdriven Guitar
 23        Harmonica                 31        Distortion Guitar
 24        Tango Accordian           32        Guitar Harmonics

    (33-40      BASS)                    (41-48     STRINGS)
 33        Acoustic Bass             41        Violin
 34        Electric Bass(finger)     42        Viola
 35        Electric Bass(pick)       43        Cello
 36        Fretless Bass             44        Contrabass
 37        Slap Bass 1               45        Tremolo Strings
 38        Slap Bass 2               46        Pizzicato Strings
 39        Synth Bass 1              47        Orchestral Strings
 40        Synth Bass 2              48        Timpani

    (49-56     ENSEMBLE)                 (57-64      BRASS)
 49        String Ensemble 1         57        Trumpet
 50        String Ensemble 2         58        Trombone
 51        SynthStrings 1            59        Tuba
 52        SynthStrings 2            60        Muted Trumpet
 53        Choir Aahs                61        French Horn
 54        Voice Oohs                62        Brass Section
 55        Synth Voice               63        SynthBrass 1
 56        Orchestra Hit             64        SynthBrass 2

    (65-72      REED)                    (73-80      PIPE)
 65        Soprano Sax               73        Piccolo
 66        Alto Sax                  74        Flute
 67        Tenor Sax                 75        Recorder
 68        Baritone Sax              76        Pan Flute
 69        Oboe                      77        Blown Bottle
 70        English Horn              78        Skakuhachi
 71        Bassoon                   79        Whistle
 72        Clarinet                  80        Ocarina

    (81-88      SYNTH LEAD)              (89-96      SYNTH PAD)
 81        Lead 1 (square)           89        Pad 1 (new age)
 82        Lead 2 (sawtooth)         90        Pad 2 (warm)
 83        Lead 3 (calliope)         91        Pad 3 (polysynth)
 84        Lead 4 (chiff)            92        Pad 4 (choir)
 85        Lead 5 (charang)          93        Pad 5 (bowed)
 86        Lead 6 (voice)            94        Pad 6 (metallic)
 87        Lead 7 (fifths)           95        Pad 7 (halo)
 88        Lead 8 (bass+lead)        96        Pad 8 (sweep)

    (97-104     SYNTH EFFECTS)           (105-112     ETHNIC)
  97        FX 1 (rain)              105       Sitar
  98        FX 2 (soundtrack)        106       Banjo
  99        FX 3 (crystal)           107       Shamisen
 100        FX 4 (atmosphere)        108       Koto
 101        FX 5 (brightness)        109       Kalimba
 102        FX 6 (goblins)           110       Bagpipe
 103        FX 7 (echoes)            111       Fiddle
 104        FX 8 (sci-fi)            112       Shanai

    (113-120    PERCUSSIVE)              (121-128     SOUND EFFECTS)
 113        Tinkle Bell              121       Guitar Fret Noise
 114        Agogo                    122       Breath Noise
 115        Steel Drums              123       Seashore
 116        Woodblock                124       Bird Tweet
 117        Taiko Drum               125       Telephone Ring
 118        Melodic Tom              126       Helicopter
 119        Synth Drum               127       Applause
 120        Reverse Cymbal           128       Gunshot


=head1 HISTORY

=over 4

=item Version 0.01  2001-11-04

Initial version.

=item Version 0.02  2001-11-05

Changed default instrument from Drawbar Organ (17) to Piano (1).

=item Version 0.03  2001-12-27

Fixed comment error and added some tests.

=item Version 0.04  2002-01-02

Fixed documentation errors in synopsis.

=back

=head1 AUTHOR

Craig Manley	c.manley@skybound.nl

=head1 COPYRIGHT

Copyright (C) 2001 Craig Manley <c.manley@skybound.nl>.  All rights reserved.
This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. There is NO warranty;
not even for MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=cut
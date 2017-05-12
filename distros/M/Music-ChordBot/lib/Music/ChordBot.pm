#! perl

package Music::ChordBot;

use warnings;
use strict;

our $VERSION = '0.91';

=head1 NAME

Music::ChordBot - Programmatically build songs for ChordBot

=head1 SYNOPSIS

Song API (simple):

  use Music::ChordBot::Song;

  # Define a song
  song "Funky Perl";
  tempo 120;

  # Define a section (song part)
  section "Funky Section";
  style "Kubiac";

  # Add chords.
  Dm7 4; Am7; Dm7; Dm7;

Song API (explicit chords):

  # Add chords.
  chord "D Min7 4";
  chord "A Min7 4";
  chord "D Min7 4";
  chord "D Min7 4";

Opus API (powerful):

  use Music::ChordBot::Opus;
  use Music::ChordBot::Opus::Section;

  # The song.
  my $song = Music::ChordBot::Opus->new(
      name => "Funky Perl", tempo => 120 );

  # One section.
  my $section = Music::ChordBot::Opus::Section->new(
      name => "Funky Section" );

  $section->set_style( "Kubiac" );
  $section->add_chord( "D Min7 4" );
  $section->add_chord( "A Min7 4" );
  $section->add_chord( "D Min7 4" );
  $section->add_chord( "D Min7 4" );

  # Add section to song.
  $song->add_section($section);

  # Export as json.
  print $song->json, "\n";

=head1 DESCRIPTION

Chordbot is a songwriting tool / electronic backup band for
iPhone/iPad and Android that lets you experiment with advanced chord
progressions and arrangements quickly and easily. You can use Chordbot
for songwriting experiments, as accompaniment when learning new songs
or for making backing tracks for your guitar / saxophone / theremin
solos.

ChordBot can import and export songs in JSON format. Music::ChordBot
provides a set of modules that can be used to programmatically
build songs and produce the JSON data suitable for import into
ChordBot.

ChordBot web site: L<http://www.chordbot.com>.

Note that Music::ChordBot requires the full version of ChordBot since
the Lite version does not have import capabilities.

Currently there are two distinct API's as can be seen from the
SYNOPSYS. See L<Music::ChordBot::Song> and L<Music::ChordBot::Opus>
for details.

=head1 AUTHOR

Johan Vromans, C<< <jv at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-music-chordbot at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Music-ChordBot>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Music::ChordBot
    perldoc Music::ChordBot::Song
    perldoc Music::ChordBot::Opus

=head1 ACKNOWLEDGEMENTS

Lars Careliusson, for writing ChordBot and being helpful by providing
implementation details so I didn't have to reverse engineer
everything.

=head1 COPYRIGHT & LICENSE

Copyright 2013 Johan Vromans, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;

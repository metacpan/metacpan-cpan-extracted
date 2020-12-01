package Task::MusicBundle;

BEGIN {
  $Task::MusicBundle::AUTHORITY = 'cpan:GENE';
}

# ABSTRACT: A bundle of MIDI and music modules

use strict;
use warnings;

our $VERSION = '0.1901';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Task::MusicBundle - A bundle of MIDI and music modules

=head1 VERSION

version 0.1901

=head1 SYNOPSIS

 cpanm Task::MusicBundle
 # or
 cpan Task::MusicBundle
 # or
 perl -MCPAN -e 'install Task::MusicBundle'
 # or
 ppm install Task-MusicBundle

=head1 DESCRIPTION

This is a bundle to install various MIDI and music related modules.

If you would like to see a specific module included (or discluded), please email
or use rt.cpan.org.

Modules marked with a date, in the C<CONTENTS>, are 10 years or older. But so
what?  B<Music is older than agriculture.>

=head1 CONTENTS

L<App::MusicTools>

L<Csound>

L<Guitar::Scale>

L<MIDI>

L<MIDI::Chord::Guitar>

L<MIDI::Drummer::Tiny>

L<MIDI::Morph>

L<MIDI::Ngram>

L<MIDI::Pitch>

L<MIDI::Praxis::Variation>

L<MIDI::Simple::Drummer>

L<MIDI::SoundFont>

L<MIDI::Tab>

L<MIDI::Tools>

L<MIDI::Trans>

L<MIDI::Tweaks>

L<MIDI::Util>

L<Music::AtonalUtil>

L<Music::Cadence>

L<Music::Canon>

L<Music::ChordBot>

L<Music::Chord::Namer>

L<Music::Chord::Note>

L<Music::Chord::Positions>

L<Music::Duration>

L<Music::Duration::Partition>

L<Music::Gestalt>

L<Music::Harmonics>

L<Music::Interval::Barycentric>

L<Music::Intervals>

L<Music::NeoRiemannianTonnetz>

L<Music::Note::Frequency>

L<Music::Note::Role::Operators>

L<Music::PitchNum>

L<Music::RecRhythm>

L<Music::Scala>

L<Music::ScaleNote>

L<Music::Scales>

L<Music::Tempo>

L<Music::Tension>

L<Music::ToRoman>

L<Music::VoiceGen>

L<Music::Voss>

L<Text::Chord::Piano>

=head1 AUTHOR

Gene Boggs <gene@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Gene Boggs.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

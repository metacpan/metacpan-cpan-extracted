package Music::Harmonica::TabsCreator;

use 5.036;
use strict;
use warnings;
use utf8;

use English;
use Exporter qw(import);
use List::Util qw(min max none);
use Music::Harmonica::TabsCreator::NoteToToneConverter;
use Music::Harmonica::TabsCreator::TabParser;
use Readonly;
use Scalar::Util qw(looks_like_number);

our $VERSION = '0.04';

our @EXPORT_OK = qw(tune_to_tab get_tuning_details tune_to_tab_rendered
    transpose_tab transpose_tab_rendered list_tunings);

# Options to add:
# - print B as H (international convention), but probably not Bb which stays Bb.

Readonly my $TONES_PER_SCALE => 12;

Readonly my %ALL_TUNINGS => (
  # Written in the key of C to match the default key used in the note_to_tone
  # function.
  # Note that when we have the same note appear multiple time (like -2 and 3 in
  # Richter scale) we always use only the last appearance one when rendering a
  # tab (but other appearances are still used when reading a tab).
  richter => {
    tags => [qw(diatonic 10-holes)],
    name => 'Richter',
    # Although we We arbitrarily keep only +3 and never use -2.
    # We might need to change that if we wanted to support chords.
    tab => [qw(  1  -1 2 -2  3  -3  4 -4 5  -5 6  -6 7  -7 8  -8 9  -9 10 -10)],
    notes => [qw(C4 D4 E4 G4 G4 B4 C5 D5 E5 F5 G5 A5 C6 B5 E6 D6 G6 F6 C7 A6)],
    bends => [qw(0  1  0  2  0  3  0  1  0  0  0  1  0  0  1  0  1  0  2  0)],
  },
  harmonic_minor => {
    tags => [qw(diatonic 10-holes)],
    name => 'Harmonic minor',
    # We arbitrarily keep only +3 and never use -2.
    # We might need to change that if we wanted to support chords.
    tab => [qw(1  -1 2   -2 3  -3 4 -4  5   -5 6  -6  7  -7 8   -8 9  -9 10 -10)],
    notes => [qw(C4 D4 Eb4 G4 G4 B4 C5 D5 Eb5 F5 G5 Ab5 C6 B5 Eb6 D6 G6 F6 C7 Ab6)],
    bends => [qw(0  1  0   3  0  3  0  1  0   1  0  0   0  0  0   0  1  0  3  0)],
  },
);

# We can’t use qw() because of the # that triggers a warning.
Readonly my @keys_offset => split / /, q(C Db D Eb E F F# G Ab A Bb B);

Readonly my $MAX_BENDS => 6;  # Probably higher than any realistic value.

sub tune_to_tab ($sheet, %options) {
  my $note_converter = Music::Harmonica::TabsCreator::NoteToToneConverter->new();
  my @tones = $note_converter->convert($sheet);
  my $tunings = generate_tunings($options{max_bends} // 0, $options{tunings} // []);
  return find_matching_tuning(\@tones, $tunings);
}

sub transpose_tab ($tab, $tuning_id, $key, %options) {
  die "Unknown tuning: $tuning_id\n" unless exists $ALL_TUNINGS{$tuning_id};
  # For the input, we accept any level of bending.
  my $tuning = generate_tunings($MAX_BENDS, [$tuning_id])->{$tuning_id};
  my $note_converter = Music::Harmonica::TabsCreator::NoteToToneConverter->new();
  my %tab_to_tones = map { $tuning->{tab}[$_] => $note_converter->convert($tuning->{notes}[$_]) }
      0 .. $#{$tuning->{tab}};
  my $parser = Music::Harmonica::TabsCreator::TabParser->new(\%tab_to_tones);
  my @tones = $parser->parse($tab);
  my @key_tone = eval { $note_converter->convert($key) };
  return "Invalid key: $key" if $@ || @key_tone != 1;
  my $key_tone = $key_tone[0];
  @tones = map { looks_like_number($_) ? $_ + $key_tone : $_ } @tones;
  my $tunings = generate_tunings($options{max_bends} // 0, $options{tunings} // []);
  return find_matching_tuning(\@tones, $tunings);
}

# We take the global %ALL_TUNINGS and generate a %tunings hash with the same
# keys but where the values only have the notes and tab entries. But we have
# added the notes corresponding to the allowed bends.
sub generate_tunings ($max_bends, $tunings) {
  my %out;
  while (my ($k, $v) = each %ALL_TUNINGS) {
    next if @{$tunings} && none { $_ eq $k } @{$tunings};
    for my $i (0 .. $#{$v->{notes}}) {
      my $note = $v->{notes}[$i];
      my $tab = $v->{tab}[$i];
      for my $b (0 .. min($max_bends, $v->{bends}[$i])) {
        my $bent = (substr $note, 0, 1).('b' x $b).(substr $note, 1);
        push @{$out{$k}{notes}}, $bent;
        # TODO: this won’t work once we have chromatic harmonicas
        push @{$out{$k}{tab}}, $tab.('"' x ($b / 2)).("'" x ($b % 2));
      }
    }
  }
  return \%out;
}

sub find_matching_tuning ($tones, $tunings) {
  my %all_matches;
  while (my ($k, $v) = each %{$tunings}) {
    my @matches = match_notes_to_tuning($tones, $v);
    for my $m (@matches) {
      push @{$all_matches{$k}{$m->[1]}}, $m->[0];
    }
  }
  return %all_matches;
}

sub tune_to_tab_rendered ($sheet, %options) {
  my %tabs = eval { tune_to_tab($sheet, %options) };
  return $@ if $@;
  return render_tabs(%tabs);
}

sub transpose_tab_rendered ($tab, $tuning, $key, %options) {
  my %tabs = eval { transpose_tab($tab, $tuning, $key, %options) };
  return $@ if $@;
  return render_tabs(%tabs);
}

sub render_tabs (%tabs) {
  if (!%tabs) {
    return 'No tabs found';
  }

  my $out;

  for my $type (sort keys %tabs) {
    my %details = get_tuning_details($type);
    $out .= sprintf "For %s %s tuning harmonicas:\n", join(' ', @{$details{tags}}), $details{name};
    for my $key (sort keys %{$tabs{$type}}) {
      $out .= "  In the key of ${key}:\n";
      for my $tab (@{$tabs{$type}{$key}}) {
        my $str_tab = join(' ', map { m/^\v+$/ ? $_.'   ' : $_ } @{$tab});
        $str_tab =~ s/(\h|\v)+\Z//;
        $out .= "    ${str_tab}\n\n";
      }
    }
  }

  return $out;
}

sub get_tuning_details ($key) {
  return %{$ALL_TUNINGS{$key}}{qw(name tags)};
}

sub list_tunings () {
  return map { {id => $_, name => $ALL_TUNINGS{$_}{name}, tags => $ALL_TUNINGS{$_}{tags}} }
      sort keys %ALL_TUNINGS;
}

# Given all the tones (with C0 = 0) of a melody and the data of a given
# harmonica tuning, returns whether the melody can be played on this
# harmonica and, if yes, the octave shift to apply to the melody.
sub match_notes_to_tuning ($tones, $tuning) {
  my $note_converter = Music::Harmonica::TabsCreator::NoteToToneConverter->new();
  my @scale_tones = map { $note_converter->convert($_) } @{$tuning->{notes}};
  my ($scale_min, $scale_max) = (min(@scale_tones), max(@scale_tones));
  my @real_tones = grep { looks_like_number($_) } @{$tones};
  my ($tones_min, $tones_max) = (min(@real_tones), max(@real_tones));
  my %scale_tones = map { $scale_tones[$_] => $tuning->{tab}[$_] } 0 .. $#scale_tones;
  my ($o_min, $o_max) = ($scale_min - $tones_min, $scale_max - $tones_max);
  my @matches;

  for my $o ($o_min .. $o_max) {
    my @tab = tab_from_tones($tones, $o, %scale_tones);
    push @matches, [\@tab, $keys_offset[($TONES_PER_SCALE - $o) % $TONES_PER_SCALE]] if @tab;
  }
  return @matches;
}

sub tab_from_tones($tones, $offset, %scale_tones) {
  my @tab;
  for my $t (@{$tones}) {
    if (looks_like_number($t)) {
      return unless exists $scale_tones{$t + $offset};
      push @tab, $scale_tones{$t + $offset};
    } else {
      push @tab, $t;
    }
  }
  return @tab;
}

1;

# TODO: document the options of the methods.

__END__

=pod

=encoding utf8

=head1 NAME

Music::Harmonica::TabsCreator - Convert tunes into harmonica tabs

=head1 SYNOPSIS

  use Music::Harmonica::TabsCreator qw(sheet_to_tab_rendered);
  say sheet_to_tab_rendered('C D E F G A B C');

=head1 DESCRIPTION

=head2 tune_to_tab

  my %tabs = tune_to_tab($tune)

Convert a sheet music into harmonica tablatures. Sheets can be specified using
a flexible syntax like: C<C D E F>, C<C# Db>, C<Do ré mi>, C<C4 C5>,
C<< A B > C D E F G A B > C D D C < B A >> (that last example shows how you can
switch the current octave if you don’t specify octave numbers with each note).

For more details on the tune format, see the
L<GitHub README|https://github.com/mkende/harmonica_tabs_creator>.

The function returns a hash (not a hash-ref) where the keys are the identifier
of a given harmonica (you can learn more about that harmonica using the
C<get_harmonica_details()> function), and the values are hash-refs where the
keys are the key of the harmonica to use to play the tune. The values associated
to these keys are arrays of tablatures. Each tablature is itself an array of
strings, one for each note making up the tablature.

=head2 tune_to_tab_rendered

  say tune_to_tab_rendered('Kb B C D E F G A B C');

This is the same thing as C<tune_to_tab> but the output is returned in a string
ready to be displayed to a user. Also this function will not C<die> (instead a
user friendly error will be returned directly in the string).

=head2 get_harmonica_details

  my %details = get_harmonica_details($harmonica_id);

Given an ID that is one of the key of the hash returned by C<tune_to_tab()>
function this returns a hash containing two keys: C<name> and C<tags> where the
first has a human readable name for the harmonica and the second a list of
tags relevant to the harmonica.

=head1 AUTHOR

Mathias Kende <mathias@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright 2025 Mathias Kende

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
the Software, and to permit persons to whom the Software is furnished to do so,
subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

=head1 SEE ALSO

=over

=item L<harmonica-tabs-creator>

=back

=cut

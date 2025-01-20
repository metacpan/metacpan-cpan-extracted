package Music::Harmonica::TabsCreator::NoteToToneConverter;

use 5.036;
use strict;
use warnings;
use utf8;

use List::Util qw(any);
use Readonly;

our $VERSION = '0.01';

# This class converts written note (accepting various syntax for the notes) into
# tones (degrees) relative to the key of C4.

sub new ($class, %options) {
  my $self = bless {
    default_octave => $options{default_octave} // 5,  ## no critic (ProhibitMagicNumbers)
    key => $options{key} // 'C',
  }, $class;
  return $self;
}

# For now we assume that the key is C when entering the sheet music (when
# specifying octaves). It’s unclear what are the convention here for other keys.

Readonly my %NOTE_TO_TONE => (
  C => 0,
  Do => 0,
  D => 2,
  'Ré' => 2,
  E => 4,
  Mi => 4,
  F => 5,
  Fa => 5,
  G => 7,
  Sol => 7,
  A => 9,
  La => 9,
  B => 11,
  Si => 11,
  H => 11,
);

Readonly my %ACCIDENTAL_TO_ALTERATION => (
  '#' => 1,
  '+' => 1,
  'b' => -1,
  '-' => -1,
  '' => 0,
);

Readonly my %SIGNATURE_TO_KEY => (
  '' => 'C',
  b => 'F',
  bb => 'Bb',
  bbb => 'Eb',
  bbbb => 'Ab',
  bbbbb => 'Db',
  bbbbbb => 'Gb',
  bbbbbbb => 'Cb',
  '#' => 'G',
  '##' => 'D',
  '###' => 'A',
  '####' => 'E',
  '#####' => 'B',
  '######' => 'F#',
  '#######' => 'C#',
);

Readonly my @FLAT_ORDER => qw(B E A D G C F);
Readonly my @SHARP_ORDER => qw(F C G D A E B);
Readonly my %KEY_TO_ALTERATION => (
  C => 0,
  F => -1,
  Bb => -2,
  Eb => -3,
  Ab => -4,
  Db => -5,
  Gb => -6,
  Cb => -7,
  G => 1,
  D => 2,
  A => 3,
  E => 4,
  B => 5,
  'F#' => 6,
  'C#' => 7,
);

Readonly my $NOTE_NAME_RE => qr/ do|Do|ré|Ré|mi|Mi|fa|Fa|sol|Sol|la|La|si|Si | [A-H] /x;

Readonly my $BASE_OCTAVE => 4;
Readonly my $TONES_PER_SCALE => 12;

sub note_to_tone ($note) {
  return $NOTE_TO_TONE{$note};
}

sub alteration_for_note ($self, $note) {
  my $alt = $KEY_TO_ALTERATION{$self->{key}};
  if ($alt > 0) {
    return (any { note_to_tone($_) eq note_to_tone($note) } @SHARP_ORDER[0 .. $alt - 1]) ? 1 : 0;
  } elsif ($alt < 0) {
    return (any { note_to_tone($_) eq note_to_tone($note) } @FLAT_ORDER[0 .. abs($alt) - 1])
        ? -1
        : 0;
  } else {
    return 0;
  }
}

# Note that calls to convert can return nothing. The general pattern is to call
# that in a sub passed to a map call.

sub convert ($self, $symbols) {
  my @out;
  while ((pos($symbols) // 0) < length($symbols)) {
    next if $symbols =~ m/\G\h+/gc;

    if ($symbols =~ m/\G(\v+)/gc) {
      push @out, $1;
      next;
    }

    if ($symbols =~ m/\G(#.*?(?:\v|$))/mgc) {
      push @out, $1;
      next;
    }

    if ($symbols =~ m/\G(<|>)/gc) {
      $self->{default_octave} += $1 eq '>' ? 1 : -1;
      next;
    }

    if ($symbols =~ m/\GK(b{0,7}|#{0,7})?/gc) {
      $self->{key} = $SIGNATURE_TO_KEY{$1};
      next;
    }

    # TODO: print only the relevant part of symbols here
    # There is a bug here that A-3 won’t be parsed as the - will be taken for a flat.
    if ($symbols =~ m/\G ( ${NOTE_NAME_RE} ) ( [#+b-]? )( -?\d+ )? (,+|'+)?/xgc) {
      my ($note, $accidental, $octave, $rel_octave) =
          (ucfirst($1), $2, $3 // $self->{default_octave}, $4);
      if ($rel_octave) {
        $octave += length($rel_octave) * ($rel_octave =~ /,/ ? -1 : 1);
      }
      my $base = $TONES_PER_SCALE * ($octave - $BASE_OCTAVE) + note_to_tone($note);
      my $alteration =
          $accidental ? $ACCIDENTAL_TO_ALTERATION{$accidental} : $self->alteration_for_note($note);
      push @out, $base + $alteration;
      next;
    }

    my $pos = pos($symbols) // 0;
    die "Invalid syntax at position ${pos} in: ${symbols}\n";
  }
  return wantarray ? @out : \@out;
}

1;

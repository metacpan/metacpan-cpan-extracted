# -*- Perl -*-
#
# http://www.lilypond.org/ related utility code (mostly to transition
# between Perl processing integers and the related appropriate letter
# names for the black dots in lilypond). See also Music::PitchNum.

package Music::LilyPondUtil;

use 5.010000;
use strict;
use warnings;
use Carp qw/croak/;
use Scalar::Util qw/blessed looks_like_number/;
use Try::Tiny;

our $VERSION = '0.56';

# Since dealing with lilypond, assume 12 pitch material
my $DEG_IN_SCALE = 12;
my $TRITONE      = 6;

# Default register - due to "c" in lilypond absolute notation mapping to
# the fourth register, or MIDI pitch number 48. Used by the reg_*
# utility subs.
my $REL_DEF_REG = 4;

# Just the note and register information - the 0,6 bit grants perhaps
# too much leeway for relative motion (silly things like c,,,,,,,
# relative to the top note on a piano) but there are other bounds on the
# results so that they lie within the span of the MIDI note numbers.
my $LY_NOTE_RE = qr/(([a-g])(?:eses|isis|es|is)?)(([,'])\g{-1}{0,6})?/;

my %N2P = (
  qw/bis 0 c 0 deses 0 bisis 1 cis 1 des 1 cisis 2 d 2 eeses 2 dis 3 ees 3 feses 3 disis 4 e 4 fes 4 eis 5 f 5 geses 5 eisis 6 fis 6 ges 6 fisis 7 g 7 aeses 7 gis 8 aes 8 gisis 9 a 9 beses 9 ais 10 bes 10 ceses 10 aisis 11 b 11 ces 11/
);
# mixing flats and sharps not supported, either one or other right now
my %P2N = (
  flats  => {qw/0 c 1 des 2 d 3 ees 4 e 5 f 6 ges 7 g 8 aes 9 a 10 bes 11 b/},
  sharps => {qw/0 c 1 cis 2 d 3 dis 4 e 5 f 6 fis 7 g 8 gis 9 a 10 ais 11 b/},
);

# Diabolus in Musica, indeed (direction tritone heads in relative mode)
my %TTDIR = (
  flats  => {qw/0 -1 1 1 2 -1 3 1 4 -1 5 1 6 1 7 -1 8 1 9 -1 10 1 11 -1/},
  sharps => {qw/0 1 1 -1 2 1 3 -1 4 1 5 1 6 -1 7 1 8 -1 9 1 10 -1 11 -1/},
);

# on loan from scm/midi.scm of lilypond fame (and possibly also some
# MIDI specification somewhere?)
my %PATCH2INSTRUMENT = (
  0   => "acoustic grand",
  1   => "bright acoustic",
  2   => "electric grand",
  3   => "honky-tonk",
  4   => "electric piano 1",
  5   => "electric piano 2",
  6   => "harpsichord",
  7   => "clav",
  8   => "celesta",
  9   => "glockenspiel",
  10  => "music box",
  11  => "vibraphone",
  12  => "marimba",
  13  => "xylophone",
  14  => "tubular bells",
  15  => "dulcimer",
  16  => "drawbar organ",
  17  => "percussive organ",
  18  => "rock organ",
  19  => "church organ",
  20  => "reed organ",
  21  => "accordion",
  22  => "harmonica",
  23  => "concertina",
  24  => "acoustic guitar (nylon)",
  25  => "acoustic guitar (steel)",
  26  => "electric guitar (jazz)",
  27  => "electric guitar (clean)",
  28  => "electric guitar (muted)",
  29  => "overdriven guitar",
  30  => "distorted guitar",
  31  => "guitar harmonics",
  32  => "acoustic bass",
  33  => "electric bass (finger)",
  34  => "electric bass (pick)",
  35  => "fretless bass",
  36  => "slap bass 1",
  37  => "slap bass 2",
  38  => "synth bass 1",
  39  => "synth bass 2",
  40  => "violin",
  41  => "viola",
  42  => "cello",
  43  => "contrabass",
  44  => "tremolo strings",
  45  => "pizzicato strings",
  46  => "orchestral harp",
  47  => "timpani",
  48  => "string ensemble 1",
  49  => "string ensemble 2",
  50  => "synthstrings 1",
  51  => "synthstrings 2",
  52  => "choir aahs",
  53  => "voice oohs",
  54  => "synth voice",
  55  => "orchestra hit",
  56  => "trumpet",
  57  => "trombone",
  58  => "tuba",
  59  => "muted trumpet",
  60  => "french horn",
  61  => "brass section",
  62  => "synthbrass 1",
  63  => "synthbrass 2",
  64  => "soprano sax",
  65  => "alto sax",
  66  => "tenor sax",
  67  => "baritone sax",
  68  => "oboe",
  69  => "english horn",
  70  => "bassoon",
  71  => "clarinet",
  72  => "piccolo",
  73  => "flute",
  74  => "recorder",
  75  => "pan flute",
  76  => "blown bottle",
  77  => "shakuhachi",
  78  => "whistle",
  79  => "ocarina",
  80  => "lead 1 (square)",
  81  => "lead 2 (sawtooth)",
  82  => "lead 3 (calliope)",
  83  => "lead 4 (chiff)",
  84  => "lead 5 (charang)",
  85  => "lead 6 (voice)",
  86  => "lead 7 (fifths)",
  87  => "lead 8 (bass+lead)",
  88  => "pad 1 (new age)",
  89  => "pad 2 (warm)",
  90  => "pad 3 (polysynth)",
  91  => "pad 4 (choir)",
  92  => "pad 5 (bowed)",
  93  => "pad 6 (metallic)",
  94  => "pad 7 (halo)",
  95  => "pad 8 (sweep)",
  96  => "fx 1 (rain)",
  97  => "fx 2 (soundtrack)",
  98  => "fx 3 (crystal)",
  99  => "fx 4 (atmosphere)",
  100 => "fx 5 (brightness)",
  101 => "fx 6 (goblins)",
  102 => "fx 7 (echoes)",
  103 => "fx 8 (sci-fi)",
  104 => "sitar",
  105 => "banjo",
  106 => "shamisen",
  107 => "koto",
  108 => "kalimba",
  109 => "bagpipe",
  110 => "fiddle",
  111 => "shanai",
  112 => "tinkle bell",
  113 => "agogo",
  114 => "steel drums",
  115 => "woodblock",
  116 => "taiko drum",
  117 => "melodic tom",
  118 => "synth drum",
  119 => "reverse cymbal",
  120 => "guitar fret noise",
  121 => "breath noise",
  122 => "seashore",
  123 => "bird tweet",
  124 => "telephone ring",
  125 => "helicopter",
  126 => "applause",
  127 => "gunshot",
);

########################################################################
#
# SUBROUTINES

sub _range_check {
  my ( $self, $pitch ) = @_;
  if ( $pitch < $self->{_min_pitch} ) {
    if ( exists $self->{_min_pitch_hook} ) {
      return $self->{_min_pitch_hook}
        ( $pitch, $self->{_min_pitch}, $self->{_max_pitch}, $self );
    } else {
      die "pitch $pitch is too low\n";
    }

  } elsif ( $pitch > $self->{_max_pitch} ) {
    if ( exists $self->{_max_pitch_hook} ) {
      return $self->{_max_pitch_hook}
        ( $pitch, $self->{_min_pitch}, $self->{_max_pitch}, $self );
    } else {
      die "pitch $pitch is too high\n";
    }
  }

  return;
}

sub _symbol2relreg {
  my ($symbol) = @_;
  $symbol ||= q{};

  # no leap, within three stave lines of previous note
  return 0 if length $symbol == 0;

  die "invalid register symbol $symbol\n"
    if $symbol !~ m/^(([,'])\g{-1}*)$/;

  my $count = length $1;
  $count *= $2 eq q{'} ? 1 : -1;

  return $count;
}

sub chrome {
  my ( $self, $chrome ) = @_;
  if ( defined $chrome ) {
    croak q{chrome must be 'sharps' or 'flats'} unless exists $P2N{$chrome};
    $self->{_chrome} = $chrome;
  }
  return $self->{_chrome};
}

sub clear_prev_note {
  my ($self) = @_;
  undef $self->{prev_note};
}

sub clear_prev_pitch {
  my ($self) = @_;
  undef $self->{prev_pitch};
}

# diatonic (piano white key) pitch number for a given input note (like
# prev_note() below except without side-effects).
sub diatonic_pitch {
  my ( $self, $note ) = @_;

  croak 'note not defined' unless defined $note;

  my $pitch;
  if ( $note =~ m/^$LY_NOTE_RE/ ) {
    # TODO duplicates (portions of) same code, below
    my $real_note     = $1;
    my $diatonic_note = $2;
    my $reg_symbol    = $3 // '';

    croak "unknown lilypond note $note" unless exists $N2P{$real_note};

    $pitch = $N2P{$diatonic_note} + $self->reg_sym2num($reg_symbol) * $DEG_IN_SCALE;
    $pitch %= $DEG_IN_SCALE if $self->{_ignore_register};

  } else {
    croak "unknown note $note";
  }

  return $pitch;
}

sub ignore_register {
  my ( $self, $state ) = @_;
  $self->{_ignore_register} = $state if defined $state;
  return $self->{_ignore_register};
}

sub keep_state {
  my ( $self, $state ) = @_;
  $self->{_keep_state} = $state if defined $state;
  return $self->{_keep_state};
}

sub mode {
  my ( $self, $mode ) = @_;
  if ( defined $mode ) {
    croak q{mode must be 'absolute' or 'relative'}
      if $mode ne 'absolute' and $mode ne 'relative';
    $self->{_mode} = $mode;
  }
  return $self->{_mode};
}

sub new {
  my ( $class, %param ) = @_;
  my $self = {};

  $self->{_chrome} = $param{chrome} || 'sharps';
  croak q{chrome must be 'sharps' or 'flats'}
    unless exists $P2N{ $self->{_chrome} };

  $self->{_keep_state}      = $param{keep_state}      // 1;
  $self->{_ignore_register} = $param{ignore_register} // 0;

  # Default min_pitch of 21 causes too many problems for existing code,
  # so minimum defaults to 0, which is a bit beyond the bottom of 88-key
  # pianos. 108 is the top of a standard 88-key piano.
  $self->{_min_pitch} = $param{min_pitch} // 0;
  $self->{_max_pitch} = $param{max_pitch} // 108;

  if ( exists $param{min_pitch_hook} ) {
    croak 'min_pitch_hook must be code ref'
      unless ref $param{min_pitch_hook} eq 'CODE';
    $self->{_min_pitch_hook} = $param{min_pitch_hook};
  }
  if ( exists $param{max_pitch_hook} ) {
    croak 'max_pitch_hook must be code ref'
      unless ref $param{max_pitch_hook} eq 'CODE';
    $self->{_max_pitch_hook} = $param{max_pitch_hook};
  }

  $self->{_mode} = $param{mode} || 'absolute';
  croak q{'mode' must be 'absolute' or 'relative'}
    if $self->{_mode} ne 'absolute' and $self->{_mode} ne 'relative';

  $self->{_p2n_hook} = $param{p2n_hook}
    || sub { $P2N{ $_[1] }->{ $_[0] % $DEG_IN_SCALE } };
  croak q{'p2n_hook' must be code ref}
    unless ref $self->{_p2n_hook} eq 'CODE';

  $self->{_sticky_state} = $param{sticky_state} // 0;
  $self->{_strip_rests}  = $param{strip_rests}  // 0;

  bless $self, $class;
  return $self;
}

sub notes2pitches {
  my $self = shift;
  my @pitches;

  for my $n ( ref $_[0] eq 'ARRAY' ? @{ $_[0] } : @_ ) {
    # pass through what hopefully are raw pitch numbers, otherwise parse
    # note from subset of the lilypond note format
    if ( !defined $n ) {
      # might instead blow up? or have option to blow up...
      push @pitches, undef unless $self->{_strip_rests};

    } elsif ( $n =~ m/^(-?\d+)$/ ) {
      push @pitches, $n;

    } elsif ( $n =~ m/^(?i)[rs]/ or $n =~ m/\\rest/ ) {
      # rests or lilypond 'silent' bits
      push @pitches, undef unless $self->{_strip_rests};

    } elsif ( $n =~ m/^$LY_NOTE_RE/ ) {
      # "diatonic" (here, the white notes of a piano) are necessary
      # for leap calculations in relative mode, as "cisis" goes down
      # to "aeses" despite the real notes ("d" and "g," in absolute
      # mode) being a fifth apart. Another way to think of it: the
      # diatonic "c" and "a" of "cisis" and "aeses" are within three
      # stave lines of one another; anything involving three or more
      # stave lines is a leap.
      my $real_note     = $1;
      my $diatonic_note = $2;
      my $reg_symbol    = $3 // '';

      croak "unknown lilypond note $n" unless exists $N2P{$real_note};

      my ( $diatonic_pitch, $real_pitch );
      if ( $self->{_mode} ne 'relative' ) {    # absolute
            # TODO see if can do this code regardless of mode, and still
            # sanity check the register for absolute/relative-no-previous,
            # but not for relative-with-previous, to avoid code
            # duplication in abs/r-no-p blocks - or call subs with
            # appropriate register numbers.
        ( $diatonic_pitch, $real_pitch ) =
          map { $N2P{$_} + $self->reg_sym2num($reg_symbol) * $DEG_IN_SCALE }
          $diatonic_note, $real_note;

        # Account for edge cases of ces and bis and the like
        my $delta = $diatonic_pitch - $real_pitch;
        if ( abs($delta) > $TRITONE ) {
          $real_pitch += $delta > 0 ? $DEG_IN_SCALE : -$DEG_IN_SCALE;
        }

      } else {    # relatively more complicated

        if ( !defined $self->{prev_note} ) {    # absolute if nothing prior
          ( $diatonic_pitch, $real_pitch ) =
            map { $N2P{$_} + $self->reg_sym2num($reg_symbol) * $DEG_IN_SCALE }
            $diatonic_note, $real_note;

          # Account for edge cases of ces and bis and the like
          my $delta = $diatonic_pitch - $real_pitch;
          if ( abs($delta) > $TRITONE ) {
            $real_pitch += $delta > 0 ? $DEG_IN_SCALE : -$DEG_IN_SCALE;
          }

        } else {                                # meat of relativity
          my $reg_number = int( $self->{prev_note} / $DEG_IN_SCALE ) * $DEG_IN_SCALE;

          my $reg_delta = $self->{prev_note} % $DEG_IN_SCALE - $N2P{$diatonic_note};
          if ( abs($reg_delta) > $TRITONE ) {
            $reg_number += $reg_delta > 0 ? $DEG_IN_SCALE : -$DEG_IN_SCALE;
          }

          # adjust register by the required relative offset
          my $reg_offset = _symbol2relreg($reg_symbol);
          if ( $reg_offset != 0 ) {
            $reg_number += $reg_offset * $DEG_IN_SCALE;
          }

          ( $diatonic_pitch, $real_pitch ) =
            map { $reg_number + $N2P{$_} } $diatonic_note, $real_note;

          my $delta = $diatonic_pitch - $real_pitch;
          if ( abs($delta) > $TRITONE ) {
            $real_pitch += $delta > 0 ? $DEG_IN_SCALE : -$DEG_IN_SCALE;
          }
        }

        $self->{prev_note} = $diatonic_pitch if $self->{_keep_state};
      }

      push @pitches, $real_pitch;

    } else {
      croak "unknown note '$n'";
    }
  }

  if ( $self->{_ignore_register} ) {
    for my $p (@pitches) {
      $p %= $DEG_IN_SCALE if defined $p;
    }
  }

  undef $self->{prev_note} unless $self->{_sticky_state};

  return @pitches > 1 ? @pitches : $pitches[0];
}

# Converts pitches to lilypond names
sub p2ly {
  my $self = shift;

  my @notes;
  for my $obj ( ref $_[0] eq 'ARRAY' ? @{ $_[0] } : @_ ) {
    my $pitch;
    if ( !defined $obj ) {
      croak "cannot convert undefined value to lilypond element";
    } elsif ( blessed $obj and $obj->can("pitch") ) {
      $pitch = $obj->pitch;
    } elsif ( looks_like_number $obj) {
      $pitch = int $obj;
    } else {
      # pass through on unknowns (could be rests or who knows what)
      push @notes, $obj;
      next;
    }

    # Response handling on range check:
    # * exception - out of bounds, default die() handler tripped
    # * defined return value - got something from a hook function, use that
    # * undefined - pitch is within bounds, continue with code below
    my $range_result;
    try { $range_result = $self->_range_check($pitch) }
    catch {
      croak $_;
    };
    if ( defined $range_result ) {
      push @notes, $range_result;
      next;
    }

    my $note = $self->{_p2n_hook}( $pitch, $self->{_chrome} );
    croak "could not lookup note for pitch '$pitch'" unless defined $note;

    my $register;
    if ( $self->{_mode} ne 'relative' ) {
      $register = $self->reg_num2sym( $pitch / $DEG_IN_SCALE );

    } else {    # relatively more complicated
      my $rel_reg = $REL_DEF_REG;
      if ( defined $self->{prev_pitch} ) {
        my $delta = int( $pitch - $self->{prev_pitch} );
        if ( abs($delta) >= $TRITONE ) {    # leaps need , or ' variously
          if ( $delta % $DEG_IN_SCALE == $TRITONE ) {
            $rel_reg += int( $delta / $DEG_IN_SCALE );

            # Adjust for tricky changing tritone default direction
            my $default_dir =
              $TTDIR{ $self->{_chrome} }->{ $self->{prev_pitch} % $DEG_IN_SCALE };
            if ( $delta > 0 and $default_dir < 0 ) {
              $rel_reg++;
            } elsif ( $delta < 0 and $default_dir > 0 ) {
              $rel_reg--;
            }

          } else {    # not tritone, but leap
                      # TT adjust is to push <1 leaps out so become 1
            $rel_reg +=
              int( ( $delta + ( $delta > 0 ? $TRITONE : -$TRITONE ) ) / $DEG_IN_SCALE );
          }
        }
      }
      $register = $self->reg_num2sym($rel_reg);
      $self->{prev_pitch} = $pitch if $self->{_keep_state};
    }

    # Do not care about register (even in absolute mode) if keeping state
    if ( $self->{_keep_state} ) {
      croak "register out of range for pitch '$pitch'"
        unless defined $register;
    } else {
      $register = '';
    }
    push @notes, $note . $register;
  }

  undef $self->{prev_pitch} unless $self->{_sticky_state};
  return @_ > 1 ? @notes : $notes[0];
}

# Class method, patch number to instrument name utility function
sub patch2instrument {
  my ( $class, $patchnum ) = @_;

  return $PATCH2INSTRUMENT{$patchnum} // '';
}

# MUST NOT accept raw pitch numbers, as who knows if "61" is a "cis"
# or "des" or the like, which will in turn affect the relative
# calculations!
sub prev_note {
  my ( $self, $pitch ) = @_;
  if ( defined $pitch ) {
    if ( $pitch =~ m/^$LY_NOTE_RE/ ) {
      # TODO duplicates (portions of) same code, below
      my $real_note     = $1;
      my $diatonic_note = $2;
      my $reg_symbol    = $3 // '';

      croak "unknown lilypond note $pitch" unless exists $N2P{$real_note};

      # for relative-to-this just need the diatonic
      $self->{prev_note} =
        $N2P{$diatonic_note} + $self->reg_sym2num($reg_symbol) * $DEG_IN_SCALE;

    } else {
      croak "unknown pitch '$pitch'";
    }
  }
  return $self->{prev_note};
}

sub prev_pitch {
  my ( $self, $pitch ) = @_;
  if ( defined $pitch ) {
    if ( blessed $pitch and $pitch->can("pitch") ) {
      $self->{prev_pitch} = $pitch->pitch;
    } elsif ( looks_like_number $pitch) {
      $self->{prev_pitch} = int $pitch;
    } else {
      try { $self->{prev_pitch} = $self->diatonic_pitch($pitch) }
      catch {
        croak $_;
      };
    }
  }
  return $self->{prev_pitch};
}

# Utility, converts arbitrary numbers into lilypond register notation
sub reg_num2sym {
  my ( $self, $number ) = @_;
  croak 'register number must be numeric'
    if !defined $number
    or !looks_like_number $number;

  $number = int $number;
  my $symbol = q{};
  if ( $number < $REL_DEF_REG ) {
    $symbol = q{,} x ( $REL_DEF_REG - $number );
  } elsif ( $number > $REL_DEF_REG ) {
    $symbol = q{'} x ( $number - $REL_DEF_REG );
  }
  return $symbol;
}

# Utility, converts arbitrary ,, or ''' into appropriate register number
sub reg_sym2num {
  my ( $self, $symbol ) = @_;
  croak 'undefined register symbol' unless defined $symbol;
  croak 'invalid register symbol'   unless $symbol =~ m/^(,|')*$/;

  my $dir = $symbol =~ m/[,]/ ? -1 : 1;

  return $REL_DEF_REG + $dir * length $symbol;
}

sub sticky_state {
  my ( $self, $state ) = @_;
  $self->{_sticky_state} = $state if defined $state;
  return $self->{_sticky_state};
}

sub strip_rests {
  my ( $self, $state ) = @_;
  $self->{_strip_rests} = $state if defined $state;
  return $self->{_strip_rests};
}

1;
__END__

=head1 NAME

Music::LilyPondUtil - utility methods for lilypond data

=head1 SYNOPSIS

  use Music::LilyPondUtil ();
  my $lyu   = Music::LilyPondUtil->new;

  my $pitch = $lyu->notes2pitches("c'") # 60
  $lyu->diatonic_pitch("ces'")          # 60

  $lyu->ignore_register(1);
  $lyu->notes2pitches("c'")             # 0
  $lyu->diatonic_pitch("ces'")          # 0


  my $note  = $lyu->p2ly(60)            # c'

  $lyu->mode('relative');
  my @bach  = $lyu->p2ly(qw/60 62 64 65 62 64 60 67 72 71 72 74/)
      # c d e f d e c g' c b c d

  $lyu->keep_state(0);
  $lyu->p2ly(qw/0 1023 79 77 -384/);   # c dis g f c

  $lyu->chrome('flats');
  $lyu->p2ly(qw/2 9 5 2 1 2/);         # d a f d des d

=head1 DESCRIPTION

Utility methods for interacting with lilypond (as of version 2.16), most
notably for the conversion of integers to lilypond note names (or the
other way around, for a subset of the lilypond notation). The Western
12-tone system is assumed.

The note conversions parse the lilypond defaults, including enharmonic
equivalents such as C<bes> or C<ceses> (for C double flat or more simply
B flat) and C<bis> (B sharp or C natural) but not any microtonal C<cih>,
C<beh> nor any other conventions. Lilypond output is restricted to all
sharps or all flats (set via a parameter), and never emits double sharps
nor double flats. Pitch numbers are integers, and might be the MIDI note
numbers, or based around 0, or whatever, depending on the need and the
parameters set.

=head1 CLASS METHODS

The module will throw errors via B<croak> if an abnormal condition is
encountered.

=over 4

=item B<new> I<optional params>

Constructor. Optional parameters include:

=over 4

=item *

B<chrome> to set the accidental style (C<sharps> or C<flats>). Mixing
flats and sharps is not supported. (Under no circumstances are double
sharps or double flats emitted, though the module does know how to
read those.)

=item *

B<ignore_register> a boolean that if set causes the B<diatonic_pitch>
and B<notes2pitches> methods to only return values from 0..11. The
default is to include the register information in the resulting pitch.
Set this option if feeding data to atonal routines, for example those in
L<Music::AtonalUtil>.

=item *

B<keep_state> a boolean, enabled by default, that will maintain state on
the previous pitch in the B<p2ly> call. State is not maintained across
separate calls to B<p2ly> (see also the B<sticky_state> param).

Disabling this option will remove all register notation from both
C<relative> and C<absolute> modes.

=item *

B<min_pitch> integer, by default 0, below which pitches passed to
B<p2ly> will cause the module to by default throw an exception. To
constrain pitches to what an 88-key piano is capable of, set:

  Music::LilyPondUtil->new( min_pitch => 21 );

Too much existing code allows for zero as a minimum pitch to set 21 by
default, or if B<ignore_register> is set, pitches from B<notes2pitches>
are constrained to zero through eleven, and relative lilypond notes can
easily be generated from those...so 0 is the minimum.

=item *

B<min_pitch_hook> code reference to handle minimum pitch cases instead
of the default exception. The hook is passed the pitch, min_pitch,
max_pitch, and the object itself as arguments. The hook must return
C<undef> if the value is to be accepted, or something not defined to use
that instead, or could throw an exception, which will be re-thrown via
C<croak>. One approach would be to silence the out-of-bounds pitches by
returning a lilypond rest symbol:

  Music::LilyPondUtil->new( min_pitch_hook => sub { 'r' } );

One use for this is to generate pitch numbers via some mechanism and
then silence or omit the pitches that fall outside a particular range of
notes via the C<*_pitch_hook> hook functions. See L</"EXAMPLES"> for
sample code.

=item *

B<max_pitch> integer, by default 108 (the highest note on a standard 88-
key piano), above which pitches passed to B<p2ly> will cause the module
to by default throw an exception.

=item *

B<max_pitch_hook> code reference to handle minimum pitch cases instead
of the default exception. The hook is passed the pitch, min_pitch,
max_pitch, and the object itself as arguments. Return values are handled
as for the B<min_pitch_hook>, above.

=item *

B<mode> to set C<absolute> or C<relative> mode. Default is C<absolute>.
Altering this changes how both B<notes2pitches> and B<p2ly> operate.
Create two instances of the object if this is a problem, and set the
appropriate mode for the appropriate routine.

=item *

B<p2n_hook> to set a custom code reference for the pitch to note
conversion (see source for details, untested, use at own risk, blah
blah blah).

=item *

B<sticky_state> a boolean, disabled by default, that if enabled,
will maintain the previous pitch state across separate calls to
B<p2ly>, assuming B<keep_state> is also enabled, and again only in
C<relative> B<mode>.

=item *

B<strip_rests> boolean that informs B<notes2pitches> as to whether rests
should be omitted. By default, rests are returned as undefined values.

(Canon or fugue related calculations, in particular, need the rests, as
otherwise the wrong notes line up with one another in the comparative
lists. An alternative approach would be to convert notes to start
times and durations (among other metadata), and ignore rests, but that
would take more work to implement. It would, however, better suit
larger data sets.)

=back

=item B<patch2instrument> I<patch_number>

Given a MIDI patch number (presumably in the range from 0 to 127,
inclusive), returns the instrument name (or otherwise the empty string).

=back

=head1 METHODS

Call these on an object created via B<new>.

=over 4

=item B<chrome> I<optional sharps or flats>

Get/set accidental style.

=item B<clear_prev_note>

For use with B<notes2pitches>. Wipes out the previous note (the state
variable used with B<sticky_state> enabled in C<relative> B<mode> to
maintain state across multiple calls to B<notes2pitches>.

=item B<clear_prev_pitch>

For use with B<p2ly>. Wipes out the previous pitch (the state variable
used with B<sticky_state> enabled in C<relative> B<mode> to maintain
state across multiple calls to B<p2ly>). Be sure to call this method
after completing any standalone chord or phrase, as otherwise any
subsequent B<p2ly> calls will use the previously cached pitch.

=item B<diatonic_pitch> I<note>

Returns the diatonic (here defined as the white notes on the piano)
pitch number for a given lilypond absolute notation note, for example
C<ceses'>, C<ces'>, C<c'>, C<cis'>, and C<cisis'> all return 60. This
method is influenced by the B<ignore_register>, B<min_pitch>, and
B<max_pitch> parameters.

=item B<ignore_register> I<optional boolean>

Get/set B<ignore_register> param.

=item B<keep_state> I<optional boolean>

Get/set B<keep_state> param.

=item B<mode> I<optional relative or absolute>

Get/set the mode of operation.

=item B<notes2pitches> I<list of note names or pitch numbers>

Converts note names to pitches. Raw pitch numbers (integers) are passed
through as is. Lilypond non-note C<r> or C<s> in any case are converted
to undefined values (likewise for notes adorned with C<\rest>).
Otherwise, lilypond note names (C<c>, C<cis>, etc.) and registers
(C<'>, C<''>, etc.) are converted to a pitch number. The
B<ignore_register> and B<strip_rests> options can influence the output.
Use the B<prev_note> method to set what a C<\relative d'' { ...>
statement in lilypond would do:

  $lyu->prev_note(q{d''});
  $lyu->notes2pitches(qw/d g fis g a g fis e/);

Returns list of pitches (integers), or single pitch as scalar if only a
single pitch was input.

=item B<p2ly> I<list of pitches or whatnot>

Converts a list of pitches (integers or objects that have a B<pitch>
method that returns an integer) to a list of lilypond note names.
Unknown data will be passed through as is. Returns said converted list.
The behavior of this method depends heavily on various parameters that
can be passed to B<new> or called as various methods, notably
the B<prev_pitch> method to set the most recent diatonic pitch.

However, note that B<prev_pitch> will only influence the first note
(probably in a surprising way). Pitches are pitches, and if they need to
be transposed to a particular register, run something like:

  $n += 60 for @list_of_pitches;

on all the pitches. Methods from L<Music::Canon> might be another
option, for example if contrary motion or retrograde must also be
calculated on the pitches to be transposed.

=item B<prev_note> I<optional note>

For use with B<notes2pitches>. Get/set previous note (the state variable
used with B<sticky_state> enabled in C<relative> B<mode> to maintain
state across multiple calls to B<p2ly>). Optionally accepts only a note
(for example, C<ces,> or C<f''>), and always returns the current
previous note (which may be unset), which will be the pitch of the
diatonic of the note provided (e.g. C<ces,> will return the pitch for
C<c,>, and C<fisfis'''> the pitch for C<f'''>).

=item B<prev_pitch> I<optional pitch>

For use with B<p2ly>. Get/set previous pitch (the state variable used
with B<sticky_state> enabled in C<relative> B<mode> to maintain state
across multiple calls to B<p2ly>). Can be a pitch number, or lilypond
note name, though the lilypond note name will be converted to the
nearest diatonic pitch number, and may be influenced by various other
parameters set (notably B<ignore_register>).

=item B<reg_num2sym> I<number>

Utility method, converts an arbitrary number into a lilypond
register symbol, with the empty string being returned for the
default register C<4>.

  $lyu->reg_num2sym(3)        # ,
  $lyu->reg_num2sym(6)        # ''

=item B<reg_sym2num> I<register>

Utility method, converts an arbitrary lilypond register symbol into a
register number. Pass the empty string to obtain the default register.

  $lyu->reg_sym2num( q{,}  )  # 3
  $lyu->reg_sym2num( q{}   )  # 4
  $lyu->reg_sym2num( q{''} )  # 6

=item B<sticky_state> I<optional boolean>

Get/set B<sticky_state> param.

=item B<strip_rests> I<optional boolean>

Get/set B<strip_rests> param.

=back

=head1 EXAMPLES

An idea for composition: generate pitch numbers via some mathematical
function, and omit the notes if they fall outside a particular range.
This method requires the use of a graphing calculator, knowledge of
various mathematical functions, and spare time, though may produce
interesting results, depending on how the function(s) interact with the
playable range. This example strips pitches that exceed the limits:

  use Music::LilyPondUtil ();
  my $lyu = Music::LilyPondUtil->new(
    min_pitch      => 59,
    max_pitch      => 79,
    min_pitch_hook => sub { '' },
    max_pitch_hook => sub { '' },
  );
  
  # generate notes from mathematical function
  my @notes;
  for my $t ( 1 .. 174 ) {
    my $pitch = 50 * cos( $t / 25 ) + 3 * sin( 2 * $t ) + 22;
    push @notes, grep length $_ > 0, $lyu->p2ly($pitch);
  }
  
  # replace repeated notes with rests
  for my $ni ( 1 .. $#notes ) {
    $notes[$ni] = 'r' if $notes[$ni] eq $notes[ $ni - 1 ];
  }
  
  print "@notes\n";

This output could then be piped to the C<ly-fu> utility of
L<App::MusicTools>, for example if saved as C<domath>:

  $ perl domath | ly-fu --open --instrument=drawbar\ organ --absolute -

Which in turn would require C<lilypond>, a PDF viewer, and a MIDI player.

This more complicated example uses the C<reflect_pitch> method of
L<Music::AtonalUtil> to fold out-of-bounds pitches to within the limits:

  use Music::AtonalUtil;
  use Music::LilyPondUtil;

  my $atu = Music::AtonalUtil->new;
  my $lyu = Music::LilyPondUtil->new(
    min_pitch      => 59,
    max_pitch      => 79,
    min_pitch_hook => \&fold,
    max_pitch_hook => \&fold,
  );

  sub fold {
    my ($p, $min, $max, $self) = @_;
    return $self->p2ly( $atu->reflect_pitch( $p, $min, $max ) );
  }

=head1 SEE ALSO

L<http://www.lilypond.org/> and most notably the Learning and
Notation manuals.

My other music related modules, including L<App::MusicTools>,
L<Music::AtonalUtil>, L<Music::Canon>, and L<Music::PitchNum>.

=head1 AUTHOR

thrig - Jeremy Mates (cpan:JMATES) C<< <jmates at cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012-2013,2015 Jeremy Mates

This module is free software; you can redistribute it and/or modify it
under the Artistic License (2.0).

=cut

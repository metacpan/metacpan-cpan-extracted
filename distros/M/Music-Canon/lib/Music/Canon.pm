# -*- Perl -*-
#
# Routines for musical canon construction. See also C<canonical> of the
# L<App::MusicTools> module for a command line tool interface to this
# code, and the eg/ directory of this module's distribution for other
# example scripts.
#
# Run perldoc(1) on this file for additional documentation.

package Music::Canon;

use 5.010000;

use List::Util qw/sum/;
use Moo;
use Music::AtonalUtil ();    # Forte Number to interval sets
use Music::Scales qw/get_scale_nums is_scale/;
use namespace::clean;
use Scalar::Util qw/blessed looks_like_number/;

our $VERSION = '2.04';

# Array indices for ascending versus descending scales (as some minor
# scales are different, depending)
my $ASC = 0;
my $DSC = 1;

my $FORTE_NUMBER_RE;

##############################################################################
#
# ATTRIBUTES

has atonal => (
  is      => 'rw',
  default => sub { Music::AtonalUtil->new },
);

has contrary => (
  is => 'rw',
  cocerce =>
    sub { die "contrary needs boolean\n" if !defined $_[0]; $_[0] ? 1 : 0 },
  default => sub { 1 },
  reader  => 'get_contrary',
  writer  => 'set_contrary',
);

has DEG_IN_SCALE => (
  is     => 'rw',
  coerce => sub {
    die "scale degrees must be integer greater than 1"
      if !defined $_[0]
      or !looks_like_number $_[0]
      or $_[0] < 2;
    int $_[0];
  },
  default => sub {
    12;
  },
);

has modal_chrome => (
  is     => 'rw',
  coerce => sub {
    die "modal_chrome needs troolean (-1,0,1)\n" if !defined $_[0];
    $_[0] <=> 0;
  },
  default => sub {
    0;
  },
  reader => 'get_modal_chrome',
  writer => 'set_modal_chrome',
);

has modal_hook => (
  is      => 'rw',
  default => sub {
    sub { undef }
  },
  isa => sub {
    ref $_[0] eq 'CODE';
  },
);

# input tonic pitch for modal_map
has modal_in => (
  is        => 'rw',
  clearer   => 1,
  predicate => 1,
);

# output tonic pitch for modal_map
has modal_out => (
  is        => 'rw',
  clearer   => 1,
  predicate => 1,
);

# These have custom setters as support Forte Numbers and other such
# cases difficult to put into a simple coerce sub, so the user-facing
# setter are really the set_modal_scale_* subs.
has modal_scale_in => (
  is        => 'rw',
  clearer   => 1,
  predicate => 1,
);
has modal_scale_out => (
  is        => 'rw',
  clearer   => 1,
  predicate => 1,
);

has non_octave_scales => (
  is      => 'rw',
  cocerce => sub {
    die "non_octave_scales needs boolean\n" if !defined $_[0];
    $_[0] ? 1 : 0;
  },
  default => sub {
    0;
  },
);

has retrograde => (
  is => 'rw',
  cocerce =>
    sub { die "retrograde needs boolean\n" if !defined $_[0]; $_[0] ? 1 : 0 },
  default => sub { 1 },
  reader  => 'get_retrograde',
  writer  => 'set_retrograde',
);

has transpose => (
  is      => 'rw',
  default => sub { 0 },
  reader  => 'get_transpose',
  writer  => 'set_transpose',
);

##############################################################################
#
# METHODS

sub BUILD {
  my ( $self, $param ) = @_;
  with( exists $param->{pitchstyle} ? $param->{pitchstyle} : 'Music::PitchNum' );

  # as not expected to change much, if at all
  $FORTE_NUMBER_RE = $self->atonal->forte_number_re;

  # Major scale by default
  $self->modal_scale_in( [ [qw(2 2 1 2 2 2 1)], [qw(2 2 1 2 2 2 1)] ] )
    if !$self->has_modal_scale_in;
  $self->modal_scale_out( [ [qw(2 2 1 2 2 2 1)], [qw(2 2 1 2 2 2 1)] ] )
    if !$self->has_modal_scale_out;
}

# One-to-one interval mapping, though with the contrary, retrograde, and
# transpose parameters as possible influences on the results.
sub exact_map {
  my $self = shift;

  my ( @new_phrase, $prev_in, $prev_out );

  for my $e ( ref $_[0] eq 'ARRAY' ? @{ $_[0] } : @_ ) {
    my $pitch;
    if ( !defined $e ) {
      # presumably rests/silent bits
      push @new_phrase, undef;
      next;
    } elsif ( blessed $e and $e->can('pitch') ) {
      $pitch = $e->pitch;
    } elsif ( looks_like_number $e) {
      $pitch = $e;
    } else {
      # pass through unknowns
      push @new_phrase, $e;
      next;
    }

    my $new_pitch;
    if ( !defined $prev_out ) {
      my $trans = $self->get_transpose;
      if ( !looks_like_number($trans) ) {
        my $transpose_to = $self->pitchnum($trans)
          // die "pitchnum failed to parse '$trans'\n";
        $trans = $transpose_to - $pitch;
      }
      $new_pitch = $pitch + $trans;
    } else {
      my $delta = $pitch - $prev_in;
      $delta *= -1 if $self->get_contrary;
      $new_pitch = $prev_out + $delta;
    }
    push @new_phrase, $new_pitch;
    $prev_in  = $pitch;
    $prev_out = $new_pitch;
  }
  @new_phrase = reverse @new_phrase if $self->get_retrograde;

  return @new_phrase;
}

# mostly for compatibility with older versions of this module
sub get_modal_pitches {
  my ($self) = @_;
  return $self->modal_in, $self->modal_out;
}

sub get_modal_scale_in {
  return @{ $_[0]->modal_scale_in };
}

sub get_modal_scale_out {
  return @{ $_[0]->modal_scale_out };
}

# Modal interval mapping - determines the number of diatonic steps and
# chromatic offset (if any) from the direction and magnitude of the
# delta from the previous input pitch via the input scale intervals,
# then replays that number of diatonic steps and (if possible) chromatic
# offset via the output scale intervals. Ascending vs. descending motion
# may be handled by different scale intervals, if a melodic minor or
# similar asymmetric interval set is involved. If this sounds tricky and
# complicated, it is because it is.
sub modal_map {
  my $self = shift;

  my ( $input_tonic, $output_tonic );
  if ( $self->has_modal_in ) {
    $input_tonic = $self->pitchnum( $self->modal_in )
      // die "pitchnum could not convert modal_in '", $self->modal_in,
      "' to a pitch number\n";
  }
  if ( $self->has_modal_out ) {
    $output_tonic = $self->pitchnum( $self->modal_out )
      // die "pitchnum could not convert modal_out '", $self->modal_out,
      "' to a pitch number\n";
  }

  my $input_mode = $self->modal_scale_in;
  # local copy of the output scale in the event transposition forces a
  # rotation of the intervals
  my $output_mode = $self->modal_scale_out;

  # but have to wait until have the first pitch as might be transposing
  # to a note instead of by some number
  my $trans;
  my $rotate_by     = 0;
  my $rotate_chrome = 0;

  my ( @new_phrase, $prev_in, $prev_out );
  my $phrase_index = 0;
  for my $obj ( ref $_[0] eq 'ARRAY' ? @{ $_[0] } : @_ ) {
    my $pitch;
    if ( !defined $obj ) {
      # presumably rests/silent bits
      push @new_phrase, undef;
      next;
    } elsif ( blessed $obj and $obj->can('pitch') ) {
      $pitch = $obj->pitch;
    } elsif ( looks_like_number $obj) {
      $pitch = $obj;
    } else {
      # pass through unknowns
      push @new_phrase, $obj;
      next;
    }

    my $new_pitch;
    if ( defined $prev_in and $pitch == $prev_in ) {
      # oblique motion optimization (a repeated note): just copy previous
      $new_pitch = $prev_out;

    } else {
      # Interval sets are useless without being tied to some pitch,
      # assume this is the first note of the phrase if not already set.
      $input_tonic = $pitch unless defined $input_tonic;

      # NOTE output tonic is not longer set based on transposed pitch
      # (as of v1.00); use set_modal_pitches() to specify as necessary.
      # This change motivated by transpose not really working
      # everywhere. Instead, output tonic by default is the same as the
      # input tonic (so the input and output modes share the same root
      # pitch by default).
      $output_tonic = $input_tonic unless defined $output_tonic;

      if ( !defined $trans ) {
        $trans = $self->get_transpose;
        if ( !looks_like_number($trans) ) {
          # Letter note: "transpose to 'A'" instead of "transpose by N"
          my $transpose_to = $self->pitchnum($trans)
            // die 'pitchnum failed to parse ' . $self->transpose . "\n";
          $trans = $transpose_to - $pitch;
        }

        if ( $trans != 0 ) {
          # Steps must be from input tonic to first note of phrase plus
          # transposition, as if in Bflat-Major if one has a phrase that
          # begins on "D" being moved to "Eflat" that transposition is
          # modal, and not chromatic.
          ( $rotate_by, $rotate_chrome ) =
            ( $self->steps( $input_tonic, $input_tonic + $trans, $input_mode->[$ASC] ) )
            [ 0, 1 ];
          # inverted due to how M::AU->rotate works
          $rotate_by *= -1;

          if ( $rotate_chrome != 0 ) {
            die "transpose to chromatic pitch unsupported by modal_map()";
          }

          # Transpositions require rotation of the output mode to match
          # where the starting pitch of the phrase lies in the output
          # mode, as otherwise for c-minor to c-minor, transposing from
          # C to E-flat, would for an input phrase of C->Bb->Ab get the
          # C->Bb->Ab intervals instead of those for Eb->D->C. That is,
          # the output would become E-flat minor by virtue of the
          # transposition without the rotation done here.
          if ( $rotate_by != 0 ) {
            $output_mode->[$ASC] =
              $self->atonal->rotate( $rotate_by, $output_mode->[$ASC] );
            $output_mode->[$DSC] =
              $self->atonal->rotate( $rotate_by, $output_mode->[$DSC] );
          }
        }
      }

      # Determine whether input must be figured on the ascending or
      # descending scale intervals; descending intervals only if there
      # is a previous pitch and if the delta from that previous pitch
      # shows descending motion, otherwise ascending. The scales are
      # [[asc],[dsc]] AoA.
      my $input_motion = $ASC;
      $input_motion = $DSC if defined $prev_in and $pitch - $prev_in < 0;
      my $output_motion = $self->get_contrary ? !$input_motion : $input_motion;

      # Magnitude of interval from tonic, and whether above or below the
      # tonic (as if below, must walk scale intervals backwards).
      my ( $steps, $chromatic_offset, $is_dsc, $last_input_interval ) =
        $self->steps( $input_tonic, $pitch, $input_mode->[$input_motion] );

      # Contrary motion means not only the opposite scale intervals,
      # but the opposite direction through those intervals (in
      # melodic minor, ascending motion in ascending intervals (C to
      # Eflat) corresponds to descending motion in descending
      # intervals (C to Aflat).
      $is_dsc = !$is_dsc if $self->get_contrary;

      my $output_interval = 0;

      # Replay the same number of diatonic steps using the appropriate
      # output intervals and direction of interval iteration, plus
      # chromatic adjustments, if any.
      my $idx;
      if ($steps) {
        $steps--;
        for my $s ( 0 .. $steps ) {
          $idx = $s % @{ $output_mode->[$output_motion] };
          $idx = $#{ $output_mode->[$output_motion] } - $idx if $is_dsc;
          $output_interval += $output_mode->[$output_motion][$idx];
        }
      }

      my $hooked = 0;
      if ( $chromatic_offset != 0 ) {
        my $step_interval = $output_mode->[$output_motion][$idx];
        my $step_dir = $step_interval < 0 ? -1 : 1;
        $step_interval = abs $step_interval;

        if ( $chromatic_offset >= $step_interval ) {
          # Whoops, chromatic does not fit into output scale. Punt to hook
          # function to handle everything for this pitch.
          $new_pitch = $self->modal_hook->(
            $output_interval,
            chromatic_offset => $chromatic_offset,
            phrase_index     => $phrase_index,
            scale            => $output_mode->[$output_motion],
            scale_index      => $idx,
            step_dir         => $step_dir,
            step_interval    => $step_interval,
          );
          $hooked = 1;
        } else {
          if ( $step_interval == 2 ) {
            # only one possible chromatic fits
            $output_interval -= $step_dir * $chromatic_offset;
          } else {
            # modal_chrome is a troolean - either a literal chromatic
            # going up or down if positive or negative, otherwise if 0
            # try to figure out something proportional to where the
            # chromatic was between the diatonics of the input scale.
            if ( $self->get_modal_chrome > 0 ) {
              $output_interval -= $step_dir * $chromatic_offset;
            } elsif ( $self->get_modal_chrome < 0 ) {
              $output_interval += $step_dir * ( $chromatic_offset - $step_interval );
            } else {
              my $fraction = sprintf "%.0f",
                $step_interval * $chromatic_offset / $last_input_interval;
              $output_interval += $step_dir * ( $fraction - $step_interval );
            }
          }
        }
      }

      if ( !$hooked ) {
        $output_interval = int( $output_interval * -1 ) if $is_dsc;
        $new_pitch = $output_tonic + $trans + $output_interval;
      }
    }

    push @new_phrase, $new_pitch;
    $prev_in  = $pitch;
    $prev_out = $new_pitch;

    $phrase_index++;
  }
  @new_phrase = reverse @new_phrase if $self->get_retrograde;

  return @new_phrase;
}

sub reset_modal_pitches {
  $_[0]->clear_modal_in;
  $_[0]->clear_modal_out;
}

# Mostly for compatibility with how older versions of this module
# worked, and handy to do these in a single call.
sub set_modal_pitches {
  my ( $self, $input_pitch, $output_pitch ) = @_;

  my $pitch;
  if ( defined $input_pitch ) {
    $pitch = $self->pitchnum($input_pitch)
      // die "pitchnum failed to parse $input_pitch\n";
    $self->modal_in($pitch);
    # Auto-reset output if something prior there so not carrying along
    # something from a previous conversion, as the default is to use the
    # same pitch for the output tonic as from the input.
    if ( !defined $output_pitch and $self->has_modal_out ) {
      $self->clear_modal_out;
    }
  }
  if ( defined $output_pitch ) {
    $pitch = $self->pitchnum($output_pitch)
      // die "pitchnum failed to parse $output_pitch\n";
    $self->modal_out($pitch);
  }
}

sub set_modal_scale_in {
  my $self = shift;
  $self->modal_scale_in( $self->scales2intervals(@_) );
}

sub set_modal_scale_out {
  my $self = shift;
  $self->modal_scale_out( $self->scales2intervals(@_) );
}

sub scales2intervals {
  my ( $self, $asc, $dsc ) = @_;
  if ( !defined $asc and !defined $dsc ) {
    die "must define one of asc or dsc or both";
  }

  my @intervals;
  my $is_scale = 0;
  if ( defined $asc ) {
    if ( ref $asc eq 'ARRAY' ) {
      # Assume arbitrary list of intervals as integers if array ref
      for my $n (@$asc) {
        die "ascending intervals must be positive integers"
          unless looks_like_number $n and $n =~ m/^[+]?[0-9]+$/;
      }
      $intervals[$ASC] = [@$asc];

    } elsif ( $asc =~ m/($FORTE_NUMBER_RE)/ ) {
      # derive scale intervals from pitches of the named Forte Number
      my $pset = $self->atonal->forte2pcs($1);
      die "no Forte Number parsed from ascending '$asc'" unless defined $pset;
      $intervals[$ASC] = $self->atonal->pcs2intervals($pset);

    } else {
      die "ascending scale '$asc' unknown to Music::Scales"
        unless is_scale($asc);
      my @asc_nums = get_scale_nums($asc);
      my @dsc_nums;
      @dsc_nums = get_scale_nums( $asc, 1 ) unless defined $dsc;

      $intervals[$ASC] = [];
      for my $i ( 1 .. $#asc_nums ) {
        push @{ $intervals[$ASC] }, $asc_nums[$i] - $asc_nums[ $i - 1 ];
      }
      if (@dsc_nums) {
        $intervals[$DSC] = [];
        for my $i ( 1 .. $#dsc_nums ) {
          unshift @{ $intervals[$DSC] }, $dsc_nums[ $i - 1 ] - $dsc_nums[$i];
        }
      }
      $is_scale = 1;
    }
  }

  if ( !defined $dsc ) {
    # Assume descending equals ascending (true in most cases, except
    # melodic minor and similar), unless a scale was involved, as the
    # Music::Scales code should already have setup the descending bit.
    $intervals[$DSC] = $intervals[$ASC] unless $is_scale;
  } else {
    if ( ref $dsc eq 'ARRAY' ) {
      for my $n (@$dsc) {
        die "descending intervals must be positive integers"
          unless looks_like_number $n and $n =~ m/^[+]?[0-9]+$/;
      }
      $intervals[$DSC] = [@$dsc];

    } elsif ( $dsc =~ m/($FORTE_NUMBER_RE)/ ) {
      # derive scale intervals from pitches of the named Forte Number
      my $pset = $self->atonal->forte2pcs($1);
      die "no Forte Number parsed from descending '$dsc'" unless defined $pset;
      $intervals[$DSC] = $self->atonal->pcs2intervals($pset);

    } else {
      die "descending scale '$dsc' unknown to Music::Scales"
        unless is_scale($dsc);
      my @dsc_nums = get_scale_nums( $dsc, 1 );

      $intervals[$DSC] = [];
      for my $i ( 1 .. $#dsc_nums ) {
        unshift @{ $intervals[$DSC] }, $dsc_nums[ $i - 1 ] - $dsc_nums[$i];
      }
    }
  }

  # Complete scales to sum to 12 by default (Music::Scales omits the VII
  # to I interval, and who knows what a custom list would contain).
  if ( !$self->non_octave_scales ) {
    for my $ref (@intervals) {
      my $sum = sum(@$ref) // 0;
      die "empty interval set\n" if $sum == 0;
      if ( $sum < $self->DEG_IN_SCALE ) {
        push @$ref, $self->DEG_IN_SCALE - $sum;
      } elsif ( $sum > $self->DEG_IN_SCALE ) {
        die "non-octave scales require non_octave_scales param";
      }
    }
  }

  return \@intervals;
}

sub steps {
  my ( $self, $from, $to, $scale ) = @_;

  die "from pitch must be a number\n" if !looks_like_number $from;
  die "to pitch must be a number\n"   if !looks_like_number $to;
  die "scales must be reference to two array ref of intervals\n"
    if !defined $scale
    or ref $scale ne 'ARRAY';

  my $delta = $to - $from;
  my $dir = $delta < 0 ? $DSC : $ASC;
  $delta = abs $delta;

  my $running_total = 0;
  my $steps         = 0;
  my $index         = 0;
  while ( $running_total < $delta ) {
    $index = $steps++ % @$scale;
    $index = $#{$scale} - $index if $dir == $DSC;
    $running_total += $scale->[$index];
  }

  return $steps, $running_total - $delta, $dir, $scale->[$index];
}

1;
__END__

##############################################################################
#
# DOCS

=head1 NAME

Music::Canon - routines for musical canon construction

=head1 SYNOPSIS

  use Music::Canon ();
  my $mc = Music::Canon->new;

  # options affecting all the *_map routines
  # NOTE that contrary motion and retrograde are enabled by default
  $mc->set_contrary(0);
  $mc->set_retrograde(0);
  $mc->set_transpose(12);     # by semitones (from tonic)
  $mc->set_transpose(q{c'});  # or "to" a note

  # 1:1 semitone mapping
  my @new_phrase = $mc->exact_map(qw/0 7 4 0 -1 0 .../);

  # modal mapping; the default is Major to Major
  @new_phrase = $mc->modal_map(qw/0 7 4 0 -1 0 .../);

  # or instead modal mapping by scale name (via Music::Scales)
  $mc->set_modal_scale_in(  'minor'  );
  $mc->set_modal_scale_out( 'dorian' );
  @new_phrase = $mc->modal_map(qw/0 7 4 0 -1 0 .../);

  # modal_map will require custom tonics if the phrase does not
  # begin on the tonic of the scale
  $mc->set_modal_pitches(60, 60);
  @new_phrase = $mc->modal_map(qw/64 64 65 67 67 .../);

See also C<canonical> of the L<App::MusicTools> module for a command
line tool interface to this module, and the C<eg/> and C<t/> directories
of this distribution for additional example code.

=head1 DESCRIPTION

Musical canons involve horizontal lines of music (often called voices)
that are combined with other canonic or free counterpoint voices to
produce harmony. This module assists with the creation of new voices via
C<*_map> methods that transform pitches according to various rules.
Chords could also be transformed via the C<*_map> functions by passing
the pitches of the chord to the C<*_map> method, then forming a new
chord from the results.

Whether the output is usable is left to the composer. Harmony can be
created by careful selection of the input material and the mapping
settings, or perhaps by adding a free counterpoint voice to support the
canon voices. Analyzing the results with L<Music::Tension> may help
locate suitable material.

The methods of this module at present suit the crab canon, as those
lines are relatively easy to calculate. Other forms of canon would
ideally require a counterpoint module, which has not yet been written.
The B<modal_map> method also assists with the calculation of new voices
of a fugue, for example converting the subject to the dominant.

Several routines take human-readable note names (B<set_transpose>,
B<modal_in>, B<modal_out>, B<set_modal_pitches>) as provided by
L<Music::PitchNum>. Most methods in this module otherwise expect raw
pitch numbers (integers).

Output from the C<*_map> functions for a fixed set of parameters and
input pitches is extremely suitable to memoization. The conversion of a
range of input pitches could be built into a hash table, or assuming non-
negative pitch numbers, an array.

=head1 CONSTRUCTOR

The B<new> method accepts any of the L</"ATTRIBUTES"> as well as
optionally a B<pitchstyle> parameter to set where the B<pitchnum>
method (to convert note names to note numbers, e.g. for transposition)
comes from:

  my $mc = Music::Canon->new(
    pitchstyle => 'Music::PitchNum::German',
  );

The default for B<pitchstyle> is L<Music::PitchNum>, which supports a
variety of note name formats. Note names are used by some but not all of
the attributes of this module.

=head1 ATTRIBUTES

=over 4

=item B<atonal>(I<Music::AtonalUtil object>)

Gets or sets the custom L<Music::AtonalUtil> object used internally by
this module for various purposes. By default, this is a
L<Music::AtonalUtil> object.

=item B<contrary> (B<get_contrary>, B<set_contrary>(I<truthiness>))

Gets or sets the B<contrary> setting, that is, whether or not the
resulting canonic line moves in the same or opposite direction as the
original phrase. Enabled by default.

=item B<DEG_IN_SCALE>

Number of degrees in the scale, C<12> by default. Probably should not be
changed, as changing it is probably untested.

=item B<modal_chrome> (B<get_modal_chrome>, B<set_modal_chrome>(I<troolean>))

Method by which to handle chromatics under B<modal_map>, most notably
when there are relatively few notes in the scale, so many possible non-
scale notes a chromatic could be. The default, C<0>, tries to place the
chromatic evenly between the two given notes; C<-1> flattens the input
pitch under consideration, and C<1> sharpens the input pitch.

This method is explained in more detail under the B<modal_map> method
documentation, below.

=item B<modal_hook>

Gets or sets the code reference that handles pitches that are impossible
to convert into the output scale. By default, this is a code reference
that returns C<undef>, though could be adjusted to return, say, C<s> for
lilypond "silents":

  $mc->modal_hook( sub { 's' } );

With a custom hook, the writer of that subroutine must perform the full
pitch calculation, if necessary, and whatever the routine returns will
be used as the new pitch in the output phrase. Consult the source to see
what arguments the hook is passed to produce a suitable pitch number
instead of a string value.

=item B<modal_in> I<pitch> - (B<clear_modal_in>, B<has_modal_in>)

Optional input tonic for B<modal_map>; if unset (which is the default)
then B<modal_map> will use the first note of the phrase as the tonic.
This will not suit phrases that do not begin on the tonic of the scale.
The value may either be a pitch number, or a note name in absolute
format, e.g. C<c> for 48, or C<C4> for 60, etc. See L<Music::PitchNum>
for details.

The B<clear_modal_in> and B<has_modal_in> methods can be used to clear
or check whether this attribute is set.

=item B<modal_out> I<pitch> - (B<clear_modal_out>, B<has_modal_out>)

Optional output tonic for B<modal_map>, unset by default. Necessary
as for B<modal_in> if the output phrase will not begin on the tonic.
This value may either be a pitch number, or a note name in absolute
format, e.g. C<c> for 48, or C<C4> for 60, etc. See
L<Music::PitchNum> for details.

=item B<modal_scale_in> (B<clear_modal_scale_in>, B<has_modal_scale_in>)

Input scale for B<modal_map>, the Major scale by default. Should be
changed ideally by the B<set_modal_scale_in> method, which runs the
input through the B<scales2intervals> method.

=item B<modal_scale_out> (B<clear_modal_scale_out>, B<has_modal_scale_out>)

Output scale for B<modal_map>, the Major scale by default. Should be
changed ideally by the B<set_modal_scale_out> method, which runs the
input through the B<scales2intervals> method.

=item B<non_octave_scales>

Boolean, disabled by default. If enabled will allow for B<modal_map>
scales that do not sum up to the B<DEG_IN_SCALE> value (12). By default,
scales are implicitly modified to sum up to B<DEG_IN_SCALE> (due to
L<Music::Scales> omitting the C<VII> to C<I> interval) or an error is
thrown if the interval sum exceeds B<DEG_IN_SCALE>.

=item B<retrograde> (B<get_retrograde>, B<set_retrograde>(I<truthiness>))

Boolean. Gets or sets the B<retrograde> setting. This is enabled by
default, and is a fancy way of saying that the order of the input notes
will be reversed.

=item B<transpose> (B<get_transpose>, B<set_transpose>(I<note-or-number>))

Gets or sets the B<transpose> value, C<0> by default, used by both the
B<exact_map> and B<modal_map> methods to offset the output phrase by.
The value can either be an integer, in which case the transposition will
be by that number of semitones, or a note name, in which case the
transposition will be made from the starting pitch number of the phrase
to the pitch number of that note name. Note names use absolute notation,
so something like C<c> is actually C<C3> or MIDI number C<48>.

The transposition is calculated from the tonic of the input phrase; that
is, in Bflat Major, the tonic of C<bes> (C<70>) plus a transposition of
C<2> would be from C<bes> to C<c>, regardless of what degree of the
scale the phrase begins on.

=back

=head1 METHODS

=over 4

=item B<exact_map> I<phrase of notes or whatnot as list or array ref>

One-to-one semitone mapping from the input I<phrase> to the returned
list. I<phrase> may be a list or an array reference, and may contain raw
pitch numbers (integers), objects that support a B<pitch> method, or
other data that will be passed through unchanged.

This method is affected by various L</"ATTRIBUTES">, notably
B<set_contrary>, B<set_retrograde>, and B<set_transpose>.

=item B<get_modal_pitches>

Returns the current modal input and output starting pitches used by
B<modal_map>. These will be undefined if unset. Mostly present for
compatibility with older versions of this module; the values it returns
may also be accessed via the B<modal_in> and B<modal_out> attributes.

=item B<get_modal_scale_in>

Returns a list of two array references from the B<modal_scale_in>
attribute that are the ascending and descending scale intervals used by
B<modal_map> for the input phrase. The Major scale is used by default.

=item B<get_modal_scale_out>

Returns a list of two array references from the B<modal_scale_out>
attribute that are the ascending and descending scale intervals used by
B<modal_map> for the output phrase. The Major scale is used by default.

=item B<modal_map> I<phrase of notes or whatnot as list or array ref>

Modal mapping of the pitches in I<phrase> from an arbitrary input mode
to an arbitrary output mode, using the Major scale by default. Returns a
list that is the new phrase, though bear in mind that elements that
cannot be converted will be replaced with C<undef> by default. I<phrase>
may be a list or an array reference, and may contain raw pitch numbers
(integers), objects that support a B<pitch> method, or other data that
will be passed through unchanged.

B<modal_map> will die if a transposition to a chromatic note is
attempted. Use an C<eval> block or otherwise catch the exception if this
is a problem.

Setting the starting pitches via B<modal_in> and B<modal_out> is a
necessity if the I<phrase> starts on a scale degree that is not the root
or tonic of the mode involved. That is, a I<phrase> that begins on the
note E4 (MIDI 64) will create a mapping around E-major by default; if a
mapping around C-Major (at MIDI pitch 60) is intended, this must be set
in advance:

  # equivalent means
  $mc->modal_in(60); $mc->modal_out(60);
  # of doing the same thing
  $mc->set_modal_pitches(60, 60);

  $mc->modal_map(qw/64 .../);

Note that B<modal_map> is somewhat complicated, so likely has edge cases
and bugs. Consult the tests under the module distribution C<t/>
directory for what cases are covered. It is also relatively unexplored,
for example mapping between exotic scales or Forte Numbers.

The algorithm calculates the scale steps (plus any chromatic offset)
from the input tonic to the notes of the phrase, then replicates those
steps (and chromatic offsets, if possible) in the output mode. The
initial starting pitches (derived from the input phrase or the pitches
set via the B<set_modal_pitches> method, along with the the B<transpose>
attribute) form the point of linkage between the two scales (or really
any arbitrary set of intervals).

An example may help illustrate the operation. Assuming Major to Major
conversion, contrary motion, and a transposition by an octave (12
semitones), the algorithm will convert pitches as shown in the chart
below. The "linking point" is from 0 in the input scale to 12 in the
output scale.

        0    1    2   3    4   5   6    7   8    9   10  11  12
  In  | C  | c# | D | d# | E | F | f# | G | g# | A | a# | B | C' |
  Out | C' | x  | B | a# | A | G | f# | F | x  | E | d# | D | C  |
       12        11   10   9   7   6    5        4   3    2   0

Assuming an input phrase of C<C G c#>, the output phrase would be C<C' F
undef> by default, as there is no way to convert C<c#> using these map
and transposition settings. Other settings will have zero to several
notes that cannot be converted. The C<eg/conversion-charts> file of this
module's distribution contains more such charts, as also can be
generated by the C<eg/brutecanon> utility.

How to map non-scale notes is another concern; the above chart shows two
C<x> for notes that cannot be converted. Depending on the mapping, there
might be zero, one, or several possible choices for a given chromatic.
Consider C<c#> of C Major to various entry points of the sakura scale
C<G# A# B D# E>:

    C Major    | C  | c# | D  | 
  ------------------------------------------------------------
  Sakura @ G#  | G# | a  | A# |  - one choice
  Sakura @ A#  | A# | x  | B  |  - throw exception
  Sakura @ B   | B  | ?  | D# |  - (c, c#, d)

The I<modal_chrome> attribute controls the multiple choice situation.
The default setting of C<0> results in C<c#>, as that value is halfway
between C<B> and C<D>, just as the input scale chromatic is halfway
between C<C> and C<D>. Otherwise, with a negative I<modal_chrome>, C<c>
is favored, or for a positive I<modal_chrome>, C<d>. Test cases are
advised to confirm that the resulting chromatics are appropriate, though
this should only be necessary if the output scale has intervals greater
than two--hungarian minor, any of the pentatonic scales, and so forth.

B<modal_map> is affected by various attributes including
B<set_contrary>, B<set_modal_pitches> (or B<modal_in> or B<modal_out>),
B<set_retrograde>, B<set_modal_scale_in>, B<set_modal_scale_out>, and
B<set_transpose>.

A call to B<reset_modal_pitches> may be necessary to clear any custom
B<modal_in> or B<modal_out> pitches, if different tonics for different
phrases are being run through B<modal_map> in a single process. Or,
instead, always set the desired tonics with a B<set_modal_pitches>
before calling B<modal_map>.

=item B<reset_modal_pitches>

Routine to nullify the B<modal_map> pitches that are either set by the
first note of the input phrase, or via the B<set_modal_pitches> method.
These values otherwise persist across calls to B<modal_map>.

=item B<set_modal_pitches> I<input_tonic>, [ I<output_tonic> ]

Sets the tonic note or pitch of the input and output interval sets used
by B<modal_map>. Really just updates the B<modal_in> or B<modal_out>
attributes in a single call. If the I<input_tonic> is C<undef>, then
only the I<output_tonic> will be changed, assuming that is set.

Setting these values is a necessity if the I<phrase> given to
B<modal_map> begins on a non-tonic scale degree, as otherwise that non-
tonic scale degree will become the tonic for whatever interval set is
involved. That is, if the notes C<64 64 65 67 67> are passed to
B<modal_map>, by default B<modal_map> will assume C<E> Major (MIDI note
64) as the input scale, and C<E> Major as the output scale (though that
may vary depending on the B<transpose> attribute as well).

The values may either be a pitch number, or a note name in absolute
format, e.g. C<c> for 48, or C<C4> for 60, etc. See L<Music::PitchNum>
for details.

=item B<set_modal_scale_in>(I<asc>, [I<dsc>])

Sets the scale intervals for the input scale used by B<modal_map>.
The I<asc> or optional I<dsc> arguments can be one of several
different things:

  $mc->set_modal_scale_in('minor');  # Music::Scales
  $mc->set_modal_scale_in('7-23');   # Forte Number
  # arbitrary interval sequence
  $mc->set_modal_scale_in([qw/2 1 3 2 1 3 1/]);

If the I<dsc> is undefined, the corresponding I<asc> intervals will be
used, except for anything that calls L<Music::Scales>, for which the
descending intervals associated with the ascending scale will be used.
If I<asc> is undefined, I<dsc> must then be set to something. This
allows the descending intervals alone to be adjusted.

  $mc->set_modal_scale_in(undef, 'aeolian');

=item B<set_modal_scale_out>(I<asc>, [I<dsc>])

As for B<set_modal_scale_in> only for the output scale used by
B<modal_map>.

=item B<scales2intervals>(I<asc>, [I<dsc>])

Scale-to-interval utility method, mostly for the attributes
B<modal_scale_in> and B<modal_scale_out> to accept Forte Numbers (a
string such as C<7-23>) or L<Music::Scales> scales or a raw interval set
(an array reference of intervals).

=item B<steps> I<pitch_from>, I<pitch_to>, I<scale_intervals>

A mostly internal routine used in particular by B<modal_map> that given
a starting pitch and a destination pitch, along with the intervals for a
scale (such as returned by the B<modal_scale_*> attributes), returns the
number of scale steps between the two pitches, any possible chromatic
offset (in semitones, 0 by default), the direction of the motion, and
the last interval from the scale (this detail is handy for chromatic
conversions).

=back

=head1 MELODIC INVERSION

John W. Verrall in "Fugue and Invention in Theory and Practice"
discusses various inversions, detailed for reference here. The most
effective notes (pitch degrees) for tonal melodic inversions are:

            c d e f g a b c'
  Original  1 2 3 4 5 6 7 8
  Inversion 5 4 3 2 1 7 6 5
            g f e d c b a g

Symmetric inversions (for perhaps B<exact_map>) vary by the key;
for major:

  Original  1 2 3 4 5 6 7 8
  Inversion 3 2 1 7 6 5 4 3

With only a subset of the major scale, another possible mapping is:

  Original  1 2 3 4 5 6
  Inversion 6 5 4 3 2 1

Chromatics raised in the original should be lowered in the inversion,
etc. In minor mode, a potential mapping might be:

  Original  5 6 7 1 2 3 4 5
  Inversion 5 4 3 2 1 7 6 5

These were taken from chapter 9 of the aforementioned book (p. 85-7).
Implementation is another matter, as there is no way for B<modal_map> to
perform the first of these mappings (unless I missed something in the
attempted brute-force fit). The easiest solution with the present
software would likely be to have two C<Music::Canon> objects, and pass
pitches to one or the other depending on whether the pitch is in the c-g
range, and to the other for g-b.

=head1 BUGS

=head2 Reporting Bugs

Please report any bugs or feature requests to
C<bug-music-canon at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Music-Canon>.

Patches might best be applied towards:

L<https://github.com/thrig/Music-Canon>

=head2 Known Issues

B<modal_map> cannot transpose to a chromatic pitch (it will C<die> if
such is attempted). This method is otherwise complex, so may have other
unknown bugs.

Actual composition often requires arbitrary adjustment of canonic or
other imitative forms, usually to make the harmony more convincing. Such
adjustments are outside the scope of this module.

=head1 SEE ALSO

"Fugue and Invention in Theory and Practice" by John W. Verrall

"The Technique of Canon" by Hugo Norden

The C<canonical> and C<scalemogrifier> utilities of L<App::MusicTools>
may also be of interest.

=head1 AUTHOR

thrig - Jeremy Mates (cpan:JMATES) C<< <jmates at cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013-2016 by Jeremy Mates

This module is free software; you can redistribute it and/or modify it
under the Artistic License (2.0).

=cut

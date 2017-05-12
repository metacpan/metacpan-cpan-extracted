package Music::Gestalt;

use warnings;
use strict;
use fields
  qw (automation density duration notes note_length pitch_base pitch_extent pitches pitches_count pitches_mode pitches_mapping pitches_row_pos velocity_base velocity_extent);
use 5.006;
use MIDI::Pitch qw(findsemitone);

=head1 NAME

Music::Gestalt - Compose music using gestalts.

=head1 VERSION

Version 0.06

=cut

our $VERSION = '0.06';

=head1 SYNOPSIS

    use Music::Gestalt;
    
    # see below

=head1 DESCRIPTION

This module helps to compose music using musical gestalts (forms). A gestalt is
similar to a list in L<MIDI::Score> format, but so far it only supports note
events, and all parameters are expressed as values between 0 and 1. This allows
for more flexible transformations of the musical material.

=head1 CONSTRUCTOR

=head2 C<new>

  my $g = Music::Gestalt->new(score => $score);

Creates a new Music::Gestalt object. The optional score argument receives
a score in L<MIDI::Score> format.

=cut

sub new {
    my $class  = shift;
    my %params = @_;
    my $self   = fields::new($class);

    $self->{pitches_count} = 0;
    $self->{pitches_mode}  = 'all';
    $self->{density}       = 1;
    $self->{note_length}   = 1;
    $self->_InitializeFromScore($params{score})
      if (ref $params{score} eq 'ARRAY');
    $self->_PitchesUpdateMapping();

    return $self;
}

# private methods

sub _InitializeFromScore {
    my ($self, $score) = @_;

    my ($max_time, $min_pitch, $max_pitch, $min_velocity, $max_velocity);

    # find min/max values
    # #0: 'note'
    # #1: start time
    # #2: duration
    # #3: channel
    # #4: note
    # #5: velocity
    foreach (@$score) {
        next unless $_->[0] eq 'note';

        # min_time is always 0
        $max_time = $_->[1] + $_->[2]
          if (!defined $max_time || $_->[1] + $_->[2] > $max_time);
        $min_pitch = $_->[4]
          if (!defined $min_pitch || $_->[4] < $min_pitch);
        $max_pitch = $_->[4]
          if (!defined $max_pitch || $_->[4] > $max_pitch);
        $min_velocity = $_->[5]
          if (!defined $min_velocity || $_->[5] < $min_velocity);
        $max_velocity = $_->[5]
          if (!defined $max_velocity || $_->[5] > $max_velocity);
    }

    $self->{pitch_base}   = $min_pitch;
    $self->{pitch_extent} = defined $min_pitch
      && defined $max_pitch ? $max_pitch - $min_pitch : undef;
    $self->{velocity_base}   = $min_velocity;
    $self->{velocity_extent} = defined $min_velocity
      && defined $max_velocity ? $max_velocity - $min_velocity : undef;
    $self->{duration} = $max_time || 0;
    $self->{notes}    = [];

    return if (!defined $max_time || $max_time == 0);

    my @notes           = ();
    my $pitch_extent    = ($max_pitch - $min_pitch);
    my $velocity_extent = ($max_velocity - $min_velocity);
    foreach (@$score) {
        next unless $_->[0] eq 'note';
        push @notes,
          [
            $_->[1] / $max_time,
            $_->[2] / $max_time,
            ($_->[3] - 1) / 15,
            $pitch_extent == 0    ? 0 : ($_->[4] - $min_pitch) / $pitch_extent,
            $velocity_extent == 0 ? 0 :
              ($_->[5] - $min_velocity) / $velocity_extent];
    }

    $self->{notes} = [@notes];
}

sub _min {
    my ($a, $b) = @_;

    return $a < $b ? $a : $b;
}

sub _max {
    my ($a, $b) = @_;

    return $a > $b ? $a : $b;
}

sub _CalcAutomationValue {
    my ($self, $param_name, $position, $value) = @_;

    return $value
      unless (ref $self->{automation}->{$param_name} eq 'HASH'
        && ref $self->{automation}->{$param_name}->{values} eq 'ARRAY');
    my %am = %{$self->{automation}->{$param_name}};

    my $count = scalar @{$am{values}};

    if ($count == 1) {
        if ($am{mode} eq 'absolute') {
            return $am{values}->[0];
        } else {
            return $value * $am{values}->[0];
        }
    }

    my $time_per_value = 1 / ($count - 1);
    my $div            = $position / $time_per_value;
    my $idx            = int($div);
    my $frac           = $div - $idx;
    my $base           = $am{values}->[$idx];
    my $extent         = $am{values}->[$idx + 1] - $base;
    my $val            = $base + $frac * $extent;

    if ($am{mode} eq 'absolute') {
        return $val;
    } else {
        return $value * $val;
    }
}

sub _CalcPitch {
    my ($self, $v, $pos) = @_;

    my $pb = $self->{pitch_base};
    my $pe = $self->{pitch_extent};

    if (ref $self->{automation}->{pitch_middle}->{values} eq 'ARRAY') {
        my $pm = $self->PitchMiddle();
        $pb += $self->_CalcAutomationValue('pitch_middle', $pos, $pm) - $pm;
    }

    my $val = $pb + $v * $pe + 0.5;
    $val = _max(0, _min(int($val), 127));

    my $pitch = $self->{pitches_mapping}->{$val};
    if ($self->{pitches_mode} eq 'row' && ref $self->{pitches} eq 'ARRAY') {
        $pitch =
          findsemitone($self->{pitches}->[$self->{pitches_row_pos}], $pitch);
        $self->{pitches_row_pos} =
          ($self->{pitches_row_pos} + 1) % scalar @{$self->{pitches}};
    }
    return $pitch;
}

sub _CalcVelocity {
    my ($self, $v, $pos) = @_;

    my $val =
      $self->_CalcAutomationValue('velocity', $pos,
        $self->{velocity_base} + $v * $self->{velocity_extent} + 0.5);
    return _max(0, _min(int($val), 127));
}

=head1 PROPERTIES

=head2 C<PitchLowest>

Sets (if you pass a value) and returns lowest pitch used in this gestalt.

=cut

sub PitchLowest {
    my ($self, $v) = @_;

    if (defined $v) {
        $v = _max(0, _min($self->{pitch_base} + $self->{pitch_extent}, $v));
        $self->{pitch_extent} =
          $self->{pitch_base} + $self->{pitch_extent} - $v;
        $self->{pitch_base} = $v;
    }

    return $self->{pitch_base};
}

=head2 C<PitchHighest>

Sets (if you pass a value) and returns highest pitch used in this gestalt.

=cut

sub PitchHighest {
    my ($self, $v) = @_;

    return undef
      unless defined $self->{pitch_base} && defined $self->{pitch_extent};

    if (defined $v) {
        $v = _min(127, _max($self->{pitch_base}, $v));
        $self->{pitch_extent} = $v - $self->{pitch_base};
    }

    return $self->{pitch_base} + $self->{pitch_extent};
}

=head2 C<PitchMiddle>

Sets (if you pass a value) and returns middle pitch of the range used in this gestalt.

=cut

sub PitchMiddle {
    my ($self, $v) = @_;

    return undef
      unless defined $self->{pitch_base} && defined $self->{pitch_extent};

    if (defined $v) {
        $v = _min(_max($v, 0), 127);
        my $pm_old = (2 * $self->{pitch_base} + $self->{pitch_extent}) / 2;
        $self->{pitch_base} += $v - $pm_old;
    }

    return (2 * $self->{pitch_base} + $self->{pitch_extent}) / 2;
}

=head2 C<PitchRange>

Returns the pitch range used in this gestalt, ie. the pitches that occur
will be between pitch middle +/- pitch range.

If you pass a value as parameter, the new pitch range will be calculated
around the current pitch middle.

=cut

sub PitchRange {
    my ($self, $value) = @_;

    return undef unless defined $self->{pitch_base};

    if (defined $value) {
        my $old_range = $self->{pitch_extent} / 2;
        $self->{pitch_extent} = 2 * $value;
        $self->{pitch_base} += $old_range - $value;
    }

    return undef unless defined $self->{pitch_extent};
    return $self->{pitch_extent} / 2;
}

=head2 C<VelocityLowest>

Sets (if you pass a value) and returns lowest velocity used in this gestalt.

=cut

sub VelocityLowest {
    my ($self, $v) = @_;

    if (defined $v) {
        $v =
          _max(0, _min($self->{velocity_base} + $self->{velocity_extent}, $v));
        $self->{velocity_extent} =
          $self->{velocity_base} + $self->{velocity_extent} - $v;
        $self->{velocity_base} = $v;
    }

    return $self->{velocity_base};
}

=head2 C<VelocityHighest>

Sets (if you pass a value) and returns highest velocity used in this gestalt.

=cut

sub VelocityHighest {
    my ($self, $v) = @_;

    return undef
      unless defined $self->{velocity_base} && defined $self->{velocity_extent};

    if (defined $v) {
        $v = _min(127, _max($self->{velocity_base}, $v));
        $self->{velocity_extent} = $v - $self->{velocity_base};
    }

    return $self->{velocity_base} + $self->{velocity_extent};
}

=head2 C<VelocityMiddle>

Sets (if you pass a value) and returns middle velocity of the range used in this gestalt.

=cut

sub VelocityMiddle {
    my ($self, $v) = @_;

    return undef
      unless defined $self->{velocity_base} && defined $self->{velocity_extent};

    if (defined $v) {
        $v = _min(_max($v, 0), 127);
        my $vm_old =
          (2 * $self->{velocity_base} + $self->{velocity_extent}) / 2;
        $self->{velocity_base} += $v - $vm_old;
    }

    return (2 * $self->{velocity_base} + $self->{velocity_extent}) / 2;
}

=head2 C<VelocityRange>

Returns the velocity range used in this gestalt, ie. the velocities that occur
will be between velocity middle +/- velocity range.

If you pass a value as parameter, the new velocity range will be calculated
around the current velocity middle.

=cut

sub VelocityRange {
    my ($self, $value) = @_;

    return undef unless defined $self->{velocity_base};

    if (defined $value) {
        my $old_range = $self->{velocity_extent} / 2;
        $self->{velocity_extent} = 2 * $value;
        $self->{velocity_base} += $old_range - $value;
    }

    return undef unless defined $self->{velocity_extent};
    return $self->{velocity_extent} / 2;
}

=head2 C<Duration>

Returns the duration of this gestalt.

If you pass a value as a parameter, it will be used as new duration.

=cut

sub Duration {
    my ($self, $v) = @_;

    $self->{duration} = _max(0, $v) if defined $v;
    return $self->{duration} || 0;
}

=head2 C<NoteLength>

Returns the note length property of this gestalt. "1" means that the 
original note lengths are retained, ".5" means that each note is half
as long as it originally was.

If you pass a value as a parameter, it will be used as new note length.

=cut

sub NoteLength {
    my ($self, $v) = @_;

    $self->{note_length} = _max(0, $v) if defined $v;
    return $self->{note_length} || 0;
}

=head2 C<Notes>

Returns the note list of this gestalt.

=cut

sub Notes {
    my $self = shift;

    return @{[]} unless ref $self->{notes} eq 'ARRAY';
    return @{$self->{notes}};
}

=head2 C<Density>

Sets and returns the density of this gestalt. The initial density is 1, meaning
that all notes will be used. At density 0, a score created from this gestalt
will have no events. At density 0.5, a score created from this gestalt will
have half the original events, selected at random.

It is intentional that the density may not be greater than 1; there are too
many possible ways to generate additional events. 

=cut

sub Density {
    my ($self, $v) = @_;

    $self->{density} = _min(1, _max(0, $v)) if defined $v;
    return $self->{density};
}

=head2 C<Pitches>

Returns or sets the pitches used in this gestalt. You should pass areference to a list that contains the pitch numbers used. Returns a
reference to a list of pitches that will be used.
An empty list signifies that all pitches are used.
Note that the set of pitches used is also influenced by the L</"PitchesMode">
parameter.

=cut

sub Pitches {
    my ($self, $pitches) = @_;
    if (defined $pitches && ref $pitches eq 'ARRAY') {
        $self->{pitches} = [map { _max(0, _min($_, 127)) } @$pitches];
        $self->{pitches_count} = scalar @$pitches;
        $self->_PitchesUpdateMapping();
    }

    if (defined $self->{pitches}) { return $pitches; }
    else { return []; }
}

=head2 C<PitchesMode>

Returns or sets the pitch mode used in this gestalt.

=cut

sub _PitchesUpdateMapping {
    my ($self) = @_;

    if (ref $self->{pitches} eq 'ARRAY' && scalar @{$self->{pitches}} > 0) {
        my %map;
        if ($self->{pitches_mode} eq 'nearest') {
            if (scalar @{$self->{pitches}} == 1) {
                %map = map { $_ => $self->{pitches}->[0] } 0 .. 127;
                return $self->{pitches_mapping} = {%map};
            }

            my @list = sort { $a <=> $b } @{$self->{pitches}};
            my $idx = 0;
            for (0 .. 127) {
                my $diffA = abs($list[$idx] - $_);
                my $diffB = abs($list[$idx + 1] - $_);

                if ($diffA < $diffB) {
                    $map{$_} = $list[$idx];
                } else {
                    $map{$_} = $list[$idx + 1];
                    $idx++ if ($idx < $#list);
                }
            }
            return $self->{pitches_mapping} = {%map};
        }
    }

    $self->{pitches_mapping} = {map { $_ => $_ } 0 .. 127};
}

sub PitchesMode {
    my ($self, $mode) = @_;

    if (defined $mode) {
        $self->{pitches_mode} = $mode;
        $self->_PitchesUpdateMapping();
    }
    return $self->{pitches_mode};
}

=head1 METHODS

=head2 C<AsScore>

Returns a structure representing the gestalt in L<MIDI::Score> format.

=cut

sub AsScore {
    my $self = shift;

    return [] if $self->{density} == 0;

    my @score = ();
    $self->{pitches_row_pos} = 0;
    foreach (@{$self->{notes}}) {
        push @score,
          [
            'note',
            $_->[0] * $self->{duration},
            $_->[1] * $self->{duration} * $self->{note_length},
            int(($_->[2] * 15 + 0.5) + 1),
            $self->_CalcPitch($_->[3], $_->[0]),
            $self->_CalcVelocity($_->[4], $_->[0])];
    }

    # remove events if density < 1
    if ($self->{density} < 1) {
        for (1 .. int((1 - $self->{density}) * scalar @score)) {
            splice @score, int(rand(scalar @score)), 1;
        }
    }

    return [@score];
}

=head2 C<Append>

Appends other Music::Gestalt objects to this object.

=cut

sub Append {
    my $self = shift;

    # 1. Find out lowest/highest pitch and velocity overall
    my $pitch_lowest     = $self->PitchLowest();
    my $pitch_highest    = $self->PitchHighest();
    my $velocity_lowest  = $self->VelocityLowest();
    my $velocity_highest = $self->VelocityHighest();
    my $duration         = $self->Duration() || 0;

    @_ = grep { UNIVERSAL::isa($_, 'Music::Gestalt') } @_;
    foreach (@_) {
        $pitch_lowest = $_->PitchLowest()
          if (!defined $pitch_lowest || $_->PitchLowest() < $pitch_lowest);
        $pitch_highest = $_->PitchHighest()
          if (!defined $pitch_highest
            || $_->PitchHighest() > $pitch_highest);
        $velocity_lowest = $_->VelocityLowest()
          if (!defined $velocity_lowest
            || $_->VelocityLowest() < $velocity_lowest);
        $velocity_highest = $_->VelocityHighest()
          if (!defined $velocity_highest
            || $_->VelocityHighest() > $velocity_highest);
        $duration += $_->Duration;
    }

    return
      if ( !defined $pitch_lowest
        || !defined $pitch_highest
        || !defined $velocity_lowest
        || !defined $velocity_highest);

    my $pitch_extent    = $pitch_highest - $pitch_lowest;
    my $velocity_extent = $velocity_highest - $velocity_lowest;

    # 2. Transform notes in this gestalt to new pitch
    foreach (@{$self->{notes}}) {

        # start time, duration, pitch, velocity
        $_->[0] = $_->[0] * $self->{duration} / $duration;
        $_->[1] = $_->[1] * $self->{duration} / $duration;

        # channel stays as it is
        $_->[3] =
          $pitch_extent == 0 ? 0 :
          (
            (
                $self->{pitch_base} - $pitch_lowest + $self->{pitch_extent} *
                  $_->[3]) / $pitch_extent);
        $_->[4] =
          $velocity_extent == 0 ? 0 :
          (
            (
                $self->{velocity_base} - $velocity_lowest +
                  $self->{velocity_extent} * $_->[4]) / $velocity_extent);
    }

    # 3. Transform and append notes in the gestalts to be appended
    my $time_pos = $self->{duration} || 0;

    foreach my $g (@_) {
        my $time_delta      = $time_pos / $duration;
        my $gpitchextent    = $g->PitchHighest() - $g->PitchLowest();
        my $gvelocityextent = $g->VelocityHighest() - $g->VelocityLowest();
        my $dur             = $g->Duration() / $duration;
        foreach ($g->Notes()) {
            push @{$self->{notes}},
              [
                $time_delta + ($_->[0] * $dur),
                $_->[1] * $dur,
                $_->[2],
                $pitch_extent == 0 ? 0 :
                  (
                    (
                        $g->PitchLowest() - $pitch_lowest + $gpitchextent *
                          $_->[3]) / $pitch_extent),
                $velocity_extent == 0 ? 0 :
                  (
                    (
                        $g->VelocityLowest() - $velocity_lowest +
                          $gvelocityextent * $_->[4]) / $velocity_extent)];
        }
        $time_pos += $g->Duration();
    }

    # 4. Save new attributes in this gestalt
    $self->{pitch_base}      = $pitch_lowest;
    $self->{pitch_extent}    = $pitch_extent;
    $self->{velocity_base}   = $velocity_lowest;
    $self->{velocity_extent} = $velocity_extent;
    $self->{duration}        = $duration;
}

=head2 C<Insert>

Inserts other Music::Gestalt objects into this object.

=cut

sub Insert {
    my $self = shift;

    # 1. Find out lowest/highest pitch and velocity overall
    my $pitch_lowest     = $self->PitchLowest();
    my $pitch_highest    = $self->PitchHighest();
    my $velocity_lowest  = $self->VelocityLowest();
    my $velocity_highest = $self->VelocityHighest();
    my $duration         = $self->Duration() || 0;

    @_ = grep { UNIVERSAL::isa($_, 'Music::Gestalt') } @_;
    foreach (@_) {
        $pitch_lowest = $_->PitchLowest()
          if (!defined $pitch_lowest || $_->PitchLowest() < $pitch_lowest);
        $pitch_highest = $_->PitchHighest()
          if (!defined $pitch_highest
            || $_->PitchHighest() > $pitch_highest);
        $velocity_lowest = $_->VelocityLowest()
          if (!defined $velocity_lowest
            || $_->VelocityLowest() < $velocity_lowest);
        $velocity_highest = $_->VelocityHighest()
          if (!defined $velocity_highest
            || $_->VelocityHighest() > $velocity_highest);
        $duration = $_->Duration() if $_->Duration() > $duration;
    }

    return
      if ( !defined $pitch_lowest
        || !defined $pitch_highest
        || !defined $velocity_lowest
        || !defined $velocity_highest);

    my $pitch_extent    = $pitch_highest - $pitch_lowest;
    my $velocity_extent = $velocity_highest - $velocity_lowest;

    # 2. Transform notes in this gestalt to new pitch
    foreach (@{$self->{notes}}) {

        # start time, duration, pitch, velocity
        $_->[0] = $_->[0] * $self->{duration} / $duration;
        $_->[1] = $_->[1] * $self->{duration} / $duration;

        # channel stays as it is
        $_->[3] =
          $pitch_extent == 0 ? 0 :
          (
            (
                $self->{pitch_base} - $pitch_lowest + $self->{pitch_extent} *
                  $_->[3]) / $pitch_extent);
        $_->[4] =
          $velocity_extent == 0 ? 0 :
          (
            (
                $self->{velocity_base} - $velocity_lowest +
                  $self->{velocity_extent} * $_->[4]) / $velocity_extent);
    }

    # 3. Transform and insert notes in the gestalts to be inserted
    foreach my $g (@_) {
        my $gpitchextent    = $g->PitchHighest() - $g->PitchLowest();
        my $gvelocityextent = $g->VelocityHighest() - $g->VelocityLowest();
        my $notes_pos       = 0;
        my $dur             = $g->Duration() / $duration;
        foreach ($g->Notes()) {

            my $start = $_->[0] * $dur;
            $notes_pos++ while ($notes_pos <= $#{$self->{notes}}
                && $self->{notes}->[$notes_pos]->[0] <= $start);
            splice @{$self->{notes}}, $notes_pos, 0,
              [
                $_->[0] * $dur,
                $_->[1] * $dur,
                $_->[2],
                $pitch_extent == 0 ? 0 :
                  (
                    (
                        $g->PitchLowest() - $pitch_lowest + $gpitchextent *
                          $_->[3]) / $pitch_extent),
                $velocity_extent == 0 ? 0 :
                  (
                    (
                        $g->VelocityLowest() - $velocity_lowest +
                          $gvelocityextent * $_->[4]) / $velocity_extent)];
        }
    }

    # 4. Save new attributes in this gestalt
    $self->{pitch_base}      = $pitch_lowest;
    $self->{pitch_extent}    = $pitch_extent;
    $self->{velocity_base}   = $velocity_lowest;
    $self->{velocity_extent} = $velocity_extent;
    $self->{duration}        = $duration;
}

=head2 C<MirrorTime>, C<MirrorPitch>, C<MirrorVelocity>

Mirrors the start times, pitches and velocites found in the gestalt.

=cut

sub _mirror {
    my ($self, $param) = @_;

    return unless ref $self->{notes} eq 'ARRAY';
    foreach (@{$self->{notes}}) {

        #        die "\n\n\nparam = $param\n\n\n";

        # start time, duration, pitch, velocity
        $_->[$param] = 1 - $_->[$param];
    }
}

sub MirrorTime {
    my ($self) = @_;

    $self->_mirror(0);
}

sub MirrorPitch {
    my ($self) = @_;

    $self->_mirror(3);
}

sub MirrorVelocity {
    my ($self) = @_;

    $self->_mirror(4);
}

=head1 AUTOMATION METHODS

Using automation, you can vary a parameter over time (comparable to parameter
automation in sequencers like Logic or Cubase). For each parameter that can be
automated, there are three modes available:

=over 4

=item Absolute mode

In this mode, the currently set parameter values will be I<replaced> with the
values that you pass to the function. If you pass (0, 100), the parameter
will range from 0 to 100 over the whole gestalt. If you pass (20, 50 20), the
parameter will first rise from 20 to 50, then in the second half of the gestalt
fall from 50 to 20. The parameter value is interpolated at the event's position.

=item Relative mode

In this mode, the currently set parameter values will be I<multiplied> with the
values that you pass to the function. If you pass (0, 1), the parameter
will fade in over the whole gestalt. If you pass (.2, .5 .2), the
parameter will first fade in from 20% to 50%, then in the second half of
the gestalt fade out from 50% to 20%. The parameter value is interpolated
at the event's position.

=item Off

Automation will not be applied.

=back

Here are some examples how to call the automation functions:

  $g->AutomateVelocityOff(); # default
  $g->AutomateVelocityAbs(20, 50, 20);
  $g->AutomateVelocityRel(0, 1);

The values passed to the automation methods will be applied evenly-spaced.

The following automation methods are available:

=over 4

=item C<AutomateVelocityOff>, C<AutomateVelocityAbs>, C<AutomateVelocityRel>

=cut

sub AutomateVelocityOff {
    my $self = shift;

    delete $self->{automation}->{velocity};
}

sub AutomateVelocityAbs {
    my $self = shift;
    if (scalar @_) {
        $self->{automation}->{velocity}->{mode}   = 'absolute';
        $self->{automation}->{velocity}->{values} =
          [map { _min(127, _max(0, $_)) } @_];
    }

    return $self->{automation}->{velocity};
}

sub AutomateVelocityRel {
    my $self = shift;
    if (scalar @_) {
        $self->{automation}->{velocity}->{mode}   = 'relative';
        $self->{automation}->{velocity}->{values} = [@_];
    }

    return $self->{automation}->{velocity};
}

=item C<AutomatePitchMiddleOff>, C<AutomatePitchMiddleAbs>, C<AutomatePitchMiddleRel>

=cut

sub AutomatePitchMiddleOff {
    my $self = shift;

    delete $self->{automation}->{pitch_middle};
}

sub AutomatePitchMiddleAbs {
    my $self = shift;
    if (scalar @_) {
        $self->{automation}->{pitch_middle}->{mode}   = 'absolute';
        $self->{automation}->{pitch_middle}->{values} =
          [map { _min(127, _max(0, $_)) } @_];
    }

    return $self->{automation}->{pitch_middle};
}

sub AutomatePitchMiddleRel {
    my $self = shift;
    if (scalar @_) {
        $self->{automation}->{pitch_middle}->{mode}   = 'relative';
        $self->{automation}->{pitch_middle}->{values} = [@_];
    }

    return $self->{automation}->{pitch_middle};
}

=back

=head1 AUTHOR

Christian Renz, E<lt>crenz @ web42.comE<gt>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-music-gestalt@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Music-Gestalt>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

Please also consider adding a test case to your bug report (.t script).

=head1 COPYRIGHT & LICENSE

Copyright 2005 Christian Renz, E<lt>crenz @ web42.comE<gt>, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

42;

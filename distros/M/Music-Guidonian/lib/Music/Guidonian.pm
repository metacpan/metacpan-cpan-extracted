# -*- Perl -*-
#
# Music::Guidonian - a means of melodic phrase generation based on the
# "Guidonian Hand" that is credited to Guido of Arezzo

package Music::Guidonian;
our $VERSION = '0.05';

use 5.24.0;
use warnings;
use Carp 'croak';
use List::Util 'shuffle';
use List::UtilsBy 'nsort_by';
use Moo;
use namespace::clean;

use constant { INDEX => 0, CHOICE => 1, FIRST => 0, DONE => -1, DIRTY => -1 };

use parent qw(Exporter);
our @EXPORT_OK = qw(intervalize_scale_nums);

has key2pitch  => ( is => 'rw' );
has pitchstyle => ( is => 'ro' );

# perldoc Moo
sub BUILD {
    my ( $self, $args ) = @_;

    if ( exists $args->{key2pitch} and exists $args->{key_set} ) {
        croak "cannot specify both key2pitch and key_set";

    } elsif ( exists $args->{key2pitch} ) {
        croak "key2pitch must be a hash reference with keys"
          unless defined $args->{key2pitch}
          and ref $args->{key2pitch} eq 'HASH'
          and keys $args->{key2pitch}->%*;

    } elsif ( exists $args->{key_set} ) {
        my $set = $args->{key_set};
        croak "key_set must be a hash reference with keys"
          unless defined $set
          and ref $set eq 'HASH'
          and keys $set->%*;

        croak "intervals must be an array with elements"
          unless defined $set->{intervals}
          and ref $set->{intervals} eq 'ARRAY'
          and $set->{intervals}->@*;
        croak "keys must be an array with elements"
          unless defined $set->{keys}
          and ref $set->{keys} eq 'ARRAY'
          and $set->{keys}->@*;
        croak "min must be an integer"
          unless defined $set->{min} and $set->{min} =~ m/^(?a)-?\d+$/;
        croak "max must be an integer"
          unless defined $set->{max} and $set->{max} =~ m/^(?a)-?\d+$/;

        croak "min must be less than max" if $set->{min} >= $set->{max};

        my $curinterval = 0;
        my $curkey      = 0;
        my %key2pitch;
        my $pitch = $set->{min};

        while (1) {
            push @{ $key2pitch{ $set->{keys}->[$curkey] } }, $pitch;
            $pitch += $set->{intervals}->[$curinterval];
            last if $pitch > $set->{max};
            $curinterval = ++$curinterval % $set->{intervals}->@*;
            $curkey      = ++$curkey % $set->{keys}->@*;
        }
        $self->key2pitch( \%key2pitch );

        # may want to preserve this for reference or cloning?
        delete $args->{key_set};

    } else {
        croak "need key2pitch or key_set";
    }

    with( $args->{pitchstyle} ) if exists $args->{pitchstyle};
}

########################################################################
#
# METHODS

sub iterator {
    my ( $self, $sequence, %param ) = @_;
    croak "sequence is not an array reference"
      unless defined $sequence and ref $sequence eq 'ARRAY';
    croak "sequence is too short" if @$sequence < 2;

    if ( exists $param{renew} ) {
        croak "renew is not a code reference"
          unless !defined $param{renew}
          or ref $param{renew} eq 'CODE';
    } else {
        $param{renew} = \&_renew;
    }

    my $key2pitch = $self->key2pitch;
    croak "no key2pitch map is set"
      unless defined $key2pitch
      and ref $key2pitch eq 'HASH'
      and keys %$key2pitch;

    # the possibilities are either scalars (integer pitch numbers, a
    # static choice) or an [ INDEX, CHOICE ] array reference where the
    # CHOICE is an array reference of possible integer pitch numbers
    my @possible;
    for my $i ( 0 .. $#$sequence ) {
        my $s = $sequence->[$i];
        croak "sequence element is undefined ($i)" unless defined $s;
        if ( $s =~ m/^(?a)-?\d+$/ ) {
            push @possible, $s;
        } else {
            my $choices = $key2pitch->{$s} // '';
            croak "choices are not an array reference for '$s'"
              unless ref $choices eq 'ARRAY';
            my $length = $choices->@*;
            croak "no choices for '$s' at index $i" if $length == 0;
            if ( $length == 1 ) {
                push @possible, $choices->[0];
                next;
            }
            $param{renew}->( $choices, $i, \@possible, $param{stash} )
              if defined $param{renew};
            push @possible, [ FIRST, $choices ];    # INDEX, CHOICE
        }
    }

    # edge case: there is only one iteration due to a lack of choices.
    # fail so that the iterator is not complicated to handle that
    my $refcount = 0;
    for my $p (@possible) { $refcount++ if ref $p eq 'ARRAY' }
    croak "no choices in @possible" if $refcount == 0;

    return sub {
        return unless @possible;

        my @phrase;
        for my $p (@possible) {
            if ( ref $p eq 'ARRAY' ) {
                push @phrase, 0 + $p->[CHOICE][ $p->[INDEX] ];
            } else {
                push @phrase, 0 + $p;
            }
        }

        my $dirty = 0;
        for my $i ( reverse DONE .. $#possible ) {
            if ( $i == DONE ) {
                @possible = ();
                $dirty    = 0;
                last;
            } elsif ( ref $possible[$i] eq 'ARRAY' ) {
                if ( ++$possible[$i][INDEX] >= $possible[$i][CHOICE]->@* ) {
                    $possible[$i][INDEX] = DIRTY;
                    $dirty = 1;
                } else {
                    # nothing more to update (this time)
                    last;
                }
            }
        }
        if ($dirty) {
            for my $i ( 0 .. $#possible ) {
                if ( ref $possible[$i] eq 'ARRAY' and $possible[$i][INDEX] == DIRTY ) {
                    $possible[$i][INDEX] = FIRST;
                    $param{renew}->( $possible[$i][CHOICE], $i, \@possible, $param{stash} )
                      if defined $param{renew};
                }
            }
        }

        if ( defined $self->pitchstyle ) {
            for my $p (@phrase) {
                $p = $self->pitchname($p);
            }
        }

        return \@phrase;
    };
}

# this has various problems not typical to melodies, such as confining
# leaps towards the end of the phrase in early subsequent iterations.
# improvements might be to use a non-random starting pitch (e.g. one
# suitable to previous material unknown to the current phrase), or to
# sometimes shuffle the choices mid-phrase, or to leap when there is a
# repeated note?
sub _renew {
    my ( $choices, $index, $possible ) = @_;
    if ( $index == 0 ) {
        $choices = [ shuffle @$choices ];
    } else {
        my $previous = $possible->[ $index - 1 ];
        my $previous_pitch =
          ref $previous eq 'ARRAY'
          ? $previous->[CHOICE][ $previous->[INDEX] ]
          : $previous;
        $choices = [ nsort_by { abs( $previous_pitch - $_ ) } $choices->@* ];
    }
}

########################################################################
#
# FUNCTIONS

# convert Music::Scales "get_scale_nums" to the interval for each step,
# making various assumptions (or lack of sanity tests) along the way
# (pretty sure I've written this same code elsewhere...)
sub intervalize_scale_nums {
    my ( $scale, $max_interval ) = @_;
    $max_interval ||= 12;    # assume Western 12-tone system
    my @intervals;
    my $previous = 0;
    for my $s (@$scale) {
        next if $s == 0;
        push @intervals, $s - $previous;
        $previous = $s;
    }
    push @intervals, $max_interval - $previous;
    return \@intervals;
}

1;
__END__

=head1 NAME

Music::Guidonian - a "Guidonian Hand" melodic phrase generator

=head1 SYNOPSIS

  use Data::Dumper;
  use Music::Guidonian;

  my $mg = Music::Guidonian->new(
    key_set => {
      # Major scale
      intervals => [2,2,1,2,2,2,1],
      # vowels to map from min to max by the intervals
      keys      => [qw(a e i o u)],         
      min       => 48,
      max       => 72
    }
  );

  warn Dumper $mg->key2pitch;

  #                '  '  '   '   '  '   '
  my @text   = qw(Lo rem ip sum do lor sit);
  my @vowels = map { m/([aeiou])/; $1 } @text;
  my $iter   = $mg->iterator(\@vowels);

  #                o  e  i  u  o  o  i
  $iter->();    # [71,67,69,72,71,71,69] (maybe)

=head1 DESCRIPTION

"Guido of Arezzo" is credited with the creation of the "Guidonian Hand"
which grew into among other things a method to aid with the creation of
new music. This implementation is based off of a description of the
process found in "Musimathics" (Volume 1, Chapter 9). In brief, pitches
in a given ambitus are keyed to particular letters, usually vowels
repeated over some sequence of intervals (a scale). Then, given a
sequence of those particular letters, a sequence of pitch numbers is
returned for each call to an iterator function until no more
possibilities remain, or, more likely for longer phrases, the caller
gives up having found something suitable (or perhaps aborts early).
Pitch numbers may be included in the input sequence to lock those
positions to the given pitches.

Pitches are integers, typically MIDI numbers. These may need to be
confined to a particular range (the ambitus) of values. Keys could be
any scalar value (though integers would be a bad choice) and typically
will be the vowels of a text phrase that is to be set to music. The
caller may need to manually or otherwise process the a phrase to extract
the vowels or whatever keys are being used.

=head2 What is that synopsis code even doing?

The synopsis code should result in the keys (vowels) being mapped to
pitches as follows;

   a  e  i  o  u  a  e  i  o  u  a  e  i  o  u
  48 50 52 53 55 57 59 60 62 64 65 67 69 71 72
   C  D  E  F  G  A  B  C  D  E  F  G  A  B  C

the iterator function works (eventually, and assuming no bugs) through
all possible combinations given that there are multiple choices for each
vowel: the "o" of "Lorem" maps to 53 or 62 or 71, and then the "e" maps
to ..., etc. Longer phrases will suffer from what has been called the
"combinatorial explosion" (see "The Lighthill debate on Artificial
Intelligence").

=head2 Caveat

Various calls will throw exceptions when something is awry.

=head3 Caveat

Various calls may accept bad data and not generate known exceptions.

=head1 CONSTRUCTOR

The B<new> method requires either that the B<key2pitch> attribute is
set, or that B<key_set> containing B<intervals>, B<keys>, B<min>, and
B<max> is set so that B<key2pitch> can be constructed from those values.

If the range between B<min> and B<max> is too small (or the B<intervals>
too are large) there may not be many possible choices. Review what
B<key2pitch> contains after changing the parameters:

  my $mg = ...;
  use Data::Dumper;
  warn Dumper $mg->key2pitch;

L<Music::Scales> can be used to obtain suitable B<intervals> for
different known scales. These will need to be converted with the
B<intervalize_scale_nums> function. L<Music::AtonalUtil> is another way
to obtain pitch set intervals.

=head1 ATTRIBUTES

=over 4

=item B<key2pitch>

This attribute must be set for the B<iterator> method to be able to
generate choices from a given I<sequence> of keys. Example keys for a
Latin phrase would typically be the vowels C<a e i o u>. These vowels
must map to one or more integer pitch numbers.

  Music::Guidonian->new(
    key2pitch => { i => [60, 67], a => [62, 69], ... } );
  );

=item B<pitchstyle>

Optional. Specifies a L<Music::PitchNum> compatible role module that
will convert the integer pitch numbers returned by calls to the
B<iterator>-returned function to some other form, such as note names,
e.g. L<Music::PitchNum::Dutch> for LilyPond.

=back

=head1 METHOD

=over 4

=item B<iterator> I<sequence> [ I<parameters> ]

This method accepts an array reference that is a I<sequence> of B<key>
values or integer pitch numbers. A function is returned. Each call of
the function will return an array reference containing a list of integer
pitch numbers. When there are no more combinations the empty list or
undefined value is returned, depending on the context.

The I<parameters> may contain a I<renew> code reference; this will
be called as

  sub renew {
    my ($choices, $index, $possible, $stash) = @_;
    ...
  }

when a set of choices (an array reference of pitch numbers) need to be
set for the first time and each time those choices have been completely
iterated over. The index is the current position in the possible array
reference. I<stash> can be supplied as a I<parameter> to pass that to
each I<renew> call.

The default I<renew> call shuffles the choices at the first index (if
there are choices there and not a static entry) and otherwise sorts the
choices minimizing the absolute distance from the previous pitch. This
defaults to the creation of a (more) smooth melodic line for the first
iteration call, but creates leaps mostly towards the end of the phrase
on subsequent iterations.

  # always shuffle the choices
  use List::Util 'shuffle';
  $mg->iterator( ..., renew => sub { $_[0] = [ shuffle $_[0]->@* ] } );

Set I<renew> to C<undef> to disable the callback. In this case the
choices will be iterated over in the order given in I<sequence>.

=back

=head1 FUNCTION

The function is not exported by default.

=over 4

=item B<intervalize_scale_nums> I<scale> [ I<max-interval> ]

Converts the output of C<get_scale_nums> of L<Music::Scales> into
an interval form usable by this module.

  use Music::Guidonian 'intervalize_scale_nums';
  use Music::Scales 'get_scale_nums';
  ...
    intervals => intervalize_scale_nums([get_scale_nums('major')])

=item B<BUILD>

Internal. This is a L<Moo> utility function used by the
L</"CONSTRUCTOR">.

=back

=head1 BUGS

None known.

=head1 SEE ALSO

=over 4

=item *

L<Algorithm::Permute> or similar would likely be a faster way to
generate all possible permutations of a given set of pitches.

=item *

L<MIDI> can help convert pitch numbers to noises.

=item *

L<Music::AtonalUtil> has routines suitable for feeding to B<intervals>
and also melody generation. (If you consider a tone row to be a melody.)

=item *

L<Music::PitchNum> can convert pitch numbers to names.

=item *

L<Music::Scales> also can feed B<intervals> (after conversion).

=item *

L<Music::VoiceGen> alternative means to generate a random melody.

=back

"Musimathics: the mathematical foundations of music". Gareth Loy.
Mit Press. 2011.

=head1 COPYRIGHT AND LICENSE

Copyright 2021 Jeremy Mates

This program is distributed under the (Revised) BSD License:
L<https://opensource.org/licenses/BSD-3-Clause>

=cut

# -*- Perl -*-
#
# Performs Neo-Riemann operations on set classes.
# https://en.wikipedia.org/wiki/Neo-Riemannian_theory

package Music::NeoRiemannianTonnetz;

use 5.010000;
use strict;
use warnings;

use Carp qw/croak/;
use List::Util qw/min/;
use Scalar::Util qw/reftype/;
use Try::Tiny;

our $VERSION = '0.27';

my $DEG_IN_SCALE = 12;

# For the transform table. "SEE ALSO" section in docs has links for
# [refs]. These are expanded as a simple grammar, until a code reference
# is reached; the code reference then looks up what needs to be done via
# the operations table.
my %TRANSFORMATIONS = (
  # 3-11 operations
  P => \&_apply_operation,    # Parallel [WP]
  R => \&_apply_operation,    # Relative [WP]
  L => \&_apply_operation,    # Leittonwechsel [WP]
  N => 'RLP',                 # Nebenverwandt [WP]
  S => 'LPR',                 # Slide [WP]
  H => 'LPL',                 # [WP]

  # 4-27 operations [Childs 1998]
  S23 => \&_apply_operation,
  S32 => \&_apply_operation,
  S34 => \&_apply_operation,
  S43 => \&_apply_operation,
  S56 => \&_apply_operation,
  S65 => \&_apply_operation,
  C32 => \&_apply_operation,
  C34 => \&_apply_operation,
  C65 => \&_apply_operation,
);

# The important bits (these munge set classes to a different form of the
# same parent prime form of a set class, e.g. toggling 0,3,7 to 0,4,7).
# The operation names come from the literature, as well as the magic
# numbers required to change the set classes correctly.
my %OPERATIONS = (
  L => { '0,3,7' => { 7 => 1 },  '0,4,7' => { 0 => -1 } },
  P => { '0,3,7' => { 3 => 1 },  '0,4,7' => { 4 => -1 } },
  R => { '0,3,7' => { 0 => -2 }, '0,4,7' => { 7 => 2 } },
  S23 =>
    { '0,3,6,8' => { 0 => -1, 3 => -1 }, '0,2,5,8' => { 5 => 1, 8 => 1 } },
  S32 =>
    { '0,3,6,8' => { 6 => 1, 8 => 1 }, '0,2,5,8' => { 0 => -1, 2 => -1 } },
  S34 =>
    { '0,3,6,8' => { 0 => 1, 8 => 1 }, '0,2,5,8' => { 0 => -1, 8 => -1 } },
  S43 =>
    { '0,3,6,8' => { 3 => -1, 6 => -1 }, '0,2,5,8' => { 2 => 1, 5 => 1 } },
  S56 =>
    { '0,3,6,8' => { 0 => -1, 6 => -1 }, '0,2,5,8' => { 2 => 1, 8 => 1 } },
  S65 =>
    { '0,3,6,8' => { 3 => 1, 8 => 1 }, '0,2,5,8' => { 0 => -1, 5 => -1 } },
  C32 =>
    { '0,3,6,8' => { 6 => -1, 8 => 1 }, '0,2,5,8' => { 0 => -1, 2 => 1 } },
  C34 =>
    { '0,3,6,8' => { 0 => -1, 8 => 1 }, '0,2,5,8' => { 0 => -1, 8 => 1 } },
  C65 =>
    { '0,3,6,8' => { 3 => -1, 8 => 1 }, '0,2,5,8' => { 0 => -1, 5 => 1 } },
);

########################################################################
#
# SUBROUTINES

sub _apply_operation {
  my ( $self, $token, $pset_str, $pset2orig ) = @_;

  if ( !exists $self->{op}->{$token}->{$pset_str} ) {
    croak "no set class [$pset_str] for token '$token'";
  }

  # apply pitch modifications from the operations table
  for my $i ( keys %{ $self->{op}->{$token}->{$pset_str} } ) {
    for my $p ( @{ $pset2orig->{$i} } ) {
      $p += $self->{op}->{$token}->{$pset_str}->{$i};
    }
  }

  # reformulate the (updated) original pitches into new pitch set
  my @new_set;
  for my $r ( values %$pset2orig ) {
    push @new_set, @$r;
  }

  @new_set = sort { $a <=> $b } @new_set;
  return \@new_set;
}

sub new {
  my ( $class, %param ) = @_;
  my $self = { op => \%OPERATIONS, x => \%TRANSFORMATIONS };

  # should not need to alter, but who knows
  $self->{_DEG_IN_SCALE} = int( $param{DEG_IN_SCALE} // $DEG_IN_SCALE );
  if ( $self->{_DEG_IN_SCALE} < 2 ) {
    croak 'degrees in scale must be greater than one';
  }

  bless $self, $class;

  return $self;
}

# Based on normal_form of Music::AtonalUtil but always transposes to
# zero (cannot use prime_form, as that goes one step too far and
# conflates [0,4,7] with [0,3,7] which here must be distinct).
sub normalize {
  my $self = shift;
  my $pset = ref $_[0] eq 'ARRAY' ? $_[0] : [@_];

  croak 'pitch set must contain something' if !@$pset;

  my %origmap;
  for my $p (@$pset) {
    push @{ $origmap{ $p % $self->{_DEG_IN_SCALE} } }, $p;
  }
  if ( keys %origmap == 1 ) {
    return wantarray ? ( keys %origmap, \%origmap ) : keys %origmap;
  }
  my @nset = sort { $a <=> $b } keys %origmap;

  my @equivs;
  for my $i ( 0 .. $#nset ) {
    for my $j ( 0 .. $#nset ) {
      $equivs[$i][$j] = $nset[ ( $i + $j ) % @nset ];
    }
  }
  my @order = reverse 1 .. $#nset;

  my @normal;
  for my $i (@order) {
    my $min_span = $self->{_DEG_IN_SCALE};
    my @min_span_idx;

    for my $eidx ( 0 .. $#equivs ) {
      my $span =
        ( $equivs[$eidx][$i] - $equivs[$eidx][0] ) % $self->{_DEG_IN_SCALE};
      if ( $span < $min_span ) {
        $min_span     = $span;
        @min_span_idx = $eidx;
      } elsif ( $span == $min_span ) {
        push @min_span_idx, $eidx;
      }
    }

    if ( @min_span_idx == 1 ) {
      @normal = @{ $equivs[ $min_span_idx[0] ] };
      last;
    } else {
      @equivs = @equivs[@min_span_idx];
    }
  }

  if ( !@normal ) {
    # nothing unique, pick lowest starting pitch, which is first index
    # by virtue of the numeric sort performed above.
    @normal = @{ $equivs[0] };
  }

  # but must map <b dis fis> (and anything else not <c e g>) so b is 0,
  # dis 4, etc. and also update the original pitch mapping - this is
  # the major addition to the otherwise stock normal_form code.
  if ( $normal[0] != 0 ) {
    my $trans = $self->{_DEG_IN_SCALE} - $normal[0];
    my %newmap;
    for my $i (@normal) {
      my $prev = $i;
      $i = ( $i + $trans ) % $self->{_DEG_IN_SCALE};
      $newmap{$i} = $origmap{$prev};
    }
    %origmap = %newmap;
  }

  return
    wantarray ? ( join( ',', @normal ), \%origmap ) : join( ',', @normal );
}

# Turns string of tokens (e.g. 'RLP') into a list of tasks (CODE refs,
# or more strings, which are recursed on until CODE refs or error).
# Returns array reference of such tasks. Called by transform() if user
# has not already done this and passes transform() a string of tokens.
sub taskify_tokens {
  my ( $self, $tokens, $tasks ) = @_;
  $tasks //= [];
  $tokens = [ $tokens =~ m/([A-Z][a-z0-9]*)/g ] if !defined reftype $tokens;

  # XXX optimize input? - runs of P can be reduced, as those just toggle
  # the third - even number of P a no-op, odd number of P can be
  # replaced with 'P'. Other optimizations are likely possible.

  for my $t (@$tokens) {
    if ( exists $self->{x}{$t} ) {
      if ( ref $self->{x}{$t} eq 'CODE' ) {
        push @$tasks, [ $t, $self->{x}{$t} ];
      } elsif ( !defined reftype $self->{x}{$t}
        or ref $self->{x}{$t} eq 'ARRAY' ) {
        $self->taskify_tokens( $self->{x}{$t}, $tasks );
      } else {
        croak 'unknown token in transformation table';
      }
    } else {
      croak "unimplemented transformation token '$t'";
    }
  }

  return $tasks;
}

sub techno { shift; (qw/tonn tz/) x ( 8 * ( shift || 1 ) ) }

sub transform {
  my $self   = shift;
  my $tokens = shift;
  croak 'tokens must be defined' unless defined $tokens;
  my $pset = ref $_[0] eq 'ARRAY' ? $_[0] : [@_];
  croak 'pitch set must contain something' if !@$pset;

  # Assume list of tasks (code refs to call) if array ref, otherwise try
  # to generate such a list.
  my $tasks;
  if ( ref $tokens eq 'ARRAY' ) {
    $tasks = $tokens;
  } else {
    try { $tasks = $self->taskify_tokens($tokens) } catch { croak $_ };
  }

  my $new_pset = $pset;
  try {
    for my $task (@$tasks) {
      $new_pset =
        $task->[1]->( $self, $task->[0], $self->normalize($new_pset) );
    }
  }
  catch {
    croak $_;
  };
  return $new_pset;
}

1;
__END__

=head1 NAME

Music::NeoRiemannianTonnetz - performs Neo-Riemann operations on set classes

=head1 SYNOPSIS

  use Music::NeoRiemannianTonnetz ();
  my $nrt = Music::NeoRiemannianTonnetz->new;

  # "parallel" changes Major to minor
  $nrt->transform( 'P', [60, 64, 67] );   # [60, 63, 67]
  $nrt->transform( 'P', [60, 63, 67] );   # [60, 64, 67]

  # or multiple operations (LPR)
  my $tasks = $nrt->taskify_tokens('LPR');
  my $new_pitch_set = $nrt->transform($tasks, 0, 3, 7);

  # Sevenths (4-27 only), e.g. F+ to C-
  $nrt->transform( 'S34', [65,69,72,75] ); # [66,70,72,75]

The L<Music::LilyPondUtil> module will assist with converting between
lilypond note names and raw pitch numbers; this module deals with only
the raw pitch numbers (integers).

=head1 DESCRIPTION

Performs Neo-Riemannian operations on major and minor triads (set class
C<3-11>), and sevenths (set class C<4-27>).

This is a very new module, use with caution, things may change, etc.

=head2 TRIAD OPERATIONS (3-11)

Available operations (called "tokens" in this module) for the
B<transform> method on members of set class 3-11:

  P  Parallel
  R  Relative
  L  Leittonwechsel
  N  Nebenverwandt (RLP)
  S  Slide (LPR)
  H  "hexatonic pole exchange" (LPL)

=head2 SEVENTH OPERATIONS (4-27)

These are derived from [Childs 1998] and operate only on members of set
class 4-27. For example, the C<S23> will convert a F+ chord C<F A C Eb>
into F- C<F# A C E>, or a F- chord into a F+, and so forth:

       F+   F-
  ----------------
  S23  F-   F+
  S32  F#-  E+
  S34  C-   Bb+
  S43  B-   B+
  S56  D-   Ab+
  S65  D#-  G+
  C32  D+   G#-
  C34  Ab+  D-
  C65  B+   B-

These always change two notes while holding the other two invariant;
there is also a 10th (here unnamed) operation that holds three pitches
invariant e.g. F+ C<[0,3,5,9]> to A- C<[0,3,7,9]>. But there is no
network of changes while holding three invariant, only toggling between
one or the other of two chords.

=head2 TOKEN NAMES

Token names are at present defined to be upper case ASCII letters (A-Z),
followed by zero to many lower case ASCII letters or numbers (a-z0-9).
Tokens will not perform any changes to a pitch set unless suitable code
is added to the transformation table (a hash of token names to CODE
references).

=head2 EXTENSION TO ARBITRARY SET CLASSES

Most operations on most set classes are undefined. Use the
C<eg/nrt-study-setclass> program under the distribution of this module
to graph arbitrary set classes. Otherwise, software exploiting links
between related forms of a set class would not need to know the name
of the link being followed (but humans might to help analyze what is
going on).

=head1 METHODS

The code may C<croak> if something goes awry; catch these errors with
e.g. L<Try::Tiny>. The B<new> method is doubtless a good one to begin
with, and then B<transform> to just experiment around with the
transformations.

=over 4

=item B<new> I<parameter_pairs ...>

Constructor.

=over 4

=item B<DEG_IN_SCALE> => I<positiveinteger>

A 12-tone system is assumed, though may be changed, though I have no
idea what that would do.

  Music::NeoRiemannianTonnetz->new(DEG_IN_SCALE => 17);

=back

=item B<normalize> I<pitch_set>

Normalizes the given pitch set (a list or array reference of pitch
numbers, which in turn should be integers) via code that is something
like B<normal_form> of L<Music::AtonalUtil> but slightly different.
Returns in list context a string of the normalized pitch set (such as
C<0,4,7> for a Major triad), and a hash reference that maps the
normalized pitch set pitch numbers to the original pitches of the input
I<pitch_set>. In scalar context, just the string of the normalized pitch
set is returned:

  use Music::LilyPondUtil         ();
  use Music::NeoRiemannianTonnetz ();
  my $lyu = Music::LilyPondUtil->new;
  my $nrt = Music::NeoRiemannianTonnetz->new;

  scalar $nrt->normalize( $lyu->notes2pitches(qw/c e g/) ) # 0,4,7

This method is used internally by the B<transform> method, or can be
used to explore the C<3-11>, C<4-27>, or other arbitrary set classes:

  chord        normalized  set class
  <c e g>      [0,4,7]     3-11
  <c ees g>    [0,3,7]     3-11
  <f a c ees>  [0,3,6,8]   4-27
  <fis a c e>  [0,2,5,8]   4-27

Neo-Riemannian operations need this unique normalized form as the set
class conflates these different forms into the same Forte Number
(C<3-11>) or prime form pitch set (C<[0,3,7]>), and Neo-Riemannian
operations must do different things depending on whether the triad is
major or minor, or is C<[0,3,6,8]> or C<[0,2,5,8]>.

There are scripts under the C<eg/> directory of the distribution of this
module that explore the normalize/atonal prime form set space.

=item B<taskify_tokens> I<tokens>, [ I<tasks> ]

Converts tokens (a string such as C<RLP> (three tokens, C<R>, C<L>, and
C<P>), or an array reference of such) to a list of tasks (CODE
references) returned as an array reference, assuming all went well with
the taskification.

=item B<techno> [ I<measurecount> ]

Generates techno beats (returned as a list). The optional
I<measurecount> should be a positive integer, and doubtless a
power of two.

=item B<transform> I<tokens>, I<pitch_set>

Transforms the given I<pitch_set> (a list or array reference of pitch
numbers, ideally integers) via the given I<tokens>. If I<tokens> is
not an array reference, it is fed through the B<taskify_tokens>
method first. Returns the new pitch set (as an array reference) if
all goes well.

The resulting pitch set will be ordered from lowest pitch to highest;
Neo-Riemannian theory cares little about chord inversions, and will
convert root position chords to and from various inversions:

  # C-major to F-minor (2nd inversion)
  $nrt->transform('N', 60, 64, 67); # [60, 65, 68]

=back

=head1 BUGS

Newer versions of this module may be available from CPAN. If the bug is
in the latest version, check:

L<http://github.com/thrig/Music-NeoRiemannianTonnetz>

C<techno> is not a bug, though may bug some.

=head1 SEE ALSO

[WP] L<https://en.wikipedia.org/wiki/Neo-Riemannian_theory> as an
introduction.

L<https://en.wikipedia.org/wiki/Forte_number> for a description of the
C<3-11> and other set class names used in this documentation.

[Cohn 1998] "Introduction to Neo-Riemannian Theory: A Survey and a
Historical Perspective" by Richard Cohn. Journal of Music Theory, Vol.
42, No. 2, Neo-Riemannian Theory (Autumn, 1998), pp. 167-180.

[Childs 1998] "Moving beyond Neo-Riemannian Triads: Exploring a
Transformational Model for Seventh Chords" by Adrian P. Childs. Journal
of Music Theory, Vol. 42, No. 2, Neo-Riemannian Theory (Autumn, 1998),
pp. 181-193.

And also the rest of the Journal of Music Theory Vol. 42, No. 2, Autumn,
1998 publication: L<http://www.jstor.org/stable/i235025>

Various other music modules by the author, for different views on music
theory: L<Music::AtonalUtil>, L<Music::Canon>,
L<Music::Chord::Positions>, L<Music::LilyPondUtil>, etc.

=head1 AUTHOR

thrig - Jeremy Mates (cpan:JMATES) C<< <jmates at cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013-2015 by Jeremy Mates

This module is free software; you can redistribute it and/or modify it
under the Artistic License (2.0).

=cut

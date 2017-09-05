# -*- Perl -*-
#
# rhythms within rhythms within rhythms
#
# Run perldoc(1) on this file for additional documentation.

package Music::RecRhythm;

use 5.10.0;
use strict;
use warnings;

use List::Util 1.26 qw(sum0);
use Math::BigInt ();
use Moo;
use namespace::clean;
use Scalar::Util qw(looks_like_number);

our $VERSION = '0.05';

with 'MooX::Rebuild';    # for ->rebuild a.k.a. clone

has extra => ( is => 'rw' );

has next => (
    is      => 'rw',
    trigger => sub {
        my ( $self, $next ) = @_;
        $next->prev($self);
    },
);
has prev => ( is => 'rw', weak_ref => 1 );

has set => (
    is     => 'rw',
    coerce => sub {
        my ($set) = @_;
        die "need a set of positive integers"
          if !Music::RecRhythm->validate_set($set);
        for my $n (@$set) {
            $n = int $n;
        }
        return $set;
    },
    trigger => sub {
        my ( $self, $set ) = @_;
        $self->_set_count( scalar @$set );
        $self->_set_sum( sum0(@$set) );
    },
);
has count => ( is => 'rwp' );
has sum   => ( is => 'rwp' );

# flag to skip the callback (though the rhythm will still be present in
# the recursion)
has is_silent => (
    is      => 'rw',
    default => sub { 0 },
    coerce  => sub { $_[0] ? 1 : 0 },
);

sub BUILD {
    my ( $self, $param ) = @_;
    die "need a set of positive integers" if !exists $param->{set};
}

########################################################################
#
# METHODS

sub audible_levels {
    my ($self) = @_;
    my $count = 0;
    while ($self) {
        $count++ unless $self->is_silent;
        $self = $self->next;
    }
    return $count;
}

sub beatfactor {
    my ($self) = @_;
    my %factors;
    my $prev_sum = 1;
    while ($self) {
        my $sum = $self->sum * $prev_sum;
        @factors{ @{ $self->set }, $sum } = ();
        $self     = $self->next;
        $prev_sum = $sum;
    }
    return Math::BigInt->bone()->blcm( keys %factors )->numify;
}

sub levels {
    my ($self) = @_;
    my $count = 0;
    while ($self) {
        $count++;
        $self = $self->next;
    }
    return $count;
}

sub recurse {
    my ( $self, $callback, $extra ) = @_;
    my $bf = $self->beatfactor;
    _recurse( $self, $callback, $extra, $bf, 0, 0 );
}

sub _recurse {
    my ( $rset, $callback, $extra, $totaltime, $level, $audible_level, @beats ) =
      @_;
    my %param = ( level => $level, audible_level => $audible_level );
    for my $p (qw/next set/) {
        $param{$p} = $rset->$p;
    }
    my $sil = $rset->is_silent;
    $audible_level++ if !$sil;
    my $unittime = $totaltime / $rset->sum;
    for my $n ( 0 .. $#{ $param{set} } ) {
        $param{beat}     = $param{set}[$n];
        $param{index}    = $n;
        $param{duration} = int( $unittime * $param{beat} );
        if ( !$sil ) {
            $callback->( $rset, \%param, $extra, @beats, $param{beat} );
        }
        if ( defined $param{next} ) {
            _recurse( $param{next}, $callback, $extra, $param{duration}, $level + 1,
                $audible_level, @beats, $param{beat} );
        }
    }
}

sub validate_set {
    my ( $class, $set ) = @_;
    return 0 if !defined $set or ref $set ne 'ARRAY' or !@$set;
    for my $x (@$set) {
        return 0 if !defined $x or !looks_like_number $x or $x < 1;
    }
    return 1;
}

1;
__END__

=head1 NAME

Music::RecRhythm - rhythms within rhythms within rhythms

=head1 SYNOPSIS

  use Music::RecRhythm;

  my $one = Music::RecRhythm->new( set => [qw(2 2 1 2 2 2 1)] );

  my $two = $one->rebuild;  # clone the (original) object

  $one->is_silent(1);       # silent (but present)

  $one->next($two);         # link for recursion
  $two->prev;               # now returns $one

  $one->recurse( sub { ... } );

=head1 DESCRIPTION

A utility module for recursive rhythm construction, where a B<set> is
defined as an array reference of positive integers (beats). Multiple
such objects may be linked through the B<next> attribute, which the
B<recurse> method follows. Each B<next> rhythm I<is played out in full
for each beat of the parent> rhythm, though whether these events are
simultaneous or strung out in time depends on the callback code provided
to B<recurse>.

=head1 CONSTRUCTOR

The B<new> method accepts any of the L</ATTRIBUTES>. The B<set>
attribute I<must> be supplied.

=head1 ATTRIBUTES

=over 4

=item B<count>

A read-only count of the beats in the B<set>. Updated when B<set>
is changed.

=item B<extra>

Use this to stash anything extra you need to associate with an instance,
e.g. a MIDI track, some other object, etc.

=item B<is_silent>

Boolean as to whether or not the callback function of B<recurse> will be
invoked for beats of the set. False by default. Recursion will continue
through silent objects as per usual; B<is_silent> merely disables
calling the callback, so "silent, but present" may be a more accurate
term for this attribute.

=item B<next>

Optional next object to B<recurse> into. While often a
C<Music::RecRhythm> object, any object that supports the necessary
method calls could be used. Recursion will stop should this attribute be
C<undef> (the default). Probably should not be changed in the middle of
a B<recurse> call.

Calls B<prev> in the given object to setup a bi-directional chain.

=item B<prev>

Previous object, if any. Will be automatically set by a B<next> call.

=item B<set>

An array reference of one or more positive integers (a.k.a. beats). This
attribute I<must> be supplied at construction time.

=item B<sum>

A read-only sum of the beats in the B<set>. Updated when B<set>
is changed.

=back

=head1 METHODS

=over 4

=item B<audible_levels>

Returns the number of audible levels (those that do not set
B<is_silent>) recursion will take place over. See also B<levels>.

=item B<beatfactor>

Least common multiple of the beats and sum of the beats such that the
durations at each level of recursion work out to the same overall
duration. Hopefully. Uses L<Math::BigInt> though downgrades that via
B<numify>, so integers larger than what perl can handle internally may
be problematic. See I<duration> under L</CALLBACK> for how this
information is exposed during recursion.

=item B<levels>

Returns the number of levels recursion will take place over. May be
useful prior to a B<recurse> call if an array of MIDI tracks (one for
each level) need be created, or similar. Note that the actual level
numbers may be discontiguous if any of the objects enable B<is_silent>,
hence also the B<audible_levels> method.

=item B<recurse> I<coderef> I<extra>

Iterates the beats of the B<set> and recurses through every B<next> for
each beat, calling the I<coderef> unless B<is_silent> is true for the
object. I<extra> gets passed along to the callback I<coderef>.

See L</CALLBACK> for the arguments the callback sub will be passed.

=item B<validate_set> I<set>

Class method. Checks whether a B<set> really is a list of positive
numbers (the C<int> truncation is done elsewhere). The empty set is not
allowed. Used internally by the B<set> attribute.

  Music::RecRhythm->validate_set("cat")      # 0
  Music::RecRhythm->validate_set([qw/1 2/])  # 1

=back

=head1 CALLBACK

The I<coderef> called during B<recurse> (only for not-silenced objects)
is passed four or more arguments. First, the C<Music::RecRhythm> object,
second, a hash reference containing various parameters (listed below),
third, I<extra>, a scalar that can be whatever you want it to be
(reference, object, whatever) and fourth a list of the durations of the
recursion stack where the last element of that list is the current
C<$param{beat}>.

    $one->recurse(
        sub {
            my ( $rset, $param, $extra, @beats ) = @_;
            ...
        },
        $this_is_passed_as_dollarextra
    );

The I<param> passed as the second argument (which are read-write (though
probably should not be changed on the fly)) include:

=over 4

=item I<audible_level>

Level of recursion, counting from C<0> but only incremented when
B<is_silent> is not set. See I<level> for the exact level of recursion.

=item I<beat>

The current beat, a member of the I<set> at the given I<index>.

=item I<duration>

A calculated duration based on the I<beat> and B<beatfactor> such that
each I<beat> in combination with the others of the set lasts the
duration of the ancestor set. A fudge factor will likely be necessary to
change the least common multiples to something suitable for MIDI
durations:

    $one->recurse(
        sub {
            my ( $rset, $param ) = @_;
            my $duration = $param->{duration} * 128;
            ...
        },
    );

Another option is to multiply the current and ancestor C<@beats>
together, again with a fudge factor:

    use List::Util qw(reduce);
    $one->recurse(
        sub {
            my ( $rset, $param, undef, @beats ) = @_;
            my $duration = reduce { $a * $b } @beats, 128;
            ...
        },
    );

though this may produce different results and adds work.

=item I<index>

Index of the current beat in the I<set>, numbered from 0 on up.

=item I<level>

Level of recursion, C<0> for the first level, C<1> for the second, and
so forth. The level numbers will have gaps if B<is_silent> is set. See
I<audible_level> if that is a problem.

=item I<next>

The B<next> object, or C<undef> should this be the lowest level of
recursion. Probably should not be changed on the fly.

=item I<set>

Array reference containing the beats of the current set, of which
I<beat> is the current at index I<index>.

=back

There are, again, example callbacks in the C<eg/> and C<t/>
directory code.

=head1 BUGS

=head2 Reporting Bugs

Please report any bugs or feature requests to
C<bug-music-recrhythm at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Music-RecRhythm>.

Patches might best be applied towards:

L<https://github.com/thrig/Music-RecRhythm>

=head2 Known Issues

=over 4

=item *

B<beatfactor> may still be buggy, and does not produce minimum factors
in various cases (see C<t/200-recursion-see-recursion.t>). A fudge
factor to get the appropriate MIDI duration for a specific set of rhythm
sets will likely be necessary (see C<eg/rhythm2midi>).

=item *

Loops created with B<next> calls will cause various methods to then run
forever. If this is a risk for generated code, wrap these calls with
C<alarm> to abort them should they run for too long (or add loop
detection somehow (or don't create loops via B<next> calls, sheesh!)).

=item *

B<next> should be checked via C<isa> or somesuch to audit that passed
objects are suitable to be used in B<beatfactor> and B<recurse>.

=item *

B<prev> is primitive and may have problems on object destruction; this
is an unknown as my scripts that use this module exit the entire perl
process when they are done.

=back

=head1 SEE ALSO

L<MIDI> or L<MIDI::Simple> may assist in the callback code to produce
MIDI during the recursion. Consult the C<eg/> and C<t/> directories
under this module's distribution for example code.

L<Music::Voss> is a similar if different means of changing a rhythm
over time.

Various scripts under L<https://github.com/thrig/compositions> use this
module, in particular "Three Levels of the Standard Pattern".

"The Geometry of Musical Rhythm" by Godfried T. Toussaint.

=head1 AUTHOR

thrig - Jeremy Mates (cpan:JMATES) C<< <jmates at cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2016-2017 by Jeremy Mates

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a copy
of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

=cut

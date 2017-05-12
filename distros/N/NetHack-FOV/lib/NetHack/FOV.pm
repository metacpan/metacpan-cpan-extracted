#!/usr/bin/env perl
package NetHack::FOV;

use warnings;
use strict;

use Exporter;

our $VERSION = 0.01;
our @EXPORT_OK = qw(calculate_fov);
our @ISA = qw(Exporter);

sub _clear {
    my ($self, $x, $y) = @_;

    return $self->{cbi}->($x + $self->{x}, $y + $self->{y});
}

sub _see {
    my ($self, $x, $y) = @_;

    return $self->{cbo}->($x + $self->{x}, $y + $self->{y});
}

sub _Q_path {
    my ($self, $x, $y) = @_;

    my ($px, $py) = (0,0);

    my $flip = abs($x) > abs($y);

    my ($rmaj, $rmin) = $flip ? (\$px,\$py) : (\$py,\$px);
    my ($dmaj, $dmin) = $flip ? ( $x , $y ) : ( $y , $x );

    my $fmin = -abs($dmaj);

    for (2 .. abs($dmaj)) {
        $fmin += 2*abs($dmin);
        if ($fmin >= 0) { $fmin -= 2*abs($dmaj); $$rmin += ($dmin <=> 0); }
        $$rmaj += ($dmaj <=> 0);
        if (!$self->_clear($px, $py)) {
            return 0;
        }
    }

    return 1;
}

sub _quadrant {
    my ($self, $hs, $row, $left, $right_mark) = @_;

    my ($right, $right_edge);

    my $rail = ($hs == 1) ? 79 - $self->{x} : $self->{x};
    # Why does this have to be irregular

    while ($left <= $right_mark) {
        #print "in quadrant, $rail  $hs $row $left $right_mark\n";
        $right_edge = $left;
        my $left_clear = $self->_clear($hs*$left, $row);
        while ($self->_clear($hs*$right_edge, $row) == $left_clear &&
                ($left_clear || $right_edge <= $right_mark + 1))
            { $right_edge++ }
        $right_edge--;
        if ($left_clear) { $right_edge++; }

        if ($right_edge >= $rail) {
            $right_edge = $rail; # Yuck
        }

        #print "in quadrant2, $hs $row $left $right_mark $right_edge\n";

        if (!$left_clear) {
            if ($right_edge > $right_mark) {
                $right_edge = $self->_clear($hs*$right_mark,
                    $row - ($row <=> 0)) ? $right_mark + 1 : $right_mark;
            }

            for (my $i = $left; $i <= $right_edge; $i++) {
                $self->_see($hs*$i, $row);
            }
            $left = $right_edge + 1;
            next;
        }
        #print "in quadrant3, $hs $row $left $right_mark\n";

        if ($left != 0) {
            for (; $left <= $right_edge; $left++) {
                last if $self->_Q_path($hs*$left, $row);
            }

            if ($left >= $rail) {
                # Double yuck
                if ($left == $rail) {
                    $self->_see($left*$hs, $row);
                }

                return;
            }

            if ($left >= $right_edge) {
                $left = $right_edge;
                next;
            }
        }
        #print "in quadrant4, $hs $row $left $right_mark\n";

        if ($right_mark < $right_edge) {
            for ($right = $right_mark; $right <= $right_edge; $right++) {
                last if !$self->_Q_path($hs*$right, $row);
            }
            --$right;
        }
        else { $right = $right_edge; }
        #print "in quadrant5, $hs $row $left $right_mark\n";
        if ($left <= $right) {
            if ($left == $right && $left == 0 && !$self->_clear($hs,$row) &&
                   ($left != $rail)) {
                $right = 1;
            }

            if ($right > $rail) { $right = $rail }

            for (my $i = $left; $i <= $right; $i++) {
                $self->_see($hs*$i,$row);
            }

            $self->_quadrant($hs, $row + ($row <=> 0),$left,$right);
            $left = $right + 1;
        }
        #print "in quadrant6, $hs $row $left $right_mark\n";
    }
}

sub _trace {
    my $self = shift;

    my ($xl, $xr) = (0, 0);

    $self->_see(0,0);

    #for my $i (-2 .. 2) { print ($self->_clear($i,0) ? "1" : "0"); }
    #print "\n";

    do { $self->_see(--$xl,0) } while $self->_clear($xl,0);
    do { $self->_see(++$xr,0) } while $self->_clear($xr,0);

    # Triple yuck
    $xr-- if $xr + $self->{x} == 80;
    $xl++ if $xl + $self->{x} < 0;

    #print "$xl $xr\n";

    $self->_quadrant(-1,-1,0,-$xl);
    $self->_quadrant(+1,-1,0,$xr);
    $self->_quadrant(-1,+1,0,-$xl);
    $self->_quadrant(+1,+1,0,$xr);
}

# not handled: swimming, phasing
# possibly buggy: everything
sub calculate_fov {
    my ($startx, $starty, $cb, $cbo) = @_;

    my @visible;

    my $self = bless { x => $startx, y => $starty, cbi => $cb, cbo => $cbo };

    $self->{cbo} ||= sub { my ($x, $y) = @_;
        $visible[$x][$y] = 1 unless $x < 0 || $y < 0; };

    $self->_trace();

    return \@visible;
}

1;

=head1 NAME

NetHack::FOV - NetHack compatible field of view

=head1 SYNOPSIS

  use NetHack::FOV 'calculate_fov';

  my $AoA = calculate_fov($x, $y, \&transparent);

=head1 DESCRIPTION

This package implements field of view (the determination, for every
square on the map simultaneously, of whether it is visible to the
avatar), in a NetHack compatible way.  It is expected to be primarily
useful to bot writers.

=head1 FUNCTION

NetHack::FOV defines and allows import of a single function.

=over 4

=item B<calculate_fov STARTX, STARTY, INCALLBACK, [OUTCALLBACK]>

STARTX and STARTY determine the location of the avatar on the integer
plane used by FOV::NetHack.  INCALLBACK is used to determine the map's
local structure; it is passed two arguments, X and Y coordinates, and
must return true iff the specified point is transparent.  OUTCALLBACK
is used to return the viewable map, one coordinate pair at a time as
for INCALLBACK.  OUTCALLBACK is optional; if you omit it, calculate_fov
will return an array of arrays such that $ret[$x][$y] will be true
iff ($x,$y) is visible.

Obviously, calculate_fov will hang if passed a map which has lines of
sight with infinite length.  Also, if the visible part of the map
extends beyond the doubly non-negative quadrant, and you are using
the array of arrays return method, only the part which lies within
said quadrant will be returned.  Due to unusual boundary conditions
of the NetHack FOV algorithm, this module will misbehave if passed
data outside the range of 1 to 79 inclusive in the horizontal
dimension; no such restriction exists vertically.

You may be wondering why the callbacks exist at all and calculate_fov
doesn't just use arrays of arrays both ways.  The answer is asymptotic
complexity.  The algorithm used by calculate_fov takes time proportional
to the number of I<visible> tiles.  If an array of arrays had to be
constructed for the transparency data, any user would suffer time costs
proportional to the number of I<total> tiles.

=back

=head1 AUTHOR

Stefan O'Rear <stefanor@cox.net>

=head1 COPYRIGHT

Copyright 2008 Stefan O'Rear.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut


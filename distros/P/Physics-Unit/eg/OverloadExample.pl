#!/usr/bin/perl
use strict;
# overloaded interface example

# simple projectile motion simulation on different planets
use Physics::Unit::Scalar ':ALL';
@Physics::Unit::Scalar::type_context = ('Energy');      # we are working with energy i.e. Joules
$Physics::Unit::Scalar::format_string = "%.3f";         # provide a format string for output
my $m = GetScalar("1 Kg");                              # mass
my $u = GetScalar("1 meter per second");                # initial upward velocity
foreach my $body ( qw(mercury earth mars jupiter pluto) ) {
    my $a = GetScalar("-1 $body-gravity");              # e.g. "-1 earth-gravity" (-1 for direction vector)
    my $t = GetScalar("0 seconds");                     # start at t = 0s
    print "On " . ucfirst($body) . ":\n";               # so we know which planet we're on
    while ( $t < 3.5 ) {                                # simulate for a few seconds
        my $s = $u * $t + (1/2) * $a * $t**2;           # 'suvat' equations
        my $v = $u + $a * $t;
        my $KE = (1/2) * $m * $v**2;                    # kinetic energy
        my $PE = $m * -1 * $a * $s;                     # potential energy, again -1 for direction
        my $TE = $KE + $PE;                             # total energy (should be constant)
        # display with units
        print "At $t: dist = $s;\tvel = $v;\tKE = $KE;\tPE = $PE;\tTotal energy = $TE\n";
        $t += 0.1;                                      # increment timestep
    }
}


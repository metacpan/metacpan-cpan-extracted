package GnipTest;

use strict;
use Test::More;

=head1 NAME

GnipTest - useful testing functions 

=head1 METHODS 

=head2 plan_tests <tests>

Check for certain environment variables and then plan tests.

=cut

sub plan_tests {
    my $tests = shift;
    my @vars  = map { "GNIP_TEST_${_}" } qw(USERNAME PASSWORD PUBLISHER);
    my $found = 1;
    $found  &&= defined $ENV{$_} for @vars;
    if (!$found) {
        plan skip_all => "You must define the environment variables ".join(", ", @vars);
    } else {
        plan tests => $tests;
    }  
}

1;

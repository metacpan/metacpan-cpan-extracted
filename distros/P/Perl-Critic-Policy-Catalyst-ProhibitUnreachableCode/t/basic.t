#!/usr/bin/env perl
use 5.008001;
use strict;
use warnings;
use Test2::V0;

use Perl::Critic;

my @tests = (
    [Good          => 1],
    [BadContext    => 0],
    [BadController => 0],
);

foreach my $test (@tests) {
    my ($package, $expected_ok) = @$test;

    my $file = "t/$package.pm";
    my $critic = Perl::Critic->new(
        '-single-policy' => 'Catalyst::ProhibitUnreachableCode',
    );
    $critic->add_policy(
        '-policy' => 'Catalyst::ProhibitUnreachableCode',
        '-params' => { controller_methods => 'foo_and_detach' },
    );
    my @violations = $critic->critique($file);

    if ($expected_ok) {
        ok(
            (@violations == 0),
            "$package should NOT violate",
        );

        diag "VIOLATION: $_" for @violations;
    }
    else {
        ok(
            (@violations > 0),
            "$package should violate",
        );

        #diag "VIOLATION: $_" for @violations;
    }
}

done_testing;

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :

#!/usr/bin/env perl

use v5.10;

use strict;
use warnings;

use Test::More;
use OTRS::OPM::Maker::Utils::Git;

my @tests = (
    [ '3.3.1', '3.3.1', '' ],
    [ '3.3.1', '3.3.2', 1 ],
    [ '3.3.1', '3.3.0', '' ],
    [ '3.3.1', '5.0.1', 1 ],
);

for my $test ( @tests ) {
    my ($old, $new, $check) = @{ $test || [] };

    my $result = OTRS::OPM::Maker::Utils::Git::_check_version(
        old_version => $old,
        new_version => $new,
    );

    is $result, $check, "$old <-> $new";
}

done_testing();

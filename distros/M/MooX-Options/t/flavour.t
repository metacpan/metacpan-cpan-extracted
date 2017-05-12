#!/usr/bin/env perl
#
# This file is part of MooX-Options
#
# This software is copyright (c) 2013 by celogeek <me@celogeek.com>.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#

use t::Test;
use Test::Trap;
use Carp;
use FindBin qw/$RealBin/;
use Try::Tiny;

local $ENV{TEST_FORCE_COLUMN_SIZE} = 78;

{

    package plain;
    use Moo;
    use MooX::Options protect_argv => 0;

    option 'bool' => ( is => 'ro' );

    1;
}
{

    package plain2;
    use Moo;
    use MooX::Options protect_argv => 0, flavour => undef;

    option 'bool' => ( is => 'ro' );

    1;
}

{

    package FlavourTest;
    use Moo;
    use MooX::Options flavour => [qw(pass_through)], protect_argv => 0;

    option 'bool' => ( is => 'ro' );

    1;
}

for my $noflavour (qw/plain plain2/) {
    subtest "unknown option $noflavour" => sub {
        note "Without flavour $noflavour";
        {
            local @ARGV = ('anarg');
            my $plain = $noflavour->new_with_options();
            is_deeply( [@ARGV], ['anarg'], "anarg is left" );
        }
        {
            local @ARGV = ( '--bool', 'anarg' );
            my $plain = $noflavour->new_with_options();
            is( $plain->bool, 1, "bool was set" );
            is_deeply( [@ARGV], ['anarg'], "anarg is left" );
        }
        {
            local @ARGV = ( '--bool', 'anarg', '--unknown_option' );
            my @r = trap { $noflavour->new_with_options() };
            is( $trap->exit, 1, "exit code ok" );
            like(
                $trap->stderr,
                qr/Unknown option: unknown_option/,
                "and a warning from GLD"
            );
            like( $trap->stderr, qr/USAGE:/, "died with usage message" );
        }
    };
}

subtest "flavour" => sub {
    note "With flavour";
    {
        local @ARGV = ('anarg');
        my $flavour_test = FlavourTest->new_with_options();
        is_deeply( [@ARGV], ['anarg'], "anarg is left" );
    }
    {
        local @ARGV = ( '--bool', 'anarg' );
        my $flavour_test = FlavourTest->new_with_options();
        is( $flavour_test->bool, 1, "bool was set" );
        is_deeply( [@ARGV], ['anarg'], "anarg is left" );
    }
    {
        local @ARGV = ( '--bool', 'anarg', '--unknown_option' );
        my $flavour_test = FlavourTest->new_with_options();
        is( $flavour_test->bool, 1, "bool was set" );
        is_deeply(
            [@ARGV],
            [ 'anarg', '--unknown_option' ],
            "anarg and unknown_option are left"
        );
    }
};

done_testing;

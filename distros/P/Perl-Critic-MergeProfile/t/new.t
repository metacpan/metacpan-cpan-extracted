#!perl

use 5.006;
use strict;
use warnings;

use Test::More 0.88;

use Perl::Critic::MergeProfile;

main();

sub main {

    my $class = 'Perl::Critic::MergeProfile';

    {
        my $obj = $class->new();
        isa_ok( $obj, $class, "new() returns a $class object" );

        is_deeply( [ keys %{$obj} ], [], '... with no attributes' );
    }

    #
    done_testing();

    exit 0;
}

# vim: ts=4 sts=4 sw=4 et: syntax=perl

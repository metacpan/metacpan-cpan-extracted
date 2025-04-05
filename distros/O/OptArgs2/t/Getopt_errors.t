#!perl
use strict;
use warnings;
use OptArgs2;
use Test2::V0;

@ARGV = ( '--range', 'a' );

isa_ok(
    dies {
        optargs(
            comment => 'script to paint things',
            optargs => [
                range => {
                    isa     => '--HashRef',
                    comment => 'the item to paint',
                },
            ],
        );
    },
    'OptArgs2::Usage::GetOptError'
);

done_testing;

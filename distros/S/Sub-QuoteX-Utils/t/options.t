#! perl

use strict;
use warnings;

use Test2::Bundle::Extended;
use Sub::Quote qw[ quote_sub ];
use Sub::QuoteX::Utils qw[ quote_subs ];

# test transmission of options through quote_subs to quote_sub


sub stash_caller {

    my $stash = shift || [];

    @$stash = caller( 0 );
}

subtest context => sub {

    #######################################
    # KEEP THESE HERE.

    # If these are moved around, Perl will sometimes flip the
    # HINTS_BLOCK_SCOPE_BIT in $^H, which causes the context seen by
    # the compiled code to change, causing the test to fail.

    # Don't ask me why mixing these declarations in with the code
    # does that.  I dunno.

    my @fiducial;
    my @chunk;
    my @snippet;

    #######################################


    quote_sub(
        dragon => q[main::stash_caller( $stash);],
        { '$stash' => \\@fiducial, } )->();

    quote_subs( [
            'main::stash_caller( $stash );',
            capture => { '$stash' => \\@chunk },
        ]
	      )->();

    is( [ @chunk[ 8, 9 ] ], [ @fiducial[ 8, 9 ] ], "chunk" );

    quote_subs(
        \' main::stash_caller( $stash );',
        {
            capture => { '$stash' => \\@snippet },
        },
    )->();

    is( [ @snippet[ 8, 9 ] ], [ @fiducial[ 8, 9 ] ], "snippet" );

};

subtest name => sub {

    my @fiducial;
    my @chunk;

    quote_sub(
        dragon => q[main::stash_caller( $stash);],
        { '$stash' => \\@fiducial, },
        { package  => 'Snap' } )->();

    quote_subs( [
            'main::stash_caller( $stash );',
            capture => { '$stash' => \\@chunk },
        ],
        {
            package => 'Snap',
            name    => 'dragon'
        },
    )->();

    is( [ @chunk[ 8, 9 ] ], [ @fiducial[ 8, 9 ] ], "specify package" );

    quote_sub(
        dragon => q[main::stash_caller( $stash);],
        { '$stash' => \\@fiducial, },
        )->();

    quote_subs( [
            'main::stash_caller( $stash );',
            capture => { '$stash' => \\@chunk },
        ],
        {
            name    => 'dragon'
        },
    )->();

    is( [ @chunk[ 8, 9 ] ], [ @fiducial[ 8, 9 ] ], "don't specify package" );

};

done_testing;

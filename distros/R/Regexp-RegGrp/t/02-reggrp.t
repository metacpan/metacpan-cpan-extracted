#!perl -T

use Test::More;

SKIP: {
    my $not = 1;

    eval( 'use Regexp::RegGrp::Data' );
    skip( 'Regexp::RegGrp::Data not installed!', $not ) if ( $@ );

    eval( 'use Regexp::RegGrp' );
    skip( 'Regexp::RegGrp not installed!', $not ) if ( $@ );

    plan tests => $not;

    my $reggrp = Regexp::RegGrp->new();

    ok( ! $reggrp, 'Regexp::RegGrp->new() without args' );
}
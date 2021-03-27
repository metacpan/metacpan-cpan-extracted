# -*- perl -*-

use strict;
use warnings;

use Test::More qw( no_plan );

use Nice::Try;

{
    my $i = 0;
    try
    {
        $i++;
        die( "First exception\n" );
    }
    catch( $e )
    {
        is( "$e", "First exception", 'First try-catch block error value' );
    }
    is( $i, 1, 'First try-catch block variable check' );
    
    try
    {
        $i++;
        die( "Second exception\n" );
    }
    catch( $e2 )
    {
        is( "$e2", "Second exception", 'Second try-catch block error value' );
    }
    is( $i, 2, 'Second try-catch block variable check' );
}

done_testing;

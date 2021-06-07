# -*- perl -*-
use strict;
use warnings;
use Test::More qw( no_plan );
use Nice::Try;

subtest 'consecutive blocks' => sub
{
    my $i = 0;
    my $j = 0;
    try
    {
        $i++;
        die( "First exception\n" );
    }
    catch( $e )
    {
        is( "$e", "First exception", 'First try-catch block error value' );
    }
    try
    {
        $j++;
        die( "Second exception\n" );
    }
    catch( $e2 )
    {
        is( "$e2", "Second exception", 'Second try-catch block error value' );
    }
    is( $i, 1, 'First try-catch block variable check' );
    is( $j, 1, 'Second try-catch block variable check' );
};

subtest 'insignificants elements after' => sub
{
    my $i = 0;
    my $j = 0;
    ok(eval
    {
        try { $i++ } catch { }
        try { $j++ } catch { }
        my $foo = sub { };
    }, 'consecutive unrelated block');
    is( $i, 1, 'first try-catch blocks' );
    is( $j, 1, 'second try-catch blocks' );
};

done_testing;

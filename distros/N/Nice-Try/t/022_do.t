#!/usr/bin/perl
BEGIN
{
    use strict;
    use warnings;
    use Test::More qw( no_plan );
    use Nice::Try;
};

subtest 'do implicit return value in try' => sub
{
    my $name = do
    {
        ok( !wantarray(), 'void context' );
        try
        {
            "John";
        }
        catch( $e )
        {
            "Peter";
        }
    };
    is( $name, 'John', 'do { try } in scalar context' );

    my @names = do
    {
        ok( !wantarray(), 'void context' );
        try
        {
            ( qw( John Paul Peter ) );
        }
        catch( $e )
        {
            ( qw( Gabriel Emmanuel Samuel ) );
        }
    };
    is_deeply( \@names, [qw( John Paul Peter )], 'do { try } in list context' );
};

subtest 'do implicit return value in catch' => sub
{
    my $name = do
    {
        try
        {
            die( "Oh no!\n" );
        }
        catch( $e )
        {
            "Peter";
        }
    };
    is( $name, "Peter", 'do { try/catch } in scalar context' );

    my @names = do
    {
        try
        {
            die( "Oh no!\n" );
        }
        catch( $e )
        {
            ( qw( Gabriel Emmanuel Samuel ) );
        }
    };
    is_deeply( \@names, [qw( Gabriel Emmanuel Samuel )], 'do { try/catch } in list context' );
};

done_testing();


# -*- perl -*-
BEGIN
{
    use strict;
    use warnings;
    use Test::More qw( no_plan );
    use Nice::Try;
    our $DEBUG = 0;
};

{
    my @info = &callme();
    diag( "Called from package $info[0] in file $info[1] at line $info[2]" ) if( $DEBUG );
    is( $info[2], __LINE__ - 2, 'caller' );
    is( [&catchme()]->[2], __LINE__, 'caller in catch' );
    &catchme_finally( __LINE__ );
    is( &tellme(), __LINE__, 'caller outside of try-catch block' );
    is( [&callme2()]->[2], __LINE__, 'caller(2)' );
    &catchme_finally2( __LINE__ );
    is( [&call_global()]->[2], __LINE__, 'caller global' );
    done_testing;
}

sub callme
{
    my $n = shift( @_ ) // 1;
    try
    {
        my @info = caller($n);
        return( @info );
    }
    catch( $e )
    {
        print( "Oops, got an error: $e\n" );
    }
}

sub catchme
{
    try
    {
        die( "Argh..." );
    }
    catch( $e )
    {
        print( "Oops, got an error: $e\n" );
        my @info = CORE::caller;
        # diag( "Returning: $info[2]" );
        return( @info );
    }
}

sub catchme_finally
{
    my $line = shift( @_ );
    my $n = shift( @_ );
    try
    {
        die( "Argh..." );
    }
    catch( $e )
    {
        print( "Oops, got an error: $e\n" );
    }
    finally
    {
        my @info = defined( $n ) ? CORE::caller( $n ) : CORE::caller;
        is( $info[2], $line, 'caller in finally' . ( defined( $n ) ? " -> $n" : '' ) );
    }
}

sub callme2 { return( &callme(2) ) }

sub catchme_finally2 { return( &catchme_finally( shift( @_ ), 2 ) ); }

sub call_global
{
    try
    {
        return( CORE::GLOBAL::caller );
    }
    catch( $e )
    {
        print( "Oops, got an error: $e\n" );
    }
}

sub tellme
{
    return( [caller()]->[2] );
}

__END__


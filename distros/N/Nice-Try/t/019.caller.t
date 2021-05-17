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
    is( $info[2], 12, 'caller' );
    done_testing;
}

sub callme
{
    try
    {
        my @info = caller(1);
        return( @info );
    }
    catch( $e )
    {
        print( "Oops, got an error: $e\n" );
    }
}

__END__


# -*- perl -*-
BEGIN
{
    use strict;
    use warnings;
    use Test::More qw( no_plan );
    use Nice::Try;
    # use Nice::Try debug => 6, debug_file => './dev/debug_snail.pl', debug_code => 1;
};

# Credits to Steve Scaffidi for his test suit

# try gets @_
{
    my @args;
    ( sub {
        try { @args = @_ }
        catch {}
    } )->( 1, 2, 3 );

    is_deeply( \@args, [ 1, 2, 3 ], 'try{} sees surrounding @_' );
}

# catch sees @_
{
    my @args;
    ( sub {
        try { die "oopsie" }
        catch { @args = @_ }
    } )->( 4, 5, 6 );

    is_deeply( \@args, [ 4, 5, 6 ], 'catch{} sees @_' );
}

done_testing;

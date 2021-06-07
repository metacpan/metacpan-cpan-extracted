# -*- perl -*-
BEGIN
{
    use strict;
    use warnings;
    use Config;
    # Config->import;
    if( $Config{useithreads} )
    {
        require threads;
        # "Because of its global effect, this setting should not be used inside modules or the like."
        # threads->import qw( exit threads_only );
        threads->import;
        require threads::shared;
        threads::shared->import;
    }
    use constant THREADED => $Config{useithreads};
    use Test::More qw( no_plan );
    use Nice::Try;
    use Want;
    our $DEBUG = 0;
};

SKIP:
{
    diag( "perl is not threaded." ) if( !THREADED && $DEBUG );
    skip( 'Your perl is not threaded.', 1 ) if( !THREADED );
    $SIG{SEGV} = sub
    {
        # stdout->print( "Caught a segmentation fault!\n" );
        fail( 'Nice::Try is not thread safe' );
        exit(1);
    };
    my $tid = threads->create(sub
    {
        &tryme();
        sub tryme
        {
            # If this is uncommented, under thread this will trigger a segmentation fault, 
            # most likely because wantarray thinks the callers expects a scalar in return
            # while in reality, the caller is calling tryme() in void context
            # This issue does not produce if we use 'forks' instead of 'threads'
#             my $expect = Want::want( 'LIST' )
#                 ? 'LIST'
#                 : Want::want( 'HASH' )
#                     ? 'HASH'
#                     : Want::want( 'ARRAY' )
#                         ? 'ARRAY'
#                         : Want::want( 'OBJECT' )
#                             ? 'OBJECT'
#                             : Want::want( 'CODE' )
#                                 ? 'CODE'
#                                 : Want::want( 'REFSCALAR' )
#                                     ? 'REFSCALAR'
#                                     : Want::want( 'BOOLEAN' )
#                                         ? 'BOOLEAN'
#                                         : Want::want( 'GLOB' )
#                                             ? 'GLOB'
#                                             : Want::want( 'SCALAR' )
#                                                 ? 'SCALAR'
#                                                 : Want::want( 'VOID' )
#                                                     ? 'VOID'
#                                                     : '';
            # diag( "Caller expects '$expect'" ) if( $DEBUG );
            try
            {
                my $want = wantarray;
                diag( "Caller wants ", ( defined( $want ) ? $want ? 'list' : 'scalar' : 'void' ) ) if( $DEBUG );
                return( "Hello world" );
            }
            catch( $e )
            {
                stderr->print( "Oopsie daisy: $e\n" );
            }
        }
    });
    ok( $tid, 'Nice::Try is thread safe' );
    $tid->join;
};
done_testing;

__END__


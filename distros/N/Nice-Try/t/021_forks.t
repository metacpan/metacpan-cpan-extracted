# -*- perl -*-
BEGIN
{
    use strict;
    use warnings;
    use vars qw( $has_forks );
    our $has_forks = 0;
    if( $INC{'forks.pm'} )
    {
        $has_forks++;
        require forks;
        forks->import;
        require constant;
        constant->import( 'HAS_FORKS', $has_forks );
    }
    else
    {
        eval( 'require forks;' );
        if( !$@ )
        {
            $has_forks++;
            forks->import;
            constant->import( 'HAS_FORKS', $has_forks );
        }
    }
    use Test::More qw( no_plan );
    use Nice::Try;
    use Want;
    our $DEBUG = 0;
};

SKIP:
{
    diag( "forks emulating perl threads is not installed." ) if( !HAS_FORKS && $DEBUG );
    skip( 'forks emulating perl threads is not installed.', 1 ) if( !HAS_FORKS || !$INC{'forks.pm'} || !threads->can( 'create' ) );
    $SIG{SEGV} = sub
    {
        # stdout->print( "Caught a segmentation fault!\n" );
        fail( 'Nice::Try is not working under forks (threads emulation)' );
        exit(1);
    };
    my $tid = threads->create(sub
    {
        &tryme();
        sub tryme
        {
            my $expect = Want::want( 'LIST' )
                ? 'LIST'
                : Want::want( 'HASH' )
                    ? 'HASH'
                    : Want::want( 'ARRAY' )
                        ? 'ARRAY'
                        : Want::want( 'OBJECT' )
                            ? 'OBJECT'
                            : Want::want( 'CODE' )
                                ? 'CODE'
                                : Want::want( 'REFSCALAR' )
                                    ? 'REFSCALAR'
                                    : Want::want( 'BOOLEAN' )
                                        ? 'BOOLEAN'
                                        : Want::want( 'GLOB' )
                                            ? 'GLOB'
                                            : Want::want( 'SCALAR' )
                                                ? 'SCALAR'
                                                : Want::want( 'VOID' )
                                                    ? 'VOID'
                                                    : '';
            diag( "Caller expects '$expect'" ) if( $DEBUG );
            try
            {
                my $want = wantarray;
                diag( "Caller wants ", ( defined( $want ) ? $want ? 'list' : 'scalar' : 'void' ) ) if( $DEBUG );
                if( Want::want('LIST') )
                {
                    return( qw( Hello world ) );
                }
                else
                {
                    return( "Hello world" );
                }
            }
            catch( $e )
            {
                stderr->print( "Oopsie daisy: $e\n" );
            }
        }
    });
    ok( $tid, 'Nice::Try works under forks (threads emulation)' );
    $tid->join;
}

done_testing;

__END__


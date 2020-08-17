#!/usr/local/bin/perl
BEGIN
{
    use strict;
};

sub run_tests
{
    my $tests = shift( @_ );
    my $opts  = {};
    $opts = shift( @_ ) if( ref( $_[0] ) eq 'HASH' );
    for( my $i = 0; $i < scalar( @$tests ); $i++ )
    {
        my $expect = $tests->[$i];
        my $test = delete( $expect->{test} );
        my $name = delete( $expect->{name} );
        if( $test =~ /$opts->{re}/g )
        {
            my $re = { %+ };
            my $ok;
            foreach my $k ( keys( %$expect ) )
            {
                if( exists( $+{ $k } ) &&
                    $+{ $k } eq $expect->{ $k } )
                {
                    $ok++;
                }
                else
                {
                    diag( "Test No ", $i + 1, ( length( $name ) ? " ($name)" : '' ), ": key $k failed to match \"$expect->{$k}\"" ) if( $opts->{debug} );
                    $ok = 0, last;
                }
            }
            ok( $ok, sprintf( "$opts->{type} test No %d%s", $i + 1, ( length( $name ) ? " ($name)" : '' ) ) );
        }
        elsif( $expect->{fail} )
        {
            pass( sprintf( "$opts->{type} test No %d%s", $i + 1, ( length( $name ) ? " ($name)" : '' ) ) );
        }
        else
        {
            fail( sprintf( "$opts->{type} test No %d%s", $i + 1, ( length( $name ) ? " ($name)" : '' ) ) );
        }
    }
}

sub dump_tests
{
    my $tests = shift( @_ );
    eval
    {
        require Data::Dump;
    };
    return if( $@ );
    my $opts  = {};
    $opts = shift( @_ ) if( ref( $_[0] ) eq 'HASH' );
    for( my $i = 0; $i < scalar( @$tests ); $i++ )
    {
        my $expect = $tests->[$i];
        my $test = $expect->{test};
        my $name = $expect->{name};
        printf( "Checking test %d%s\n", $i + 1, ( length( $name ) ? " ($name)" : '' ) );
        
        if( $test =~ /$opts->{re}/g )
        {
            # print( "Yes, it works\n" );
            my $re = { %+ };
            $re->{test} = $test;
            $re->{name} = $name if( length( $name ) );
            # print( "bold_all => $+{bold_all}\nbold_type => $+{bold_type}\nbold_text => $+{bold_text}\n" );
            print( Data::Dump::dump( $re ), ",\n\n" );
        }
        else
        {
            print( "Test ", $i + 1, ( length( $name ) ? " ($name)" : '' ), " failed: '$test'\n\n" );
        }
    }
}

1;

__END__


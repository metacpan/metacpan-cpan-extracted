#!/usr/local/bin/perl
BEGIN
{
    use strict;
    use warnings;
};

sub run_tests
{
    my $tests = shift( @_ );
    # no warnings qw( experimental::vlb );
    my $opts  = {};
    $opts = shift( @_ ) if( ref( $_[0] ) eq 'HASH' );
    use re 'eval';
    for( my $i = 0; $i < scalar( @$tests ); $i++ )
    {
        my $expect = $tests->[$i];
        my $test = delete( $expect->{test} );
        my $name = delete( $expect->{name} );
        if( $test =~ /^$opts->{re}$/g )
        {
            my $re = { %+ };
            my $ok;
            $ok++ if( !scalar( keys( %$expect ) ) );
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
    use re 'eval';
    my $opts  = {};
    $opts = shift( @_ ) if( ref( $_[0] ) eq 'HASH' );
    my $total = scalar( @$tests );
    my $ok = 0;
    my $all = [];
    for( my $i = 0; $i < scalar( @$tests ); $i++ )
    {
        my $expect = $tests->[$i];
        my $test = $expect->{test};
        my $name = $expect->{name};
        printf( "Checking test %d%s\n", $i + 1, ( length( $name ) ? " ($name)" : '' ) );
        
        if( $test =~ /^$opts->{re}$/g )
        {
            # print( "Yes, it works\n" );
            my $re = { %+ };
            $re->{test} = $test;
            $re->{name} = $name if( length( $name ) );
            $ok++;
            # print( "bold_all => $+{bold_all}\nbold_type => $+{bold_type}\nbold_text => $+{bold_text}\n" );
            push( @$all, $re );
            ## print( Data::Dump::dump( $re ), ",\n\n" );
        }
        else
        {
            $ok++ if( $expect->{fail} );
            print( "Test ", $i + 1, ( length( $name ) ? " ($name)" : '' ), " failed (", $expect->{fail} ? 'expected' : 'unexpected', "): '$test'\n\n" );
        }
    }
    if( $ok == $total )
    {
        printf( STDERR "All tests ok\n" );
        foreach my $ref ( @$all )
        {
            print( ( ' ' x 4 ), "\{\n" );
            foreach my $k ( sort( keys( %$ref ) ) )
            {
                printf( "%s%-15s => q{%s},\n", ( ' ' x 8 ), $k, $ref->{ $k } );
            }
            print( ( ' ' x 4 ), "\},\n" );
        }
    }
    else
    {
        printf( STDERR "Failed %d (%.2f%%) test(s) out of $total\n", ( $total - $ok ), ( ( ( $total - $ok ) / $total ) * 100 ) );
    }
}

1;

__END__


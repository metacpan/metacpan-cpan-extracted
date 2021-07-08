#! perl

use Test2::V0;

use PGPLOT::Device;

# empty prefix, interactive device
{
    my $dev = PGPLOT::Device->new( '/xs' );
    is( $dev->next, "/xs", "/inter" );
}

# autoincrement empty prefix, interactive device
{
    my $dev = PGPLOT::Device->new( '+/xs' );
    is( $dev->next, "1/xs", "+/inter" );
}

# fixed specific dev value
{
    my $dev = PGPLOT::Device->new( '2/xs' );
    ok( "2/xs" eq $dev->next && "2/xs" eq $dev->next, "N/inter" );
}

# auto increment and specific dev value
{
    my $dev = PGPLOT::Device->new( '+2/xs' );
    ok( "2/xs" eq $dev->next && "3/xs" eq $dev->next, "+N/inter" );
}

# bogus interactive prefix
like(
    dies {
        PGPLOT::Device->new( 'bogus/xs' )
    },
    qr{error: interactive device with unparseable prefix},
    'bogus interactive device'
);


# interpolate with globals
{
    our $theta = 3;
    our $phi   = 4;

    my $dev
      = PGPLOT::Device->new( 'try_${devn}_${theta:%0.2f}_${phi:%02d}/png' );

    is( $dev->next, "try_1_3.00_04.png/png", 'global interpolation' );
}

# interpolate with passed hash
{
    my %vars = (
        theta => 3,
        phi   => 2
    );

    my $dev = PGPLOT::Device->new( 'try_${devn}_${theta:%0.2f}_${phi:%02d}/png',
        { vars => \%vars } );

    $vars{phi} = 4;

    is( $dev->next, "try_1_3.00_04.png/png", 'hash interpolation' );
}

# true const value
{
    my $dev = PGPLOT::Device->new( '2/xs' );
    ok( $dev->is_const, "const is true" );
}

# false const value
{
    my $dev = PGPLOT::Device->new( '+2/xs' );
    ok( !$dev->is_const, "const is false" );
}

# interactive
{
    for my $dv ( qw{ /xs /xw } ) {
        my $dev = PGPLOT::Device->new( $dv );
        ok( $dev->is_interactive, "interactive: $dv" );
    }

    for my $dv ( qw{ /cps /png } ) {
        my $dev = PGPLOT::Device->new( $dv );
        ok( !$dev->is_interactive, "not interactive: $dv" );
    }

}


# can't override an interactive device
{
    my $dev = PGPLOT::Device->new( '/xs' );

    $dev->override( "foo.ps" );
    is( $dev->next, '/xs', "override interactive" );
}

# can override a non-interactive device if no initial prefix
{
    my $dev = PGPLOT::Device->new( '/ps' );

    $dev->override( "boo" );
    is( $dev->next, 'boo.ps/ps', "override non-interactive no prefix" );
}

# cannot override a non-interactive device if an initial prefix
{
    my $dev = PGPLOT::Device->new( 'foo/ps' );

    $dev->override( "boo" );
    is( $dev->next, 'foo.ps/ps',
        "non-interactive w/ init prefix: can't override" );

    ok( !$dev->would_change,
        "non-interactive w/ init prefix: wouldn't change" );
}


# allow overrides with multi-component paths
{
    my $dev = PGPLOT::Device->new( '/cps' );

    $dev->override( "boo/foo" );
    is( $dev->next, 'boo/foo.ps/cps', "multi-component path" );
}

# check that overrides don't mess up devinfo (bug fix)
{
    my $dev = PGPLOT::Device->new( '/cps' );

    # testing ask is (currently) a good way of doing things
    ok( defined $dev->ask, "devinfo initial" );

    $dev->override( "boo/foo" );
    ok( defined $dev->ask, "devinfo after override" );
}


# ensure that information for default device is fully populated
{
    my $dev = PGPLOT::Device->new();
    ok( $dev->is_interactive, "default device devinfo" );
}

done_testing;

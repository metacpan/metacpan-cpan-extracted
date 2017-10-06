use Test::More;

BEGIN{
    BAIL_OUT "A bug in Perl 5.20 regex compilation prevents the use of PPR under that release"
        if $] > 5.020 && $] < 5.022;
}

BEGIN {
    use_ok( 'PPR' );
}

plan tests => 1;

diag( "Testing PPR $PPR::VERSION" );

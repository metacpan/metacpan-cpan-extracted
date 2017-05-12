use strict;
use Test::More tests => 15;

BEGIN {
    use_ok( 'Pod::Extract::URI' );
}

my $peu = Pod::Extract::URI->new();

$peu->L_only( 2 );
is( $peu->L_only, 2 );

$peu->want_textblock( 2 );
is( $peu->want_textblock, 2 );

$peu->want_verbatim( 2 );
is( $peu->want_verbatim, 2 );

$peu->want_command( 2 );
is( $peu->want_command, 2 );

{
    my $warning = "";
    local $SIG{ __WARN__ } = sub {
        $warning = shift;
    };

    $peu->schemes( [ 'foo' ] );
    is_deeply( $peu->schemes, [ 'foo' ] );

    $peu->schemes( 'foo' );
    ok( $warning =~ /^\QArgument to schemes() must be an arrayref\E/ );

    $peu->exclude_schemes( [ 'bar' ] );
    is_deeply( $peu->exclude_schemes, [ 'bar' ] );

    $peu->exclude_schemes( 'foo' );
    ok( $warning =~ /^\QArgument to exclude_schemes() must be an arrayref\E/ );

    $peu->stop_uris( [ qr/foo/, 'bar' ] );
    is_deeply( $peu->stop_uris, [ qr/foo/, qr/bar/ ] );

    $peu->stop_uris( 'foo' );
    ok( $warning =~ /^\QArgument to stop_uris() must be an arrayref\E/ );

    $peu->stop_sub( sub { return 'qwerty' } );
    is( $peu->_check_stop_sub, 'qwerty' );

    $peu->stop_sub( 'foo' );
    ok( $warning =~ /^\QArgument to stop_sub() must be a coderef\E/ );
}

$peu->use_canonical( 2 );
is( $peu->use_canonical, 2 );

$peu->strip_brackets( 2 );
is( $peu->strip_brackets, 2 );

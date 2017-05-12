use strict;
use Test::More tests => 24;

BEGIN {
    use_ok( 'Pod::Extract::URI' );
}

# test defaults
my $peu = Pod::Extract::URI->new();
is( $peu->L_only, 0 );
is( $peu->want_textblock, 1 );
is( $peu->want_verbatim, 1 );
is( $peu->want_command, 1 );
is_deeply( $peu->schemes, [] );
is_deeply( $peu->exclude_schemes, [] );
is_deeply( $peu->stop_uris, [] );
is( $peu->_check_stop_sub, 0 );
is( $peu->use_canonical, 0 );
is( $peu->strip_brackets, 1 );
is( ref $peu->_finder, "URI::Find" );

# test overriding
$peu = Pod::Extract::URI->new(
    L_only => 1,
    want_textblock => 0,
    want_verbatim => 0,
    want_command => 0,
    schemes => [ 'http' ],
    exclude_schemes => [ 'https' ],
    stop_uris => [ 'foo' ],
    stop_sub => sub { return 1 },
    use_canonical => 1,
    strip_brackets => 0,
    schemeless => 1,
);
is( $peu->L_only, 1 );
is( $peu->want_textblock, 0 );
is( $peu->want_verbatim, 0 );
is( $peu->want_command, 0 );
is_deeply( $peu->schemes, [ 'http' ] );
is_deeply( $peu->exclude_schemes, [ 'https' ] );
is_deeply( $peu->stop_uris, [ qr/foo/ ] );
is( $peu->_check_stop_sub, 1 );
is( $peu->use_canonical, 1 );
is( $peu->strip_brackets, 0 );
is( ref $peu->_finder, "URI::Find::Schemeless" );

# test pass-through to Pod::Parser
$peu = Pod::Extract::URI->new( FOO => 'BAR' );
is ( $peu->{ FOO }, 'BAR' );

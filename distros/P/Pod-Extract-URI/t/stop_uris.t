use strict;
use Test::More tests => 4;

BEGIN {
    use_ok( 'Pod::Extract::URI' );
}

my $peu = Pod::Extract::URI->new(
    stop_uris => [ 'example.com' ]
);
my @uris = $peu->uris_from_file( 't/pod/stop_uris.pod' );
is_deeply( \@uris, [
    'https://www.foobar.com/',
    'http://www.google.com/'
] );

$peu = Pod::Extract::URI->new(
    stop_uris => [ 'example.com/' ],
    use_canonical => 0,
);
@uris = $peu->uris_from_file( 't/pod/stop_uris_canonical.pod' );
is_deeply( \@uris, [
    'http://www.example.com:80/'
] );

$peu = Pod::Extract::URI->new(
    stop_uris => [ 'example.com/' ],
    use_canonical => 1,
);
@uris = $peu->uris_from_file( 't/pod/stop_uris_canonical.pod' );
is_deeply( \@uris, [ ] );

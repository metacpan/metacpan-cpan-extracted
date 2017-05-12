use strict;
use Test::More tests => 5;

BEGIN {
    use_ok( 'Pod::Extract::URI' );
}

my $peu = Pod::Extract::URI->new();
my @uris = $peu->uris_from_file( 't/pod/schemes.pod' );
is ( scalar @uris, 4, "No schemes - get all" );

$peu = Pod::Extract::URI->new(
    schemes => [ 'http', 'ftp' ],
);
@uris = $peu->uris_from_file( 't/pod/schemes.pod' );
is_deeply ( \@uris, [
    'http://www.example.com/',
    'ftp://www.example.com/'
], "Schemes - get right URIs" );

$peu = Pod::Extract::URI->new(
    exclude_schemes => [ 'http', 'ftp' ],
);
@uris = $peu->uris_from_file( 't/pod/schemes.pod' );
is_deeply ( \@uris, [
    'https://www.example.com/',
    'mailto:joe@example.com'
], "Exclude - get right URIs" );

$peu = Pod::Extract::URI->new(
    schemes => [ 'http', 'ftp' ],
    exclude_schemes => [ 'mailto', 'ftp' ],
);
@uris = $peu->uris_from_file( 't/pod/schemes.pod' );
is_deeply ( \@uris, [
    'http://www.example.com/',
], "Schemes & exclude schemes - get right URIs" );


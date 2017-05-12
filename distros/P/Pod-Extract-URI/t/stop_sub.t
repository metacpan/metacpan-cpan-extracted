use strict;
use Test::More tests => 8;

BEGIN {
    use_ok( 'Pod::Extract::URI' );
}

my $peu = Pod::Extract::URI->new(
    stop_sub => sub {
        my $uri = shift;
        return ( $uri->host =~ /example\.com/ ) ? 1 : 0;
    }
);
my @uris = $peu->uris_from_file( 't/pod/stop_sub.pod' );
is_deeply( \@uris, [
    'http://www.google.com/search?q=example.com'
] );

$peu = Pod::Extract::URI->new(
    stop_sub => sub {
        my ( $uri, $text, $p ) = @_;
        is ( ref $uri, "URI::URL" );
        ok ( $text eq "http://www.example.com/" || $text eq "http://www.google.com/search?q=example.com" );
        is ( ref $p, "Pod::Extract::URI" );
    }
);
$peu->parse_from_file( 't/pod/stop_sub.pod' );

use Test::Most tests => 5;
use ok( 'Search::Sitemap::URL' );
use DateTime;

my $url = Search::Sitemap::URL->new();

time_test(
    'epoch time 1',
    '1133128421',
    '2005-11-27T21:53:41+00:00'
);
time_test(
    'ISO8601 1',
    '2005-11-27T21:55:51+00:00',
    '2005-11-27T21:55:51+00:00'
);
url_elt_test(
    'entities 1',
    'http://www.example.com/view?widget=3&count>2',
    qr{\Qhttp://www.example.com/view?widget=3&amp;count\E(?i:&gt;|%3e)2},
);

my $dt1 = DateTime->from_epoch( epoch => 1133128421 );
time_test( 'DateTime 1', $dt1, '2005-11-27T21:53:41+00:00' );

sub time_test {
    my($id,$from,$to) = @_;
    my $url = Search::Sitemap::URL->new(
        loc     => 'http://www.example.com/',
        lastmod => $from,
    );
    is( $url->lastmod, $to, "lastmod check: $id" );
}

sub url_elt_test {
    my ( $id, $from, $to ) = @_;
    my $url = Search::Sitemap::URL->new( loc => $from );
    $url->as_elt->sprint =~ m#<loc>(.*)</loc>#s;
    like( $1, $to, "loc check: $id" );
}

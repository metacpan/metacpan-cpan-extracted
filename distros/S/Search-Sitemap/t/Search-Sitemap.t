use Test::Most tests => 18;

use_ok( 'Search::Sitemap' );

use File::Copy;

my $baseurl = "http://www.jasonkohles.com/software/search-sitemap";

my $map;
ok( $map = Search::Sitemap->new( pretty => 'indented' ),
    " object created"
);
isa_ok( $map => 'Search::Sitemap' );
ok( $map->add( Search::Sitemap::URL->new(
    loc         => "$baseurl/test1",
    lastmod     => '2005-06-03',
    changefreq  => 'daily',
    priority    => 1,
) ), "url as Search::Sitemap::URL object added" );
ok( $map->add(
    loc         => "$baseurl/test2",
    lastmod     => '2005-07-11',
    changefreq  => 'weekly',
    priority    => 0.1,
), "url from hash added" );
ok( $map->add(
    loc         => "$baseurl/test2?foo=1&bar=2&baz=3>2",
    lastmod     => '2005-07-11',
    changefreq  => 'weekly',
    priority    => 0.1,
), "url with query string added" );

ok( $map->write( 'test.xml' ) );
unlink 'test.xml';


my $map2;
ok( $map2 = Search::Sitemap->new( pretty => 'indented' ),
    " object created"
);
isa_ok( $map2 => 'Search::Sitemap' );
copy('t/sitemap.xml', 't/sitemap-test.xml');
for ( 1 .. 3 ) {
    ok $map2->read( "t/sitemap-test.xml" ), "read sitemap (iter $_)";
    ok $map2->add( loc => 'http://www.example.com/'. time() ),
        "new url added";
    ok $map2->write( "t/sitemap-test.xml" ), "sitemap written";
    sleep 1;
}
unlink 't/sitemap-test.xml';


#eval "use XML::LibXML";
#my $HAVE_libxml = $XML::LibXML::VERSION;
#SKIP: {
#    skip "Need XML::LibXML for these tests", 1 unless $HAVE_libxml;
#    eval {
#        my $parser = XML::LibXML->new;
#        $parser->validation(1);
#        $parser->parse_file('test.xml');
#    };
#    ok(!$@,"test.xml validated with XML::LibXML");
#};

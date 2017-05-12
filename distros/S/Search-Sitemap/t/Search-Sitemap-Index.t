use Test::Most tests => 17;
die_on_fail;

use ok( 'Search::Sitemap::Index' );

my $baseurl = "http://www.example.com";

my $index;
ok( $index = Search::Sitemap::Index->new( pretty => 'indented' ),
    "object created"
);
isa_ok( $index => 'Search::Sitemap::Index' );
ok( $index->add( Search::Sitemap::URL->new(
    loc         => "$baseurl/test-sitemap-1.gz",
    lastmod     => '2005-06-03',
) ), "sitemap as Search::Sitemap::URL added" );
ok( $index->add(
    loc         => "$baseurl/test-sitemap-2.gz",
    lastmod     => '2005-07-11',
), "sitemap as hash added" );

ok( $index->write( 'test-sitemap.xml' .( $index->have_zlib ? '.gz' : '') ),
    "sitemap index written"
);
unlink( 'test-sitemap.xml' .( $index->have_zlib ? '.gz' : '') );

my $index2;
ok( $index2 = Search::Sitemap::Index->new( pretty => 'indented' ),
    "object created"
);
ok $index2->read('t/sitemap-index.xml'), "read plain sitemap index";
isa_ok( $index2 => 'Search::Sitemap::Index' );
ok( $index2->add( Search::Sitemap::URL->new(
    loc         => "$baseurl/test-sitemap-1.gz",
    lastmod     => '2005-06-03',
) ), "sitemap as Search::Sitemap::URL added" );
ok( $index2->add(
    loc         => "$baseurl/test-sitemap-2.gz",
    lastmod     => '2005-07-11',
), "sitemap as hash added" );

ok( $index2->write( 'test-sitemap.xml' .( $index2->have_zlib ? '.gz' : '') ),
    "sitemap index written"
);
unlink( 'test-sitemap.xml' .( $index2->have_zlib ? '.gz' : '') );

SKIP: {
    my $index3 = Search::Sitemap::Index->new( pretty => 'indented' );
    skip "IO::Zlib not available", 5
        unless $index3->have_zlib;
    ok $index3->read('t/sitemap-index.xml.gz'), "read compressed sitemap index";
    isa_ok( $index3 => 'Search::Sitemap::Index' );
    ok( $index3->add( Search::Sitemap::URL->new(
        loc         => "$baseurl/test-sitemap-1.gz",
        lastmod     => '2005-06-03',
    ) ), "sitemap as Search::Sitemap::URL added" );
    ok( $index3->add(
        loc         => "$baseurl/test-sitemap-2.gz",
        lastmod     => '2005-07-11',
    ), "sitemap as hash added" );

    ok( $index3->write( 'test-sitemap.xml' .( $index->have_zlib ? '.gz' : '') ),
        "sitemap index written"
    );
    unlink( 'test-sitemap.xml' .( $index3->have_zlib ? '.gz' : '') );
}

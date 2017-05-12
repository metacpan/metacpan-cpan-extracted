use strict;
use OpenGuides;
use OpenGuides::Test;
use Test::More;

eval { require DBD::SQLite; };
if ( $@ ) {
    my ($error) = $@ =~ /^(.*?)\n/;
    plan skip_all => "DBD::SQLite not available ($error)";
}

eval { require Test::HTML::Content; };
if ( $@ ) {
    plan skip_all => "Test::HTML::Content not available";
}

plan tests => 8;

OpenGuides::Test::refresh_db();

my $config = OpenGuides::Test->make_basic_config;
$config->use_leaflet( 1 );
$config->script_url( "http://wiki.example.com/" );
$config->script_name( "mywiki.cgi" );
my $guide = OpenGuides->new( config => $config );
my $wiki = $guide->wiki;

# Write a node and give it a category and locale.
OpenGuides::Test->write_data( guide => $guide, node => "Dog And Bull",
    summary => "A pub.", categories => "Pubs", locales => "Croydon", node_image => "http://example.com/image.jpg",
    return_output => 1 );

OpenGuides::Test->write_data( guide => $guide, node => "Royal Standard",
    summary => "A pub.", categories => "Pubs", locales => "Croydon",
    return_output => 1 );


my $output;

eval {
  $output = $guide->display_node( id             => 'Dog And Bull',
    return_output  => 1,
    noheaders      => 1
  );
};

# Test that a page outputs the the required OpenGraph meta tags.
Test::HTML::Content::tag_ok( $output, "meta", { property => "og:title", content => "Dog And Bull" }, "has og:title meta tag" );
Test::HTML::Content::tag_ok( $output, "meta", { property => "og:type", content => "article" }, "has og:type meta tag" );
Test::HTML::Content::tag_ok( $output, "meta", { property => "og:image", content => "http://example.com/image.jpg" }, "has og:url meta tag" );
Test::HTML::Content::tag_ok( $output, "meta", { property => "og:url", content => "http://wiki.example.com/mywiki.cgi?Dog_And_Bull" }, "has og:url meta tag" );


eval {
  $output = $guide->display_node( id             => 'Royal Standard',
    return_output  => 1,
    noheaders      => 1
  );
};

# Test that a page with no image does no output OpenGraph meta tags since an image is required.
Test::HTML::Content::no_tag( $output, "meta", { property => "og:title" }, "has no og:title meta tag" );
Test::HTML::Content::no_tag( $output, "meta", { property => "og:type" }, "has no og:type meta tag" );
Test::HTML::Content::no_tag( $output, "meta", { property => "og:image" }, "has no og:url meta tag" );
Test::HTML::Content::no_tag( $output, "meta", { property => "og:url" }, "has no og:url meta tag" );

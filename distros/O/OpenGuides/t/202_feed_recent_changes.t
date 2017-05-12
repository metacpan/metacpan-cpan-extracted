use strict;
use Wiki::Toolkit::Setup::SQLite;
use OpenGuides::Config;
use OpenGuides;
use OpenGuides::Feed;
use OpenGuides::Test;
use OpenGuides::Utils;
use Test::More;

eval { require DBD::SQLite; };
if ( $@ ) {
    my ($error) = $@ =~ /^(.*?)\n/;
    plan skip_all => "DBD::SQLite could not be used - no database to test with. ($error)";
}

eval { require Wiki::Toolkit::Search::Plucene; };
if ( $@ ) {
    plan skip_all => "Plucene not installed";
}


# Which feed types do we test?
my @feed_types = qw( rss atom );
plan tests => 12 * scalar @feed_types;

my %content_types = (rss=>'application/rdf+xml', atom=>'application/atom+xml');

foreach my $feed_type (@feed_types) {
    # Clear out the database from any previous runs.
    OpenGuides::Test::refresh_db();

    my $config = OpenGuides::Test->make_basic_config;
    $config->script_name( "wiki.cgi" );
    $config->script_url( "http://example.com/" );
    $config->http_charset( "UTF-7" );

    # Basic sanity check first.
    my $wiki = OpenGuides::Utils->make_wiki_object( config => $config );

    my $feed = OpenGuides::Feed->new( wiki   => $wiki,
                                      config => $config );
    is( $feed->default_content_type($feed_type), $content_types{$feed_type}, "Return the right content type" );

    like( $feed->html_equiv_link, qr|http://example.com/wiki.cgi\?|,
          "html_equiv_link looks right" );

    my $feed_output = eval { $feed->make_feed(feed_type => $feed_type, feed_listing => 'recent_changes'); };
    is( $@, "", "->make_feed for $feed_type doesn't croak" );

    # Ensure that the feed actually contained rss/atom (a good guide
    #  that we actually got the right feed)
    like( $feed_output, "/$feed_type/i", "Does contain the feed type" );

    # Check the XML
    like( $feed_output, qr/<?xml version="1.0" encoding="UTF-7"/, "Right XML type and encoding" );

    # Now write some data, first a minor edit then a non-minor one.
    my $guide = OpenGuides->new( config => $config );

    OpenGuides::Test->write_data(
                                  node          => "Wombats",
                                  guide         => $guide,
                                  username      => "bob",
                                  edit_type     => "Minor tidying",
                                  return_output => 1,
                                );
    OpenGuides::Test->write_data(
                                  node          => "Badgers",
                                  guide         => $guide,
                                  username      => "bob",
                                  edit_type     => "Normal edit",
                                  return_output => 1,
                                );
    OpenGuides::Test->write_data(
                                  node          => "Wombles",
                                  guide         => $guide,
                                  username      => "Kake",
                                  edit_type     => "Normal edit",
                                  return_output => 1,
                                );

    # Check that the writes went in.
    ok( $wiki->node_exists( "Wombats" ), "Wombats written" );
    ok( $wiki->node_exists( "Badgers" ), "Badgers written" );
    ok( $wiki->node_exists( "Wombles" ), "Wombles written" );

    # Check that the minor edits can be filtered out.
    my $output = $guide->display_feed(
                                       feed_type          => $feed_type,
                                       feed_listing       => "recent_changes",
                                       items              => 5,
                                       username           => "bob",
                                       ignore_minor_edits => 1,
                                       return_output      => 1,
                                     );
    unlike( $output, qr/Wombats/, "minor edits filtered out when required" );
    like( $output, qr/Badgers/, "but normal edits still in" );

    # Check that the username parameter is taken notice of.
    unlike( $output, qr/Wombles/, "username parameter taken note of" );

    # Now make sure that the HTTP euiv link still works with a blank scriptname
    $config->script_name( "" );
    $wiki = OpenGuides::Utils->make_wiki_object( config => $config );

    $feed = OpenGuides::Feed->new( wiki   => $wiki,
                                   config => $config );
    like( $feed->html_equiv_link, qr|http://example.com/\?|,
          "html_equiv_link looks right with blank script_name" );
}

use strict;
use Wiki::Toolkit::Setup::SQLite;
use OpenGuides::Config;
use OpenGuides;
use OpenGuides::Feed;
use OpenGuides::Utils;
use OpenGuides::Test;
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
plan tests => 14 * scalar @feed_types;


foreach my $feed_type (@feed_types) {
    # Clear out the database from any previous runs.
    OpenGuides::Test::refresh_db();

    my $config = OpenGuides::Config->new(
           vars => {
                     dbtype             => "sqlite",
                     dbname             => "t/node.db",
                     indexing_directory => "t/indexes",
                     script_name        => "wiki.cgi",
                     script_url         => "http://example.com/",
                     site_name          => "Test Site",
                     template_path      => "./templates",
                     home_name          => "Home",
                     use_plucene        => 1,
                     http_charset       => "UTF-8"
                   }
    );

    # Basic sanity check first.
    my $wiki = OpenGuides::Utils->make_wiki_object( config => $config );

    my $feed = OpenGuides::Feed->new( wiki   => $wiki,
                                      config => $config );

    my $feed_output = eval { $feed->make_feed(feed_type => $feed_type, feed_listing => 'recent_changes'); };
    is( $@, "", "->make_feed for $feed_type doesn't croak" );

    # Ensure that the feed actually contained rss/atom (a good guide
    #  that we actually got the right feed)
    like( $feed_output, "/$feed_type/i", "Does contain the feed type" );


    # Now write some data: 3 versions of one node, and 1 of another
    my $guide = OpenGuides->new( config => $config );

    # Set up CGI parameters ready for a node write.
    # Most of these are in here to avoid uninitialised value warnings.
    my $q = CGI->new;
    $q->param( -name => "content", -value => "foo" );
    $q->param( -name => "categories", -value => "" );
    $q->param( -name => "locales", -value => "" );
    $q->param( -name => "phone", -value => "" );
    $q->param( -name => "fax", -value => "" );
    $q->param( -name => "website", -value => "" );
    $q->param( -name => "hours_text", -value => "" );
    $q->param( -name => "address", -value => "" );
    $q->param( -name => "postcode", -value => "" );
    $q->param( -name => "map_link", -value => "" );
    $q->param( -name => "os_x", -value => "" );
    $q->param( -name => "os_y", -value => "" );
    $q->param( -name => "username", -value => "bob" );
    $q->param( -name => "comment", -value => "foo" );
    $q->param( -name => "edit_type", -value => "Minor tidying" );
    $ENV{REMOTE_ADDR} = "127.0.0.1";

    # First version of Wombats
    my $output = $guide->commit_node(
                                      return_output => 1,
                                      id => "Wombats",
                                      cgi_obj => $q,
                                    );
    my %node = $wiki->retrieve_node(name=>"Wombats");

    # Now second and third
    $q->param( -name => "edit_type", -value => "Normal edit" );
    $q->param( -name => "checksum", -value => $node{"checksum"} );
    $output = $guide->commit_node(
                                      return_output => 1,
                                      id => "Wombats",
                                      cgi_obj => $q,
                                    );

    %node = $wiki->retrieve_node(name=>"Wombats");
    $q->param( -name => "username", -value => "Kake" );
    $q->param( -name => "checksum", -value => $node{"checksum"} );
    $output = $guide->commit_node(
                                      return_output => 1,
                                      id => "Wombats",
                                      cgi_obj => $q,
                                    );

    # Now a different node
    $q->delete('checksum');
    $output = $guide->commit_node(
                                   return_output => 1,
                                   id => "Badgers",
                                   cgi_obj => $q,
                                 );

    # Check that the writes went in.
    ok( $wiki->node_exists( "Wombats" ), "Wombats written" );
    ok( $wiki->node_exists( "Badgers" ), "Badgers written" );
    is( scalar $wiki->list_node_all_versions("Wombats"), 3, "3 Wombat versions");
    is( scalar $wiki->list_node_all_versions("Badgers"), 1, "1 Badger version");

    # Fetch for Badgers
    $output = $guide->display_feed(
                                   return_output      => 1,
                                   feed_type          => $feed_type,
                                   feed_listing       => "node_all_versions",
                                   name               => "Badgers"
                                 );
    unlike( $output, qr/<title>Wombats/, "Was on Badgers, so no wombats" );
    like( $output, qr/<title>Badgers/, "Badgers correctly found" );

    # Now for Wombats
    $output = $guide->display_feed(
                                   return_output      => 1,
                                   feed_type          => $feed_type,
                                   feed_listing       => "node_all_versions",
                                   name               => "Wombats"
                                 );
    unlike( $output, qr/<title>Badgers/, "Was on Wombats, so no badgers" );
    like( $output, qr/<title>Wombats/, "Wombats correctly found" );

    my @wombats = $output =~ /(<title>Wombats)/g;
    is( scalar @wombats, 3, "All 3 wombat versions found" );

    # Check the content type and charset
    like( $output, qr/Content-Type: /, "Has content type" );
    like( $output, qr/$feed_type/, "Which is the right one" );
    like( $output, qr/charset=UTF-8/, "And a charset" );
}

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
plan tests => 17 * scalar @feed_types;


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



    # Grab a list of all the nodes
    my @all_names = $wiki->list_all_nodes();
    my @all_nodes;
    foreach my $name (@all_names) {
        my %node = $wiki->retrieve_node(name=>$name);
        $node{name} = $name;
        push @all_nodes,  \%node;
    }

    # Ask build_feed_for_nodes to make a feed of these
    $output = $feed->build_feed_for_nodes($feed_type,@all_nodes);

    like( $output, qr/<title>Wombats/, "Found wombats" );
    like( $output, qr/<title>Badgers/, "Found badgers" );

    # Check it had the extra metadata
    if($feed_type eq "rss") {
        like( $output, qr/<dc:date>/, "Found metadata" );
        like( $output, qr/<modwiki:diff>/, "Found metadata" );
        like( $output, qr/<modwiki:version>/, "Found metadata" );
    } else {
        like( $output, qr/<updated>/, "Found metadata" );
        like( $output, qr/<summary>/, "Found metadata" );
        like( $output, qr/<author>/, "Found metadata" );
    }


    # Grab a list of the different versions of Wombats
    my @wombats = $wiki->list_node_all_versions("Wombats");

    # Ask build_mini_feed_for_nodes to make a mini feed of these
    $output = $feed->build_mini_feed_for_nodes($feed_type,@wombats);

    like( $output, qr/<title>Wombats/, "Wombats had wombats" );
    unlike( $output, qr/<title>Badgers/, "Wombats didn't have Badgers" );

    @wombats = $output =~ /(<title>Wombats)/g;
    is( scalar @wombats, 3, "All 3 wombat versions found" );

    # Check it was really the mini version

    if($feed_type eq "rss") {
        like( $output, qr/<link>/, "Has link" );
        unlike( $output, qr/<dc:contributor>/, "Really mini version" );
        unlike( $output, qr/<modwiki:history>/, "Really mini version" );
    } else {
        like( $output, qr/<link href=/, "Has link" );
        unlike( $output, qr/<summary>/, "Really mini version" );
        unlike( $output, qr/<author>/, "Really mini version" );
    }
}

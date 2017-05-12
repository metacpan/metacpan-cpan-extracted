use strict;
use Wiki::Toolkit::Setup::SQLite;
use OpenGuides;
use OpenGuides::Test;
use Test::More;

eval { require DBD::SQLite; };

if ( $@ ) {
    my ($error) = $@ =~ /^(.*?)\n/;
    plan skip_all => "DBD::SQLite could not be used - no database to test with ($error)";
}

plan tests => 19;

    OpenGuides::Test::refresh_db();

my $config = OpenGuides::Test->make_basic_config;
$config->script_name( "wiki.cgi" );
$config->script_url( "http://example.com/" );
my $guide = OpenGuides->new( config => $config );
isa_ok( $guide, "OpenGuides" );
my $wiki = $guide->wiki;
isa_ok( $wiki, "Wiki::Toolkit" );



# Add a page
my $q = CGI->new;
$q->param( -name => "content", -value => "foo" );
$q->param( -name => "categories", -value => "Alpha" );
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

my $output = $guide->commit_node(
                                  return_output => 1,
                                  id => "Wombats",
                                  cgi_obj => $q,
                                );

# Check it's moderated
my %details = $wiki->retrieve_node("Wombats");
is($details{'moderated'}, 1, "Moderated");
is($wiki->node_required_moderation("Wombats"), 0, "No moderation");

# Turn on moderation
$wiki->set_node_moderation(
                            name => "Wombats",
                            required => 1,
);
is($wiki->node_required_moderation("Wombats"), 1, "Moderation");


# Now add a new one, with new categories and locales
$q->param( -name => "categories", -value => "Alpha\r\nBeta" );
$q->param( -name => "locales", -value => "Hello" );
$q->param( -name => "edit_type", -value => "Normal edit" );
$q->param( -name => "checksum", -value => $details{checksum} );
$output = $guide->commit_node(
                                  return_output => 1,
                                  id => "Wombats",
                                  cgi_obj => $q,
                                );

# Check that the current version is still 1
%details = $wiki->retrieve_node("Wombats");
is($details{'version'}, 1, "Still on v1");
is($details{'moderated'}, 1, "v1 Moderated");

# Check that version 2 isn't moderated
my %v2 = $wiki->retrieve_node(name=>"Wombats",version=>2);
is($v2{'version'}, 2, "Is v2");
is($v2{'moderated'}, 0, "Not moderated");

# Check that the new categories and locales aren't there
is(1, $wiki->node_exists("Category Alpha"), "Right Categories");
is(0, $wiki->node_exists("Category Beta"), "Right Categories");
is(0, $wiki->node_exists("Locale Hello"), "Right Locales");


# Moderate
$guide->moderate_node(
                        id       => "Wombats",
                        version  => 2,
                        password => $guide->config->admin_pass
);


# Check that the current version is 2
%details = $wiki->retrieve_node(name=>"Wombats");
is($details{'version'}, 2, "Is v2");
is($details{'moderated'}, 1, "Moderated");

# Check that version 2 is moderated
%v2 = $wiki->retrieve_node(name=>"Wombats",version=>2);
is($v2{'version'}, 2, "Is v2");
is($v2{'moderated'}, 1, "Moderated");

# Check that the new categories and locales exist
is(1, $wiki->node_exists("Category Alpha"), "Right Categories");
is(1, $wiki->node_exists("Category Beta"), "Right Categories");
is(1, $wiki->node_exists("Locale Hello"), "Right Locales");

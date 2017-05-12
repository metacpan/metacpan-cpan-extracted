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


plan tests => 7;

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
                 use_plucene        => 1
               }
);

# Basic sanity check first.
my $wiki = OpenGuides::Utils->make_wiki_object( config => $config );

my $feed = OpenGuides::Feed->new( wiki   => $wiki,
                                  config => $config );


# Write the first version
my $guide = OpenGuides->new( config => $config );

# Set up CGI parameters ready for a node write.
my $q = OpenGuides::Test->make_cgi_object(
    content => "foo",
    username => "bob",
    comment => "foo",
    node_image => "image",
    edit_type => "Minor tidying"
);

my $output = $guide->commit_node(
                                  return_output => 1,
                                  id => "Wombats",
                                  cgi_obj => $q,
                                );

# Check we have it
ok( $wiki->node_exists( "Wombats" ), "Wombats written" );

my %node = $wiki->retrieve_node("Wombats");
is( $node{version}, 1, "First version" );
is( $node{metadata}->{edit_type}[0], "Minor tidying", "Right edit type" );


# Now write a second version of it
$q->param( -name => "edit_type", -value => "Normal edit" );
$q->param( -name => "checksum", -value => $node{checksum} );
$output = $guide->commit_node(
                               return_output => 1,
                               id => "Wombats",
                               cgi_obj => $q,
                             );

# Check it's as expected
%node = $wiki->retrieve_node("Wombats");
is( $node{version}, 2, "First version" );
is( $node{metadata}->{edit_type}[0], "Normal edit", "Right edit type" );

# Now try to commit some invalid data, and make sure we get an edit form back
$q = OpenGuides::Test->make_cgi_object(
    content => "foo",
    os_x => "fooooo",
    username => "bob",
    comment => "foo",
    node_image => "image",
    edit_type => "Minor tidying"
);

$output = $guide->commit_node(
                                return_output => 1,
                                id => "Wombats again",
                                cgi_obj => $q,
                             );

like( $output, qr/Your input was invalid/,
    "Edit form displayed and invalid input message shown if invalid input" );

like( $output, qr/os_x must be integer/,
    "Edit form displayed and os_x integer message displayed" );

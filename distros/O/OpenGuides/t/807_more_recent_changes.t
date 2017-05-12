use strict;
use Wiki::Toolkit::Setup::SQLite;
use OpenGuides::Config;
use OpenGuides;
use OpenGuides::Feed;
use OpenGuides::Utils;
use OpenGuides::Test;
use Test::More;
use OpenGuides::CGI;


eval { require DBD::SQLite; };
if ( $@ ) {
    my ($error) = $@ =~ /^(.*?)\n/;
    plan skip_all => "DBD::SQLite could not be used - no database to test with. ($error)";
}

eval { require Wiki::Toolkit::Search::Plucene; };
if ( $@ ) {
    plan skip_all => "Plucene not installed";
}


plan tests => 15;

# Clear out the database from any previous runs.
unlink "t/node.db";
unlink <t/indexes/*>;

Wiki::Toolkit::Setup::SQLite::setup( { dbname => "t/node.db" } );
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
    comment => "First edit",
    node_image => "image",
    edit_type => "Normal edit",
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

sleep(2);
# Now write a second version of it
$q->param( -name => "edit_type", -value => "Normal edit" );
$q->param( -name => "checksum", -value => $node{checksum} );
$q->param( -name => "comment", -value => "Second edit" );
$output = $guide->commit_node(
                               return_output => 1,
                               id => "Wombats",
                               cgi_obj => $q,
                             );

# Check it's as expected
%node = $wiki->retrieve_node("Wombats");
is( $node{version}, 2, "First version" );
is( $node{metadata}->{edit_type}[0], "Normal edit", "Right edit type" );

sleep(2);
# Now write a third version of it
$q->param( -name => "edit_type", -value => "Minor tidying" );
$q->param( -name => "checksum", -value => $node{checksum} );
$q->param( -name => "comment", -value => "Third edit" );
$output = $guide->commit_node(
                               return_output => 1,
                               id => "Wombats",
                               cgi_obj => $q,
                             );

# Check it's as expected
%node = $wiki->retrieve_node("Wombats");
is( $node{version}, 3, "Third version" );
is( $node{metadata}->{edit_type}[0], "Minor tidying", "Right edit type" );


my @nodes = $wiki->list_recent_changes( days => 1 );
    is( scalar @nodes, 1,
        "By default each node returned only once however many times changed" );
    @nodes = $wiki->list_recent_changes( days => 1, include_all_changes => 1 );
    is( scalar @nodes, 3,
        "...returned more than once when 'include_all_changes' set" );

# when minor_edits = 1

my $cookie = OpenGuides::CGI->make_prefs_cookie(
    config                     => $config,
    username                   => "bob",
    include_geocache_link      => 1,
    preview_above_edit_box     => 1,
    omit_help_links            => 1,
    show_minor_edits_in_rc     => 1,
    default_edit_type          => "tidying",
    cookie_expires             => "never",
    track_recent_changes_views => 1,
    is_admin => 1,
);

$output = $guide->display_recent_changes( return_output => 1 );

like( $output, qr/<td class="recentchanges_node_name"/,
      "expecting a table definition for an edit" );
like ($output, qr/Third edit/, "showing the most recent minor edit");
unlike ($output, qr/First edit/, "showing a page edit twice when show minor edits enabled. ");


# set show_minor_edits to 0.
$cookie = OpenGuides::CGI->make_prefs_cookie(
    config                     => $config,
    username                   => "bob",
    include_geocache_link      => 1,
    preview_above_edit_box     => 1,
    omit_help_links            => 1,
    show_minor_edits_in_rc     => 0,
    default_edit_type          => "tidying",
    cookie_expires             => "never",
    track_recent_changes_views => 1,
    is_admin => 1,
);
$ENV{HTTP_COOKIE} = $cookie;

$output = $guide->display_recent_changes( return_output => 1 );
like( $output, qr/<td class="recentchanges_node_name"/,
      "expecting a table definition for an edit" );
like ($output, qr/Second edit/, "expecting at least one edit");
unlike ($output, qr/First edit/, "showing a page edit twice when not showing minor edits");
unlike ($output, qr/Third edit/, "showing a page edit twice when not showing minor edits");

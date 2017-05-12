use strict;
use Wiki::Toolkit::Setup::SQLite;
use OpenGuides::Config;
use OpenGuides;
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


plan tests => 28;

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


my $guide = OpenGuides->new( config => $config );

# Generate 3 nodes
$guide->wiki->write_node( "Wombats","Wombats are cool",undef, { username => "bob", comment => "wombats rock", edit_type => "Normal edit" } ) or die "Can't write node";

$guide->wiki->write_node( "Armadillos","Armadillos are cool",undef, { username => "bob", comment => "Armadillos rock", edit_type => "Normal edit" } ) or die "Can't write node";

$guide->wiki->write_node( "Echidnas","Echidnas are cool",undef, { username => "bob", comment => "Echidnas rock", edit_type => "Normal edit" } ) or die "Can't write node";

#check they got created properly
my %node;

ok( $wiki->node_exists( "Wombats" ), "Wombats written" );

%node = $wiki->retrieve_node("Wombats");
is( $node{version}, 1, "First version" );

ok( $wiki->node_exists( "Armadillos" ), "Armadillos written" );

%node = $wiki->retrieve_node("Armadillos");
is( $node{version}, 1, "First version" );
ok( $wiki->node_exists( "Echidnas" ), "Echidnas written" );

%node = $wiki->retrieve_node("Echidnas");
is( $node{version}, 1, "First version" );

# Make them go back in time

my $dbh = DBI->connect("dbi:SQLite:dbname=t/node.db", "", "",
                    { RaiseError => 1, AutoCommit => 1 });

$dbh->do("update content set modified = datetime('now','-13 day') where node_id = 1");
$dbh->do("update node set modified = datetime('now','-13 day') where id = 1");
$dbh->do("update content set modified = datetime('now','-2 day') where node_id = 2");
$dbh->do("update node set modified = datetime('now','-2 day') where id = 2");
$dbh->do("update content set modified = datetime('now','-25 day') where node_id = 3");
$dbh->do("update node set modified = datetime('now','-25 day') where id = 3");

#check we only find 1 node in each time period
my @nodes;
@nodes = $wiki->list_recent_changes( between_days => [14, 30] );
    is( scalar @nodes, 1,
        "node edited between 14 to 30 days ago" );
@nodes = $wiki->list_recent_changes( between_days => [7, 14] );
    is( scalar @nodes, 1,
        "node edited between 7 to 14 days ago" );
@nodes = $wiki->list_recent_changes( between_days => [1, 6] );
    is( scalar @nodes, 1,
        "node edited between 1 to 7 days ago" );
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
my $output = $guide->display_recent_changes( return_output => 1 );

# check recent changes renders properly
unlike ($output, qr/24 hours/, "no pages changed in the last 24 hours");
like ($output, qr/last week/, "edits in the last week");
like ($output, qr/last fortnight/, "edits in the last fornight");
like ($output, qr/last 30 days/, "edits in the last 30 days");

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
# check recent changes renders properly
unlike ($output, qr/24 hours/, "no pages changed in the last 24 hours");
like ($output, qr/last week/, "edits in the last week");
like ($output, qr/last fortnight/, "edits in the last fornight");
like ($output, qr/last 30 days/, "edits in the last 30 days");

# make an extra edit now.
my %data = $wiki->retrieve_node( "Echidnas" );
$guide->wiki->write_node( "Echidnas","Echidnas are so cool", $data{checksum}, { username => "bob", comment => "Echidnas suck", edit_type => "Normal edit" } ) or die "Can't write node";
%node = $wiki->retrieve_node("Echidnas");
is( $node{version}, 2, "Second version" );
$output = $guide->display_recent_changes( return_output => 1 );
# check recent changes renders properly
like ($output, qr/24 hours/, "pages changed in the last 24 hours");
unlike ($output, qr/Echidnas rock/, "not showing multiple edits");
like ($output, qr/last week/, "edits in the last week");
like ($output, qr/last fortnight/, "edits in the last fornight");
unlike ($output, qr/last 30 days/, "no edits in the last 30 days");

$cookie = OpenGuides::CGI->make_prefs_cookie(
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
$ENV{HTTP_COOKIE} = $cookie;
$output = $guide->display_recent_changes( return_output => 1 );

# check recent changes renders properly
like ($output, qr/24 hours/, "pages changed in the last 24 hours");
unlike ($output, qr/Echidnas rock/, "not showing multiple edits");
like ($output, qr/last week/, "edits in the last week");
like ($output, qr/last fortnight/, "edits in the last fornight");
unlike ($output, qr/last 30 days/, "no edits in the last 30 days");

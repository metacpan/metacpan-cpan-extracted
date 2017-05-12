use strict;
use CGI;
use Wiki::Toolkit::Setup::SQLite;
use OpenGuides::Config;
use OpenGuides::CGI;
use OpenGuides;
use OpenGuides::Test;
use Test::More;

eval { require DBD::SQLite; };
if ( $@ ) {
    my ($error) = $@ =~ /^(.*?)\n/;
    plan skip_all => "DBD::SQLite could not be used - no database to test with ($error)";
}


plan tests => 4;

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
                 geo_handler        => 3, # Test w/ UTM - nat grids use X/Y
                 ellipsoid          => "Airy",
               }
);

# Plucene is the recommended searcher now.
eval { require Wiki::Toolkit::Search::Plucene; };
if ( $@ ) { $config->use_plucene( 0 ) };

my $guide = OpenGuides->new( config => $config );

# Set preferences to have lat/long displayed in deg/min/sec.
my $cookie = OpenGuides::CGI->make_prefs_cookie(
    config                     => $config,
    username                   => "Kake",
    include_geocache_link      => 1,
    preview_above_edit_box     => 1,
    latlong_traditional        => 1,  # this is the important bit
    omit_help_links            => 1,
    show_minor_edits_in_rc     => 1,
    default_edit_type          => "tidying",
    cookie_expires             => "never",
    track_recent_changes_views => 1,
);
$ENV{HTTP_COOKIE} = $cookie;

OpenGuides::Test->write_data(
                              guide      => $guide,
                              node       => "Test Page",
                              latitude   => 51.368,
                              longitude  => -0.0973,
                            );

my %data = $guide->wiki->retrieve_node( "Test Page" );
my $lat = $data{metadata}{latitude}[0];
unlike( $lat, qr/d/,
    "lat not stored in dms format even if prefs set to display that way" );

# Check the distance search form has unmunged lat/long.
my $output = $guide->display_node(
                                   return_output => 1,
                                   id => "Test Page",
                                 );
unlike( $output, qr/name="latitude"\svalue="[-0-9]*d/,
        "latitude in non-dms format in distance search form" );

# Now write a node with no location data, and check that it doesn't
# claim to have any when we display it.
eval {
    local $SIG{__WARN__} = sub { die $_[0]; };
    OpenGuides::Test->write_data(
                                  guide      => $guide,
                                  node       => "Locationless Page",
                                );
};
is( $@, "",
    "commit doesn't warn when prefs say dms format and node has no loc data" );

$output = $guide->display_node(
                                return_output => 1,
                                id => "Locationless Page",
                              );
unlike( $output, qr/latitude:/i,
        "node with no location data doesn't display a latitude" );

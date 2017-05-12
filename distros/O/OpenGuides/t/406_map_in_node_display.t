use strict;
use OpenGuides;
use OpenGuides::Test;
use Test::More;
use Wiki::Toolkit::Setup::SQLite;

eval { require DBD::SQLite; };
if ( $@ ) {
    plan skip_all => "DBD::SQLite not installed - no database to test with";
    exit 0;
}

eval { require Test::HTML::Content; };
if ( $@ ) {
    plan skip_all => "Test::HTML::Content not installed";
    exit 0;
}

plan tests => 10;

my ( $config, $guide, $wiki, $cookie, $output );

# Clear out the database from any previous runs.
    OpenGuides::Test::refresh_db();

# Make a guide.
$config = OpenGuides::Test->make_basic_config;
$guide = OpenGuides->new( config => $config );
$wiki = $guide->wiki;

# Write a node with location data.
OpenGuides::Test->write_data(
                              guide => $guide,
                              node  => "Red Lion",
                              os_x  => 530000,
                              os_y  => 180000,
                            );

# Maps shouldn't show up if there's no API key and we're not using Leaflet.
$config->show_gmap_in_node_display( 1 );
$config->use_leaflet( 0 );
$cookie = OpenGuides::CGI->make_prefs_cookie(
                                              config => $config,
                                              display_google_maps => 1,
                                            );
$ENV{HTTP_COOKIE} = $cookie;

$output = $guide->display_node(
                                id => "Red Lion",
                                return_output => 1,
                              );
$output =~ s/^Content-Type.*[\r\n]+//m;
Test::HTML::Content::no_tag( $output, "div", { id => "map" },
               "Map omitted from node if no API key and not using Leaflet" );

# And they should if there is a Google API key.
$config->gmaps_api_key( "This is not a real API key." );
$output = $guide->display_node(
                                id => "Red Lion",
                                return_output => 1,
                              );
$output =~ s/^Content-Type.*[\r\n]+//m;
Test::HTML::Content::tag_ok( $output, "div", { id => "map" },
                             "Map shown on node if we have a Google API key");

# But not if the user doesn't want them.
$cookie = OpenGuides::CGI->make_prefs_cookie(
                                              config => $config,
                                              display_google_maps => 0,
                                            );
$ENV{HTTP_COOKIE} = $cookie;
$output = $guide->display_node(
                                id => "Red Lion",
                                return_output => 1,
                              );
$output =~ s/^Content-Type.*[\r\n]+//m;
Test::HTML::Content::no_tag( $output, "div", { id => "map" },
                             "...but not if the user turned it off" );

# And not if the admin doesn't want them.
$config->show_gmap_in_node_display( 0 );
$cookie = OpenGuides::CGI->make_prefs_cookie(
                                              config => $config,
                                              display_google_maps => 1,
                                            );
$ENV{HTTP_COOKIE} = $cookie;
$output = $guide->display_node(
                                id => "Red Lion",
                                return_output => 1,
                              );
$output =~ s/^Content-Type.*[\r\n]+//m;
Test::HTML::Content::no_tag( $output, "div", { id => "map" },
                             "...and not if the admin turned it off" );

# Now test with Leaflet.
$cookie = OpenGuides::CGI->make_prefs_cookie(
                               config => $config, display_google_maps => 1 );
$ENV{HTTP_COOKIE} = $cookie;
$config->gmaps_api_key( "I still have a key but don't expect to use it" );
$config->show_gmap_in_node_display( 1 );
$config->use_leaflet( 1 );

# Shouldn't get any of the GMap stuff.
$output = $guide->display_node(
                                id => "Red Lion",
                                return_output => 1,
                              );
unlike( $output, qr|new GMap|,
        "No invocation of GMap constructor when using Leaflet" );
unlike ( $output, qr|new GPoint|, "...nor GPoint" );
unlike ( $output, qr|new GIcon|, "...nor GIcon" );

# Map should show in node if we're using Leaflet and have no GMap API key.
$config->gmaps_api_key( "" );
$output = $guide->display_node(
                                id => "Red Lion",
                                return_output => 1,
                              );
$output =~ s/^Content-Type.*[\r\n]+//m;
Test::HTML::Content::tag_ok( $output, "div", { id => "node_map_canvas" },
                             "Map shown on node if using Leaflet");

# But not if the user doesn't want them.
$cookie = OpenGuides::CGI->make_prefs_cookie(
                                              config => $config,
                                              display_google_maps => 0,
                                            );
$ENV{HTTP_COOKIE} = $cookie;
$output = $guide->display_node(
                                id => "Red Lion",
                                return_output => 1,
                              );
$output =~ s/^Content-Type.*[\r\n]+//m;
Test::HTML::Content::no_tag( $output, "div", { id => "map" },
                             "...but not if the user turned it off" );

# And not if the admin doesn't want them.
$config->show_gmap_in_node_display( 0 );
$cookie = OpenGuides::CGI->make_prefs_cookie(
                                              config => $config,
                                              display_google_maps => 1,
                                            );
$ENV{HTTP_COOKIE} = $cookie;
$output = $guide->display_node(
                                id => "Red Lion",
                                return_output => 1,
                              );
$output =~ s/^Content-Type.*[\r\n]+//m;
Test::HTML::Content::no_tag( $output, "div", { id => "map" },
                             "...and not if the admin turned it off" );

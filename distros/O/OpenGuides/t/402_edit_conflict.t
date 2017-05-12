use strict;
use OpenGuides;
use OpenGuides::Test;
use Test::More;
use Wiki::Toolkit::Setup::SQLite;

eval { require DBD::SQLite; };
if ( $@ ) {
    my ($error) = $@ =~ /^(.*?)\n/;
    plan skip_all => "DBD::SQLite could not be used - no database to test with ($error)";
}

eval { require Test::HTML::Content; };
if ( $@ ) {
    plan skip_all => "Test::HTML::Content not installed";
}

plan tests => 16;
# clear out database
    OpenGuides::Test::refresh_db();

# Make a guide that works on latitude/longitude, and allows node images.
my $config = OpenGuides::Test->make_basic_config;
$config->geo_handler( 3 );
$config->ellipsoid( "WGS-84" );
$config->enable_node_image( 1 );
my $guide = OpenGuides->new( config => $config );
my $wiki = $guide->wiki;



# Write some data.
OpenGuides::Test->write_data(
                              guide         => $guide,
                              node          => "Crabtree Tavern",
                              content       => "A pub.",
                              locales       => "W6",
                              categories    => "Pubs\r\nPub Food",
                              latitude      => 51.5,
                              longitude     => -0.05,
                            );

# Make sure the normal edit form doesn't think there's a conflict.
my $output = $guide->display_edit_form(
                                        id => "Crabtree Tavern",
                                        return_output => 1,
                                      );

# Strip Content-Type header to stop Test::HTML::Content getting confused.
$output =~ s/^Content-Type.*[\r\n]+//m;

Test::HTML::Content::no_tag( $output, "div", { class => "warning_text" },
                             "Normal edit form doesn't contain warning_text" );

# Now try to commit some edits without giving the checksum.
$output = OpenGuides::Test->write_data(
                                        guide         => $guide,
                                        node          => "Crabtree Tavern",
                                        content       => "Still a pub.",
                                        locales       => "Hammersmith",
                                        categories    => "Beer Garden",
                                        latitude      => 41.5,
                                        longitude     => -0.04,
                                        omit_checksum => 1,
                                        return_output => 1,
                                      );

# Strip Content-Type header to stop Test::HTML::Content getting confused.
$output =~ s/^Content-Type.*[\r\n]+//m;

Test::HTML::Content::tag_ok( $output, "div", { class => "warning_text" },
                             "Edit conflict form contains warning_text" );

like( $output, qr/A pub./s, "...and old content" );
like( $output, qr/Still a pub./s, "...and new content" );
like( $output, qr/W6/s, "...and old locales" );
like( $output, qr/Hammersmith/s, "...and new locales" );
like( $output, qr/Pubs/s, "...and old categories" );
like( $output, qr/Pub Food/s, "...both of them" );
like( $output, qr/Beer Garden/s, "...and new categories" );

# Bug #173 (edit conflict form doesn't let you edit everything).
Test::HTML::Content::tag_ok( $output, "input", { name => "node_image" },
                             "...and 'node_image' input box too" );

# Bug #48 (Edit conflict page erroneously converts lat/lon to os_x, os_y).
Test::HTML::Content::tag_ok( $output, "input", { name => "latitude" },
                             "UTM guide has 'latitude' input box in edit "
                             . "conflict" );
Test::HTML::Content::tag_ok( $output, "input", { name  => "latitude",
                                                 value => 51.5 },
                             "...with correct value" );
Test::HTML::Content::tag_ok( $output, "input", { name => "longitude" },
                             "...and 'longitude' input box too" );
Test::HTML::Content::tag_ok( $output, "input", { name  => "longitude",
                                                 value => -0.05 },
                             "...with correct value" );
like( $output, qr/41\.5/, "...new latitude is there too" );
like( $output, qr/-0\.04/, "...and new longitude" );

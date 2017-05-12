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

plan tests => 12;

# NB These tests don't actually test the placement - but they do test that
# we get at least one navbar where appropriate.  Better tests would be better.

my ( $config, $guide, $wiki, $cookie, $output );

# Clear out the database from any previous runs.
OpenGuides::Test::refresh_db();

# Make a guide.
$config = OpenGuides::Test->make_basic_config;
$guide = OpenGuides->new( config => $config );

# Write a node.
OpenGuides::Test->write_data(
                              guide => $guide,
                              node  => "Red Lion",
                            );

# Make sure navbar shows up on node display.
$output = display_node( "Red Lion" );
Test::HTML::Content::tag_ok( $output, "div", { id => "navbar" },
                             "navbar included on node display" );

$config->content_above_navbar_in_html( 0 );
$output = display_node( "Red Lion" );
Test::HTML::Content::tag_ok( $output, "div", { id => "navbar" },
                         "...ditto if content_above_navbar_in_html set to 0" );

$config->content_above_navbar_in_html( 1 );
$output = display_node( "Red Lion" );
Test::HTML::Content::tag_ok( $output, "div", { id => "navbar" },
                         "...ditto if content_above_navbar_in_html set to 1" );

# And on home node, if it's switched on.
$config = OpenGuides::Test->make_basic_config; # get a fresh config
$guide = OpenGuides->new( config => $config ); # make sure the guide sees it
$config->navbar_on_home_page( 1 );
$output = display_node( $config->home_name );
Test::HTML::Content::tag_ok( $output, "div", { id => "navbar" },
         "navbar included on home node when navbar_on_home_page switched on" );

$config->content_above_navbar_in_html( 0 );
$output = display_node( $config->home_name );
Test::HTML::Content::tag_ok( $output, "div", { id => "navbar" },
                         "...ditto if content_above_navbar_in_html set to 0" );

$config->content_above_navbar_in_html( 1 );
$output = display_node( $config->home_name );
Test::HTML::Content::tag_ok( $output, "div", { id => "navbar" },
                         "...ditto if content_above_navbar_in_html set to 1" );

# But not on home node, if it's switched off.
$config = OpenGuides::Test->make_basic_config; # get a fresh config
$guide = OpenGuides->new( config => $config ); # make sure the guide sees it
$config->navbar_on_home_page( 0 );
$output = display_node( $config->home_name );
Test::HTML::Content::no_tag( $output, "div", { id => "navbar" },
      "navbar excluded from home node when navbar_on_home_page switched off" );

$config->content_above_navbar_in_html( 0 );
$output = display_node( $config->home_name );
Test::HTML::Content::no_tag( $output, "div", { id => "navbar" },
                         "...ditto if content_above_navbar_in_html set to 0" );

$config->content_above_navbar_in_html( 1 );
$output = display_node( $config->home_name );
Test::HTML::Content::no_tag( $output, "div", { id => "navbar" },
                         "...ditto if content_above_navbar_in_html set to 1" );

# Make sure navbar appears on recent changes.
$config = OpenGuides::Test->make_basic_config; # get a fresh config
$guide = OpenGuides->new( config => $config ); # make sure the guide sees it
$output = $guide->display_recent_changes(
                                          return_output => 1,
                                        );
$output =~ s/^Content-Type.*[\r\n]+//m;
Test::HTML::Content::tag_ok( $output, "div", { id => "navbar" },
                             "navbar appears on recent changes" );

$config->content_above_navbar_in_html( 0 );
$output = $guide->display_recent_changes(
                                          return_output => 1,
                                        );
$output =~ s/^Content-Type.*[\r\n]+//m;
Test::HTML::Content::tag_ok( $output, "div", { id => "navbar" },
                         "...ditto if content_above_navbar_in_html set to 0" );

$config->content_above_navbar_in_html( 1 );
$output = $guide->display_recent_changes(
                                          return_output => 1,
                                        );
$output =~ s/^Content-Type.*[\r\n]+//m;
Test::HTML::Content::tag_ok( $output, "div", { id => "navbar" },
                         "...ditto if content_above_navbar_in_html set to 1" );

sub display_node {
  return $guide->display_node( id => shift,
                               return_output => 1,
                               noheaders => 1,
                             );
}

use strict;
use OpenGuides;
use OpenGuides::CGI;
use OpenGuides::Test;
use Test::More;

eval { require DBD::SQLite; };
if ( $@ ) {
    my ($error) = $@ =~ /^(.*?)\n/;
    plan skip_all =>
        "DBD::SQLite could not be used - no database to test with. ($error)";
}

eval { require Test::HTML::Content; };
if ( $@ ) {
    plan skip_all => "Test::HTML::Content not available.";
}

plan tests => 3;

# Clear out the database from any previous runs.
OpenGuides::Test::refresh_db();

my $config = OpenGuides::Test->make_basic_config;
my $guide = OpenGuides->new( config => $config );
my $wiki = $guide->wiki;

# Write a node.
OpenGuides::Test->write_data( guide => $guide, node => "Red Lion",
                              return_output => 1 );

# Display it, and make sure we get the openguides-base.css in there.
$config->static_url( "http://example.org/static/" );
my $output = $guide->display_node( id => "Red Lion", return_output => 1,
                                   noheaders => 1 );
Test::HTML::Content::tag_ok( $output, "link",
    { rel => "stylesheet",
      href => "http://example.org/static/openguides-base.css" },
    "openguides-base stylesheet used when none provided" );

# Make sure the guide's own stylesheet overrides this though.
$config->stylesheet_url( "http://example.com/styles.css" );
$output = $guide->display_node( id => "Red Lion", return_output => 1,
                                noheaders => 1 );
Test::HTML::Content::no_tag( $output, "link",
    { rel => "stylesheet", href => "openguides-base.css" },
    "...but not when one is provided" );
Test::HTML::Content::tag_ok( $output, "link",
    { rel => "stylesheet", href => "http://example.com/styles.css" },
    "...and the guide's own stylesheet is used instead" );

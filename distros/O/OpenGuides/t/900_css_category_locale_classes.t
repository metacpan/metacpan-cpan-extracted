use strict;
use Cwd;
use OpenGuides;
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
    plan skip_all => "Test::HTML::Content not installed";
}

plan tests => 3;

# Clear out the database from any previous runs.
OpenGuides::Test::refresh_db();

my $config = OpenGuides::Test->make_basic_config;
$config->custom_template_path( cwd . "/t/templates/" );
my $guide = OpenGuides->new( config => $config );

# Check that a node in one locale and one category has CSS classes for both.
OpenGuides::Test->write_data(
                              guide => $guide,
                              node  => "Crown",
                              categories => "Pubs",
                              locales => "Cornmarket",
                              return_output => 1,
                            );

my $output = $guide->display_node( id => "Crown", return_output => 1,
                                   noheaders => 1 );
Test::HTML::Content::tag_ok( $output, "div",
  { id => "content", class => "cat_pubs loc_cornmarket" },
  "Node in one locale and one category has CSS classes for both." );

# Check that spaces in locale/category names are replaced by underscores.
OpenGuides::Test->write_data(
                              guide => $guide,
                              node  => "Debenhams",
                              categories => "Baby Changing",
                              locales => "Magdalen Street",
                              return_output => 1,
                            );
$output = $guide->display_node( id => "Debenhams", return_output => 1,
                                noheaders => 1 );
Test::HTML::Content::tag_ok( $output, "div",
  { id => "content", class => "cat_baby_changing loc_magdalen_street" },
  "...and spaces in locale/category names are replaced by underscores." );

# Check that nodes with no locales or categories don't have classes added.
OpenGuides::Test->write_data(
                              guide => $guide,
                              node  => "A Blank Node",
                              return_output => 1,
                            );
$output = $guide->display_node( id => "A Blank Node", return_output => 1 );
like( $output, qr|<div id="content">|,
      "Nodes with no locales or categories don't have classes added." );

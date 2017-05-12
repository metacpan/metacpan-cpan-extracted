use strict;
use OpenGuides;
use OpenGuides::Test;
use Test::More;
use Wiki::Toolkit::Setup::SQLite;

eval { require DBD::SQLite; };
if ( $@ ) {
    plan skip_all => "DBD::SQLite not installed - no database to test with";
}

plan tests => 2;

# An editable page should get the universal edit <link>; a non-editable one
# shouldn't.

my ( $config, $guide, $wiki, $cookie, $output );

# Clear out the database from any previous runs.
    OpenGuides::Test::refresh_db();

# Make a guide.
$config = OpenGuides::Test->make_basic_config;
$guide = OpenGuides->new( config => $config );
$wiki = $guide->wiki;

# Write a node.
OpenGuides::Test->write_data(
                              guide         => $guide,
                              node          => "Red Lion",
                              return_output => 1,
                            );

# Check an editable node.
$output = $guide->display_node(
                                id => "Red Lion",
                                return_output => 1,
                              );
like( $output, qr|<link rel="alternate" type="application/wiki" title="Edit this page!"|ms, "universal edit link present on editable page" );

# Check a non-editable node.
$output = $guide->display_recent_changes( return_output => 1 );
unlike( $output, qr|<link rel="alternate" type="application/wiki" title="Edit this page!"|ms, "universal edit link not present on non-editable page" );

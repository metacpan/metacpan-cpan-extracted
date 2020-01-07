use strict;
use Cwd;
use Wiki::Toolkit::Plugin::Categoriser;
use OpenGuides;
use OpenGuides::Test;
use Test::More;

eval { require DBD::SQLite; };
if ( $@ ) {
    my ($error) = $@ =~ /^(.*?)\n/;
    plan skip_all =>
        "DBD::SQLite could not be used - no database to test with. ($error)";
}

plan tests => 17;

# Clear out the database from any previous runs.
OpenGuides::Test::refresh_db();

my $config = OpenGuides::Test->make_basic_config;
$config->custom_template_path( cwd . "/t/templates/" );
my $guide = OpenGuides->new( config => $config );
my $wiki = $guide->wiki;
my $categoriser = Wiki::Toolkit::Plugin::Categoriser->new;
$wiki->register_plugin( plugin => $categoriser );

# Check that unwelcome characters are stripped from autocreated cats/locales.
# Double spaces:
OpenGuides::Test->write_data(
                              guide => $guide,
                              node  => "Arbat",
                              categories => "Delicious  Russian  Food",
                              return_output => 1,
                            );

ok( !$wiki->node_exists( "Category Delicious  Russian  Food" ),
    "Categories with double spaces in are not auto-created." );
ok( $wiki->node_exists( "Category Delicious Russian Food" ),
    "...but the corresponding category with single spaces is." );
ok ( !$categoriser->in_category( node => "Arbat",
                                 category => "Delicious  Russian  Food" ),
    "...and the new node is not in the double-spaced category." );
ok ( $categoriser->in_category( node => "Arbat",
                                category => "Delicious Russian Food" ),
    "...but it is in the single-spaced one." );

# Newlines:
OpenGuides::Test->write_data(
                              guide => $guide,
                              node  => "Liaison",
                              categories => "Dim\nSum",
                              return_output => 1,
                            );

ok( !$wiki->node_exists( "Category Dim\nSum" ),
    "Categories with newlines in are not auto-created." );
ok( $wiki->node_exists( "Category Dim Sum" ),
    "...but the corresponding category with single spaces is." );
ok ( !$categoriser->in_category( node => "Liaison",
                                 category => "Dim\nSum" ),
    "...and the new node is not in the newlined category." );
ok ( $categoriser->in_category( node => "Liaison",
                                category => "Dim Sum" ),
    "...but it is in the single-spaced one." );

# Underscores:
OpenGuides::Test->write_data(
                              guide => $guide,
                              node  => "Red Lion",
                              categories => "Real_Ale",
                              return_output => 1,
                            );

ok( !$wiki->node_exists( "Category Real_Ale" ),
    "Categories with underscores in are not auto-created." );
ok( $wiki->node_exists( "Category Real Ale" ),
    "...but the corresponding category with spaces is." );
ok ( !$categoriser->in_category( node => "Red Lion",
                                 category => "Real_Ale" ),
    "...and the new node is not in the underscores category." );
ok ( $categoriser->in_category( node => "Red Lion",
                                category => "Real Ale" ),
    "...but it is in the one with spaces." );

# Write a custom template to autofill content in autocreated nodes.
eval {
    unlink cwd . "/t/templates/custom_autocreate_content.tt";
};
open( FILE, ">", cwd . "/t/templates/custom_autocreate_content.tt" )
  or die $!;
print FILE <<EOF;
Auto-generated list of places in
[% IF index_type == "Category" %]this category[% ELSE %][% index_value %][% END %]:
\@INDEX_LIST [[[% node_name %]]]
EOF
close FILE or die $!;

# Check that autocapitalisation works correctly in categories with hyphens.
OpenGuides::Test->write_data(
                              guide => $guide,
                              node  => "Vivat Bacchus",
                              categories => "Restaurants\r\nVegan-friendly",
                              locales => "Farringdon",
                              return_output => 1,
                            );

ok( $wiki->node_exists( "Category Vegan-Friendly" ),
    "Categories with hyphens in are auto-created correctly." );

# Check that the custom autocreate template was picked up.
my $content = $wiki->retrieve_node( "Category Vegan-Friendly" );
$content =~ s/\s+$//s;
$content =~ s/\s+/ /gs;
is( $content, "Auto-generated list of places in this category: "
              . "\@INDEX_LIST [[Category Vegan-Friendly]]",
    "Custom autocreate template works properly for categories" );

$content = $wiki->retrieve_node( "Locale Farringdon" );
$content =~ s/\s+$//s;
$content =~ s/\s+/ /gs;
is( $content, "Auto-generated list of places in Farringdon: "
              . "\@INDEX_LIST [[Locale Farringdon]]",
    "...and locales" );

# Now make sure that we have a fallback if there's no autocreate template.
unlink cwd . "/t/templates/custom_autocreate_content.tt";

OpenGuides::Test->write_data(
                              guide => $guide,
                              node  => "Bleeding Heart",
                              categories => "Pubs",
                              locales => "EC1",
                              return_output => 1,
                            );
$content = $wiki->retrieve_node( "Category Pubs" );
$content =~ s/\s+$//s;
is( $content, "Things in this category "
              . "(\@MAP_LINK [[Category Pubs|view them on a map]]):\n"
              . "\@INDEX_LIST [[Category Pubs]]",
    "Default content is picked up if autocreate template doesn't exist" );

$content = $wiki->retrieve_node( "Locale EC1" );
$content =~ s/\s+$//s;
is( $content, "Things in EC1 "
              . "(\@MAP_LINK [[Locale EC1|view them on a map]]):\n"
              . "\@INDEX_LIST [[Locale EC1]]",
    "...and for locales too." );

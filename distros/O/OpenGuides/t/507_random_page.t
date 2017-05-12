use strict;
use Wiki::Toolkit::Setup::SQLite;
use OpenGuides::Test;
use OpenGuides;
use Test::More;

eval { require DBD::SQLite; };
if ( $@ ) {
    my ($error) = $@ =~ /^(.*?)\n/;
    plan skip_all => "DBD::SQLite could not be used - no database to test with ($error)";
}

plan tests => 8;

my ( $config, $guide, $wiki );

# Clear out database from previous runs, set up a guide.
    OpenGuides::Test::refresh_db();

$config = OpenGuides::Test->make_basic_config;
$config->script_url( "http://www.example.com/" );
$config->script_name( "wiki.cgi" );
$guide = OpenGuides->new( config => $config );
$wiki = $guide->wiki;

# Write some data.
my %nodes = map { $_ => "A pub." } ( "Red Lion", "Farmers Arms", "Angel" );
foreach my $node ( keys %nodes ) {
  OpenGuides::Test->write_data(
                                guide         => $guide,
                                node          => $node,
                                return_output => 1,
                              );
}

# See what we get when we ask for a random page.
my $output = $guide->display_random_page( return_output => 1 );

# Old versions of CGI.pm mistakenly print location: instead of Location:
like( $output, qr/[lL]ocation: http:\/\/www.example.com\/wiki.cgi/,
      "->display_random_page makes a redirect" );

my $node = get_node_from_output( $output );
print "# Random node chosen: $node\n";
ok( $nodes{$node}, "...to an existing node" );

# Clear the database and write some data including categories and locales.
    OpenGuides::Test::refresh_db();

$config = OpenGuides::Test->make_basic_config;
$config->script_url( "http://www.example.com/" );
$config->script_name( "wiki.cgi" );
$guide = OpenGuides->new( config => $config );
$wiki = $guide->wiki;

# Write data including some categories/locales.
OpenGuides::Test->write_data(
                              guide         => $guide,
                              node          => "Red Lion",
                              locales       => "Hammersmith",
                              categories    => "Pubs",
                              return_output => 1,
                            );

# Check we can turn off locales.
$config = OpenGuides::Test->make_basic_config;
$config->script_url( "http://www.example.com/" );
$config->script_name( "wiki.cgi" );
$config->random_page_omits_locales( 1 );
$guide = OpenGuides->new( config => $config );
$wiki = $guide->wiki;
$output = $guide->display_random_page( return_output => 1 );
$node = get_node_from_output( $output );
print "# Random node chosen: $node\n";
isnt( $node, "Locale Hammersmith", "locale nodes not picked up as random page "
                       . "(this test may sometimes pass when it shouldn't)" );

# Check we can turn off categories.
$config = OpenGuides::Test->make_basic_config;
$config->script_url( "http://www.example.com/" );
$config->script_name( "wiki.cgi" );
$config->random_page_omits_categories( 1 );
$guide = OpenGuides->new( config => $config );
$wiki = $guide->wiki;
$output = $guide->display_random_page( return_output => 1 );
$node = get_node_from_output( $output );
print "# Random node chosen: $node\n";
isnt( $node, "Category Pubs", "category nodes not picked up as random page "
                       . "(this test may sometimes pass when it shouldn't)" );

# Now make sure we can pick things up from specific categories/locales if asked
    OpenGuides::Test::refresh_db();

$config = OpenGuides::Test->make_basic_config;
$guide = OpenGuides->new( config => $config );

OpenGuides::Test->write_data(
                              guide         => $guide,
                              node          => "Red Lion",
                              locales       => "Hammersmith",
                              categories    => "Pubs",
                              return_output => 1,
                            );
OpenGuides::Test->write_data(
                              guide         => $guide,
                              node          => "Poppy Hana",
                              locales       => "Bermondsey",
                              categories    => "Restaurants",
                              return_output => 1,
                            );
$output = $guide->display_random_page( category => "Pubs",
                                       return_output => 1 );
$node = get_node_from_output( $output );
print "# Random node chosen: $node\n";
is( $node, "Red Lion", "can ask for a random pub "
                       . "(this test may sometimes pass when it shouldn't)" );

$output = $guide->display_random_page( locale => "Bermondsey",
                                       return_output => 1 );
$node = get_node_from_output( $output );
print "# Random node chosen: $node\n";
is( $node, "Poppy Hana", "can ask for a random thing in Bermondsey "
                       . "(this test may sometimes pass when it shouldn't)" );

OpenGuides::Test->write_data(
                              guide         => $guide,
                              node          => "Stanley Arms",
                              locales       => "Bermondsey",
                              categories    => "Pubs",
                              return_output => 1,
                            );
$output = $guide->display_random_page( locale => "Bermondsey",
                                       category => "Pubs",
                                       return_output => 1
                                      );
$node = get_node_from_output( $output );
print "# Random node chosen: $node\n";
is( $node, "Stanley Arms", "can ask for a random pub in Bermondsey "
                       . "(this test may sometimes pass when it shouldn't)" );


$output = $guide->display_random_page( locale => "Islington",
                                       category => "Cinemas",
                                       return_output => 1
                                     );
unlike( $output, qr/Status: 302/,
       "don't get a redirect if we ask for category/locale with no pages in" );


sub get_node_from_output {
    my $node_param = shift;
    $node_param =~ s/^.*\?//s;
    $node_param =~ s/\s+$//;
    my $formatter = $guide->wiki->formatter;
    my $node = $formatter->node_param_to_node_name( $node_param );
    return $node;
}

use strict;
use OpenGuides;
use OpenGuides::CGI;
use OpenGuides::Test;
use Test::More;
use Cwd;

eval { require DBD::SQLite; };
if ( $@ ) {
    my ($error) = $@ =~ /^(.*?)\n/;
    plan skip_all =>
        "DBD::SQLite could not be used - no database to test with. ($error)";
}

plan tests => 3;

# Clear out the database from any previous runs.
OpenGuides::Test::refresh_db();

my $config = OpenGuides::Test->make_basic_config;
$config->custom_template_path( cwd . "/t/templates/tmp/" );
my $guide = OpenGuides->new( config => $config );
my $wiki = $guide->wiki;

# Write a couple of nodes, one with a map link and another
# without; also with/without address
# NOTE: the node with neither address nor map link 
# contains a phone number, to force the general metadata
# section to be displayed. This is documented as the behaviour
# in CUSTOMISATION but could change
OpenGuides::Test->write_data(
                              guide         => $guide,
                              node          => "Red Lion",
                              address       => "High Street",
                              latitude      => 51.4,
                              longitude     => -0.2,
                              locales       => "Croydon\r\nWaddon",
                              return_output => 1,
                              map_link      => 'http://maps.example.org/Red_Lion_Croydon'
                            );

# Make sure the tmp directory exists
eval {
    mkdir cwd . "/t/templates/tmp";
};

# Make sure we don't die if there's no custom auto map link template.
eval {
    unlink cwd . "/t/templates/tmp/custom_node_location_search.tt";
};

my $output;

eval {
    $output = $guide->display_node( id             => 'Red Lion',
                                    return_output  => 1,
                                    noheaders      => 1
                                  );
};
ok( !$@, "node display OK if no custom node location search template" );

like( $output, qr#Find all things#,
         "Find all things found" );

# Write a template which spits out the map link
open( FILE, ">", cwd . "/t/templates/tmp/custom_node_location_search.tt" )
  or die $!;
print FILE <<EOF;
custom node location search
EOF
close FILE or die $!;

$output = $guide->display_node(
                                   id            => 'Red Lion',
                                   return_output => 1,
                                   noheaders     => 1,
                                 );

like( $output, qr#custom node location search#,
        "custom template included" );

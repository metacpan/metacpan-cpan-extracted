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

plan tests => 10;

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

OpenGuides::Test->write_data(
                              guide         => $guide,
                              node          => "Blue Lion",
                              latitude      => 51.6,
                              longitude     => 0.6,
                              locales       => "Croydon",
                              phone         => '123',
                              return_output => 1,
                            );

OpenGuides::Test->write_data(
                              guide         => $guide,
                              node          => "Purple Lion",
                              latitude      => 51.6,
                              longitude     => 0.6,
                              locales       => "Croydon",
                              return_output => 1,
                              address       => '1 The Avenue',
                            );

OpenGuides::Test->write_data(
                              guide         => $guide,
                              node          => "Pink Lion",
                              latitude      => 51.6,
                              longitude     => 0.6,
                              locales       => "Croydon",
                              map_link      => 'http://maps.example.org/Pink_Lion_Croydon',
                              return_output => 1,
                            );


# Make sure the tmp directory exists
eval {
    mkdir cwd . "/t/templates/tmp";
};

# Make sure we don't die if there's no custom auto map link template.
eval {
    unlink cwd . "/t/templates/tmp/custom_auto_map_link.tt";
};

my $output;

eval {
    $output = $guide->display_node( id             => 'Red Lion',
                                    return_output  => 1,
                                    noheaders      => 1
                                  );
};
ok( !$@, "node display OK if no custom auto map link template" );

like( $output, qr#http://maps\.example\.org/Red_Lion_Croydon#,
         "map link included from node data if no custom template" );

# Write a template which spits out the map link
open( FILE, ">", cwd . "/t/templates/tmp/custom_auto_map_link.tt" )
  or die $!;
print FILE <<EOF;
[% IF map_link %]
MAP: [% map_link %]
[% ELSE %]
MAP: dunno
[% END %]
[% IF auto_map_link_in_address %]
in the address section
[% END %]
EOF
close FILE or die $!;

$output = $guide->display_node(
                                   id            => 'Red Lion',
                                   return_output => 1,
                                   noheaders     => 1,
                                 );

like( $output, qr#MAP: http://maps\.example\.org/Red_Lion_Croydon#,
        "custom template saw map link" );

like( $output, qr#in the address section#,
        "custom template noticed we were in the address section" );

$output = $guide->display_node(
                                   id            => 'Blue Lion',
                                   return_output => 1,
                                   noheaders     => 1,
                                 );

like( $output, qr#MAP: dunno#,
        "custom template didn't have any map link but was called" );

unlike( $output, qr#in the address section#,
        "but not from the address section" );

$output = $guide->display_node(
                                   id            => 'Purple Lion',
                                   return_output => 1,
                                   noheaders     => 1,
                                 );

like( $output, qr#MAP: dunno#,
        "custom template didn't have any map link but was called" );

like( $output, qr#in the address section#,
        "and was called from the address section" );

$output = $guide->display_node(
                                   id            => 'Pink Lion',
                                   return_output => 1,
                                   noheaders     => 1,
                                 );

like( $output, qr#MAP: http://maps\.example\.org/Pink_Lion_Croydon#,
        "custom template saw map link" );
unlike( $output, qr#in the address section#,
        "but not from the address section" );


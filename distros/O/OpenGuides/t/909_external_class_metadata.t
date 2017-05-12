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

plan tests => 2;

# Clear out the database from any previous runs.
OpenGuides::Test::refresh_db();

my $config = OpenGuides::Test->make_basic_config;
my $guide = OpenGuides->new( config => $config );
my $wiki = $guide->wiki;

# Write out a node with a map link and external website
OpenGuides::Test->write_data(
                              guide         => $guide,
                              node          => "Red Lion",
                              address       => "High Street",
                              latitude      => 51.4,
                              longitude     => -0.2,
                              locales       => "Croydon\r\nWaddon",
                              return_output => 1,
                              map_link      => 'http://maps.example.org/Red_Lion_Croydon',
                              website       => 'http://example.com',
                            );



my $output = $guide->display_node(
                                   id             => 'Red Lion',
                                   return_output  => 1,
                                   noheaders      => 1
                                 );

like( $output, qr#<a href="http://maps\.example\.org/Red_Lion_Croydon" class="external"#,
         "map link has a class of external" );
like( $output, qr#"url"><a href="http://example.com" class="external">example.com</a>#,
         "website link has a class of external" );


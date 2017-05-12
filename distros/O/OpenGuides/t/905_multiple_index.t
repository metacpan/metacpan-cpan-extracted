use strict;
use JSON;
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

plan tests => 18;

# Clear out the database from any previous runs.
OpenGuides::Test::refresh_db();

my $config = OpenGuides::Test->make_basic_config;
my $guide = OpenGuides->new( config => $config );
my $wiki = $guide->wiki;

# Write some nodes.
OpenGuides::Test->write_data(
                              guide         => $guide,
                              node          => "Red Lion",
                              locales       => "Croydon",
                              categories    => "Pubs",
                              return_output => 1,
                            );

OpenGuides::Test->write_data(
                              guide         => $guide,
                              node          => "Blue Lion",
                              locales       => "Waddon",
                              categories    => "Pubs",
                              return_output => 1,
                            );

OpenGuides::Test->write_data(
                              guide         => $guide,
                              node          => "Blue Ribbon",
                              locales       => "Waddon",
                              categories    => "Shops",
                              return_output => 1,
                            );

my %tt_vars = $guide->show_index( cat => "pubs", return_tt_vars => 1 );
is( scalar @{$tt_vars{nodes}}, 2,
    "Right number of nodes returned in pure category search" );
my $output = $guide->show_index( cat => "pubs", return_output => 1,
                                 noheaders => 1 );
Test::HTML::Content::tag_ok( $output, 'title', {}, "Index of Category Pubs - Test",
    "...and page title is correct" );
Test::HTML::Content::link_ok( $output, $config->script_name . "?Category_Pubs",
    "...and we link to the category page." );

%tt_vars = $guide->show_index( loc => "waddon", return_tt_vars => 1 );
is( scalar @{$tt_vars{nodes}}, 2,
    "Right number of nodes returned in pure locale search" );
$output = $guide->show_index( loc => "waddon", return_output => 1,
                              noheaders => 1 );
Test::HTML::Content::tag_ok( $output, 'title', {}, "Index of Locale Waddon - Test",
    "...and page title is correct" );
Test::HTML::Content::link_ok( $output, $config->script_name . "?Locale_Waddon",
    "...and we link to the locale page." );

%tt_vars = $guide->show_index( cat => "pubs", loc => "waddon",
                               return_tt_vars => 1 );
is( scalar @{$tt_vars{nodes}}, 1,
    "Right number of nodes returned in category+locale search" );
$output = $guide->show_index( cat => "pubs", loc => "waddon",
                              return_output => 1, noheaders => 1 );
Test::HTML::Content::tag_ok( $output, 'title', {},
     "Index of Category Pubs and Locale Waddon - Test",
     "...and page title is correct" );
Test::HTML::Content::link_ok( $output, $config->script_name . "?Category_Pubs",
    "...and we link to the category page." );
Test::HTML::Content::link_ok( $output, $config->script_name . "?Locale_Waddon",
    "...and we link to the locale page." );

# Test the map version.
$config->use_leaflet( 1 );
%tt_vars = $guide->show_index( cat => "pubs", loc => "waddon", format => "map",
                               return_tt_vars => 1 );
is( scalar @{$tt_vars{nodes}}, 1,
    "Right number of nodes returned in category+locale search with map" );
$output = $guide->show_index( cat => "pubs", loc => "waddon", format => "map",
                              return_output => 1, noheaders => 1 );
Test::HTML::Content::tag_ok( $output, 'title', {},
     "Map of Category Pubs and Locale Waddon - Test",
     "...and page title is correct" );
Test::HTML::Content::link_ok( $output, $config->script_name . "?Category_Pubs",
    "...and we link to the category page." );
Test::HTML::Content::link_ok( $output, $config->script_name . "?Locale_Waddon",
    "...and we link to the locale page." );

# Test the RDF version.
$output = $guide->show_index( cat => "pubs", loc => "waddon", format => "rdf",
                              return_output => 1 );
like( $output,
      qr|<dc:title>Category Pubs and Locale Waddon</dc:title>|,
      "Page title is correct on RDF version." );

# Test the JSON version.
$output = $guide->show_index( cat => "pubs", loc => "waddon", format => "json",
                              return_output => 1, noheaders => 1 );
unlike( $output, qr/error/i, "JSON format invocation doesn't cause error." );

my $parsed = eval {
    local $SIG{__WARN__} = sub { die $_[0]; };
    decode_json( $output );
};
ok( !$@, "...and its output looks like JSON." );
is( scalar @$parsed, 1, "...and has the right number of nodes." );

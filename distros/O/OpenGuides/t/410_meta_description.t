use strict;
use OpenGuides;
use OpenGuides::Test;
use Test::More;

eval { require DBD::SQLite; };
if ( $@ ) {
    my ($error) = $@ =~ /^(.*?)\n/;
    plan skip_all => "DBD::SQLite not available ($error)";
}

eval { require Test::HTML::Content; };
if ( $@ ) {
    plan skip_all => "Test::HTML::Content not available";
}

plan tests => 12;

OpenGuides::Test::refresh_db();

my $config = OpenGuides::Test->make_basic_config;
$config->use_leaflet( 1 );
my $guide = OpenGuides->new( config => $config );
my $wiki = $guide->wiki;

# Write a node and give it a category and locale.
OpenGuides::Test->write_data( guide => $guide, node => "Dog And Bull",
    summary => "A pub.", categories => "Pubs", locales => "Croydon",
    return_output => 1 );

# Display the category and locale indexes individually and together,
# as maps and lists, and check that the header shows up.

# Category list.
my $output = $guide->show_index( cat => "pubs", return_output => 1,
                                 noheaders => 1 );
Test::HTML::Content::tag_ok( $output, "meta", { name => "description" },
    "Category index has meta description" );
like( $output,
      qr/List of all our pages labelled with: Pubs\./,
      "...with suitable text." );

# Locale list.
$output = $guide->show_index( loc => "croydon", return_output => 1,
                              noheaders => 1 );
Test::HTML::Content::tag_ok( $output, "meta", { name => "description" },
    "Locale index has meta description" );
like( $output,
      qr/List of all our pages located in: Croydon\./,
      "...with suitable text." );

# Category + locale list.
$output = $guide->show_index( cat => "pubs", loc => "croydon",
                              return_output => 1, noheaders => 1 );
Test::HTML::Content::tag_ok( $output, "meta", { name => "description" },
    "Category+locale index has meta description" );
like( $output,
      qr/List of all our pages labelled with: Pubs, and located in: Croydon\./,
      "...with suitable text." );

# Category map.
$output = $guide->show_index( cat => "pubs", format => "map",
                              return_output => 1, noheaders => 1 );
Test::HTML::Content::tag_ok( $output, "meta", { name => "description" },
    "Category map has meta description" );
like( $output,
      qr/Map of all our pages labelled with: Pubs\./,
      "...with suitable text." );

# Locale map.
$output = $guide->show_index( loc => "croydon", format => "map",
                              return_output => 1, noheaders => 1 );
Test::HTML::Content::tag_ok( $output, "meta", { name => "description" },
    "Locale map has meta description" );
like( $output,
      qr/Map of all our pages located in: Croydon\./,
      "...with suitable text." );

# Category + locale map.
$output = $guide->show_index( cat => "pubs", loc => "croydon", format => "map",
                              return_output => 1, noheaders => 1 );
Test::HTML::Content::tag_ok( $output, "meta", { name => "description" },
    "Category+locale map has meta description" );
like( $output,
      qr/Map of all our pages labelled with: Pubs, and located in: Croydon\./,
      "...with suitable text." );

use strict;
use Wiki::Toolkit::Setup::SQLite;
use OpenGuides::Search;
use OpenGuides::Test;
use Test::More tests => 4;

eval { require DBD::SQLite; };
if ( $@ ) {
    my ($error) = $@ =~ /^(.*?)\n/;
    plan skip_all => "DBD::SQLite could not be used - no database to test with. ($error)";
}

# Clear out the database.
OpenGuides::Test::refresh_db();

my $config = OpenGuides::Test->make_basic_config;
my $guide = OpenGuides->new( config => $config );

my %data = (
             "Test Page" => "[[Test, With, Commas]]",
             "Test, With, Commas" => "Hello!",
           );
foreach my $node ( keys %data ) {
    OpenGuides::Test->write_data( guide => $guide, node => $node,
                                  content => $data{$node},
                                  locales => "Croydon",
                                  categories => "Pubs",
                                  return_output => 1 );
}

my $output = $guide->display_node( id => "Test Page", return_output => 1 );
unlike( $output, qr/%2C/,
        "internal links don't produce comma escapes in URLs" );

$output = $guide->display_recent_changes( return_output => 1 );
unlike( $output, qr/%2C/, "...neither does Recent Changes" );

$output = $guide->display_node( id => "Locale Croydon", return_output => 1 );
unlike( $output, qr/%2C/, "...neither does locale list" );

$output = $guide->display_node( id => "Category Pubs", return_output => 1 );
unlike( $output, qr/%2C/, "...neither does category list" );

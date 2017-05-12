use strict;
use Wiki::Toolkit::Setup::SQLite;
use OpenGuides::Config;
use OpenGuides;
use OpenGuides::Template;
use OpenGuides::Test;
use Test::More;

eval { require DBD::SQLite; };

if ( $@ ) {
    my ($error) = $@ =~ /^(.*?)\n/;
    plan skip_all => "DBD::SQLite could not be used - no database to test with ($error)";
}

plan tests => 9;

# Clear out the database from any previous runs.
    OpenGuides::Test::refresh_db();

my $config = OpenGuides::Test->make_basic_config;
my $guide = OpenGuides->new( config => $config );

    my $q = CGI->new( "" );
    $q->param( -name => "os_x", -value => " 123456 " );
    $q->param( -name => "os_y", -value => " 654321 " );
    $q->param( -name => "categories", -value => "" ); #avoid uninit val warning
    $q->param( -name => "locales", -value => "" );    #avoid uninit val warning

    my %metadata_vars = OpenGuides::Template->extract_metadata_vars(
        wiki    => $guide->wiki,
        config  => $config,
        cgi_obj => $q,
    );

    is( $metadata_vars{os_x}, "123456",
        "leading and trailing spaces stripped from os_x when processed" );
    is( $metadata_vars{os_y}, "654321", "...and os_y" );

    $config->geo_handler( 2 );
    $q = CGI->new( "" );
    $q->param( -name => "osie_x", -value => " 100000 " );
    $q->param( -name => "osie_y", -value => " 200000 " );
    $q->param( -name => "categories", -value => "" ); #avoid uninit val warning
    $q->param( -name => "locales", -value => "" );    #avoid uninit val warning

    %metadata_vars = OpenGuides::Template->extract_metadata_vars(
        wiki    => $guide->wiki,
        config  => $config,
        cgi_obj => $q,
    );

    is( $metadata_vars{osie_x}, "100000",
        "leading and trailing spaces stripped from osie_x when processed" );
    is( $metadata_vars{osie_y}, "200000", "...and osie_y" );

    $config->geo_handler( 3 );
    $q = CGI->new( "" );
    $q->param( -name => "latitude", -value => " 1.463113 " );
    $q->param( -name => "longitude", -value => " -0.215293 " );
    $q->param( -name => "categories", -value => "" ); #avoid uninit val warning
    $q->param( -name => "locales", -value => "" );    #avoid uninit val warning

    %metadata_vars = OpenGuides::Template->extract_metadata_vars(
        wiki    => $guide->wiki,
        config  => $config,
        cgi_obj => $q,
    );

    is( $metadata_vars{latitude}, "1.463113",
        "leading and trailing spaces stripped from latitude when processed" );
    is( $metadata_vars{longitude}, "-0.215293", "...and longitude" );

OpenGuides::Test->write_data(
                              guide => $guide,
                              node  => "A Node",
                              categories => " Food \r\n Live Music ",
                              locales    => " Hammersmith \r\n Fulham ",
                              fax => " 567890 ",
);
my %node = $guide->wiki->retrieve_node( "A Node" );
my %data = %{ $node{metadata} };
my @cats = sort @{ $data{category} || [] };
is_deeply( \@cats, [ "Food", "Live Music" ],
    "leading and trailing spaces stripped from all categories when stored" );
my @locs = sort @{ $data{locale} || [] };
is_deeply( \@locs, [ "Fulham", "Hammersmith" ], "...and all locales" );
my $fax = $data{fax}[0];
is( $fax, "567890", "...and fax field" );

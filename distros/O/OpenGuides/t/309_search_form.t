use strict;
use Wiki::Toolkit::Setup::SQLite;
use OpenGuides::Search;
use OpenGuides::Test;
use Test::More;

eval { require DBD::SQLite; };
if ( $@ ) {
    my ($error) = $@ =~ /^(.*?)\n/;
    plan skip_all => "DBD::SQLite could not be used - no database to test with ($error)";
}

eval { require Test::HTML::Content; };
if ( $@ ) {
    plan skip_all => "Test::HTML::Content not installed";
}

my $have_lucy = eval { require Lucy; } ? 1 : 0;
my $have_plucene = eval { require Plucene; } ? 1 : 0;

my $num_tests = 27;

plan tests => $num_tests * 2;

SKIP: {
    skip "Plucene not installed.", $num_tests unless $have_plucene;
    run_tests();
}

SKIP: {
    skip "Lucy not installed.", $num_tests unless $have_lucy;
    run_tests( use_lucy => 1 );
}

sub run_tests {
    my %args = @_;

    # Clear out the database from any previous runs.
    OpenGuides::Test::refresh_db();

    my $config = OpenGuides::Test->make_basic_config;

    if ( $args{use_lucy} ) {
        $config->use_lucy( 1 );
        $config->use_plucene( 0 );
    } else {
        $config->use_plucene( 1 );
    }

    # British National Grid guides should have os and latlong search fields.
    my $search = OpenGuides::Search->new( config => $config );
    my $output = $search->run( return_output => 1 );
    # Strip Content-Type header to stop Test::HTML::Content getting confused.
    $output =~ s/^Content-Type.*[\r\n]+//m;

    Test::HTML::Content::tag_ok( $output, "input", { name => "os_dist" },
                               "search page includes os_dist input with BNG" );
    Test::HTML::Content::tag_ok( $output, "input", { name => "os_x" },
                                 "...and os_x" );
    Test::HTML::Content::tag_ok( $output, "input", { name => "os_y" },
                                 "...and os_y" );
    Test::HTML::Content::tag_ok( $output, "input", { name => "latlong_dist" },
                                 "...and latlong_dist" );
    Test::HTML::Content::tag_ok( $output, "input", { name => "latitude" },
                                 "...and latitude" );
    Test::HTML::Content::tag_ok( $output, "input", { name => "longitude" },
                                 "...and longitude" );
    Test::HTML::Content::no_tag( $output, "input", { name => "osie_dist" },
                                 "...but not osie_dist" );
    Test::HTML::Content::no_tag( $output, "input", { name => "osie_x" },
                                 "...nor osie_x" );
    Test::HTML::Content::no_tag( $output, "input", { name => "osie_y" },
                                 "...nor osie_y" );

    # Irish National Grid guides should have osie and latlong.
    $config->geo_handler( 2 );
    $search = OpenGuides::Search->new( config => $config );
    $output = $search->run( return_output => 1 );
    $output =~ s/^Content-Type.*[\r\n]+//m;

    Test::HTML::Content::tag_ok( $output, "input", { name => "osie_dist" },
                               "search page includes os_dist input with ING" );
    Test::HTML::Content::tag_ok( $output, "input", { name => "osie_x" },
                                 "...and osie_x" );
    Test::HTML::Content::tag_ok( $output, "input", { name => "osie_y" },
                                 "...and osie_y" );
    Test::HTML::Content::tag_ok( $output, "input", { name => "latlong_dist" },
                                 "...and latlong_dist" );
    Test::HTML::Content::tag_ok( $output, "input", { name => "latitude" },
                                 "...and latitude" );
    Test::HTML::Content::tag_ok( $output, "input", { name => "longitude" },
                                 "...and longitude" );
    Test::HTML::Content::no_tag( $output, "input", { name => "os_dist" },
                                 "...but not os_dist" );
    Test::HTML::Content::no_tag( $output, "input", { name => "os_x" },
                                 "...nor os_x" );
    Test::HTML::Content::no_tag( $output, "input", { name => "os_y" },
                                 "...nor os_y" );

    # UTM guides should have latitude/longitude/latlong_dist only.
    $config->geo_handler( 3 );
    $config->ellipsoid( "Airy" );
    $search = OpenGuides::Search->new( config => $config );
    $output = $search->run( return_output => 1 );
    $output =~ s/^Content-Type.*[\r\n]+//m;

    Test::HTML::Content::tag_ok( $output, "input", { name => "latlong_dist" },
                                 "includes latlong_dist with UTM" );
    Test::HTML::Content::tag_ok( $output, "input", { name => "latitude" },
                                 "...and latitude" );
    Test::HTML::Content::tag_ok( $output, "input", { name => "longitude" },
                                 "...and longitude" );
    Test::HTML::Content::no_tag( $output, "input", { name => "os_dist" },
                                 "...but not os_dist" );
    Test::HTML::Content::no_tag( $output, "input", { name => "os_x" },
                                 "...nor os_x" );
    Test::HTML::Content::no_tag( $output, "input", { name => "os_y" },
                                 "...nor os_y" );
    Test::HTML::Content::no_tag( $output, "input", { name => "osie_x" },
                                 "...but not osie_x" );
    Test::HTML::Content::no_tag( $output, "input", { name => "osie_y" },
                                 "...nor osie_y" );
    Test::HTML::Content::no_tag( $output, "input", { name => "osie_dist" },
                                 "...nor osie_dist" );
}

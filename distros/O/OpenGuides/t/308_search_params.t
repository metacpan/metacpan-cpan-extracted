use strict;
use CGI;
use Wiki::Toolkit::Setup::SQLite;
use OpenGuides::Config;
use OpenGuides::Search;
use OpenGuides::Test;
use Test::More;

eval { require DBD::SQLite; };
if ( $@ ) {
    my ($error) = $@ =~ /^(.*?)\n/;
    plan skip_all => "DBD::SQLite could not be used - no database to test with ($error)";
}

my $have_lucy = eval { require Lucy; } ? 1 : 0;
my $have_plucene = eval { require Plucene; } ? 1 : 0;

my $num_tests = 19;

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

    my $config = OpenGuides::Config->new(
       vars => {
                 dbtype             => "sqlite",
                 dbname             => "t/node.db",
                 indexing_directory => "t/indexes",
                 script_name        => "wiki.cgi",
                 script_url         => "http://example.com/",
                 site_name          => "Test Site",
                 template_path      => "./templates",
                 geo_handler        => 1, # British National Grid
               }
    );

    if ( $args{use_lucy} ) {
        $config->use_lucy( 1 );
        $config->use_plucene( 0 );
    } else {
        $config->use_plucene( 1 );
    }

    # Check the British National Grid case.
    my $q = CGI->new( "" );
    $q->param( -name => "os_x",         -value => 500000 );
    $q->param( -name => "os_y",         -value => 200000 );
    $q->param( -name => "os_dist",      -value => 500    );
    $q->param( -name => "osie_dist",    -value => 600    );
    $q->param( -name => "latlong_dist", -value => 700    );
    my %vars = $q->Vars();
    my $search = OpenGuides::Search->new( config => $config );
    $search->run( vars => \%vars, return_output => 1 );
    is( $search->{distance_in_metres}, 500,
        "os_dist picked up when OS co-ords given and using British grid" );
    is( $search->{x}, 500000, "...x set from os_x" );
    is( $search->{y}, 200000, "...y set from os_y" );

    $q = CGI->new( "" );
    $q->param( -name => "osie_x",       -value => 500000 );
    $q->param( -name => "osie_y",       -value => 200000 );
    $q->param( -name => "os_dist",      -value => 500    );
    $q->param( -name => "osie_dist",    -value => 600    );
    $q->param( -name => "latlong_dist", -value => 700    );
    %vars = $q->Vars();
    $search = OpenGuides::Search->new( config => $config );
    $search->run( vars => \%vars, return_output => 1 );
    ok( !defined $search->{distance_in_metres},
        "OSIE co-ords ignored when using British grid" );

    $q = CGI->new( "" );
    $q->param( -name => "latitude",     -value => 51  );
    $q->param( -name => "longitude",    -value => 1   );
    $q->param( -name => "os_dist",      -value => 500 );
    $q->param( -name => "osie_dist",    -value => 600 );
    $q->param( -name => "latlong_dist", -value => 700 );
    %vars = $q->Vars();
    $search = OpenGuides::Search->new( config => $config );
    $search->run( vars => \%vars, return_output => 1 );
    is( $search->{distance_in_metres}, 700,
        "latlong_dist picked up when lat/long given and using British grid" );
    ok( defined $search->{x}, "...x set" );
    ok( defined $search->{y}, "...y set" );

    # Check the Irish National Grid case.
    $config->geo_handler( 2 );

    $q = CGI->new( "" );
    $q->param( -name => "osie_x",       -value => 500000 );
    $q->param( -name => "osie_y",       -value => 200000 );
    $q->param( -name => "os_dist",      -value => 500    );
    $q->param( -name => "osie_dist",    -value => 600    );
    $q->param( -name => "latlong_dist", -value => 700    );
    %vars = $q->Vars();
    $search = OpenGuides::Search->new( config => $config );
    $search->run( vars => \%vars, return_output => 1 );
    is( $search->{distance_in_metres}, 600,
        "osie_dist picked up when OS co-ords given and using Irish grid" );
    is( $search->{x}, 500000, "...x set from osie_x" );
    is( $search->{y}, 200000, "...y set from osie_y" );

    $q = CGI->new( "" );
    $q->param( -name => "os_x",         -value => 500000 );
    $q->param( -name => "os_y",         -value => 200000 );
    $q->param( -name => "os_dist",      -value => 500    );
    $q->param( -name => "osie_dist",    -value => 600    );
    $q->param( -name => "latlong_dist", -value => 700    );
    %vars = $q->Vars();
    $search = OpenGuides::Search->new( config => $config );
    $search->run( vars => \%vars, return_output => 1 );
    ok( !defined $search->{distance_in_metres},
        "OS co-ords ignored when using Irish grid" );

    $q = CGI->new( "" );
    $q->param( -name => "latitude",     -value => 55  );
    $q->param( -name => "longitude",    -value => -5  );
    $q->param( -name => "os_dist",      -value => 500 );
    $q->param( -name => "osie_dist",    -value => 600 );
    $q->param( -name => "latlong_dist", -value => 700 );
    %vars = $q->Vars();
    $search = OpenGuides::Search->new( config => $config );
    $search->run( vars => \%vars, return_output => 1 );
    is( $search->{distance_in_metres}, 700,
        "latlong_dist picked up when lat/long given and using Irish grid" );
    ok( defined $search->{x}, "...x set" );
    ok( defined $search->{y}, "...y set" );

    # Check the UTM case.
    $config->geo_handler( 3 );
    $config->ellipsoid( "Airy" );

    $q = CGI->new( "" );
    $q->param( -name => "os_x",         -value => 500000 );
    $q->param( -name => "os_y",         -value => 200000 );
    $q->param( -name => "os_dist",      -value => 500    );
    $q->param( -name => "osie_dist",    -value => 600    );
    $q->param( -name => "latlong_dist", -value => 700    );
    %vars = $q->Vars();
    $search = OpenGuides::Search->new( config => $config );
    $search->run( vars => \%vars, return_output => 1 );
    ok( !defined $search->{distance_in_metres},
        "OS co-ords ignored when using UTM" );

    $q = CGI->new( "" );
    $q->param( -name => "osie_x",       -value => 500000 );
    $q->param( -name => "osie_y",       -value => 200000 );
    $q->param( -name => "os_dist",      -value => 500    );
    $q->param( -name => "osie_dist",    -value => 600    );
    $q->param( -name => "latlong_dist", -value => 700    );
    %vars = $q->Vars();
    $search = OpenGuides::Search->new( config => $config );
    $search->run( vars => \%vars, return_output => 1 );
    ok( !defined $search->{distance_in_metres},
        "OSIE co-ords ignored when using UTM" );

    $q = CGI->new( "" );
    $q->param( -name => "latitude",     -value => 51  );
    $q->param( -name => "longitude",    -value => 1   );
    $q->param( -name => "os_dist",      -value => 500 );
    $q->param( -name => "osie_dist",    -value => 600 );
    $q->param( -name => "latlong_dist", -value => 700 );
    %vars = $q->Vars();
    $search = OpenGuides::Search->new( config => $config );
    $search->run( vars => \%vars, return_output => 1 );
    is( $search->{distance_in_metres}, 700,
        "latlong_dist picked up when lat/long given and using UTM" );
    ok( defined $search->{x}, "...x set" );
    ok( defined $search->{y}, "...y set" );
}

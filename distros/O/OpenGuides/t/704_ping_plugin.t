use strict;
use Wiki::Toolkit::Setup::SQLite;
use OpenGuides;
use OpenGuides::Test;
use Test::More;

eval { require DBD::SQLite; };
if ( $@ ) {
    my ($error) = $@ =~ /^(.*?)\n/;
    plan skip_all => "DBD::SQLite could not be used - no database to test with ($error)";
}

plan tests => 11;

eval { require Wiki::Toolkit::Plugin::Ping; };
my $have_ping = $@ ? 0 : 1;

    OpenGuides::Test::refresh_db();

my $config = OpenGuides::Config->new(
    vars => {
                dbtype             => "sqlite",
                dbname             => "t/node.db",
                indexing_directory => "t/indexes",
                script_url         => "http://wiki.example.com/",
                script_name        => "mywiki.cgi",
                site_name          => "Wiki::Toolkit Test Site",
                default_city       => "London",
                default_country    => "United Kingdom",
                ping_services      => ""
            }
);
my $guide = OpenGuides->new( config => $config );

ok( $guide, "Created a guide with blank ping_services" );

# Check for the plugin
my @plugins = @{ $guide->wiki->{_registered_plugins} };
is( scalar @plugins, 2, "...and it has two plugins" );


# Now with the plugin
$config = OpenGuides::Config->new(
    vars => {
                dbtype             => "sqlite",
                dbname             => "t/node.db",
                indexing_directory => "t/indexes",
                script_url         => "http://wiki.example.com/",
                script_name        => "mywiki.cgi",
                site_name          => "Wiki::Toolkit Test Site",
                default_city       => "London",
                default_country    => "United Kingdom",
                ping_services      => "pingerati,geourl,FOOOO"
            }
);

SKIP: {
    skip "Wiki::Toolkit::Plugin::Ping installed - no need to test graceful "
         . "failure", 2
        if $have_ping;
    eval {
        # Suppress warnings; we expect them.
        local $SIG{__WARN__} = sub { };
        $guide = OpenGuides->new( config => $config );
    };
    ok( !$@, "Guide creation doesn't die if we ask for ping_services but "
        . "don't have Wiki::Toolkit::Plugin::Ping" );
    eval {
        local $SIG{__WARN__} = sub { die $_[0]; };
        $guide = OpenGuides->new( config => $config );
    };
    ok( $@, "...but it does warn" );
}

SKIP: {
    skip "Wiki::Toolkit::Plugin::Ping not installed - can't test if it works",
         7
        unless $have_ping;

    $guide = OpenGuides->new( config => $config );
    ok($guide, "Made the guide OK");

    @plugins = @{ $guide->wiki->{_registered_plugins} };
    is( scalar @plugins, 3, "Has plugin now" );
    ok( $plugins[2]->isa( "Wiki::Toolkit::Plugin" ), "Right plugin" );
    ok( $plugins[2]->isa( "Wiki::Toolkit::Plugin::Ping" ), "Right plugin" );

    # Check it has the right services registered
    my %services = $plugins[2]->services;
    my @snames = sort keys %services;
    is( scalar @snames, 2, "Has 2 services as expected" );
    is( $snames[0], "geourl", "Right service" );
    is( $snames[1], "pingerati", "Right service" );
}

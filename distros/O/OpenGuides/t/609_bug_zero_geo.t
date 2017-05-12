use strict;
use Wiki::Toolkit::Setup::SQLite;
use OpenGuides::Config;
use Cwd;
use OpenGuides;
use Test::More;
use OpenGuides::Test;

eval { require DBD::SQLite; };
if ( $@ ) {
    my ($error) = $@ =~ /^(.*?)\n/;
    plan skip_all => "DBD::SQLite could not be used - no database to test with ($error)";
}

plan tests => 6;

    OpenGuides::Test::refresh_db();

my $config = OpenGuides::Config->new(
       vars => {
                 dbtype             => "sqlite",
                 dbname             => "t/node.db",
                 indexing_directory => "t/indexes",
                 script_url         => "http://wiki.example.com/",
                 script_name        => "mywiki.cgi",
                 site_name          => "Wiki::Toolkit Test Site",
                 template_path      => cwd . "/templates",
               }
);
eval { require Wiki::Toolkit::Search::Plucene; };
if ( $@ ) { $config->use_plucene ( 0 ) };

$config->{geo_handler} = 1;

my $guide = OpenGuides->new( config => $config );

my $q = OpenGuides::Test->make_cgi_object(
    content => "Blah",
    os_x    => 0,
    os_y    => 0
);

my $output = $guide->commit_node(
    id            => "Test Node",
    cgi_obj       => $q,
    return_output => 1
);

my %details = $guide->wiki->retrieve_node("Test Node");

is( @{$details{metadata}->{os_x}}[0], 0, "Zero os_x saved" );
is( @{$details{metadata}->{os_y}}[0], 0, "Zero os_y saved" );

$config->{geo_handler} = 2;

Wiki::Toolkit::Setup::SQLite::cleardb( { dbname => "t/node.db" } );
Wiki::Toolkit::Setup::SQLite::setup( { dbname => "t/node.db" } );

$guide = OpenGuides->new( config => $config );

$q = OpenGuides::Test->make_cgi_object(
    content => "Blah",
    osie_x  => 0,
    osie_y  => 0
);

$output = $guide->commit_node(
    id            => "Test Node IE",
    cgi_obj       => $q,
    return_output => 1
);

%details = $guide->wiki->retrieve_node("Test Node IE");

is( @{$details{metadata}->{osie_x}}[0], 0, "Zero osie_x saved" );
is( @{$details{metadata}->{osie_y}}[0], 0, "Zero osie_y saved" );
$config->{geo_handler} = 3;

Wiki::Toolkit::Setup::SQLite::cleardb( { dbname => "t/node.db" } );
Wiki::Toolkit::Setup::SQLite::setup( { dbname => "t/node.db" } );

$guide = OpenGuides->new( config => $config );

$q = OpenGuides::Test->make_cgi_object(
    content   => "Blah",
    latitude  => 0,
    longitude => 0
);

$output = $guide->commit_node(
    id            => "Test Node lat/long",
    cgi_obj       => $q,
    return_output => 1
);

%details = $guide->wiki->retrieve_node("Test Node lat/long");

is( @{$details{metadata}->{latitude}}[0], 0, "Zero latitude saved" );
is( @{$details{metadata}->{longitude}}[0], 0, "Zero longitude saved" );


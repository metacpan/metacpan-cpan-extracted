use strict;
use Wiki::Toolkit::Setup::SQLite;
use OpenGuides::Config;
use Cwd;
use OpenGuides;
use OpenGuides::Test;
use Test::More;

eval { require DBD::SQLite; };
if ( $@ ) {
    my ($error) = $@ =~ /^(.*?)\n/;
    plan skip_all => "DBD::SQLite could not be used - no database to test with ($error)";
}

plan tests => 1;

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

my $guide = OpenGuides->new( config => $config );

$guide->wiki->write_node( "South Croydon Station", "A sleepy main-line station in what is arguably the nicest part of Croydon.", undef, { phone => "<hr><h1>hello mum</h1><hr>" } ) or die "Can't write node";

my $output = $guide->display_node(
                                   id => "South Croydon Station",
                                   return_output => 1,
                                 );
unlike( $output, qr'<hr><h1>hello mum</h1><hr>',
        "HTML escaped in metadata on node display" );

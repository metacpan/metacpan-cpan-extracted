use strict;
use Wiki::Toolkit::Setup::SQLite;
use OpenGuides::Config;
use OpenGuides;
use OpenGuides::Test;
use Test::More;

eval { require DBD::SQLite; };

if ( $@ ) {
    my ($error) = $@ =~ /^(.*?)\n/;
    plan skip_all => "DBD::SQLite could not be used - no database to test with ($error)";
}

plan tests => 2;

my $config = OpenGuides::Config->new(
       vars => {
                 dbtype             => "sqlite",
                 dbname             => "t/node.db",
                 indexing_directory => "t/indexes",
                 script_name        => "wiki.cgi",
                 script_url         => "http://example.com/",
                 site_name          => "Test Site",
                 template_path      => "./templates",
               }
);
eval { require Wiki::Toolkit::Search::Plucene; };
if ( $@ ) { $config->use_plucene ( 0 ) };

    OpenGuides::Test::refresh_db();

my $guide = OpenGuides->new( config => $config );
my $wiki = $guide->wiki;


$wiki->write_node( "Test Page", "#REDIRECT [[Test Page 2]]" )
  or die "Can't write node";
$wiki->write_node( "Test Page 2", "foo" )
  or die "Can't write node";
my $output = eval {
    $guide->display_node( id => "Test Page",
                          return_output => 1,
                          intercept_redirect => 1 );
};
is( $@, "", "->display_node doesn't die when page is a redirect" );

# Old versions of CGI.pm mistakenly print location: instead of Location:
like( $output,
      qr/[lL]ocation: http:\/\/example.com\/wiki.cgi\?id=Test_Page_2\;oldid=Test_Page/,
      "...and redirects to the right place" );

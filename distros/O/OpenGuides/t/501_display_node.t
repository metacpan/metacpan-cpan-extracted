use strict;
use Wiki::Toolkit::Setup::SQLite;
use OpenGuides::Config;
use OpenGuides;
use OpenGuides::Test;
use Test::More;

eval { require DBD::SQLite; };
my $have_sqlite = $@ ? 0 : 1;

if ( $@ ) {
    my ($error) = $@ =~ /^(.*?)\n/;
    plan skip_all => "DBD::SQLite could not be used - no database to test with ($error)";
}

plan tests => 20;

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
                 home_name          => "Home",
                 admin_pass         => "password",
               }
);
eval { require Wiki::Toolkit::Search::Plucene; };
if ( $@ ) { $config->use_plucene ( 0 ) };

my $guide = OpenGuides->new( config => $config );
isa_ok( $guide, "OpenGuides" );
my $wiki = $guide->wiki;
isa_ok( $wiki, "Wiki::Toolkit" );
$wiki->write_node( "Test Page", "foo", undef, { source => "alternate.cgi?Test_Page" } );
my $output = eval {
    $guide->display_node( id => "Test Page", return_output => 1 );
};
is( $@, "", "->display_node doesn't die" );

like( $output, qr{\<a.*?\Qhref="alternate.cgi?id=Test_Page;action=edit"\E>Edit\s+this\s+page</a>}, "...and edit link is redirected to source URL" );
$config->home_name( "My Home Page" );
$output = $guide->display_node( return_output => 1 );
like( $output, qr/My\s+Home\s+Page/, "...and defaults to the home node, and takes notice of what we want to call it" );
like( $output, qr{\Q<a href="wiki.cgi?action=edit;id=My_Home_Page"\E>Edit\s+this\s+page</a>}, "...and home page has an edit link" );
my %tt_vars = $guide->display_node( return_tt_vars => 1 );
ok( defined $tt_vars{recent_changes}, "...and recent_changes is set for the home node even if we have changed its name" );

$wiki->write_node( 'Redirect Test', '#REDIRECT Test Page', undef );

$output = $guide->display_node( id => 'Redirect Test',
                                return_output => 1,
                                intercept_redirect => 1 );

like( $output, qr{^\QLocation: http://example.com/wiki.cgi?id=Test_Page;oldid=Redirect_Test}ms,
      '#REDIRECT redirects correctly' );

$output = $guide->display_node( id => 'Redirect Test', return_output => 1, redirect => 0 );

unlike( $output, qr{^\QLocation: }ms, '...but not with redirect=0' );

# Write a node, then delete one each of its categories and locales.
OpenGuides::Test->write_data(
                              guide => $guide,
                              node => "Non-existent categories and locales",
                              categories => "Does Not Exist\r\nDoes Exist",
                              locales => "Does Not Exist\r\nDoes Exist",
                              return_output => 1,
                            );
foreach my $id ( ( "Category Does Not Exist", "Locale Does Not Exist" ) ) {
    $guide->delete_node(
                         id => $id,
                         password => "password",
                         return_output => 1,
                       );
}

# Check the display comes up right for the existent and nonexistent.
$output = $guide->display_node( id => 'Non-existent categories and locales',
                                return_output => 1
                              );

unlike( $output, qr{\Q<a href="wiki.cgi?Category_Does_Not_Exist"},
    "category name not linked if category does not exist" );
like( $output, qr{\Q<a href="wiki.cgi?Category_Does_Exist"},
    "...but does when it does exist" );
unlike( $output, qr{\Q<a href="wiki.cgi?Locale_Does_Not_Exist"},
    "locale name not linked if category does not exist" );
like( $output, qr{\Q<a href="wiki.cgi?Locale_Does_Exist"},
    "...but does when it does exist" );

# Check it works when the case is different too.
OpenGuides::Test->write_data(
                              guide => $guide,
                              node => "Existent categories and locales",
                              categories => "does exist",
                              locales => "does exist",
                              return_output => 1,
                            );

$output = $guide->display_node( id => "Existent categories and locales",
                                return_output => 1
                              );
like( $output, qr{\Q<a href="wiki.cgi?Category_Does_Exist"},
    "wrongly-cased categories are linked as they should be" );
like( $output, qr{\Q<a href="wiki.cgi?Locale_Does_Exist"},
    "wrongly-cased locales are linked as they should be" );

$output = $guide->display_node( id => "Does not exist",
                                return_output => 1
                              );
like( $output, qr{\QWe don't have a node called "Does not exist".},
    "not found message shows up" );
unlike( $output, qr{\QRevision 0},
    "bogus revision number doesn't show up" );
unlike( $output, qr{\QLast edited},
    "bogus last edited doesn't show up" );
like ( $output, qr{404 Not Found}, "404 status for empty node" );

# Make sure categories with numbers in are sorted correctly.  Guess which pub
# I was in when I decided to finally fix this bug.
OpenGuides::Test->write_data(
                              guide => $guide,
                              node => "Dog And Bull",
                              categories => "GBG\r\nGBG2008\r\nGBG2011\r\nGBG2012\r\nGBG2007\r\nGBG2010\r\nGBG2009",
                              return_output => 1,
                            );

%tt_vars = $guide->display_node( id => "Dog And Bull", return_tt_vars => 1 );
is_deeply( $tt_vars{category},
           [ qw( GBG GBG2007 GBG2008 GBG2009 GBG2010 GBG2011 GBG2012 ) ],
           "categories with numbers in sorted correctly" );

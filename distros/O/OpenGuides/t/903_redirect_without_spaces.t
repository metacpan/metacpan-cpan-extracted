use strict;
use OpenGuides;
use OpenGuides::CGI;
use OpenGuides::Test;
use Test::More;

eval { require DBD::SQLite; };
if ( $@ ) {
    my ($error) = $@ =~ /^(.*?)\n/;
    plan skip_all =>
        "DBD::SQLite could not be used - no database to test with. ($error)";
}

plan tests => 27;

# Clear out the database from any previous runs.
OpenGuides::Test::refresh_db();

my $config = OpenGuides::Test->make_basic_config;
my $guide = OpenGuides->new( config => $config );
my $wiki = $guide->wiki;

# Write a couple of nodes, one with a single-word name, one with multiple.
OpenGuides::Test->write_data(
                              guide => $guide,
                              node  => "Croydon",
                              return_output => 1,
                            );
OpenGuides::Test->write_data(
                              guide => $guide,
                              node  => "Ship Of Fools",
                              return_output => 1,
                            );

my ( $q, $url );

# Check we don't get redirects with the single-word node.

$q = CGI->new( "" );
$q->param( -name => "id", -value => "Croydon" );
$url = OpenGuides::CGI->check_spaces_redirect( cgi_obj => $q, wiki => $wiki );
ok( !$url, "No URL redirect for id param with single-word node" );

$q = CGI->new( "" );
$q->param( -name => "title", -value => "Croydon" );
$url = OpenGuides::CGI->check_spaces_redirect( cgi_obj => $q, wiki => $wiki );
ok( !$url, "...nor for title param" );

$q = CGI->new( "Croydon" );
$url = OpenGuides::CGI->check_spaces_redirect( cgi_obj => $q, wiki => $wiki );
ok( !$url, "...nor for whole-string param" );

# Nor with the "proper" URLs with underscores.

$q = CGI->new( "" );
$q->param( -name => "id", -value => "Ship_Of_Fools" );
$url = OpenGuides::CGI->check_spaces_redirect( cgi_obj => $q, wiki => $wiki );
ok( !$url, "No URL redirect for id param with underscores" );

$q = CGI->new( "" );
$q->param( -name => "title", -value => "Ship_Of_Fools" );
$url = OpenGuides::CGI->check_spaces_redirect( cgi_obj => $q, wiki => $wiki );
ok( !$url, "...nor for title param with underscores" );

$q = CGI->new( "Ship_Of_Fools" );
$url = OpenGuides::CGI->check_spaces_redirect( cgi_obj => $q, wiki => $wiki );
ok( !$url, "...nor for whole-string node param with underscores" );

# Now check that we get redirects when supplying CGI objects with spaces
# in the node parameter.

# First encoded spaces.

$q = CGI->new( "" );
$q->param( -name => "id", -value => "Ship%20Of%20Fools" );
$url = OpenGuides::CGI->check_spaces_redirect( cgi_obj => $q, wiki => $wiki );
ok( $url, "We do get a redirect for id param with encoded spaces" );
is( $url, "http://localhost?id=Ship_Of_Fools", "...the right one" );
$q->param( -name => "action", -value => "edit" );
$url = OpenGuides::CGI->check_spaces_redirect( cgi_obj => $q, wiki => $wiki );
ok( $url, "...also get redirect with edit param" );
is( $url, "http://localhost?id=Ship_Of_Fools;action=edit",
    "...the right one" );

$q = CGI->new( "" );
$q->param( -name => "title", -value => "Ship%20Of%20Fools" );
$url = OpenGuides::CGI->check_spaces_redirect( cgi_obj => $q, wiki => $wiki );
ok( $url, "...also get redirect for title param with encoded spaces" );
is( $url, "http://localhost?title=Ship_Of_Fools", "...the right one" );
$q->param( -name => "action", -value => "edit" );
$url = OpenGuides::CGI->check_spaces_redirect( cgi_obj => $q, wiki => $wiki );
ok( $url, "...also get redirect with edit param" );
is( $url, "http://localhost?title=Ship_Of_Fools;action=edit",
    "...the right one" );

$q = CGI->new( "Ship%20Of%20Fools" );
$url = OpenGuides::CGI->check_spaces_redirect( cgi_obj => $q, wiki => $wiki );
ok( $url,
    "...also get redirect for whole-string node param with encoded spaces" );
is( $url, "http://localhost?id=Ship_Of_Fools", "...the right one" );

# Try it with plus signs.

$q = CGI->new( "" );
$q->param( -name => "id", -value => "Ship+Of+Fools" );
$url = OpenGuides::CGI->check_spaces_redirect( cgi_obj => $q, wiki => $wiki );
ok( $url, "We do get a redirect for id param with plus signs" );
is( $url, "http://localhost?id=Ship_Of_Fools", "...the right one" );
$q->param( -name => "action", -value => "edit" );
$url = OpenGuides::CGI->check_spaces_redirect( cgi_obj => $q, wiki => $wiki );
ok( $url, "...also get redirect with edit param" );
is( $url, "http://localhost?id=Ship_Of_Fools;action=edit",
    "...the right one" );

$q = CGI->new( "" );
$q->param( -name => "title", -value => "Ship+Of+Fools" );
$url = OpenGuides::CGI->check_spaces_redirect( cgi_obj => $q, wiki => $wiki );
ok( $url, "...and for title param with plus signs" );
is( $url, "http://localhost?title=Ship_Of_Fools", "...the right one" );
$q->param( -name => "action", -value => "edit" );
$url = OpenGuides::CGI->check_spaces_redirect( cgi_obj => $q, wiki => $wiki );
ok( $url, "...also get redirect with edit param" );
is( $url, "http://localhost?title=Ship_Of_Fools;action=edit",
    "...the right one" );

$q = CGI->new( "Ship+Of+Fools" );
$url = OpenGuides::CGI->check_spaces_redirect( cgi_obj => $q, wiki => $wiki );
ok( $url, "...and for whole-string node param with plus signs" );
is( $url, "http://localhost?id=Ship_Of_Fools", "...the right one" );

# Make sure commas don't get escaped, for it is unnecessary and ugly.
OpenGuides::Test->write_data(
                              guide => $guide,
                              node  => "Londis, Pitlake",
                              return_output => 1,
                            );
$q = CGI->new( "Londis, Pitlake" );
$url = OpenGuides::CGI->check_spaces_redirect( cgi_obj => $q, wiki => $wiki );
is( $url, "http://localhost?id=Londis,_Pitlake", "Commas don't get escaped." );

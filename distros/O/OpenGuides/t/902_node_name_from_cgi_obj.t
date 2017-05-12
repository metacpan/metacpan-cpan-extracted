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

plan tests => 18;

# Clear out the database from any previous runs.
OpenGuides::Test::refresh_db();

my $config = OpenGuides::Test->make_basic_config;
my $guide = OpenGuides->new( config => $config );
my $wiki = $guide->wiki;

# Write a node.
OpenGuides::Test->write_data(
                              guide => $guide,
                              node  => "Ship Of Fools",
                              return_output => 1,
                            );

my ( $q, $node, $param );

# Test we get the right name/param with various CGI objects.  Make sure to
# always start with an empty one by passing the empty string as arg.

$q = CGI->new( "" );
$q->param( -name => "id", -value => "Ship_Of_Fools" );
$node = OpenGuides::CGI->extract_node_name( cgi_obj => $q, wiki => $wiki );
is( $node, "Ship Of Fools",
    "extract_node_name gives correct name with id param" );
$param = OpenGuides::CGI->extract_node_param( cgi_obj => $q, wiki => $wiki );
is( $param, "Ship_Of_Fools", "...as does extract_node_param" );

$q = CGI->new( "" );
$q->param( -name => "title", -value => "Ship_Of_Fools" );
$node = OpenGuides::CGI->extract_node_name( cgi_obj => $q, wiki => $wiki );
is( $node, "Ship Of Fools", "title param works for node name" );
$param = OpenGuides::CGI->extract_node_param( cgi_obj => $q, wiki => $wiki );
is( $param, "Ship_Of_Fools", "...and for node param" );

$q = CGI->new( "Ship_Of_Fools" );
$node = OpenGuides::CGI->extract_node_name( cgi_obj => $q, wiki => $wiki );
is( $node, "Ship Of Fools", "whole-string node param works for node name" );
$param = OpenGuides::CGI->extract_node_param( cgi_obj => $q, wiki => $wiki );
is( $param, "Ship_Of_Fools", "...and for node param" );

# Now try it with encoded spaces instead of underscores.
$q = CGI->new( "" );
$q->param( -name => "id", -value => "Ship%20Of%20Fools" );
$node = OpenGuides::CGI->extract_node_name( cgi_obj => $q, wiki => $wiki );
is( $node, "Ship Of Fools",
    "id param works for node name with encoded spaces" );
$param = OpenGuides::CGI->extract_node_param( cgi_obj => $q, wiki => $wiki );
is( $param, "Ship Of Fools", "...as does node param" );

$q = CGI->new( "" );
$q->param( -name => "title", -value => "Ship%20Of%20Fools" );
$node = OpenGuides::CGI->extract_node_name( cgi_obj => $q, wiki => $wiki );
is( $node, "Ship Of Fools",
    "title param works for node name with encoded spaces" );
$param = OpenGuides::CGI->extract_node_param( cgi_obj => $q, wiki => $wiki );
is( $param, "Ship Of Fools", "...as does node param" );

$q = CGI->new( "Ship%20Of%20Fools" );
$node = OpenGuides::CGI->extract_node_name( cgi_obj => $q, wiki => $wiki );
is( $node, "Ship Of Fools",
    "whole-string node param works for node name with encoded spaces" );
$param = OpenGuides::CGI->extract_node_param( cgi_obj => $q, wiki => $wiki );
is( $param, "Ship Of Fools", "...as does node param" );

# Finally try it with plus signs.
$q = CGI->new( "" );
$q->param( -name => "id", -value => "Ship+Of+Fools" );
$node = OpenGuides::CGI->extract_node_name( cgi_obj => $q, wiki => $wiki );
is( $node, "Ship Of Fools", "id param works for node name with plus signs" );
$param = OpenGuides::CGI->extract_node_param( cgi_obj => $q, wiki => $wiki );
is( $param, "Ship Of Fools", "...as does node param" );

$q = CGI->new( "" );
$q->param( -name => "title", -value => "Ship+Of+Fools" );
$node = OpenGuides::CGI->extract_node_name( cgi_obj => $q, wiki => $wiki );
is( $node, "Ship Of Fools",
    "title param works for node name with plus signs" );
$param = OpenGuides::CGI->extract_node_param( cgi_obj => $q, wiki => $wiki );
is( $param, "Ship Of Fools", "...as does node param" );

$q = CGI->new( "Ship+Of+Fools" );
$node = OpenGuides::CGI->extract_node_name( cgi_obj => $q, wiki => $wiki );
is( $node, "Ship Of Fools",
    "whole-string node param works for node name with plus signs" );
$param = OpenGuides::CGI->extract_node_param( cgi_obj => $q, wiki => $wiki );
is( $param, "Ship Of Fools", "...as does node param" );

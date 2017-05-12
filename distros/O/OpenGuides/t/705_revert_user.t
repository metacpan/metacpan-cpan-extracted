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

plan tests => 23;

    OpenGuides::Test::refresh_db();

my $config = OpenGuides::Test->make_basic_config;
$config->script_name( "wiki.cgi" );
$config->script_url( "http://example.com/" );
my $guide = OpenGuides->new( config => $config );
isa_ok( $guide, "OpenGuides" );
my $wiki = $guide->wiki;
isa_ok( $wiki, "Wiki::Toolkit" );


my %details;
my %vars;


# Add a page, user is bob
my $q = CGI->new;
$q->param( -name => "content", -value => "foo" );
$q->param( -name => "categories", -value => "Alpha" );
$q->param( -name => "locales", -value => "" );
$q->param( -name => "phone", -value => "" );
$q->param( -name => "fax", -value => "" );
$q->param( -name => "website", -value => "" );
$q->param( -name => "hours_text", -value => "" );
$q->param( -name => "address", -value => "" );
$q->param( -name => "postcode", -value => "" );
$q->param( -name => "map_link", -value => "" );
$q->param( -name => "os_x", -value => "" );
$q->param( -name => "os_y", -value => "" );
$q->param( -name => "username", -value => "bob" );
$q->param( -name => "comment", -value => "foo" );
$q->param( -name => "edit_type", -value => "Minor tidying" );
$ENV{REMOTE_ADDR} = "127.0.0.1";

my $output = $guide->commit_node(
                                  return_output => 1,
                                  id => "Wombats",
                                  cgi_obj => $q,
                                );

%details = $wiki->retrieve_node("Wombats");
is( $details{version}, 1 );
is( $details{metadata}->{username}->[0], "bob" );


# Now add a new version, user is jim
$q->param( -name => "categories", -value => "Alpha\r\nBeta" );
$q->param( -name => "locales", -value => "Hello" );
$q->param( -name => "edit_type", -value => "Normal edit" );
$q->param( -name => "checksum", -value => $details{checksum} );
$q->param( -name => "username", -value => "jim" );
$output = $guide->commit_node(
                                  return_output => 1,
                                  id => "Wombats",
                                  cgi_obj => $q,
                                );

%details = $wiki->retrieve_node("Wombats");
is( $details{version}, 2 );
is( $details{metadata}->{username}->[0], "jim" );


# And again, another bob one
$q->param( -name => "checksum", -value => $details{checksum} );
$q->param( -name => "username", -value => "bob" );
$output = $guide->commit_node(
                                  return_output => 1,
                                  id => "Wombats",
                                  cgi_obj => $q,
                                );

%details = $wiki->retrieve_node("Wombats");
is( $details{version}, 3 );
is( $details{metadata}->{username}->[0], "bob" );

# Finally, a foo one
$q->param( -name => "checksum", -value => $details{checksum} );
$q->param( -name => "username", -value => "foo" );
$output = $guide->commit_node(
                                  return_output => 1,
                                  id => "Wombats",
                                  cgi_obj => $q,
                                );

%details = $wiki->retrieve_node("Wombats");
is( $details{version}, 4 );
is( $details{metadata}->{username}->[0], "foo" );


# Check that there are 2 versions for bob
$q = CGI->new;
%vars = $guide->revert_user_interface(
                            return_tt_vars => 1,
                            return_output => 0,
                            username => 'bob'
);
my @edits = @{$vars{'edits'}};
is( scalar @edits, 2 );

# And one for foo
%vars = $guide->revert_user_interface(
                            return_tt_vars => 1,
                            return_output => 0,
                            username => 'foo'
);
@edits = @{$vars{'edits'}};
is( scalar @edits, 1 );

# And one for jim
%vars = $guide->revert_user_interface(
                            return_tt_vars => 1,
                            return_output => 0,
                            username => 'jim'
);
@edits = @{$vars{'edits'}};
is( scalar @edits, 1 );


# Currently, we're on v4
%details = $wiki->retrieve_node("Wombats");
is( $details{'version'}, 4 );


# Delete for foo - last one
%vars = $guide->revert_user_interface(
                            return_tt_vars => 1,
                            return_output => 0,
                            password => $guide->config->admin_pass,
                            username => 'foo'
);
@edits = @{$vars{'edits'}};
is( scalar @edits, 0 );

%vars = $guide->revert_user_interface(
                            return_tt_vars => 1,
                            return_output => 0,
                            username => 'foo'
);
@edits = @{$vars{'edits'}};
is( scalar @edits, 0 );


# Now down to version 3
%details = $wiki->retrieve_node("Wombats");
is( $details{'version'}, 3 );


# Now for jim - middle one (v2)
%vars = $guide->revert_user_interface(
                            return_tt_vars => 1,
                            return_output => 0,
                            password => $guide->config->admin_pass,
                            username => 'jim'
);
@edits = @{$vars{'edits'}};
is( scalar @edits, 0 );

%vars = $guide->revert_user_interface(
                            return_tt_vars => 1,
                            return_output => 0,
                            username => 'jim'
);
@edits = @{$vars{'edits'}};
is( scalar @edits, 0 );


# Still on v3
%details = $wiki->retrieve_node("Wombats");
is( $details{'version'}, 3 );


# Now for bob - first and last
%vars = $guide->revert_user_interface(
                            return_tt_vars => 1,
                            return_output => 0,
                            password => $guide->config->admin_pass,
                            username => 'bob'
);
@edits = @{$vars{'edits'}};
is( scalar @edits, 0 );

%vars = $guide->revert_user_interface(
                            return_tt_vars => 1,
                            return_output => 0,
                            username => 'bob'
);
@edits = @{$vars{'edits'}};
is( scalar @edits, 0 );


# Page is gone
%details = $wiki->retrieve_node("Wombats");
is( $details{'version'}, 0 );

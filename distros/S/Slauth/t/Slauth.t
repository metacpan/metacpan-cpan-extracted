# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Slauth.t'

#########################

# change 'tests => x' to 'tests => last_test_to_print';

use strict;
use Cwd;
BEGIN {
	$ENV{SLAUTH_REALM} = "localhost";
	$ENV{SLAUTH_CONFIG} = getcwd."/t/slauth.conf";
}
use Apache::Test qw(plan ok have_lwp);
use Apache::TestUtil;
use Apache::TestRequest qw(GET POST);
use Apache2::Const qw(HTTP_OK HTTP_UNAUTHORIZED AUTH_REQUIRED);
use HTTP::Response;
#use Data::Dumper;
BEGIN {
	plan tests => 17, have_lwp;
	ok(1);
}

use Slauth;
BEGIN {
	ok(1);
}

use Slauth::Storage::DB;
BEGIN {
	ok(1);
}

use Slauth::Storage::User_DB;
BEGIN {
	ok(1);
}

use Slauth::Storage::Session_DB;
BEGIN {
	ok(1);
}

use Slauth::User::Web;
BEGIN {
	ok(1);
}

#
# post-loading test code begins here
#

my $res;

#
# quick return code tests on the server
#

# Test: access to /slauth should return HTTP OK
$res = GET "/slauth";
ok $res->code, HTTP_OK; # HTTP OK expected

# Test: access to / should return HTTP OK
$res = GET "/";
ok $res->code, HTTP_OK; # HTTP OK expected

# Test: access to /protected/ should return HTTP OK
#$res = GET "/protected/";
#ok $res->code, HTTP_OK; # HTTP OK expected

# Test: access to /basic-protected/ should return HTTP UNAUTHORIZED
#$res = GET "/basic-protected/";
#ok $res->code, HTTP_UNAUTHORIZED; # HTTP UNAUTHORIZED expected

#
# write and read a user record
#

# set up data for user record tests
my %user_data = (
	"domain" => "localhost",
	"user" => "fnord",
	"name" => "Joe Fnord",
	"email" => "joe\@fnord.fu",
	"password" => "foo",
	"group" => [ "foo", "bar", "baz" ],
);

# Test: write a user record
{
	# do this in its own scope to prevent any results being used later

	my $config = Slauth::Config->new();
	ok defined $config;

	#print STDERR Dumper($config);
	my $storage = $config->get( "storage" );
	ok $storage, "Slauth::Storage::DB";

	my $user_db = Slauth::Storage::User_DB->new( $config );
	ok defined $user_db;

	my $status = $user_db->write_record ( $user_data{user}, $user_data{password}, $user_data{name}, $user_data{email}, @{$user_data{group}});
	ok (defined $status), 1;	
}

# Test: read back the same record
{
	my $config = Slauth::Config->new();
	ok defined $config;

	my ( $user_login, $user_pw_hash, $user_salt, $user_name,
		$user_email, $user_groups ) =
		Slauth::Storage::User_DB::get_user($user_data{user}, $config);
	ok $user_login, $user_data{user};
	ok $user_name, $user_data{name};
	ok $user_email, $user_data{email};
	ok $user_groups, join( ",", @{$user_data{group}});
}

1;

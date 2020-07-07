#!perl

BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    print qq{1..0 # SKIP these tests are for testing by the author\n};
    exit
  }
}


# Reply with bad params.

use FindBin;
use Test::Most tests => 17;
use Test::File::ShareDir::Dist { 'OAuthomatic' => 'share/' };
use WWW::Mechanize;
use Test::WWW::Mechanize;

my $m = Test::WWW::Mechanize->new(autocheck=>0, stack_depth=>5);

use_ok('OAuthomatic');
use_ok('OAuthomatic::Internal::MicroWeb');


my $web = new_ok( 'OAuthomatic::Internal::MicroWeb' => [
    config=>OAuthomatic::Config->new(
        app_name=>'10-test'),
    server => OAuthomatic::Server->new(
        site_name => "NonExistantOAuthSite.com",
        site_client_creation_page => "http://non_existant_oauth_site.com/grant/app/permissions",
        site_client_creation_desc => "NonExistant Developers Page",
        site_client_creation_help => <<"END",
Create <New App> button and fill the form to create client tokens.
Use value labelled <Application Identifier> as client key, and
<Application Shared Secret> as client secret.
END
        # Those are not used here, but we must fill sth
        oauth_authorize_page => 'http://not.used',
        oauth_temporary_url => 'http://not.used',
        oauth_token_url => 'http://not.used',
       ),
   ]);
ok( $web, "MicroWeb->new worked" );
my $url = $web->callback_url;
like( $url , qr{^http://localhost:\d+/oauth_granted$}, "proper callback_url" );
ok( $web->start_using, "start" );

ok( $m->get( $url . '?oauth_verifier=VER&badly_named_oauth_token=TOK'), "get" );
## diag( "Content: ", $m->content );
ok( $m->success, "result reported" );
is( $m->status, 200, "got 200" );
$m->content_like(qr{^\n?<html>}, "got html" );
$m->content_like(qr{<title>Unexpected reply}, "... with proper title" );
$m->content_like(qr{NonExistantOAuthSite}, "... and comments" );
$m->content_like(qr{Invalid or unknown}, "... and comments" );
my $result;
# FIXME what here
throws_ok { $web->wait_for_oauth_grant } "OAuthomatic::Error::Generic", "wait";

$web->finish_using;

ok( $m->get($url) );
ok( ! $m->success, "web is shut down after receiving data");
is( $m->status, 500, "... and it is properly reported");

done_testing();

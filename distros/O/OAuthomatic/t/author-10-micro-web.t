#!perl

BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for testing by the author');
  }
}


# Good path, all data OK etc.

use FindBin;
use Test::Most tests => 20;
use Test::File::ShareDir::Dist { 'OAuthomatic' => 'share/' };
use Test::WWW::Mechanize;
use utf8;

my $m = Test::WWW::Mechanize->new(autocheck=>0, stack_depth=>5);

use_ok('OAuthomatic');
use_ok('OAuthomatic::Internal::MicroWeb');

my $web = OAuthomatic::Internal::MicroWeb->new(
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
   );
ok( $web, "MicroWeb->new worked" );
my $url = $web->callback_url;
like( $url , qr{^http://localhost:\d+/oauth_granted$}, "proper callback_url" );
ok( $web->start, "start" );

is( $web->is_running, 1);

$m->get_ok( $url . '?oauth_verifier=VER&oauth_token=TOK');
## diag( "Content: ", $m->content );
is( $m->success, 1, "get-ok" );
is( $m->status, 200, "get-200" );
$m->content_like( qr{^\n?<html>}, "got html" );
$m->title_like(qr/^Access properly granted/);
$m->content_like( qr{properly obtained access}, "... and comments" );
$m->content_like( qr{NonExistantOAuthSite}, "... and filled params" );
my $result;
ok( $result = $web->wait_for_oauth_grant, "wait" );

cmp_deeply( $result, (bless {
    verifier => 'VER',
    token => 'TOK',
   }, "OAuthomatic::Types::Verifier"), "proper result" );

$web->stop;
is( $web->is_running, 0);

ok( $m->get($url) );
ok( ! $m->success, "web is shut down after stop");
is( $m->status, 500, "... and it is properly reported");

undef $web;
pass( "web destructed" );

done_testing();

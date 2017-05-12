use strict;
use warnings;
use lib 't';

use Mojolicious::Lite;

use Test::More tests => 35;
use Test::Mojo;

use TestHelper;

my $error_checker = sub {
    my ($self, %options) = @_;
    my $reply  = 'No error';

    eval { $self->digest_auth(%options) };
    if($@) {
        $reply = $@;
        $self->res->code(500);
    }

    $self->render(text => $reply);
};

# TODO: Need test with options to plugin call
plugin 'digest_auth';

get '/no_allow' => sub { $error_checker->(shift) };
get '/unsupported_qop' => sub { $error_checker->(shift, allow => users(), qop => 'huh?') };
get '/unsupported_algorithm' => sub { $error_checker->(shift, allow => users(), algorithm => '3DES') };
get '/MD5-sess_no_qop' => sub { $error_checker->(shift, allow => users(), algorithm => 'MD5-sess', qop => '') };

my $t = Test::Mojo->new;
$t->get_ok('/no_allow');
$t->status_is(500);
$t->content_like(qr/you must setup an authentication source/);

$t->get_ok('/MD5-sess_no_qop');
$t->status_is(500);
$t->content_like(qr/requires a qop/);

$t->get_ok('/unsupported_qop');
$t->status_is(500);
$t->content_like(qr/unsupported qop/);

$t->get_ok('/unsupported_algorithm');
$t->status_is(500);
$t->content_like(qr/unsupported algorithm/);

any '/test_defaults' => create_action();
$t->get_ok('/test_defaults')
  ->status_is(401)
  ->header_like('WWW-Authenticate', qr/^Digest\s/)
  ->header_like('WWW-Authenticate', qr/realm="WWW"/)
  ->header_like('WWW-Authenticate', qr/nonce="[^"]+"/)
  ->header_like('WWW-Authenticate', qr/opaque="\w+"/)
  ->header_like('WWW-Authenticate', qr/domain="\/"/)
  ->header_like('WWW-Authenticate', qr/algorithm=MD5/)
  ->header_like('WWW-Authenticate', qr/qop="auth"/)  #,auth-int"/)
  ->content_isnt("You're in!");

# Belongs here?
# By default support_broken_browsers = 1
$t->get_ok('/test_defaults?a=b')
  ->status_is(401);
$t->get_ok('/test_defaults?a=b', { %{build_auth_request($t->tx)}, 'User-Agent' => IE6 })
  ->status_is(200)
  ->content_is("You're in!");
####

get '/test_defaults_overridden' => create_action(realm     => 'MD5-sess Realm',
                                                 domain    => 'example.com,dev.example.com',
                                                 algorithm => 'MD5-sess');

$t->get_ok('/test_defaults_overridden')
  ->status_is(401)
  ->header_like('WWW-Authenticate', qr/realm="MD5-sess Realm"/)
  ->header_like('WWW-Authenticate', qr/domain="example.com,dev.example.com"/)
  ->header_like('WWW-Authenticate', qr/algorithm=MD5-sess/);

get '/test_no_qop' => create_action(qop => '');
$t->get_ok('/test_no_qop')
  ->status_is(401)
  ->header_unlike('WWW-Authenticate', qr/qop="\w+"/);

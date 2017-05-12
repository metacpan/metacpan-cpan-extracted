use Mojo::Base -strict;

use Test::More;
use Mojolicious::Lite;
use Test::Mojo;

plugin 'SecureOnly';

get '/:number' => [number => qr/0/] => sub {
  my $c   = shift;
  my $url = $c->req->url->to_abs;
  $c->res->headers->header('X-Original' => $c->tx->original_remote_address);
  my $address = $c->tx->remote_address;
  my $num     = $c->param('number');
  $c->render(text => "$url-$address-$num");
};

my $t = Test::Mojo->new;

# Behind a proxy, reverse_proxy correctly enabled
#   Redirect to https
{
  local $ENV{MOJO_REVERSE_PROXY} = 1;
  $t->ua->server->restart;
  $t->get_ok('/0' => {'X-Forwarded-For' => '192.0.2.2, 192.0.2.1'})
    ->status_is(302)->header_unlike('X-Original' => qr/192\.0\.2\.1/)
    ->header_like(Location => qr!https://127\.0\.0\.1:\d+/0$!)
}

# Behind a proxy, reverse_proxy incorrectly disabled
#   No redirect or else get infinite redirects
{
  local $ENV{MOJO_REVERSE_PROXY} = 0;
  $t->ua->server->restart;
  $t->get_ok('/0' => {'X-Forwarded-For' => '192.0.2.2, 192.0.2.1'})
    ->status_is(200)->header_unlike('X-Original' => qr/192\.0\.2\.1/)
    ->content_like(qr!http://127\.0\.0\.1:\d+/0-127\.0\.0\.1-0$!);
}

# Not behind a proxy, reverse_proxy incorrectly enabled
#   Redirect to https
{
  local $ENV{MOJO_REVERSE_PROXY} = 1;
  $t->ua->server->restart;
  $t->get_ok('/0')
    ->status_is(302)->header_unlike('X-Original' => qr/192\.0\.2\.1/)
    ->header_like(Location => qr!https://127\.0\.0\.1:\d+/0$!);
}

# Not behind a proxy, reverse_proxy correctly disabled
#   Redirect to https
{
  local $ENV{MOJO_REVERSE_PROXY} = 0;
  $t->ua->server->restart;
  $t->get_ok('/0')
    ->status_is(302)->header_unlike('X-Original' => qr/192\.0\.2\.1/)
    ->header_like(Location => qr!https://127\.0\.0\.1:\d+/0$!)
}

done_testing;

package AA;

use strictures 2;
use IO::Async::Loop;
use Net::Async::HTTP;
use HTTP::Request::Common;
use Object::Tap;
use PerlX::AsyncAwait::Runtime;
use PerlX::AsyncAwait::Compiler;

my $http = Net::Async::HTTP->new;

my $loop = IO::Async::Loop->new->$_tap(add => $http);

my $go = async_sub {
  warn "Starting";
  my $res = await $http->do_request(request => GET("http://trout.me.uk"));
  return $res->content;
};

my $f = $go->();

warn "Request started";

$loop->await($f);

print join("\n", (split("\n", $f->get))[0..9], '');

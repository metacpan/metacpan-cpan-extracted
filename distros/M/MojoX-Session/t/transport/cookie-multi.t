use Test::More tests => 4;

use lib 't/lib';

use_ok('MojoX::Session');
use_ok('MojoX::Session::Transport::Cookie');

use Mojo::Transaction::HTTP;
use Mojo::Cookie::Response;
use MojoX::Session::Store::Dummy;

my $cookie = Mojo::Cookie::Request->new(name => 'sid', value => 'bar');
my $cookie2 = Mojo::Cookie::Request->new(name => 'dis', value => 'foo');

my $tx = Mojo::Transaction::HTTP->new;
$tx->req->cookies($cookie, $cookie2);

my $session = MojoX::Session->new(
    tx        => $tx,
    store     => MojoX::Session::Store::Dummy->new,
    transport => MojoX::Session::Transport::Cookie->new
);

my $sid = $session->create;
$session->flush;
ok($sid);

$cookie = Mojo::Cookie::Request->new(name => 'sid', value => $sid);
$tx = Mojo::Transaction::HTTP->new;
$tx->req->cookies($cookie2, $cookie);
$session->tx($tx);
is($session->load, $sid);

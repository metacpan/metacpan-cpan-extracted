use Mojo::Base -strict;
use Test::More;
use Mojo::Transmission;

plan skip_all => 'reason' if 0;

my $t = Mojo::Transmission->new;
my %transmission_response = (arguments => {});
my ($tx, $req);

is_deeply($t->default_trackers, [], 'no default_trackers');
is $t->url, 'http://localhost:9091/transmission/rpc', 'default url';

$ENV{TRANSMISSION_RPC_URL} = 'http://example.com/transmission/rpc';
is(Mojo::Transmission->new->url, 'http://example.com/transmission/rpc', 'TRANSMISSION_RPC_URL');

Mojo::Util::monkey_patch(
  'Mojo::UserAgent',
  post => sub {
    my $cb = ref $_[-1] eq 'CODE' ? pop : undef;
    my $ua = shift;
    my $tx = Mojo::Transaction::HTTP->new;

    $req = $_[3];
    $tx->res->code(200);
    $tx->res->body(Mojo::JSON::encode_json(\%transmission_response));

    return $cb ? $ua->$cb($tx) : $tx;
  }
);

$t->add({hash => 'a$%bc'});
is_deeply($req,
  {arguments => {filename => 'magnet:?xt=urn:btih:a$%bc&dn='}, 'method' => 'torrent-add'},
  'add hash');

$t->add({dn => '&%9', xt => 'what3ver%'});
is_deeply($req,
  {arguments => {filename => 'magnet:?xt=what3ver%&dn=&%9'}, 'method' => 'torrent-add'},
  'add xt');

$t->add({url => 'something'});
is_deeply($req, {arguments => {filename => 'something'}, 'method' => 'torrent-add'}, 'add url');

$t->session([qw(x y z)]);
is_deeply($req, {arguments => [qw(x y z)], 'method' => 'session-get'}, 'session get');

$t->session({x => 42, y => 24});
is_deeply($req, {arguments => {x => 42, y => 24}, 'method' => 'session-set'}, 'session set');

$t->stats;
is_deeply($req, {arguments => {}, 'method' => 'session-stats'}, 'session stats');

$t->torrent(['x'], [1, 2, 3]);
is_deeply(
  $req,
  {arguments => {fields => ['x'], ids => [1, 2, 3]}, 'method' => 'torrent-get'},
  'torrent get ids'
);

$t->torrent(['x']);
is_deeply($req, {arguments => {fields => ['x']}, 'method' => 'torrent-get'}, 'torrent get all');

$t->torrent({x => 42}, [1]);
is_deeply($req, {arguments => {x => 42, ids => [1]}, 'method' => 'torrent-set'}, 'torrent set');

$t->torrent(purge => [1]);
is_deeply(
  $req,
  {
    arguments => {'delete-local-data' => Mojo::JSON->true, ids => [1]},
    'method'  => 'torrent-remove'
  },
  'torrent purge'
);

$t->torrent(remove => [1]);
is_deeply($req, {arguments => {ids => [1]}, 'method' => 'torrent-remove'}, 'torrent remove');

$t->torrent(stop => [1]);
is_deeply($req, {arguments => {ids => [1]}, 'method' => 'torrent-stop'}, 'torrent stop');

done_testing;

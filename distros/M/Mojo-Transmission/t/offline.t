use Mojo::Base -strict;
use Mojo::Transmission;
use Test::Mojo;
use Test::More;

my (@res, @rpc);
use Mojolicious::Lite;
post '/rpc' => sub {
  my $c = shift;
  push @rpc, $c->req->json;
  $c->render(json => shift @res || {});
};

my $transmission = Mojo::Transmission->new;
my $res          = {};

my $t = Test::Mojo->new;
$t->post_ok('/rpc')->status_is(200);
$transmission->url($t->ua->server->nb_url->clone->path('/rpc'));

note 'session get';
push @res, {result => 'success', arguments => {'config-dir' => '/tmp'}};
$transmission->session([], \&cb);
Mojo::IOLoop->start;
ok $res->{'config-dir'}, 'session config-dir';

push @res, {result => 'success', arguments => {'config-dir' => '/tmp'}};
$transmission->session_p([])->then(sub { $res = shift })->wait;
ok $res->{'config-dir'}, 'session_p config-dir';

note 'session set';
@rpc = ();
$transmission->session_p({'alt-speed-down' => 42})->wait;
is_deeply(\@rpc, [{arguments => {'alt-speed-down' => 42}, method => 'session-set'}], 'session-set');

note 'stats';
push @res, {result => 'success', arguments => {'current-stats' => {what => 'ever'}}};
$transmission->stats_p->then(sub { $res = shift })->wait;
ok $res->{'current-stats'}, 'current-stats';

note 'torrents-get';
@rpc = ();
$transmission->torrent_p(['id'])->wait;
is_deeply(\@rpc, [{arguments => {fields => ['id']}, method => 'torrent-get'}], 'torrent-get id');

@rpc = ();
$transmission->torrent_p(['id'], 2)->wait;
is_deeply(
  \@rpc,
  [{arguments => {fields => ['id'], ids => [2]}, method => 'torrent-get'}],
  'torrent-get id by ids'
);

note 'torrents-set';
@rpc = ();
$transmission->torrent_p({x => 'y'}, 3)->wait;
is_deeply(\@rpc, [{arguments => {x => 'y', ids => [3]}, method => 'torrent-set'}], 'torrent-set');

note 'torrents-actions';
@rpc = ();
$transmission->torrent_p(purge => 4)->wait;
is_deeply(
  \@rpc,
  [{arguments => {'delete-local-data' => Mojo::JSON->true, ids => [4]}, method => 'torrent-remove'
  }],
  'purge'
);

@rpc = ();
$transmission->torrent_p(start => 5)->wait;
is_deeply(\@rpc, [{arguments => {ids => [5]}, method => 'torrent-start'}], 'torrent-start');

@rpc = ();
$transmission->torrent_p('remove')->wait;
is_deeply(
  \@rpc,
  [{arguments => {ids => undef}, method => 'torrent-remove'}],
  'id is required for action'
);

$transmission->ua($t->ua);
$transmission->url($t->ua->server->url->clone->path('/rpc'));
push @res, {result => 'success', arguments => {'config-dir' => '/tmp'}};
$res = $transmission->session([]);
ok $res->{'config-dir'}, 'session config-dir';

done_testing;

sub cb {
  $res = pop;
  Mojo::IOLoop->stop;
}

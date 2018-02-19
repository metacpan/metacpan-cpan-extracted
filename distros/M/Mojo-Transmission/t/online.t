use Mojo::Base -strict;
use Mojo::Transmission;
use Test::More;

plan skip_all => 'TEST_ONLINE=1' unless $ENV{TEST_ONLINE};
my $t   = Mojo::Transmission->new;
my $res = {};

$t->url($ENV{TEST_ONLINE}) unless $ENV{TEST_ONLINE} eq '1';

$t->session([], \&cb);
Mojo::IOLoop->start;
ok $res->{'config-dir'}, 'session config-dir';

$t->session({'alt-speed-down' => $res->{'alt-speed-down'}}, \&cb);
Mojo::IOLoop->start;
is_deeply($res, {}, 'session-set');

$t->stats(\&cb);
Mojo::IOLoop->start;
ok $res->{'current-stats'}, 'session config-dir';

note 'torrents-get all';
$t->torrent(['id'], \&cb);
Mojo::IOLoop->start;

is ref $res->{torrents}, 'ARRAY', 'torrent-get';

if (my $id = $res->{torrents}[0]{id}) {
  note "torrents-get $id";
  ok !defined($res->{torrents}[0]{status}), 'no status';

  $t->torrent({queuePosition => 1}, $id, \&cb);
  Mojo::IOLoop->start;
  is_deeply($res, {}, 'torrent-set');

  $t->torrent(start => $id, sub { });
  Mojo::IOLoop->timer(0.4 => sub { $t->torrent([qw(id status)], $id, \&cb); });
  Mojo::IOLoop->start;
  isnt $res->{torrents}[0]{status}, 0, 'started';

  $t->torrent(stop => $id, sub { });
  Mojo::IOLoop->timer(0.4 => sub { $t->torrent([qw(id status)], $id, \&cb); });
  Mojo::IOLoop->start;
  is $res->{torrents}[0]{status}, 0, 'stopped';
}
else {
  local $TODO = 'Cannot test torrents';
  ok 0, 'got torrent';
}

done_testing;

sub cb {
  $res = pop;
  Mojo::IOLoop->stop;
}

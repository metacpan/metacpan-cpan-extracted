use strict;
use warnings;
use Mojo::IOLoop;
use Mojo::Promise;
use Test::More;

BEGIN { $ENV{MOJO_REACTOR} = 'Mojo::Reactor::Poll' }

sub _timeout { ($_[0] || Mojo::IOLoop->singleton)->timer(1 => sub { Mojo::IOLoop->stop }) }

my $class = Mojo::Promise->with_roles('Mojo::Promise::Role::Get');

is_deeply [$class->new->resolve('success')->get], ['success'], 'already resolved promise';
is_deeply [$class->new->resolve(1..10)->get], [1..10], 'multiple results';
is_deeply [$class->new->resolve->get], [], 'no results';
is $class->new->resolve(1..10)->get, 1, 'first result in scalar context';
ok !eval { $class->new->reject('failure')->get; 1 }, 'already rejected promise';
like $@, qr/failure/, 'right exception message';
ok !eval { $class->new->reject->get; 1 }, 'no rejection reason';
like $@, qr/Promise was rejected/, 'right exception message';

my $p = $class->new;
my $t = Mojo::IOLoop->timer(0.01 => sub { $p->resolve('success') });
my $timeout = _timeout;
is_deeply [$p->get], ['success'], 'timer resolved';
Mojo::IOLoop->remove($_) for $t, $timeout;

$p = $class->new;
$t = Mojo::IOLoop->timer(0.01 => sub { $p->reject('failure') });
$timeout = _timeout;
ok !eval { $p->get; 1 }, 'timer rejected';
like $@, qr/failure/, 'right exception message';
Mojo::IOLoop->remove($_) for $t, $timeout;

my ($p1, $p2) = ($class->new, $class->new);
my $t1 = Mojo::IOLoop->timer(0.01 => sub { $p1->resolve(1) });
my $t2 = Mojo::IOLoop->timer(0.02 => sub { $p2->resolve(2) });
$timeout = _timeout;
is_deeply [$class->all($p1, $p2)->get], [[1],[2]], 'multiple timers resolved';
Mojo::IOLoop->remove($_) for $t1, $t2, $timeout;

($p1, $p2) = ($class->new, $class->new);
$t1 = Mojo::IOLoop->timer(0.01 => sub { $p1->resolve(1) });
$t2 = Mojo::IOLoop->timer(0.02 => sub { $p2->reject('reject 2') });
$timeout = _timeout;
ok !eval { $class->all($p1, $p2)->get; 1 }, 'multiple timers rejected';
like $@, qr/reject 2/, 'right exception message';
Mojo::IOLoop->remove($_) for $t1, $t2, $timeout;

($p1, $p2) = ($class->new, $class->new);
$t1 = Mojo::IOLoop->timer(0.01 => sub { $p1->resolve(1) });
$p1->then(sub { $t2 = Mojo::IOLoop->timer(0.01 => sub { $p2->resolve(2) }) });
$timeout = _timeout;
is_deeply [$class->race($p1, $p2)->get], [1], 'timer race resolved';
is_deeply [$p2->get], [2], 'remaining timer resolved';
Mojo::IOLoop->remove($_) for $t1, $t2, $timeout;

($p1, $p2) = ($class->new, $class->new);
$t1 = Mojo::IOLoop->timer(0.01 => sub { $p1->reject('reject 1') });
$p1->catch(sub { $t2 = Mojo::IOLoop->timer(0.01 => sub { $p2->reject('reject 2') }) });
$timeout = _timeout;
ok !eval { $class->race($p1, $p2)->get; 1 }, 'timer race rejected';
like $@, qr/reject 1/, 'right exception message';
ok !eval { $p2->get; 1 }, 'remaining timer rejected';
like $@, qr/reject 2/, 'right exception message';
Mojo::IOLoop->remove($_) for $t1, $t2, $timeout;

$p1 = $class->new->resolve('success');
$p2 = $class->new;
my $error;
$t = Mojo::IOLoop->timer(0.01 => sub { eval { $p1->get; 1 } or $error = $@; $p2->resolve(2) });
$timeout = _timeout;
is_deeply [$p2->get], [2], 'timer resolved';
ok defined $error, 'exception in running event loop';
like $error, qr/event loop is running/, 'right exception message';
Mojo::IOLoop->remove($_) for $t, $timeout;

my $loop = Mojo::IOLoop->new;
$p = $class->new->ioloop($loop);
$t = $loop->timer(0.01 => sub { $p->resolve('success') });
$timeout = _timeout($loop);
is_deeply [$p->get], ['success'], 'secondary loop timer resolved';
$loop->remove($_) for $t, $timeout;

$p1 = $class->new->ioloop($loop)->resolve('success');
$p2 = $class->new;
my $result;
$t = Mojo::IOLoop->timer(0.01 => sub { $result = $p1->get; $p2->resolve(2) });
$timeout = _timeout;
my $loop_timeout = _timeout($loop);
is_deeply [$p2->get], [2], 'timer resolved';
is $result, 'success', 'secondary event loop timer resolved in running singleton loop';
Mojo::IOLoop->remove($_) for $t, $timeout;
$loop->remove($loop_timeout);

done_testing;

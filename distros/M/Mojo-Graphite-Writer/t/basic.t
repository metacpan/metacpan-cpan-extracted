use Mojo::Base -strict;

use Mojo::IOLoop;
use Test::More;

use Mojo::Graphite::Writer;
use Mojo::EventEmitter;

my $e = Mojo::EventEmitter->new;

my $read  = '';
my $open  = 0;
my $close = 0;
my $id = Mojo::IOLoop->server(address => '127.0.0.1', sub {
  my (undef, $stream, $id) = @_;
  $stream->on(read  => sub { $read .= $_[1]; $e->emit(read => $read); });
  $stream->on(close => sub { $close++ });
  $e->emit(open => ++$open);
});
my $port = Mojo::IOLoop->acceptor($id)->port;

my $graphite = Mojo::Graphite::Writer->new(address => '127.0.0.1', port => $port);

my $time = time;
my $p = $graphite->write(
  "a.one 1 $time",
  "a.two 2 $time",
);

my $resolved;
$p->then(sub{ $resolved++ });
$e->once(read => sub { Mojo::IOLoop->stop });
Mojo::IOLoop->start;

is $read, "a.one 1 $time\na.two 2 $time\n", 'got expected writes to mock graphite';
is $open, 1, 'opened once';
is $close, 0, 'connection not closed';
$read = '';

# test line ending normalization
$p = $graphite->write(
  "b.one 1 $time\n",
  "b.two 2 $time\n",
);

$resolved = undef;
$p->then(sub{ $resolved++ });
$e->once(read => sub { Mojo::IOLoop->stop });
Mojo::IOLoop->start;

is $read, "b.one 1 $time\nb.two 2 $time\n", 'got expected writes to mock graphite';
is $open, 1, 'opened once';
is $close, 0, 'connection not closed';

# test fork safety (test method borrowed from mojo-pg)
subtest 'fork safety' => sub {
  my ($old, $new);
  $graphite->connect->then(sub{ $old = shift })->wait;
  is $open, 1, 'opened once';

  local $$ = -23;
  my $p = Mojo::Promise->new->timeout(5);
  $p->catch(sub{ fail 'Timeout!' });
  $p->finally(sub{ Mojo::IOLoop->stop });
  $e->once(open => sub { $p->resolve });

  $graphite->connect->then(sub{ $new = shift });
  Mojo::IOLoop->start;

  isnt $old, $new, 'new connection';
  is $open, 2, 'reopened';
};

$read = '';
subtest 'preprocess' => sub {
  no warnings 'redefine';
  local *Mojo::Graphite::Writer::_time = sub () { $time };
  $e->on(read => sub { Mojo::IOLoop->stop });
  $graphite->write(
    ['c.one', 1], # default time
    ['c.two', 2, $time, {foo => 'bar', baz => 'bat'}], # tags
    ['c.three', 3, undef, {foo => 'bar', baz => 'bat'}], # both
    ['c.four', 4, $time, {'what()' => 'this that', 'null' => undef}], # cleanup
  );
  Mojo::IOLoop->start;
  is $read, "c.one 1 $time\nc.two;baz=bat;foo=bar 2 $time\nc.three;baz=bat;foo=bar 3 $time\nc.four;null=;what=this_that 4 $time\n", 'expected write';
};


done_testing;


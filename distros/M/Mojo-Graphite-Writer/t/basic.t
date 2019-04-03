use Mojo::Base -strict;

use Mojo::IOLoop;
use Test::More;

use Mojo::Graphite::Writer;

my $read  = '';
my $open  = 0;
my $close = 0;
my $id = Mojo::IOLoop->server(address => '127.0.0.1', sub {
  my (undef, $stream, $id) = @_;
  $open++;
  $stream->on(read  => sub { $read .= $_[1] });
  $stream->on(close => sub { $close++ });
});
my $port = Mojo::IOLoop->acceptor($id)->port;

my $graphite = Mojo::Graphite::Writer->new(address => '127.0.0.1', port => $port);

my $time = time;
$graphite->write(
  "a.one 1 $time",
  "a.two 2 $time",
)->wait;

is $read, "a.one 1 $time\na.two 2 $time\n", 'got expected writes to mock graphite';
is $open, 1, 'opened once';
is $close, 0, 'connection not closed';
$read = '';

# test line ending normalization
$graphite->write(
  "b.one 1 $time\n",
  "b.two 2 $time\n",
)->wait;

is $read, "b.one 1 $time\nb.two 2 $time\n", 'got expected writes to mock graphite';
is $open, 1, 'opened once';
is $close, 0, 'connection not closed';

done_testing;


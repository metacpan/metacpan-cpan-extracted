use Mojo::Base -strict;
use Test::More;
use Mojo::Redis;
use Errno qw(ECONNREFUSED ENOTCONN);

# Dummy server
my $port      = Mojo::IOLoop::Server->generate_port;
my $server_id = make_server(Mojo::IOLoop->singleton);
my $redis     = Mojo::Redis->new("redis://localhost:$port");
my $err;

note 'Promises should be rejected on error';
my $db = $redis->db;
Mojo::IOLoop->next_tick(sub { $db->connection->disconnect });
get_p($db)->wait;
is $err, 'Premature connection close', 'client disconnected';

$err = '';
get_p($redis->db)->wait;
is $err, 'Premature connection close', 'server closed stream';

my $err_re = join '|', map { local $! = $_; quotemeta "$!" } ECONNREFUSED, ENOTCONN;
$err = '';
Mojo::IOLoop->remove($server_id);
get_p($redis->db)->wait;
like $err, qr/$err_re/, 'server disappeared';

note 'Do not reconnect in the middle of a transaction';
$server_id = make_server($redis->_blocking_connection->ioloop);
$db        = $redis->db;
my $step = 0;
my @err;
for my $m (qw(multi incr incr exec)) {
  eval { $db->$m($m eq 'incr' ? ($0) : ()); ++$step } or do { push @err, $@ };
  note "($step) $@" if $@;
}

is $step, 1, 'all blocking methods fail after the first fail';
like shift(@err), qr{^$_}, "expected $_"
  for 'Premature connection close', 'Redis server has gone away', 'Redis server has gone away';
isnt $redis->_blocking_connection, $db->connection(1), 'fresh connection next time';
is $redis->_blocking_connection->ioloop, $db->connection(1)->ioloop, 'same blocking ioloop';

note 'No blocking connection should be put back into connection queue';
$db = $redis->db;
$db->connection(1)->{stream} = 1;    # pretend we are connected
undef $db;
ok !(grep { warn $_; $_->ioloop ne Mojo::IOLoop->singleton } @{$redis->{queue}}), 'no blocking connections in queue';

done_testing;

sub get_p {
  return shift->get_p($0)->then(sub { diag "Should not be successfule: @_" })->catch(sub { $err = shift });
}

sub make_server {
  return shift->server(
    {port => $port},
    sub {
      my ($loop, $stream) = @_;
      $stream->on(
        read => sub {
          my ($stream, $buf) = @_;
          return $stream->write("+OK\r\n") if $buf =~ /EXEC/;    # Should not come to this
          return $stream->write("+OK\r\n") if $buf =~ /MULTI/;
          return $stream->close;
        }
      );
    }
  );
}

use Mojo::Base -strict;
use Test::More;
use Mojo::Redis;
use Errno qw(ECONNREFUSED ENOTCONN);

# Dummy server
my $port      = Mojo::IOLoop::Server->generate_port;
my $server_id = Mojo::IOLoop->server(
  {port => $port},
  sub {
    my ($loop, $stream) = @_;
    Mojo::IOLoop->timer(0.05 => sub { $stream->close });
  }
);

my $redis = Mojo::Redis->new("redis://localhost:$port");
my $db    = $redis->db;
my $err;

Mojo::IOLoop->next_tick(sub { $db->connection->disconnect });
get_p($db)->wait;
is $err, 'Premature connection close', 'client disconnected';

$err = '';
get_p($db)->wait;
is $err, 'Premature connection close', 'server closed stream';

my $err_re = join '|', map { local $! = $_; quotemeta "$!" } ECONNREFUSED, ENOTCONN;
$err = '';
Mojo::IOLoop->remove($server_id);
get_p($db)->wait;
like $err, qr/$err_re/, 'server disappeared';

done_testing;

sub get_p {
  return shift->get_p($0)->then(sub { diag "Should not be successfule: @_" })->catch(sub { $err = shift });
}

use Mojo::Base -strict;
use Test::More;
use Mojo::Redis;

plan skip_all => 'TEST_ONLINE=redis://localhost/8'      unless $ENV{TEST_ONLINE};
plan skip_all => 'Need a database index in TEST_ONLINE' unless $ENV{TEST_ONLINE} =~ m!/\d+\b!;

my $redis = Mojo::Redis->new($ENV{TEST_ONLINE});

my $db   = $redis->db;
my $conn = $db->connection;
isa_ok($db,   'Mojo::Redis::Database');
isa_ok($conn, 'Mojo::Redis::Connection');

$redis->on(connection => sub { $redis->{connections}++ });

note 'Create one connection';
my $connected = 0;
my $err;
$conn->once(connect => sub { $connected++; Mojo::IOLoop->stop });
$conn->once(error => sub { $err = $_[1]; Mojo::IOLoop->stop });
is $conn->_connect, $conn, '_connect()';
Mojo::IOLoop->start;
is $connected, 1, 'connected' or diag $err;
is @{$redis->{queue} || []}, 0, 'zero connections in queue';

note 'Put connection back into queue';
undef $db;
is @{$redis->{queue}}, 1, 'one connection in queue';

note 'Create more connections than max_connections';
my @db;
push @db, $redis->db for 1 .. 6;    # one extra
$_->connection->_connect->once(connect => sub { ++$connected == 6 and Mojo::IOLoop->stop }) for @db;
Mojo::IOLoop->start;

note 'Put max connections back into the queue';
is $db[0]->connection, $conn, 'reusing connection';
@db = ();
is @{$redis->{queue}}, 5, 'five connections in queue';

note 'Take one connection out of the queue';
$redis->db->connection->disconnect;
undef $db;
is @{$redis->{queue}}, 4, 'four connections in queue';

note 'Write and auto-connect';
my @res;
delete $redis->{queue};
$db = $redis->db;
$conn->write_p('PING')->then(sub { @res = @_; Mojo::IOLoop->stop })->wait;
is_deeply \@res, ['PONG'], 'ping response';

note 'New connection, because disconnected';
$conn = $db->connection;
$conn->disconnect;
$db = $redis->db;
$db->connection->write_p('PING')->wait;
isnt $db->connection, $conn, 'new connection when disconnected';

is $redis->{connections}++, 7, 'connections emitted';

note 'Encoding';
my $str = 'I ♥ Mojolicious!';
$conn = $db->connection;

is $redis->encoding, 'UTF-8', 'default redis encoding';
is $conn->encoding,  'UTF-8', 'encoding passed on to connection';
$conn->write_p(qw(get t:redis:encoding))->then(sub { @res = @_ })->wait;
is_deeply \@res, [undef], 'undefined key not decoded';
$conn->write_p(qw(set t:redis:encoding), $str)->wait;
$conn->write_p(qw(get t:redis:encoding))->then(sub { @res = @_ })->wait;
is_deeply \@res, [$str], 'unicode encoding';

$conn->encoding(undef);
$conn->write_p(qw(set t:redis:encoding), Mojo::Util::encode('UTF-8', $str))->wait;
$conn->encoding('UTF-8');
$conn->write_p(qw(get t:redis:encoding))->then(sub { @res = @_ })->wait;
is $res[0], $str, 'no encoding';

note 'Make sure encoding is reset';
$db = $redis->db;
$db->connection->encoding('whatever');
undef $db;
$db = $redis->db;
is $db->connection->encoding, 'UTF-8', 'connection encoding is reset';

note 'Cleanup';
$conn->write_p(qw(del t:redis:encoding))->wait;

$redis->encoding(undef);
is $redis->db->connection->encoding, undef, 'Encoding changed for new connections';

note 'Fork-safety';
$conn = $db->connection;
undef $db;
$redis->{pid} = -1;
isnt $redis->db->connection, $conn, 'new fork gets a new connecion';
undef $conn;
$redis->{pid} = $$;
$conn = $redis->_blocking_connection;
$redis->{pid} = -1;
isnt $redis->_blocking_connection, $conn, 'new fork gets a new blocking connection';
undef $conn;
$redis->{pid} = $$;

note 'Connection closes when ref is lost';
$db = $redis->db;
$db->get_p($0)->catch(sub { $err = shift })->wait;    # Make sure we are connected
ok $db->connection->is_connected, 'connected' or diag $err;
my $closed;
$db->connection->on(close => sub { $closed++ });
$redis->max_connections(0);
undef $db;
ok $closed, 'connection was closed on destruction';

note 'New connection, because URL changed';
use Socket;
my $host = $redis->url->host;
$db = $redis->db;
$db->get_p($0)->catch(sub { $err = shift })->wait;    # Make sure we are connected
$redis->url->host($host =~ /[a-z]/ ? inet_ntoa(inet_aton $host) : gethostbyaddr(inet_aton($host), AF_INET));
diag 'Changed host to ' . $redis->url->host;
$db = undef;
is @{$redis->{queue}}, 0, 'database was not enqued' or diag $err;

done_testing;

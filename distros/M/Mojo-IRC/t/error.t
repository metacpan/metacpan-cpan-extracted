use lib '.';
use t::Helper;
use Errno ();

plan skip_all => 'MSWin32' if $^O eq 'MSWin32';

my $port   = generate_port();
my $irc    = Mojo::IRC->new(server => "127.0.0.1:$port");
my $status = 'YIKES';

plan skip_all => 'Could not find any port' unless $port;

Mojo::IOLoop->server(
  {port => $port},
  sub {
    my ($ioloop, $stream) = @_;
    Mojo::IOLoop->timer(0.01 => sub { $stream->close });
  },
);

$irc->on(close => sub { $status = 'close'; Mojo::IOLoop->stop });

my $bad_port = generate_port();
my $errnum   = -1;
my $err      = '';
$irc->server("127.0.0.1:$bad_port");
$irc->connect(sub { (my $irc, $err) = @_; $errnum = int $!; Mojo::IOLoop->stop; });
start_ioloop();
ok + ($errnum == Errno::ENOTCONN || $errnum == Errno::ECONNREFUSED), "could not connect ($errnum) ($err)";

$irc->server("127.0.0.1:$port");
$irc->connect(sub { (my $irc, $err) = @_; });
start_ioloop();
is $status, 'close', 'connection closed';
is + ($err || ''), '', 'no error';

$irc->server("127.0.0.1:$port");
$irc->connect(sub { (my $irc, $err) = @_; $status = 'connected'; Mojo::IOLoop->stop; });
start_ioloop();
is $status, 'connected', 'could still connect';
is + ($err || ''), '', 'no error';

done_testing;

sub start_ioloop {
  $err    = 'ioloop-failed';
  $status = 'ioloop-failed';
  my $tid = Mojo::IOLoop->timer(1 => sub { Mojo::IOLoop->stop });
  Mojo::IOLoop->start;
  Mojo::IOLoop->remove($tid);
}

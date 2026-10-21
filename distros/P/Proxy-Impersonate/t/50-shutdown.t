use v5.10; use strict; use warnings;
use Test::More;
use EV;
use File::Temp qw(tempdir);
use Socket;
use Scalar::Util qw(weaken);
use Proxy::Impersonate;

my $p = Proxy::Impersonate->new(impersonate => 'chrome131',
    listen => '127.0.0.1:0', cert_dir => tempdir(CLEANUP => 1));

# inject a fake active connection to prove shutdown closes it
my $closed = 0;
{ package FakeConn; sub _close { ${ $_[0] } = 1 } }
my $fake = bless \$closed, 'FakeConn';
$p->{conns}{$fake} = $fake;

# shutdown must NOT break the loop: a later timer still fires
my $ran_after = 0;
my $t1 = EV::timer(0,    0, sub { $p->shutdown });
my $t2 = EV::timer(0.05, 0, sub { $ran_after = 1; EV::break() });
EV::run;

ok($closed, 'shutdown closed the active connection');
ok($ran_after, 'EV loop kept running after shutdown (no EV::break)');
is_deeply($p->{conns}, {}, 'connections cleared');
ok(!$p->{aw}, 'accept watcher dropped');
ok(!$p->{multi}, 'multi released');
ok(!$p->{srv}, 'listen socket released');
ok(eval { $p->shutdown; 1 }, 'shutdown is idempotent');

{
    my $proxy = Proxy::Impersonate->new(impersonate => 'chrome131');
    my $dir = $proxy->cert_dir;
    socket(my $client, PF_INET, SOCK_STREAM, 0) or die $!;
    connect($client, sockaddr_in($proxy->port, inet_aton('127.0.0.1'))) or die $!;
    $proxy->_accept;
    my ($conn) = values %{$proxy->{conns}};
    ok($conn, 'accepted a live connection');
    weaken($conn);
    my $weak = $proxy; weaken($weak);
    undef $proxy;
    ok(!$weak, 'live connection does not keep the proxy alive');
    ok(!$conn, 'dropping the proxy releases connection watchers');
    ok(!-d $dir, 'default certificate directory is removed on teardown');
}

{
    my $proxy = Proxy::Impersonate->new(impersonate => 'chrome131');
    $proxy->{on_response} = (sub { my $owner = shift; sub { $owner->port } })->($proxy);
    socket(my $client, PF_INET, SOCK_STREAM, 0) or die $!;
    connect($client, sockaddr_in($proxy->port, inet_aton('127.0.0.1'))) or die $!;
    $proxy->_accept;
    $proxy->shutdown;
    my $weak = $proxy; weaken($weak);
    undef $proxy;
    ok(!$weak, 'shutdown releases callbacks that captured the proxy');
}

done_testing;

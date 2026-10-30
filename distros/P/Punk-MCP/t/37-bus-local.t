#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";
use PMCPSess;
use PMCPFakeStream;

# ---- the payload ----------------------------------------------------------------

my $p = Punk::Plugin::MCP::_bus_encode(1, 4242, 'SID', "books://caf\x{e9}");
is_deeply([Punk::Plugin::MCP::_bus_decode($p)], [1, 4242, 'SID', "books://caf\x{e9}"],
    'a payload round-trips: kind, origin pid, session, URI');
is(length(Punk::Plugin::MCP::_bus_encode(2, 1, 'S' x 22, undef)), 6 + 22,
    'a close is the head and the session id');
is_deeply([Punk::Plugin::MCP::_bus_decode('garbage')], [], 'a payload not ours is ignored');
is_deeply([Punk::Plugin::MCP::_bus_decode("\x09\0\0\0\1\0")], [], 'nor an unknown kind');
ok(!defined Punk::Plugin::MCP::_bus_encode(1, 1, '', 'x' x 2100),
    'a URI that would overflow a 2KB bus slot does not encode');

# ---- an app, its sessions, and fake streams ----------------------------------------

my $t = sess_app('');
my $class = $PMCPSess::LAST;
my $c = Punk::Context->_build({}, $class->punk_app, { captures => {} });
my ($sa) = init_session($t);
my ($sb) = init_session($t);
send_msg($t, { jsonrpc => '2.0', id => 1, method => 'resources/subscribe',
               params => { uri => 'books://1' } }, sid => $sa);

my $one = PMCPFakeStream->new;
Punk::Plugin::MCP::_stream_register($class, $c, $sa, $one);
my $other = PMCPFakeStream->new;
Punk::Plugin::MCP::_stream_register($class, $c, $sb, $other);
is(Punk::Plugin::MCP::_stream_count(), 2, 'two sessions, two streams');

# Without Hyperman there is no pool: publish says 0, and local delivery is all.
is(Punk::Plugin::MCP->resource_updated($class, 'books://1'), 0,
    'with no bus, publish says this worker only');
is_deeply($one->uris, ['books://1'], 'and the subscribed stream here got it');
is_deeply($other->uris, [], 'the unsubscribed one did not');

# ---- what arrives over the bus -------------------------------------------------------------

Punk::Plugin::MCP::_bus_receive($class, Punk::Plugin::MCP::_bus_encode(1, $$, '', 'books://1'));
is(scalar @{ $one->{events} }, 1, 'a payload from this worker\'s own pid is dropped: no double delivery');
Punk::Plugin::MCP::_bus_receive($class, Punk::Plugin::MCP::_bus_encode(1, $$ + 1, '', 'books://1'));
is(scalar @{ $one->{events} }, 2, 'one from another worker is delivered');
Punk::Plugin::MCP::_bus_receive($class, Punk::Plugin::MCP::_bus_encode(2, $$ + 1, $sb, undef));
ok(!$other->is_open, 'a close from another worker closes that session\'s stream here');
is(Punk::Plugin::MCP::_stream_count(), 1, 'and drops it from the table');

# ---- one stream per session --------------------------------------------------------------

my $second = PMCPFakeStream->new;
Punk::Plugin::MCP::_stream_register($class, $c, $sa, $second);
ok(!$one->is_open, 'a second stream for a session closes the first');
is(Punk::Plugin::MCP::_stream_count(), 1, 'and takes its place');
Punk::Plugin::MCP->resource_updated($class, 'books://1');
is(scalar @{ $one->{events} }, 2, 'the old stream gets nothing more');
is_deeply($second->uris, ['books://1'], 'the new one does');

# A close callback that fires late, as one does on a loop, must not remove
# the stream that has since taken the session's place.
my $late = PMCPFakeStream->new->deferred;
my ($sl) = init_session($t);
send_msg($t, { jsonrpc => '2.0', id => 1, method => 'resources/subscribe',
               params => { uri => 'books://1' } }, sid => $sl);
Punk::Plugin::MCP::_stream_register($class, $c, $sl, $late);
my $newer = PMCPFakeStream->new;
Punk::Plugin::MCP::_stream_register($class, $c, $sl, $newer);
$late->fire;
Punk::Plugin::MCP->resource_updated($class, 'books://1');
is_deeply($newer->uris, ['books://1'],
    'a late close callback from the old stream leaves the new one in place');
$newer->close;

# ---- pruning, and DELETE -------------------------------------------------------------------

$second->gone;
Punk::Plugin::MCP->resource_updated($class, 'books://1');
is(Punk::Plugin::MCP::_stream_count(), 0, 'a stream whose client left is pruned on the next delivery');

my $third = PMCPFakeStream->new;
Punk::Plugin::MCP::_stream_register($class, $c, $sa, $third);
send_msg($t, undef, sid => $sa, http => 'DELETE');
ok(!$third->is_open, 'DELETE closes the session\'s stream');
is(Punk::Plugin::MCP::_stream_count(), 0, 'and empties its slot');

# ---- an oversize URI ---------------------------------------------------------------------

my ($sc) = init_session($t);
my $big = 'books://' . ('x' x 2100);
send_msg($t, { jsonrpc => '2.0', id => 1, method => 'resources/subscribe',
               params => { uri => $big } }, sid => $sc);
my $fourth = PMCPFakeStream->new;
Punk::Plugin::MCP::_stream_register($class, $c, $sc, $fourth);
my @w;
{
    local $SIG{__WARN__} = sub { push @w, @_ };
    is(Punk::Plugin::MCP->resource_updated($class, $big), -1, 'an oversize URI is not published');
}
like($w[0] // '', qr/does not fit a bus slot, so only this worker saw it/, 'and says so');
is(scalar @{ $fourth->{events} }, 1, 'but this worker\'s own stream still got it');

done_testing;

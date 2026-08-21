#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Punk ();

# The hop walk alone (pp_xff_client, punk_proxy.h) through the Punk::Proxy
# author shim. This is the part every implementation gets wrong, so it is
# tested as a table before anything is wired to a request.
#
# The rule: X-Forwarded-For reads `client, proxy1, proxy2` and each hop
# APPENDS the address it received FROM. The socket peer is the last proxy and
# never appears in the header it forwarded. With N trusted proxies the client
# is at index N-1 counting from the RIGHT. Reaching for the leftmost entry is
# the spoofable version, because the client writes that one.

sub client { Punk::Proxy::_client($_[0], $_[1], $_[2]) }

# ---- fixed hop counts ------------------------------------------------------

is client('1.2.3.4', '10.0.0.1', 1), '1.2.3.4',
   'one proxy, one entry: that entry is the client';

is client('1.2.3.4, 10.0.0.7', '10.0.0.1', 2), '1.2.3.4',
   'two proxies, two entries: the leftmost is the client';

is client('1.2.3.4, 10.0.0.7, 10.0.0.8', '10.0.0.1', 3), '1.2.3.4',
   'three proxies, three entries';

# THE SPOOF CASE. One real proxy in front. The client sends its own
# X-Forwarded-For claiming to be 9.9.9.9; the proxy appends the address it
# actually saw. Counting from the right lands on the truth; counting from the
# left would hand the attacker any address it liked - including one that is
# on somebody else's rate-limit bucket, or off a denylist.
is client('9.9.9.9, 1.2.3.4', '10.0.0.1', 1), '1.2.3.4',
   'a forged leading entry is ignored: the hop count counts from the right';

is client('7.7.7.7, 9.9.9.9, 1.2.3.4', '10.0.0.1', 1), '1.2.3.4',
   'a whole forged chain is ignored';

is client('9.9.9.9, 1.2.3.4, 10.0.0.7', '10.0.0.1', 2), '1.2.3.4',
   'forged entry with two real proxies';

# A chain SHORTER than declared is a misconfiguration or a client that sent
# nothing. The peer is the honest answer; the leftmost entry is not.
is client('1.2.3.4', '10.0.0.1', 2), '10.0.0.1',
   'fewer entries than declared hops: fall back to the socket peer';

is client('1.2.3.4, 10.0.0.7', '10.0.0.1', 5), '10.0.0.1',
   'far fewer entries than declared hops: the peer';

# ---- CIDR trust ------------------------------------------------------------

is client('1.2.3.4, 10.0.0.7', '10.0.0.1', ['10.0.0.0/8']), '1.2.3.4',
   'walk right to left, stop at the first untrusted entry';

is client('9.9.9.9, 1.2.3.4, 10.0.0.7', '10.0.0.1', ['10.0.0.0/8']), '1.2.3.4',
   'the walk stops at the first untrusted entry, forged ones beyond it unread';

is client('10.0.0.5, 10.0.0.7', '10.0.0.1', ['10.0.0.0/8']), '10.0.0.5',
   'an entirely trusted chain yields the leftmost entry';

is client('1.2.3.4, 10.0.0.7', '8.8.8.8', ['10.0.0.0/8']), '8.8.8.8',
   'an untrusted socket peer means the header is not ours to believe';

is client('1.2.3.4, 172.16.0.9', '10.0.0.1',
          ['10.0.0.0/8', '172.16.0.0/12']), '1.2.3.4',
   'several trusted networks';

is client('1.2.3.4, 10.0.0.7', '10.0.0.1', ['10.0.0.1']),  '10.0.0.7',
   'a bare address in the trust list is a /32 host: 10.0.0.7 is not it';

# ---- trust => all ----------------------------------------------------------

is client('9.9.9.9, 1.2.3.4', '10.0.0.1', 'all'), '9.9.9.9',
   "trust => 'all' takes the leftmost entry, forged or not";

is client('', '10.0.0.1', 'all'), '10.0.0.1',
   "trust => 'all' with an empty header: the peer";

# ---- IPv6 ------------------------------------------------------------------

is client('2001:db8::1, fd00::1', 'fd00::2', ['fd00::/8']), '2001:db8::1',
   'v6 chain and a v6 CIDR';

is client('::ffff:1.2.3.4, 10.0.0.7', '10.0.0.1', ['10.0.0.0/8']),
   '::ffff:1.2.3.4',
   'a v4-mapped v6 entry survives the walk';

# A v4-mapped v6 address must match the v4 CIDR an operator wrote: that is
# what a dual-stack listener hands you, and treating it as v6 would silently
# fail every rule in the config.
is client('1.2.3.4, ::ffff:10.0.0.7', '10.0.0.1', ['10.0.0.0/8']), '1.2.3.4',
   'a v4-mapped proxy entry matches the plain v4 CIDR';

is client('2001:db8::1', '[fd00::2]:443', ['fd00::/8']), '2001:db8::1',
   'a bracketed peer with a port is still matched against the trust list';

# ---- malformed input -------------------------------------------------------

# Everything here must end at the peer. REMOTE_ADDR feeds a shared-memory
# rate-limit key, so an entry that is not an address must never reach it.
is client('not-an-address', '10.0.0.1', 1), '10.0.0.1', 'garbage entry';
is client('999.1.1.1',      '10.0.0.1', 1), '10.0.0.1', 'octet out of range';
is client('1.2.3',          '10.0.0.1', 1), '10.0.0.1', 'short quad';
is client('1.2.3.4.5',      '10.0.0.1', 1), '10.0.0.1', 'long quad';
is client('010.0.0.1',      '10.0.0.1', 1), '10.0.0.1',
   'a leading zero is rejected, not read as octal or decimal';
is client('1.2.3.4, ',      '10.0.0.1', 1), '10.0.0.1',
   'an empty trailing entry is a malformed hop, not a skipped one';
is client('',               '10.0.0.1', 1), '10.0.0.1', 'empty header';
is client(undef,            '10.0.0.1', 1), '10.0.0.1', 'absent header';
is client('2001:db8:::1',   '10.0.0.1', 1), '10.0.0.1', 'a second ::';
is client('1::2::3',        '10.0.0.1', 1), '10.0.0.1', 'two compressions';
is client('12345::1',       '10.0.0.1', 1), '10.0.0.1', 'a five-digit group';

# ---- normalisation ---------------------------------------------------------

# The value STORED must be the address alone. A port left on it would put the
# same client into two different rate-limit buckets on two connections.
is client('1.2.3.4:5678',      '10.0.0.1', 1), '1.2.3.4',
   'a v4 port suffix is dropped from the stored address';
is client('[2001:db8::1]:443', '10.0.0.1', 1), '2001:db8::1',
   'a bracketed v6 with a port is unwrapped';
is client('  1.2.3.4  ',       '10.0.0.1', 1), '1.2.3.4',
   'surrounding whitespace is trimmed';
is client("1.2.3.4,\t10.0.0.7", '10.0.0.1', 2), '1.2.3.4',
   'tab padding between entries';

# ---- bounds ----------------------------------------------------------------

{
    # A chain longer than PP_MAX_HOPS keeps the rightmost entries, which is
    # the end the walk starts from, so a plausible hop count still resolves.
    my $long = join ', ', ('9.9.9.9') x 200, '1.2.3.4', '10.0.0.7';
    is client($long, '10.0.0.1', 2), '1.2.3.4',
       'an absurdly long chain still resolves at a sane hop count';
}

done_testing;

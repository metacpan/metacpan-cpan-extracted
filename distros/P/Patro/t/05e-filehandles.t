use Test::More;
use Carp 'verbose';
use Patro ':test', ':insecure';
use 5.010;
use Scalar::Util 'reftype';
use Symbol;
use Fcntl ':DEFAULT',':flock';
use strict;
use warnings;

# exercise esoteric operations for proxies to filehandles
#   sysopen, flock

# !!! :insecure mode allows us to call  sysopen  on the server.
# !!! Allowing patro clients to call open/close on shared
# !!! filehandles is quite insecure, just so you know.

my ($f7,$f8);
$f7 = Symbol::gensym();
$f8 = Symbol::gensym();

ok($f7 && ref($f8) eq 'GLOB', 'created remote filehandles');
my $cfg = patronize($f7,$f8);
ok($cfg, 'got config for patronize glob');
my $cfgstr = $cfg->to_string;
ok($cfgstr, 'got string representation of Patro config');

my ($p7,$p8) = Patro->new($cfgstr)->getProxies;
ok($p7, 'client as boolean, loaded from config string');
is(CORE::ref($p8), 'Patro::N5', 'client ref');
is(Patro::ref($p8), 'GLOB', 'remote ref');
is(Patro::reftype($p7), 'GLOB', 'remote reftype');

my $c = Patro::client($p7);
ok($c, 'got client for remote obj');
my $THREADED = $c->{config}{style} eq 'threaded';

# open PROXY, '>', FILE  will create FILE *on the server*
# in the test, client and server are on same machine and share the same
# filesystem, but it's something to be aware of

unlink('t/t-05e.out');
ok(! -f 't/t-05e.out', 'test file does not exist yet');

my $z = sysopen $p7, 't/t-05e.out', O_CREAT | O_WRONLY;
ok($z, 'sysopen successful with proxy filehandle');
ok(-f 't/t-05e.out', 'file created on server with proxy sysopen');

$z = print $p7 "hello world\n";
ok($z, 'print on proxy filehandle created with sysopen');
$z = close $p7;
ok($z, 'close on proxy filehandle created with sysopen');

$z = sysopen $p8, 't/t-05e.out', O_RDONLY;
ok($z, 'sysopen for read successful with proxy filehandle');

$z = flock $p8, LOCK_EX | LOCK_NB;
ok($z, 'flock ok on proxy filehandle');

$z = sysopen $p7, 't/t-05e.out', O_RDONLY;
ok($z, 'sysopen for read on proxy filehandle');
$z = flock $p7, LOCK_EX | LOCK_NB;
ok(!$z, 'flock failed - file should already be locked');
$z = close $p8;
ok($z, 'close proxy filehandle ok');
$z = flock $p7, LOCK_EX | LOCK_NB;
ok($z, 'flock succeeded after close call on lockholder');
$z = flock $p7, LOCK_UN;
ok($z, 'flock unlock call ok');
$z = close $p7;
ok($z, 'close proxy filehandle ok');

done_testing;

END {
    unlink 't/t-05e.out' unless $ENV{KEEP};
}

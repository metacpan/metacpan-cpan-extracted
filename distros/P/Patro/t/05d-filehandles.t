use Test::More;
use Carp 'verbose';
use Patro ':test', ':insecure';
use 5.010;
use Scalar::Util 'reftype';
use Symbol;
use strict;
use warnings;

# exercise open/close operations for proxies to filehandles
#   open, close

# !!! :insecure mode allows us to call  open/close  on the server.
# !!! Allowing patro clients to call open/close on shared
# !!! filehandles is quite insecure, just so you know.

my ($f6,$t6);
$f6 = Symbol::gensym();

ok($f6 && ref($f6) eq 'GLOB', 'created remote filehandle');
my $cfg = patronize($f6);
ok($cfg, 'got config for patronize glob');
my $cfgstr = $cfg->to_string;
ok($cfgstr, 'got string representation of Patro config');

my ($p6) = Patro->new($cfgstr)->getProxies;
ok($p6, 'client as boolean, loaded from config string');
is(CORE::ref($p6), 'Patro::N5', 'client ref');
is(Patro::ref($p6), 'GLOB', 'remote ref');
is(Patro::reftype($p6), 'GLOB', 'remote reftype');

my $c = Patro::client($p6);
ok($c, 'got client for remote obj');
my $THREADED = $c->{config}{style} eq 'threaded';

# open PROXY, '>', FILE  will create FILE *on the server*
# in the test, client and server are on same machine and share the same
# filesystem, but it's something to be aware of

unlink('t/t-05d.out');
ok(! -f 't/t-05d.out', 'test file does not exist yet');

my $z = open $p6, '>', 't/t-05d.out';
ok($z, 'open successful with proxy filehandle');
ok(-f 't/t-05d.out', 'file created on server with proxy open');

open $t6, '<', 't/t-05d.out';
$z = print $p6 "hello\n";
ok($z, 'print on proxy filehandle ok');
my $line = <$t6>;
ok($line eq "hello\n", 'read line on server that was printed by proxy');
$z = close $p6;
ok($z, 'close proxy filehandle ok');
$z = print $p6 "world\n";
ok(!$z, 'print to proxy filehandle after close not ok');
$line = <$t6>;
ok(!defined($line) && eof($t6), 'no line read on server');

$z = open $p6, '>>t/t-05d.out';
ok($z, 'open for append with proxy filehandle');
$z = print $p6 "cruel world\n";
ok($z, 'print on proxy filehandle ok') or ::xdiag([$z,$!]);
seek $t6, 0, 1;
$line = <$t6>;
ok($line eq "cruel world\n", 'read line on server printed by proxy');
$z = close $p6;
ok($z, 'close proxy filehandle again');

$z = open $p6, '<', 't/t-05d.out';
ok($z, 'open with proxy filehandle for input');
$line = <$p6>;
ok($line && $line eq "hello\n", 'read from proxy filehandle');
$line = getc($p6);
ok($line && $line eq 'c', 'getc from proxy filehandle');
$line = readline($p6);
$z = close $p6;
ok($z, 'close proxy filehandle ok');
$! = 0;
$line = readline($p6);
ok(!$line, 'read from closed filehandle fails');

# it's bad enough that a proxy filehandle can read/write
# arbitrary files on the server filesystem. But now there's this.

$? = 0;
$! = 0;
$z = open $p6, "-|", "perl", "-e", "print qq/foo\\n/;exit 1";
ok($z, 'open command with proxy filehandle');
$line = <$p6>;
ok($line && $line eq "foo\n", 'readline from remote command');
$line = <$p6>;
ok(!$line, 'exhausted output from remote command');

# perldoc -f close: "If the filehandle came from a piped onpen,
# "close" returns false if ... the program exits with non-zero status.
# If the only problem was that the program exited non-zero, $! will
# be set to 0. Closing the pipe also ... puts the exit status value
# of that command into $? ...
$z = close $p6;
ok(!$z, 'close remote command through proxy filehandle')
    or ::xdiag([$z,$!]);
 SKIP: {
     if ($c->{config}{style} ne 'threaded') {
	 skip('$? won\'t get set on non-threaded server', 1);
     }     
     ok($? == 256, 'set $? from remote command') or diag $?;
}

$z = open $p6, '+>>', 't/t-05d.out';
ok($z, 'reopen random access');

my $z1 = stat $p6;
ok($z1, 'scalar stat on proxy filehandle') or diag $z1;
my @z1 = stat $p6;
ok(@z1 > 0, 'list stat on proxy filehandle') or diag @z1;

$z = truncate $p6, 10;
ok($z, 'truncate proxy filehandle ok');

# -X on a proxy filehandle requires v5.12
 SKIP: {
     if ($] < 5.012000) {
	 skip("-X on proxy handle requires Perl v5.12", 3);
     }
     $z = -s $p6;
     ok($z == 10, '-s proxy_fh ok, truncate effective') or diag $z;

     $z = -r $p6;
     ok($z, 'proxy_fh is readable');
     $z = -w $p6;
     ok($z, 'proxy_fh is writeable');
}

$z = close $p6;
ok($z, 'close file again');
ok(10 == -s 't/t-05d.out', 'truncate effective');



done_testing;

END {
    unlink 't/t-05d.out' unless $ENV{KEEP};
}

use Test::More;
use Carp 'verbose';
use Patro ':test';
use 5.010;
use Scalar::Util 'reftype';
use Symbol;
use strict;
use warnings;

# exercise buffered read operations for proxies to filehandles
#   readline, getc
#   eof, fileno, seek, tell

my $r0 = 'In a hole in the ground there lived a hobbit.
Not a nasty, dirty, wet hole, filled with the ends
of worms and an oozy smell, nor yet a dry, bare,
sandy hole with nothing in it to sit down on or
to eat: it was a hobbit-hold, and that means comfort.';

open my $fh_tmp, '>', 't/t-05b.in';
print $fh_tmp $r0;
close $fh_tmp;

my ($f2,$f3); # = Symbol::gensym();

open $f2, '<', \$r0;
open $f3, '<', 't/t-05b.in';

ok($f2 && ref($f2) eq 'GLOB', 'created remote filehandle');
my $cfg = patronize($f2,$f3);
ok($cfg, 'got config for patronize glob');
my $cfgstr = $cfg->to_string;
ok($cfgstr, 'got string representation of Patro config');

my ($p2,$p3) = Patro->new($cfgstr)->getProxies;
ok($p2, 'client as boolean, loaded from config string');
is(CORE::ref($p2), 'Patro::N5', 'client ref');
is(Patro::ref($p2), 'GLOB', 'remote ref');
is(Patro::reftype($p2), 'GLOB', 'remote reftype');

my $c = Patro::client($p2);
ok($c, 'got client for remote obj');
my $THREADED = $c->{config}{style} eq 'threaded';


my $line = readline($p2);
ok($line eq "In a hole in the ground there lived a hobbit.\n",
   'readline from proxy filehandle');
$line = <$p2>;
ok($line eq "Not a nasty, dirty, wet hole, filled with the ends\n",
   '<proxy filehandle>');

$line = readline($p3);
ok($line eq "In a hole in the ground there lived a hobbit.\n",
   'readline from proxy fh (opened from scalar)');
$line = <$p3>;
ok($line eq "Not a nasty, dirty, wet hole, filled with the ends\n",
   '<proxy filehandle> (opened from scalar)');

my $ch = getc($p2);
ok($ch eq 'o', 'getc on input proxy filehandle');
$ch = getc($p2);
ok($ch eq 'f', 'getc on input proxy filehandle again');

$ch = getc($p3);
ok($ch eq 'o', 'getc on input proxy fh (opened from scalar)');
$ch = getc($p3);
ok($ch eq 'f', 'getc on input proxy fh again (opened from scalar)');
ok(tell($p2)  > 0 && tell($p2) == tell($p3),
   'tell from proxy fhs consistent');   

my @lines = <$p2>;
ok(@lines > 1, "readline from proxy handle in list context");
ok($lines[1] eq "sandy hole with nothing in it to sit down on or\n",
   'readline in list context has correct content');

@lines = <$p3>;
ok(@lines > 1, "readline from proxy fh in list context (from scalar)");
ok($lines[1] eq "sandy hole with nothing in it to sit down on or\n",
   'readline in list context has correct content (opened from scalar)');

ok(tell($p2) > 0, 'tell of input proxy filehandle should be >0');
ok(eof($p2), 'eof on input proxy filehandle');
ok(eof($p3), 'eof on input proxy fh (opened from scalar)');

# wrong args in seek call probably doesn't 
my $z = eval 'seek $p2; 1';
ok(!$z, 'seek on proxy filehandle with wrong number of args');
ok($@, 'Got not enough arguments for seek warning');

$z = seek $p2, 0, 0;
ok($z, 'seek on proxy filehandle');
ok(tell($p2) == 0, 'tell on input proxy fh');
$line = <$p2>;
ok($line eq "In a hole in the ground there lived a hobbit.\n",
   'seek reset cursor on proxy filehandle');

$z = seek $p3, 0, 0;
ok($z, 'seek on proxy filehandle (from scalar)');
ok(tell($p3) == 0, 'tell on input proxy fh (from scalar)');
$line = <$p3>;
ok($line eq "In a hole in the ground there lived a hobbit.\n",
   'seek reset cursor on proxy fh (opened from scalar)');


done_testing;

END {
    unlink 't/t-05b.in' unless $ENV{KEEP};
}

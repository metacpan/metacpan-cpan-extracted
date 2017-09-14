use Test::More;
use Carp 'verbose';
use Patro ':test';
use 5.010;
use Scalar::Util 'reftype';
use Symbol;
use strict;
use warnings;

# exercise unbuffered read operations for proxies to filehandles
#   sysread
#   fileno

my $r0 = 'In a hole in the ground there lived a hobbit.
Not a nasty, dirty, wet hole, filled with the ends
of worms and an oozy smell, nor yet a dry, bare,
sandy hole with nothing in it to sit down on or
to eat: it was a hobbit-hold, and that means comfort.';

open my $fh_tmp, '>', 't/t-05c.in';
print $fh_tmp $r0;
close $fh_tmp;

my ($f4,$f5); # = Symbol::gensym();

open $f4, '<', \$r0;
open $f5, '<', 't/t-05c.in';

ok($f5 && ref($f5) eq 'GLOB', 'created remote filehandle');
my $cfg = patronize($f4,$f5);
ok($cfg, 'got config for patronize glob');
my $cfgstr = $cfg->to_string;
ok($cfgstr, 'got string representation of Patro config');

my ($p4,$p5) = Patro->new($cfgstr)->getProxies;
ok($p5, 'client as boolean, loaded from config string');
is(CORE::ref($p5), 'Patro::N5', 'client ref');
is(Patro::ref($p5), 'GLOB', 'remote ref');
is(Patro::reftype($p5), 'GLOB', 'remote reftype');

my $c = Patro::client($p4);
ok($c, 'got client for remote obj');
my $THREADED = $c->{config}{style} eq 'threaded';


my $x = "123456789ABCD";
my $z = read $p5, $x, 3, 3;
ok($z == 3, 'read on proxy filehandle') or diag "\$z=$z";
ok($x eq "123In ", 'read on proxy filehandle updates scalar')
    or diag "\$x=$x";

# if defined(&CORE::read) is false, this sysread call will be
# treated as a read call on the server (and should succeed)

my $xx = "123456789";
$z = sysread $p4, $xx, 3, 3;
if (defined(&CORE::read)) {
    ok(!$z, 'sysread on proxy fh, opened from scalar, returns 0')
	or diag("\$z is $z, expected 0 on proxy sysread, fh opened to scalar");
    ok($xx eq '123456789', 'read buffer unchanged');
} else {
    ok($z == 3, 'sysread on proxy fh, opened from scalar, treated as read');
    ok($xx eq '123In ', "read buffer changed");
}

$xx = "123456789";
$z = read $p4, $xx, 3, 3;
ok($z == 3, 'read on proxy filehandle (opened from scalar');
ok($xx eq "123In " || $xx eq "123a h",
   "read on proxy fh (opened from scalar) updates scalar");

done_testing;

END {
    unlink 't/t-05c.in' unless $ENV{KEEP};
}

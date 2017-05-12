# call.t
#
# Tests for the 'call' and 'icall' functions.
#

use Tcl;

$| = 1;

print "1..15\n";

my $i = Tcl->new;
my (@res, $res, $a, $b);

$res = $i->call('set', 'var', "ok 1");
print "$res\n";

$res = $i->icall('set', 'var', "ok 2");
print "$res\n";

@res = $i->call('set', 'var', ['ok', '3']);
print STDOUT join(' ', @res), "\n";

@res = $i->icall('set', 'var', ['ok', '4']);
print STDOUT join(' ', @res), "\n";

($a, $b) = $i->call('list', '5', 'ok');
print "$b $a\n";

($a, $b) = $i->icall('list', '6', 'ok');
print "$b $a\n";

$i->call("puts", "ok 7");

$i->icall("puts", "ok 8");

$a = $i->call("list", 1, $i->call("list", 2, 3), 4);
print "not " unless @$a == 4 && $a->[1] == 2 && $a eq "1 2 3 4";
print "ok 9\n";

$a = $i->call("list", 1, scalar($i->call("list", 2, 3)), 4);
print "not " unless @$a == 3 && $a->[1][0] == 2 && $a eq "1 {2 3} 4";
print "ok 10\n";

my $v = 1;
$i->call("after", 250, sub { print "ok 11\n"; $v++; });
$i->call("vwait", \$v);
print "not " unless $v == 2;
print "ok 12\n";

$i->call("eval", <<'EOT');
proc f1 {h v} {
    upvar $h arr
    puts "ok $arr(ok)"
    set arr(foo) 14
    incr $v
}
EOT

my %h = (foo => 1, bar => 2, ok => 13);
$i->call("after", 250, "f1", \%h, \$v);
$i->call("vwait", \$v);

print "ok $h{foo}\n";

print "not " unless $v == 3;
print "ok 15\n";


use String::RexxParse;


my $z = String::RexxParse->new( q~ '$' $x '{' $x '}{' $x '...' $x '}' ~ );
my ($h,$p,$a,$j) = $z->parse('$hacker{perl}{another...just}');

print "1..4\n";

if ($j eq 'just' ) { print "ok 1\n" }
else { print "not ok 1\n" }

if ($a eq 'another' ) { print "ok 2\n" }
else { print "not ok 2\n" }

if ($p eq 'perl' ) { print "ok 3\n" }
else { print "not ok 3\n" }

if ($h eq 'hacker' ) { print "ok 4\n" }
else { print "not ok 4\n" }


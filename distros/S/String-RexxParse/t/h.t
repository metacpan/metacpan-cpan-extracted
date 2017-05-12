use String::RexxParse qw/parse/;

use vars qw/$j $a $p $h/;

my $t = q+'$' $h '{' $p "}" "{" $a '...' $j '}'+;
my $s = q~$hacker{perl}{another...just}~;

my @list = reverse parse $s, $t;

print "1..5\n";

if (scalar(@list) == 4) { print "ok 1\n" }
else { print "not ok 1\n" }

if ($j eq $list[0] and $j eq 'just') { print "ok 2\n" }
else { print "not ok 2\n" }

if ($a eq $list[1] and $a eq 'another') { print "ok 3\n" }
else { print "not ok 3\n" }

if ($p eq $list[2] and $p eq 'perl') { print "ok 4\n" }
else { print "not ok 4\n" }

if ($h eq $list[3] and $h eq 'hacker') { print "ok 5\n" }
else { print "not ok 5\n" }


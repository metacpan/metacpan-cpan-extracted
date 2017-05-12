
use String::RexxParse qw(parse);

$a = 'aaa ([ xxx.XXXXX ]) 3333333 mNmNmN 1234567';

$b=$c=$d=$e=$f=$g="";

parse $a, q~ $b '([' $c $d '])' $e '.'  $f 0 '.' $g . ~;

print "1..6\n";


if ($b eq 'aaa ' ) { print "ok 1\n" }
else { print "not ok 1\n" }

if ($c eq 'xxx.XXXXX' ) { print "ok 2\n" }
else { print "not ok 2\n" }

if ($d eq '' ) { print "ok 3\n" }
else { print "not ok 3\n" }

if ($e eq ' 3333333 mNmNmN 1234567' ) { print "ok 4\n" }
else { print "not ok 4\n" }

if ($f eq '' ) { print "ok 5\n" }
else { print "not ok 5\n" }

if ($g eq 'XXXXX' ) { print "ok 6\n" }
else { print "not ok 6\n" }



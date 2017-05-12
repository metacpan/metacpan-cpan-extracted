
use String::RexxParse qw(parse);

$a = 'around the rugged rocks the ragged rascal ran!';

$b=$c=$d=$e=$f=$g="";

parse $a, q~ +3 $b +3 $c +3 $d +3 $e +3 $f +3 $g ~;

print "1..6\n";


if ($b eq 'und' ) { print "ok 1\n" }
else { print "not ok 1\n" }

if ($c eq ' th' ) { print "ok 2\n" }
else { print "not ok 2\n" }

if ($d eq 'e r' ) { print "ok 3\n" }
else { print "not ok 3\n" }

if ($e eq 'ugg' ) { print "ok 4\n" }
else { print "not ok 4\n" }

if ($f eq 'ed ' ) { print "ok 5\n" }
else { print "not ok 5\n" }

if ($g eq 'rocks the ragged rascal ran!' ) { print "ok 6\n" }
else { print "not ok 6\n" }



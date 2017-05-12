
use String::RexxParse qw(parse);

$a = 'around the rugged rocks the ragged rascal ran!';

$b=$c=$d=$e=$f=$g="";

parse $a, q~ $b $c $d $e $f $g ~;

print "1..6\n";


if ($b eq 'around' ) { print "ok 1\n" }
else { print "not ok 1\n" }

if ($c eq 'the' ) { print "ok 2\n" }
else { print "not ok 2\n" }

if ($d eq 'rugged' ) { print "ok 3\n" }
else { print "not ok 3\n" }

if ($e eq 'rocks' ) { print "ok 4\n" }
else { print "not ok 4\n" }

if ($f eq 'the' ) { print "ok 5\n" }
else { print "not ok 5\n" }

if ($g eq 'ragged rascal ran!' ) { print "ok 6\n" }
else { print "not ok 6\n" }



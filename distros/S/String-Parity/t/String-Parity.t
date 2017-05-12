# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

BEGIN { $| = 1; print "1..33\n"; }
END {print "not ok 1\n" unless $loaded;}
use String::Parity qw(:DEFAULT showParity showMarkSpace);
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

$even = "\x30\xb1\xb2\x33\x00\x81\x00\x81\x7e\xff";
$p_even = "eeeeeeeeee";		# showParity()
$h_even = "smmssmsmsm";		# showMarkSpace()
$c_even = "10 0 5 5";		# count of even, odd, space and mark bytes

$odd = "\xb0\x31\x32\xb3\x80\x01\x80\x01\xfe\x7f";
$p_odd = "oooooooooo";
$h_odd = "mssmmsmsms";
$c_odd = "0 10 5 5";

$space = "\x30\x31\x32\x33\x00\x01\x00\x01\x7e\x7f";
$p_space = "eooeeoeoeo";
$h_space = "ssssssssss";
$c_space = "5 5 10 0";

$mark = "\xb0\xb1\xb2\xb3\x80\x81\x80\x81\xfe\xff";
$p_mark = "oeeooeoeoe";
$h_mark = "mmmmmmmmmm";
@c_mark = "5 5 0 10";


$e = setEvenParity $space;
if ($even eq $e) { print "ok 2\n";} else { print "not ok 2\n";}

if (isEvenParity $e) { print "ok 3\n";} else { print "not ok 3\n";}
if (isOddParity $e) { print "not ok 4\n";} else { print "ok 4\n";}
if (isMarkParity $e) { print "not ok 5\n";} else { print "ok 5\n";}
if (isSpaceParity $e) { print "not ok 6\n";} else { print "ok 6\n";}

$p = showParity $e;
if ($p_even eq $p) { print "ok 7\n";} else { print "not ok 7\n";}

$h = showMarkSpace $e;
if ($h_even eq $h) { print "ok 8\n";} else { print "not ok 8\n";}

$c = join ' ', EvenBytes($e), OddBytes($e), SpaceBytes($e), MarkBytes($e);
if ($c_even eq $c) { print "ok 9\n";} else { print "not ok 9\n";}


$o = setOddParity $mark;
if ($odd eq $o) { print "ok 10\n";} else { print "not ok 10\n";}

if (isEvenParity $o) { print "not ok 11\n";} else { print "ok 11\n";}
if (isOddParity $o) { print "ok 12\n";} else { print "not ok 12\n";}
if (isMarkParity $o) { print "not ok 13\n";} else { print "ok 13\n";}
if (isSpaceParity $o) { print "not ok 14\n";} else { print "ok 14\n";}

$p = showParity $o;
if ($p_odd eq $p) { print "ok 15\n";} else { print "not ok 15\n";}

$h = showMarkSpace $o;
if ($h_odd eq $h) { print "ok 16\n";} else { print "not ok 16\n";}

$c = join ' ', EvenBytes($o), OddBytes($o), SpaceBytes($o), MarkBytes($o);
if ($c_odd eq $c) { print "ok 17\n";} else { print "not ok 17\n";}


$s = setSpaceParity $even;
if ($space eq $s) { print "ok 18\n";} else { print "not ok 18\n";}

if (isMarkParity $s) { print "not ok 19\n";} else { print "ok 19\n";}
if (isSpaceParity $s) { print "ok 20\n";} else { print "not ok 20\n";}


$m = setMarkParity $odd;
if ($mark eq $m) { print "ok 21\n";} else { print "not ok 21\n";}

if (isMarkParity $m) { print "ok 22\n";} else { print "not ok 22\n";}
if (isSpaceParity $m) { print "not ok 23\n";} else { print "ok 23\n";}

@e = setEvenParity $o, $m, $s;
if (@e == 3) { print "ok 24\n";} else { print "not ok 24\n";}
if ($e[0] == $e) { print "ok 25\n";} else { print "not ok 25\n";}
if ($e[1] == $e) { print "ok 26\n";} else { print "not ok 26\n";}
if ($e[2] == $e) { print "ok 27\n";} else { print "not ok 27\n";}

@o = setOddParity $e, $m, $s;
if (@o == 3) { print "ok 28\n";} else { print "not ok 28\n";}
if ($o[0] == $o) { print "ok 29\n";} else { print "not ok 29\n";}
if ($o[1] == $o) { print "ok 30\n";} else { print "not ok 30\n";}
if ($o[2] == $o) { print "ok 31\n";} else { print "not ok 31\n";}

@s = setSpaceParity $e, $m, $s;
if (@s == 3) { print "ok 32\n";} else { print "not ok 32\n";}

@m = setMarkParity $e, $m, $s;
if (@m == 3) { print "ok 33\n";} else { print "not ok 33\n";}

# end of test.pl

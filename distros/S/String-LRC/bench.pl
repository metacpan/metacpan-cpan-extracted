#!/usr/local/bin/perl  -I./blib/arch -I./blib/lib
 use strict;
 my $string = qq|Testing |.chr(02).qq| stx|;
 eval { require String::Random };
 if ($@) {
	print "Failed to find String::Random, using static string\n"
 } else {
	my $str = new String::Random;
	$string = $str->randpattern(("."x180));
 }

 use lib "./blib/arch";
 use lib "./blib/lib";
 require String::LRC;
 my $timehires;
 eval {  require Time::HiRes };
 if ($@) {
	print "Failed to find Time::HiRes, using localtime() instead\n";
	$timehires = undef;
 } else {
	use Time::HiRes;
	use Time::HiRes qw(gettimeofday tv_interval);
	$timehires = 1;
 }
 print "1..5\n";
 my ($tbegin, $tbegin2, $tend, $tend2, $elapsed, $elapsed2, $lrc, $lrc2, $plrc, $clrc, 
	$error, $tbegin3, $tbegin4, $tend3, $tend4, $elapsed3, $elapsed4, $perlstring);
if (defined $timehires && $timehires > 0) {
	$tbegin = [gettimeofday];
} else {
	$tbegin = localtime;
}
$lrc = String::LRC::getPerlLRC($string);
if (defined $timehires && $timehires > 0) {
	$tend = [gettimeofday];
	$elapsed = tv_interval ($tbegin, $tend);
} else {
	$tend = localtime;
	$elapsed = $tend - $tbegin;
}

if (defined $timehires && $timehires > 0) {
	$tbegin2 = [gettimeofday];
} else {
	$tbegin2 = localtime;
}
$lrc2 = String::LRC::lrc($string);
if (defined $timehires && $timehires > 0) {
	$tend2 = [gettimeofday];
	$elapsed2 = tv_interval ($tbegin2, $tend2);
} else {
	$tend2 = localtime;
	$elapsed2 = $tend2 - $tbegin2;
}

print qq|The LRC for our test string of length |
	. length($string)
	.qq| is "$lrc"/"$lrc2" [ASCII #|.ord($lrc).qq|/|.ord($lrc2).qq|]\n|;
printf (qq|Took %12.10f seconds to find LRC as perl subroutine (%5.2fKchars/sec)\n|,$elapsed,
		((length($string)/$elapsed)/1000)
		);
printf (qq|Took %12.10f seconds to find LRC as XS function (%5.2fKchars/sec)\n|,$elapsed2,
		((length($string)/$elapsed2)/1000)
		);
print "".(defined $elapsed ? qq|ok 1| : qq|not ok 1|) ."\n";
print "".(defined $elapsed2 ? qq|ok 2| : qq|not ok 2|) ."\n";
if ($elapsed > 0) {
printf (qq|C based module takes %4.2f/20th the time of the perl subroutine\n|, ($elapsed2/$elapsed) * 20);
}
if (defined $timehires && $timehires > 0) {
	$tbegin3 = [gettimeofday];
} else {
	$tbegin3 = localtime;
}
$error = 0;
my $testfile = "README";
open TESTFILE, $testfile or $error++;
print "".($error > 0?qq|Unable to open file $testfile|:"")."\n";
if ($error <= 0) {
while (<TESTFILE>) {
	$perlstring .= $_;
}
close TESTFILE;
$plrc = String::LRC::getPerlLRC($perlstring);
}


if (defined $timehires && $timehires > 0) {
	$tend3 = [gettimeofday];
	$elapsed3 = tv_interval ($tbegin3, $tend3);
} else {
	$tend3 = localtime;
	$elapsed3 = $tend3 - $tbegin3;
}

if (defined $timehires && $timehires > 0) {
	$tbegin4 = [gettimeofday];
} else {
	$tbegin4 = localtime;
}
$error = 0;
open TESTFILE2, $testfile or $error++;
print "".($error > 0?qq|Unable to open file $testfile|:"")."\n";
if ($error <= 0) {
#	$clrc = String::LRC::lrc(*TESTFILE2);
	$clrc = String::LRC::lrc(*TESTFILE2);
	close TESTFILE2;
}
if (defined $timehires && $timehires > 0) {
	$tend4 = [gettimeofday];
	$elapsed4 = tv_interval ($tbegin4, $tend4);
} else {
	$tend4 = localtime;
	$elapsed4 = $tend4 - $tbegin4;
}

print qq|The LRC for our test file of length |
	. length($perlstring)
	.qq| is "$plrc"/"$clrc" [ASCII #|.ord($plrc).qq|/|.ord($clrc).qq|]\n|;
printf (qq|Took %12.10f seconds to find LRC as perl subroutine (%5.2fKchars/sec)\n|,$elapsed3, 
		((length($perlstring)/$elapsed3)/1000)
		);
printf (qq|Took %12.10f seconds to find LRC as XS function (%5.2fKchars/sec)\n|,$elapsed4, 
		((length($perlstring)/$elapsed4)/1000)
		);
print "".(defined $elapsed3 ? qq|ok 3| : qq|not ok 3|) ."\n";
print "".(defined $elapsed4 ? qq|ok 4| : qq|not ok 4|) ."\n";
if ($elapsed3 > 0){
printf (qq|C based module takes %4.2f/20th the time of the perl subroutine\n|, ($elapsed4/$elapsed3) * 20);
}
print "".($plrc eq $clrc ? qq|ok 5| : qq|not ok 5|)."\n";

#!/usr/bin/perl -w

#		test DateTools.pm

	BEGIN {push (@INC, '/home/ajackson/bin/lib/');} # include my personal modules

	use PlotCalendar::DateTools qw(Add_Delta_Days Day_of_Week Day_of_Year Days_in_Month Decode_Day_of_Week Day_of_Week_to_Text  Month_to_Text);

	print "1..8\n";

	($mon, $day, $yr) = (3,1,2001);
	$numdays = -8;
	$dayname = 'Tuesd';
	$dow = 6;

  	$a = 60;
  	$b = Day_of_Year($yr,$mon,$day);
	print "ok 1\n" if $a == $b;

	$a = 31;
	$b = Days_in_Month($yr,$mon);
	print "ok 2\n" if $a == $b;

	$a = 2;
	$b = Decode_Day_of_Week($dayname);
	print "ok 3\n" if $a == $b;

	$a = 4;
	$b = Day_of_Week($yr,$mon,$day);
	print "ok 4\n" if $a == $b;

	($aa,$aaa,$aaaa) = (2001,2,21);
	($bb,$bbb,$bbbb) = Add_Delta_Days($yr,$mon,$day, $numdays);
	print "ok 5\n" if ($aa == $bb && $aaa == $bbb && $aaaa == $bbbb);

	$a = "Saturday";
	$b = Day_of_Week_to_Text($dow);
	print "ok 6\n" if $a eq $b;

	$a = "March";
	$b = Month_to_Text($mon);
	print "ok 7\n" if $a eq $b;

	$a = 60;
	$b = Day_of_Year($yr,$mon,$day);
	print "ok 8\n" if $a == $b;

#!/usr/bin/perl -w

#		test Day.pm

	push (@INC, '/home/ajackson/bin/lib/'); # include my personal modules

	print "1..3\n";

	require PlotCalendar::Day;

	$digit = 10;

	$test1 = <<'TEST1';
<TD BGCOLOR=RED ALIGN=LEFT VALIGN=TOP HEIGHT=100 WIDTH=100><A href="http://this_is_a_url/">
<B><I><FONT SIZE=+3 COLOR=WHITE > 10 </FONT></I></B>
 <B><U><FONT SIZE=+1 COLOR=WHITE ><A href="http://ooga.booga.com/"> Groundhog Day </A></FONT></U></B> 
<FONT SIZE=+0 COLOR=WHITE >
 <I>
 <BR><A href="http://booga.booga.com/"> </I><FONT COLOR=BLUE SIZE=+0> <B> text string 1 </B></FONT><I> </A>
<BR><A href="mailto:> </I><FONT COLOR=RED SIZE=+1> <U> text string 2 </U></FONT><I> </A>
<BR> </I><FONT COLOR=GREEN SIZE=+0> <B><I> abcdefghijklmno 0 </I></B></FONT><I> 
</I></FONT></A></TD>
TEST1

$test2 = <<'TEST2';
<TD BGCOLOR=#33cc00 ALIGN=LEFT VALIGN=TOP HEIGHT=10 WIDTH=15><A href="http://this_is_a_url/">
<B><FONT SIZE=+0 COLOR=BLACK > 10 </FONT></B>
<B><FONT SIZE=+0 COLOR=BLACK >  </FONT></B>
<FONT SIZE=+0 COLOR=BLACK >
  
  </FONT></A></TD>
TEST2

$test3 = <<'TEST3';
<TD BGCOLOR=RED ALIGN=LEFT VALIGN=TOP HEIGHT=500 WIDTH=500><A href="http://this_is_a_url/">
<B><I><FONT SIZE=+4 COLOR=WHITE > 10 </FONT></I></B>
 <B><U><FONT SIZE=+2 COLOR=WHITE ><A href="http://ooga.booga.com/"> Groundhog Day </A></FONT></U></B> 
<FONT SIZE=+1 COLOR=WHITE >
 <I>
 <BR><A href="http://booga.booga.com/"> </I><FONT COLOR=BLUE SIZE=+0> <B> text string 1 </B></FONT><I> </A>
<BR><A href="mailto:> </I><FONT COLOR=RED SIZE=+1> <U> text string 2, which is an especially long test string to wrap around all over the place </U></FONT><I> </A>
<BR> </I><FONT COLOR=GREEN SIZE=+0> <B><I> abcdefghijklmno 0 1 2 3 4 5 6 7 8 9 0 </I></B></FONT><I> 
</I></FONT></A></TD>
TEST3

	$normday = PlotCalendar::Day->new($digit);

	#	 These are values with default settings, so these are optional

	$normday -> size(100,100);
	$normday -> color('BLACK','#33cc00',);
	$normday -> color('WHITE','RED',);
	$normday -> font('14','10','8');
	$normday -> style('bi','nbu','i');
	$normday -> cliptext('yes');

	#	HTML only options
	
	$normday -> htmlexpand('yes');

	#	These values are defaulted to blank

	$normday -> dayname('Groundhog Day');
	$normday -> nameref('<A href="http://ooga.booga.com/">');
	$normday -> textref('<A href="http://booga.booga.com/">','<A href="mailto:>');
	$normday -> text('text string 1','text string 2','abcdefghijklmno 0 1 2 3 4 5 6 7 8 9 0',);
	$normday -> textcolor('BLUE','RED','GREEN',);
	$normday -> textsize('8','10','8',);
	$normday -> textstyle('b','u','bi',);

	$normday->htmlref('<A href="http://this_is_a_url/">');

	#	So, what do we have now?

	$html = $normday -> gethtml;

	if ($html eq $test1) {
		print "ok 1\n";
	}
	else {
		print "not ok 1\n";
	}


#---------------------------- tiny day

	$tinyday = PlotCalendar::Day->new($digit);

	#	 These are values with default settings, so these are optional

	$tinyday -> size(10,15);
	$tinyday -> color('BLACK','#33cc00',);
	$tinyday -> font('8','8','8');

	#	HTML only options
	
	$tinyday -> htmlexpand('yes');

	#	These values are defaulted to blank

	$tinyday->htmlref('<A href="http://this_is_a_url/">');

	#	So, what do we have now?

	$html = $tinyday -> gethtml;

	if ($html eq $test2) {
		print "ok 2\n";
	}
	else {
		print "not ok 2\n";
	}

#---------------------------- big day
	$bigday = PlotCalendar::Day->new($digit);

	#	 These are values with default settings, so these are optional

	$bigday -> size(500,500);
	$bigday -> color('BLACK','#33cc00',);
	$bigday -> color('WHITE','RED',);
	$bigday -> font('16','12','10');
	$bigday -> style('bi','nbu','i');
	$bigday -> cliptext('no');

	#	HTML only options
	
	$bigday -> htmlexpand('yes');

	#	These values are defaulted to blank

	$bigday -> dayname('Groundhog Day');
	$bigday -> nameref('<A href="http://ooga.booga.com/">');
	$bigday -> textref('<A href="http://booga.booga.com/">','<A href="mailto:>');
	$bigday -> text('text string 1','text string 2, which is an especially long test string to wrap around all over the place','abcdefghijklmno 0 1 2 3 4 5 6 7 8 9 0',);
	$bigday -> textcolor('BLUE','RED','GREEN',);
	$bigday -> textsize('8','10','8',);
	$bigday -> textstyle('b','u','bi',);

	$bigday->htmlref('<A href="http://this_is_a_url/">');

	#	So, what do we have now?

	$html = $bigday -> gethtml;

	if ($html eq $test3) {
		print "ok 3\n";
	}
	else {
		print "not ok 3\n";
	}


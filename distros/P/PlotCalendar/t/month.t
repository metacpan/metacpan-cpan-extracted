#!/usr/bin/perl -w

#		test Month.pm

	push (@INC, '/home/ajackson/bin/lib/'); # include my personal modules

	require PlotCalendar::Month;

	print "1..2\n";

	my ($mon, $year) = (3,1998);

	$test1 = <<'TEST1';
<TABLE BORDER=1 BGCOLOR=#66FFFF WIDTH=700 >
<TR><TD COLSPAN=7 WIDTH=700 ><CENTER><IMG SRC="/home/ajackson/public_html/cgi-bin/Calendar/Calendar_art3//March.gif">&nbsp;&nbsp;<IMG SRC="/home/ajackson/public_html/cgi-bin/Calendar/Calendar_art3//1.gif">
<IMG SRC="/home/ajackson/public_html/cgi-bin/Calendar/Calendar_art3//9.gif">
<IMG SRC="/home/ajackson/public_html/cgi-bin/Calendar/Calendar_art3//9.gif">
<IMG SRC="/home/ajackson/public_html/cgi-bin/Calendar/Calendar_art3//8.gif">
</CENTER>
</TD></TR>
<TR>
<TD ALIGN=center VALIGN=bottom WIDTH=100 NOSAVE NOWRAP><H3>Sunday</H3></TD>
<TD ALIGN=center VALIGN=bottom WIDTH=100 NOSAVE NOWRAP><H3>Monday</H3></TD>
<TD ALIGN=center VALIGN=bottom WIDTH=100 NOSAVE NOWRAP><H3>Tuesday</H3></TD>
<TD ALIGN=center VALIGN=bottom WIDTH=100 NOSAVE NOWRAP><H3>Wednesday</H3></TD>
<TD ALIGN=center VALIGN=bottom WIDTH=100 NOSAVE NOWRAP><H3>Thursday</H3></TD>
<TD ALIGN=center VALIGN=bottom WIDTH=100 NOSAVE NOWRAP><H3>Friday</H3></TD>
<TD ALIGN=center VALIGN=bottom WIDTH=100 NOSAVE NOWRAP><H3>Saturday</H3></TD>
</TR>
<TR>
<TD BGCOLOR=#33cc00 ALIGN=LEFT VALIGN=TOP HEIGHT=100 WIDTH=100>
<B><FONT SIZE=+3 COLOR=BLACK > 1 </FONT></B>
<B><I><FONT SIZE=+1 COLOR=BLACK ><A HREF="http://www.1.ca"> Day number 1 </A></FONT></I></B>
<FONT SIZE=+0 COLOR=BLACK >
 <U><I>
 <BR><A HREF="http://www.1.com/"> </I></U><FONT COLOR=#FF99FF SIZE=+0> <I> Text 1 for 1 </I></FONT><U><I> </A>
<BR>Second 1 text </I></U><FONT COLOR=#FF7070 SIZE=+1> <U> Second 1 text </U></FONT><U><I> </A>
<BR><A HREF="http://www.1.net/"> </I></U><FONT COLOR=#FFB0B0 SIZE=+0> <B> 1 bit of text </B></FONT><U><I> </A>
</I></U></FONT></TD>
<TD BGCOLOR=#FF99FF ALIGN=LEFT VALIGN=TOP HEIGHT=100 WIDTH=100>
<B><FONT SIZE=+3 COLOR=BLACK > 2 </FONT></B>
<B><I><FONT SIZE=+1 COLOR=BLACK ><A HREF="http://www.2.ca"> Day number 2 </A></FONT></I></B>
<FONT SIZE=+0 COLOR=BLACK >
 <U><I>
 <BR><A HREF="http://www.2.com/"> </I></U><FONT COLOR=#FF7070 SIZE=+0> <B> Text 1 for 2 </B></FONT><U><I> </A>
<BR>Second 2 text </I></U><FONT COLOR=#FFB0B0 SIZE=+1> <U> Second 2 text </U></FONT><U><I> </A>
<BR><A HREF="http://www.2.net/"> </I></U><FONT COLOR=WHITE SIZE=+0> <I> 2 bit of text </I></FONT><U><I> </A>
</I></U></FONT></TD>
<TD BGCOLOR=#FF7070 ALIGN=LEFT VALIGN=TOP HEIGHT=100 WIDTH=100>
<B><FONT SIZE=+3 COLOR=BLACK > 3 </FONT></B>
<B><I><FONT SIZE=+1 COLOR=BLACK ><A HREF="http://www.3.ca"> Day number 3 </A></FONT></I></B>
<FONT SIZE=+0 COLOR=BLACK >
 <U><I>
 <BR><A HREF="http://www.3.com/"> </I></U><FONT COLOR=#FFB0B0 SIZE=+0> <I> Text 1 for 3 </I></FONT><U><I> </A>
<BR>Second 3 text </I></U><FONT COLOR=WHITE SIZE=+1> <U> Second 3 text </U></FONT><U><I> </A>
<BR><A HREF="http://www.3.net/"> </I></U><FONT COLOR=#33cc00 SIZE=+0> <B> 3 bit of text </B></FONT><U><I> </A>
</I></U></FONT></TD>
<TD BGCOLOR=#FFB0B0 ALIGN=LEFT VALIGN=TOP HEIGHT=100 WIDTH=100>
<B><FONT SIZE=+3 COLOR=BLACK > 4 </FONT></B>
<B><I><FONT SIZE=+1 COLOR=BLACK ><A HREF="http://www.4.ca"> Day number 4 </A></FONT></I></B>
<FONT SIZE=+0 COLOR=BLACK >
 <U><I>
 <BR><A HREF="http://www.4.com/"> </I></U><FONT COLOR=WHITE SIZE=+0> <B> Text 1 for 4 </B></FONT><U><I> </A>
<BR>Second 4 text </I></U><FONT COLOR=#33cc00 SIZE=+1> <U> Second 4 text </U></FONT><U><I> </A>
<BR><A HREF="http://www.4.net/"> </I></U><FONT COLOR=#FF99FF SIZE=+0> <I> 4 bit of text </I></FONT><U><I> </A>
</I></U></FONT></TD>
<TD BGCOLOR=WHITE ALIGN=LEFT VALIGN=TOP HEIGHT=100 WIDTH=100>
<B><FONT SIZE=+3 COLOR=BLACK > 5 </FONT></B>
<B><I><FONT SIZE=+1 COLOR=BLACK ><A HREF="http://www.5.ca"> Day number 5 </A></FONT></I></B>
<FONT SIZE=+0 COLOR=BLACK >
 <U><I>
 <BR><A HREF="http://www.5.com/"> </I></U><FONT COLOR=#33cc00 SIZE=+0> <I> Text 1 for 5 </I></FONT><U><I> </A>
<BR>Second 5 text </I></U><FONT COLOR=#FF99FF SIZE=+1> <U> Second 5 text </U></FONT><U><I> </A>
<BR><A HREF="http://www.5.net/"> </I></U><FONT COLOR=#FF7070 SIZE=+0> <B> 5 bit of text </B></FONT><U><I> </A>
</I></U></FONT></TD>
<TD BGCOLOR=#33cc00 ALIGN=LEFT VALIGN=TOP HEIGHT=100 WIDTH=100>
<B><FONT SIZE=+3 COLOR=BLACK > 6 </FONT></B>
<B><I><FONT SIZE=+1 COLOR=BLACK ><A HREF="http://www.6.ca"> Day number 6 </A></FONT></I></B>
<FONT SIZE=+0 COLOR=BLACK >
 <U><I>
 <BR><A HREF="http://www.6.com/"> </I></U><FONT COLOR=#FF99FF SIZE=+0> <B> Text 1 for 6 </B></FONT><U><I> </A>
<BR>Second 6 text </I></U><FONT COLOR=#FF7070 SIZE=+1> <U> Second 6 text </U></FONT><U><I> </A>
<BR><A HREF="http://www.6.net/"> </I></U><FONT COLOR=#FFB0B0 SIZE=+0> <I> 6 bit of text </I></FONT><U><I> </A>
</I></U></FONT></TD>
<TD BGCOLOR=#FF99FF ALIGN=LEFT VALIGN=TOP HEIGHT=100 WIDTH=100>
<B><FONT SIZE=+3 COLOR=BLACK > 7 </FONT></B>
<B><I><FONT SIZE=+1 COLOR=BLACK ><A HREF="http://www.7.ca"> Day number 7 </A></FONT></I></B>
<FONT SIZE=+0 COLOR=BLACK >
 <U><I>
 <BR><A HREF="http://www.7.com/"> </I></U><FONT COLOR=#FF7070 SIZE=+0> <I> Text 1 for 7 </I></FONT><U><I> </A>
<BR>Second 7 text </I></U><FONT COLOR=#FFB0B0 SIZE=+1> <U> Second 7 text </U></FONT><U><I> </A>
<BR><A HREF="http://www.7.net/"> </I></U><FONT COLOR=WHITE SIZE=+0> <B> 7 bit of text </B></FONT><U><I> </A>
</I></U></FONT></TD>
</TR>
<TR>
<TD BGCOLOR=#FF7070 ALIGN=LEFT VALIGN=TOP HEIGHT=100 WIDTH=100>
<B><FONT SIZE=+3 COLOR=BLACK > 8 </FONT></B>
<B><I><FONT SIZE=+1 COLOR=BLACK ><A HREF="http://www.8.ca"> Day number 8 </A></FONT></I></B>
<FONT SIZE=+0 COLOR=BLACK >
 <U><I>
 <BR><A HREF="http://www.8.com/"> </I></U><FONT COLOR=#FFB0B0 SIZE=+0> <B> Text 1 for 8 </B></FONT><U><I> </A>
<BR>Second 8 text </I></U><FONT COLOR=WHITE SIZE=+1> <U> Second 8 text </U></FONT><U><I> </A>
<BR><A HREF="http://www.8.net/"> </I></U><FONT COLOR=#33cc00 SIZE=+0> <I> 8 bit of text </I></FONT><U><I> </A>
</I></U></FONT></TD>
<TD BGCOLOR=#FFB0B0 ALIGN=LEFT VALIGN=TOP HEIGHT=100 WIDTH=100>
<B><FONT SIZE=+3 COLOR=BLACK > 9 </FONT></B>
<B><I><FONT SIZE=+1 COLOR=BLACK ><A HREF="http://www.9.ca"> Day number 9 </A></FONT></I></B>
<FONT SIZE=+0 COLOR=BLACK >
 <U><I>
 <BR><A HREF="http://www.9.com/"> </I></U><FONT COLOR=WHITE SIZE=+0> <I> Text 1 for 9 </I></FONT><U><I> </A>
<BR>Second 9 text </I></U><FONT COLOR=#33cc00 SIZE=+1> <U> Second 9 text </U></FONT><U><I> </A>
<BR><A HREF="http://www.9.net/"> </I></U><FONT COLOR=#FF99FF SIZE=+0> <B> 9 bit of text </B></FONT><U><I> </A>
</I></U></FONT></TD>
<TD BGCOLOR=WHITE ALIGN=LEFT VALIGN=TOP HEIGHT=100 WIDTH=100>
<B><FONT SIZE=+3 COLOR=BLACK > 10 </FONT></B>
<B><I><FONT SIZE=+1 COLOR=BLACK ><A HREF="http://www.10.ca"> Day number 10 </A></FONT></I></B>
<FONT SIZE=+0 COLOR=BLACK >
 <U><I>
 <BR><A HREF="http://www.10.com/"> </I></U><FONT COLOR=#33cc00 SIZE=+0> <B> Text 1 for 10 </B></FONT><U><I> </A>
<BR>Second 10 text </I></U><FONT COLOR=#FF99FF SIZE=+1> <U> Second 10 text </U></FONT><U><I> </A>
<BR><A HREF="http://www.10.net/"> </I></U><FONT COLOR=#FF7070 SIZE=+0> <I> 10 bit of text </I></FONT><U><I> </A>
</I></U></FONT></TD>
<TD BGCOLOR=#33cc00 ALIGN=LEFT VALIGN=TOP HEIGHT=100 WIDTH=100>
<B><FONT SIZE=+3 COLOR=BLACK > 11 </FONT></B>
<B><I><FONT SIZE=+1 COLOR=BLACK ><A HREF="http://www.11.ca"> Day number 11 </A></FONT></I></B>
<FONT SIZE=+0 COLOR=BLACK >
 <U><I>
 <BR><A HREF="http://www.11.com/"> </I></U><FONT COLOR=#FF99FF SIZE=+0> <I> Text 1 for 11 </I></FONT><U><I> </A>
<BR>Second 11 text </I></U><FONT COLOR=#FF7070 SIZE=+1> <U> Second 11 text </U></FONT><U><I> </A>
<BR><A HREF="http://www.11.net/"> </I></U><FONT COLOR=#FFB0B0 SIZE=+0> <B> 11 bit of text </B></FONT><U><I> </A>
</I></U></FONT></TD>
<TD BGCOLOR=#FF99FF ALIGN=LEFT VALIGN=TOP HEIGHT=100 WIDTH=100>
<B><FONT SIZE=+3 COLOR=BLACK > 12 </FONT></B>
<B><I><FONT SIZE=+1 COLOR=BLACK ><A HREF="http://www.12.ca"> Day number 12 </A></FONT></I></B>
<FONT SIZE=+0 COLOR=BLACK >
 <U><I>
 <BR><A HREF="http://www.12.com/"> </I></U><FONT COLOR=#FF7070 SIZE=+0> <B> Text 1 for 12 </B></FONT><U><I> </A>
<BR>Second 12 text </I></U><FONT COLOR=#FFB0B0 SIZE=+1> <U> Second 12 text </U></FONT><U><I> </A>
<BR><A HREF="http://www.12.net/"> </I></U><FONT COLOR=WHITE SIZE=+0> <I> 12 bit of text </I></FONT><U><I> </A>
</I></U></FONT></TD>
<TD BGCOLOR=#FF7070 ALIGN=LEFT VALIGN=TOP HEIGHT=100 WIDTH=100>
<B><FONT SIZE=+3 COLOR=BLACK > 13 </FONT></B>
<B><I><FONT SIZE=+1 COLOR=BLACK ><A HREF="http://www.13.ca"> Day number 13 </A></FONT></I></B>
<FONT SIZE=+0 COLOR=BLACK >
 <U><I>
 <BR><A HREF="http://www.13.com/"> </I></U><FONT COLOR=#FFB0B0 SIZE=+0> <I> Text 1 for 13 </I></FONT><U><I> </A>
<BR>Second 13 text </I></U><FONT COLOR=WHITE SIZE=+1> <U> Second 13 text </U></FONT><U><I> </A>
<BR><A HREF="http://www.13.net/"> </I></U><FONT COLOR=#33cc00 SIZE=+0> <B> 13 bit of text </B></FONT><U><I> </A>
</I></U></FONT></TD>
<TD BGCOLOR=#FFB0B0 ALIGN=LEFT VALIGN=TOP HEIGHT=100 WIDTH=100>
<B><FONT SIZE=+3 COLOR=BLACK > 14 </FONT></B>
<B><I><FONT SIZE=+1 COLOR=BLACK ><A HREF="http://www.14.ca"> Day number 14 </A></FONT></I></B>
<FONT SIZE=+0 COLOR=BLACK >
 <U><I>
 <BR><A HREF="http://www.14.com/"> </I></U><FONT COLOR=WHITE SIZE=+0> <B> Text 1 for 14 </B></FONT><U><I> </A>
<BR>Second 14 text </I></U><FONT COLOR=#33cc00 SIZE=+1> <U> Second 14 text </U></FONT><U><I> </A>
<BR><A HREF="http://www.14.net/"> </I></U><FONT COLOR=#FF99FF SIZE=+0> <I> 14 bit of text </I></FONT><U><I> </A>
</I></U></FONT></TD>
</TR>
<TR>
<TD BGCOLOR=WHITE ALIGN=LEFT VALIGN=TOP HEIGHT=100 WIDTH=100>
<B><FONT SIZE=+3 COLOR=BLACK > 15 </FONT></B>
<B><I><FONT SIZE=+1 COLOR=BLACK ><A HREF="http://www.15.ca"> Day number 15 </A></FONT></I></B>
<FONT SIZE=+0 COLOR=BLACK >
 <U><I>
 <BR><A HREF="http://www.15.com/"> </I></U><FONT COLOR=#33cc00 SIZE=+0> <I> Text 1 for 15 </I></FONT><U><I> </A>
<BR>Second 15 text </I></U><FONT COLOR=#FF99FF SIZE=+1> <U> Second 15 text </U></FONT><U><I> </A>
<BR><A HREF="http://www.15.net/"> </I></U><FONT COLOR=#FF7070 SIZE=+0> <B> 15 bit of text </B></FONT><U><I> </A>
</I></U></FONT></TD>
<TD BGCOLOR=#33cc00 ALIGN=LEFT VALIGN=TOP HEIGHT=100 WIDTH=100>
<B><FONT SIZE=+3 COLOR=BLACK > 16 </FONT></B>
<B><I><FONT SIZE=+1 COLOR=BLACK ><A HREF="http://www.16.ca"> Day number 16 </A></FONT></I></B>
<FONT SIZE=+0 COLOR=BLACK >
 <U><I>
 <BR><A HREF="http://www.16.com/"> </I></U><FONT COLOR=#FF99FF SIZE=+0> <B> Text 1 for 16 </B></FONT><U><I> </A>
<BR>Second 16 text </I></U><FONT COLOR=#FF7070 SIZE=+1> <U> Second 16 text </U></FONT><U><I> </A>
<BR><A HREF="http://www.16.net/"> </I></U><FONT COLOR=#FFB0B0 SIZE=+0> <I> 16 bit of text </I></FONT><U><I> </A>
</I></U></FONT></TD>
<TD BGCOLOR=#FF99FF ALIGN=LEFT VALIGN=TOP HEIGHT=100 WIDTH=100>
<B><FONT SIZE=+3 COLOR=BLACK > 17 </FONT></B>
<B><I><FONT SIZE=+1 COLOR=BLACK ><A HREF="http://www.17.ca"> Day number 17 </A></FONT></I></B>
<FONT SIZE=+0 COLOR=BLACK >
 <U><I>
 <BR><A HREF="http://www.17.com/"> </I></U><FONT COLOR=#FF7070 SIZE=+0> <I> Text 1 for 17 </I></FONT><U><I> </A>
<BR>Second 17 text </I></U><FONT COLOR=#FFB0B0 SIZE=+1> <U> Second 17 text </U></FONT><U><I> </A>
<BR><A HREF="http://www.17.net/"> </I></U><FONT COLOR=WHITE SIZE=+0> <B> 17 bit of text </B></FONT><U><I> </A>
</I></U></FONT></TD>
<TD BGCOLOR=#FF7070 ALIGN=LEFT VALIGN=TOP HEIGHT=100 WIDTH=100>
<B><FONT SIZE=+3 COLOR=BLACK > 18 </FONT></B>
<B><I><FONT SIZE=+1 COLOR=BLACK ><A HREF="http://www.18.ca"> Day number 18 </A></FONT></I></B>
<FONT SIZE=+0 COLOR=BLACK >
 <U><I>
 <BR><A HREF="http://www.18.com/"> </I></U><FONT COLOR=#FFB0B0 SIZE=+0> <B> Text 1 for 18 </B></FONT><U><I> </A>
<BR>Second 18 text </I></U><FONT COLOR=WHITE SIZE=+1> <U> Second 18 text </U></FONT><U><I> </A>
<BR><A HREF="http://www.18.net/"> </I></U><FONT COLOR=#33cc00 SIZE=+0> <I> 18 bit of text </I></FONT><U><I> </A>
</I></U></FONT></TD>
<TD BGCOLOR=#FFB0B0 ALIGN=LEFT VALIGN=TOP HEIGHT=100 WIDTH=100>
<B><FONT SIZE=+3 COLOR=BLACK > 19 </FONT></B>
<B><I><FONT SIZE=+1 COLOR=BLACK ><A HREF="http://www.19.ca"> Day number 19 </A></FONT></I></B>
<FONT SIZE=+0 COLOR=BLACK >
 <U><I>
 <BR><A HREF="http://www.19.com/"> </I></U><FONT COLOR=WHITE SIZE=+0> <I> Text 1 for 19 </I></FONT><U><I> </A>
<BR>Second 19 text </I></U><FONT COLOR=#33cc00 SIZE=+1> <U> Second 19 text </U></FONT><U><I> </A>
<BR><A HREF="http://www.19.net/"> </I></U><FONT COLOR=#FF99FF SIZE=+0> <B> 19 bit of text </B></FONT><U><I> </A>
</I></U></FONT></TD>
<TD BGCOLOR=WHITE ALIGN=LEFT VALIGN=TOP HEIGHT=100 WIDTH=100>
<B><FONT SIZE=+3 COLOR=BLACK > 20 </FONT></B>
<B><I><FONT SIZE=+1 COLOR=BLACK ><A HREF="http://www.20.ca"> Day number 20 </A></FONT></I></B>
<FONT SIZE=+0 COLOR=BLACK >
 <U><I>
 <BR><A HREF="http://www.20.com/"> </I></U><FONT COLOR=#33cc00 SIZE=+0> <B> Text 1 for 20 </B></FONT><U><I> </A>
<BR>Second 20 text </I></U><FONT COLOR=#FF99FF SIZE=+1> <U> Second 20 text </U></FONT><U><I> </A>
<BR><A HREF="http://www.20.net/"> </I></U><FONT COLOR=#FF7070 SIZE=+0> <I> 20 bit of text </I></FONT><U><I> </A>
</I></U></FONT></TD>
<TD BGCOLOR=#33cc00 ALIGN=LEFT VALIGN=TOP HEIGHT=100 WIDTH=100>
<B><FONT SIZE=+3 COLOR=BLACK > 21 </FONT></B>
<B><I><FONT SIZE=+1 COLOR=BLACK ><A HREF="http://www.21.ca"> Day number 21 </A></FONT></I></B>
<FONT SIZE=+0 COLOR=BLACK >
 <U><I>
 <BR><A HREF="http://www.21.com/"> </I></U><FONT COLOR=#FF99FF SIZE=+0> <I> Text 1 for 21 </I></FONT><U><I> </A>
<BR>Second 21 text </I></U><FONT COLOR=#FF7070 SIZE=+1> <U> Second 21 text </U></FONT><U><I> </A>
<BR><A HREF="http://www.21.net/"> </I></U><FONT COLOR=#FFB0B0 SIZE=+0> <B> 21 bit of text </B></FONT><U><I> </A>
</I></U></FONT></TD>
</TR>
<TR>
<TD BGCOLOR=#FF99FF ALIGN=LEFT VALIGN=TOP HEIGHT=100 WIDTH=100>
<B><FONT SIZE=+3 COLOR=BLACK > 22 </FONT></B>
<B><I><FONT SIZE=+1 COLOR=BLACK ><A HREF="http://www.22.ca"> Day number 22 </A></FONT></I></B>
<FONT SIZE=+0 COLOR=BLACK >
 <U><I>
 <BR><A HREF="http://www.22.com/"> </I></U><FONT COLOR=#FF7070 SIZE=+0> <B> Text 1 for 22 </B></FONT><U><I> </A>
<BR>Second 22 text </I></U><FONT COLOR=#FFB0B0 SIZE=+1> <U> Second 22 text </U></FONT><U><I> </A>
<BR><A HREF="http://www.22.net/"> </I></U><FONT COLOR=WHITE SIZE=+0> <I> 22 bit of text </I></FONT><U><I> </A>
</I></U></FONT></TD>
<TD BGCOLOR=#FF7070 ALIGN=LEFT VALIGN=TOP HEIGHT=100 WIDTH=100>
<B><FONT SIZE=+3 COLOR=BLACK > 23 </FONT></B>
<B><I><FONT SIZE=+1 COLOR=BLACK ><A HREF="http://www.23.ca"> Day number 23 </A></FONT></I></B>
<FONT SIZE=+0 COLOR=BLACK >
 <U><I>
 <BR><A HREF="http://www.23.com/"> </I></U><FONT COLOR=#FFB0B0 SIZE=+0> <I> Text 1 for 23 </I></FONT><U><I> </A>
<BR>Second 23 text </I></U><FONT COLOR=WHITE SIZE=+1> <U> Second 23 text </U></FONT><U><I> </A>
<BR><A HREF="http://www.23.net/"> </I></U><FONT COLOR=#33cc00 SIZE=+0> <B> 23 bit of text </B></FONT><U><I> </A>
</I></U></FONT></TD>
<TD BGCOLOR=#FFB0B0 ALIGN=LEFT VALIGN=TOP HEIGHT=100 WIDTH=100>
<B><FONT SIZE=+3 COLOR=BLACK > 24 </FONT></B>
<B><I><FONT SIZE=+1 COLOR=BLACK ><A HREF="http://www.24.ca"> Day number 24 </A></FONT></I></B>
<FONT SIZE=+0 COLOR=BLACK >
 <U><I>
 <BR><A HREF="http://www.24.com/"> </I></U><FONT COLOR=WHITE SIZE=+0> <B> Text 1 for 24 </B></FONT><U><I> </A>
<BR>Second 24 text </I></U><FONT COLOR=#33cc00 SIZE=+1> <U> Second 24 text </U></FONT><U><I> </A>
<BR><A HREF="http://www.24.net/"> </I></U><FONT COLOR=#FF99FF SIZE=+0> <I> 24 bit of text </I></FONT><U><I> </A>
</I></U></FONT></TD>
<TD BGCOLOR=WHITE ALIGN=LEFT VALIGN=TOP HEIGHT=100 WIDTH=100>
<B><FONT SIZE=+3 COLOR=BLACK > 25 </FONT></B>
<B><I><FONT SIZE=+1 COLOR=BLACK ><A HREF="http://www.25.ca"> Day number 25 </A></FONT></I></B>
<FONT SIZE=+0 COLOR=BLACK >
 <U><I>
 <BR><A HREF="http://www.25.com/"> </I></U><FONT COLOR=#33cc00 SIZE=+0> <I> Text 1 for 25 </I></FONT><U><I> </A>
<BR>Second 25 text </I></U><FONT COLOR=#FF99FF SIZE=+1> <U> Second 25 text </U></FONT><U><I> </A>
<BR><A HREF="http://www.25.net/"> </I></U><FONT COLOR=#FF7070 SIZE=+0> <B> 25 bit of text </B></FONT><U><I> </A>
</I></U></FONT></TD>
<TD BGCOLOR=#33cc00 ALIGN=LEFT VALIGN=TOP HEIGHT=100 WIDTH=100>
<B><FONT SIZE=+3 COLOR=BLACK > 26 </FONT></B>
<B><I><FONT SIZE=+1 COLOR=BLACK ><A HREF="http://www.26.ca"> Day number 26 </A></FONT></I></B>
<FONT SIZE=+0 COLOR=BLACK >
 <U><I>
 <BR><A HREF="http://www.26.com/"> </I></U><FONT COLOR=#FF99FF SIZE=+0> <B> Text 1 for 26 </B></FONT><U><I> </A>
<BR>Second 26 text </I></U><FONT COLOR=#FF7070 SIZE=+1> <U> Second 26 text </U></FONT><U><I> </A>
<BR><A HREF="http://www.26.net/"> </I></U><FONT COLOR=#FFB0B0 SIZE=+0> <I> 26 bit of text </I></FONT><U><I> </A>
</I></U></FONT></TD>
<TD BGCOLOR=#FF99FF ALIGN=LEFT VALIGN=TOP HEIGHT=100 WIDTH=100>
<B><FONT SIZE=+3 COLOR=BLACK > 27 </FONT></B>
<B><I><FONT SIZE=+1 COLOR=BLACK ><A HREF="http://www.27.ca"> Day number 27 </A></FONT></I></B>
<FONT SIZE=+0 COLOR=BLACK >
 <U><I>
 <BR><A HREF="http://www.27.com/"> </I></U><FONT COLOR=#FF7070 SIZE=+0> <I> Text 1 for 27 </I></FONT><U><I> </A>
<BR>Second 27 text </I></U><FONT COLOR=#FFB0B0 SIZE=+1> <U> Second 27 text </U></FONT><U><I> </A>
<BR><A HREF="http://www.27.net/"> </I></U><FONT COLOR=WHITE SIZE=+0> <B> 27 bit of text </B></FONT><U><I> </A>
</I></U></FONT></TD>
<TD BGCOLOR=#FF7070 ALIGN=LEFT VALIGN=TOP HEIGHT=100 WIDTH=100>
<B><FONT SIZE=+3 COLOR=BLACK > 28 </FONT></B>
<B><I><FONT SIZE=+1 COLOR=BLACK ><A HREF="http://www.28.ca"> Day number 28 </A></FONT></I></B>
<FONT SIZE=+0 COLOR=BLACK >
 <U><I>
 <BR><A HREF="http://www.28.com/"> </I></U><FONT COLOR=#FFB0B0 SIZE=+0> <B> Text 1 for 28 </B></FONT><U><I> </A>
<BR>Second 28 text </I></U><FONT COLOR=WHITE SIZE=+1> <U> Second 28 text </U></FONT><U><I> </A>
<BR><A HREF="http://www.28.net/"> </I></U><FONT COLOR=#33cc00 SIZE=+0> <I> 28 bit of text </I></FONT><U><I> </A>
</I></U></FONT></TD>
</TR>
<TR>
<TD BGCOLOR=#FFB0B0 ALIGN=LEFT VALIGN=TOP HEIGHT=100 WIDTH=100>
<B><FONT SIZE=+3 COLOR=BLACK > 29 </FONT></B>
<B><I><FONT SIZE=+1 COLOR=BLACK ><A HREF="http://www.29.ca"> Day number 29 </A></FONT></I></B>
<FONT SIZE=+0 COLOR=BLACK >
 <U><I>
 <BR><A HREF="http://www.29.com/"> </I></U><FONT COLOR=WHITE SIZE=+0> <I> Text 1 for 29 </I></FONT><U><I> </A>
<BR>Second 29 text </I></U><FONT COLOR=#33cc00 SIZE=+1> <U> Second 29 text </U></FONT><U><I> </A>
<BR><A HREF="http://www.29.net/"> </I></U><FONT COLOR=#FF99FF SIZE=+0> <B> 29 bit of text </B></FONT><U><I> </A>
</I></U></FONT></TD>
<TD BGCOLOR=WHITE ALIGN=LEFT VALIGN=TOP HEIGHT=100 WIDTH=100>
<B><FONT SIZE=+3 COLOR=BLACK > 30 </FONT></B>
<B><I><FONT SIZE=+1 COLOR=BLACK ><A HREF="http://www.30.ca"> Day number 30 </A></FONT></I></B>
<FONT SIZE=+0 COLOR=BLACK >
 <U><I>
 <BR><A HREF="http://www.30.com/"> </I></U><FONT COLOR=#33cc00 SIZE=+0> <B> Text 1 for 30 </B></FONT><U><I> </A>
<BR>Second 30 text </I></U><FONT COLOR=#FF99FF SIZE=+1> <U> Second 30 text </U></FONT><U><I> </A>
<BR><A HREF="http://www.30.net/"> </I></U><FONT COLOR=#FF7070 SIZE=+0> <I> 30 bit of text </I></FONT><U><I> </A>
</I></U></FONT></TD>
<TD BGCOLOR=#33cc00 ALIGN=LEFT VALIGN=TOP HEIGHT=100 WIDTH=100>
<B><FONT SIZE=+3 COLOR=BLACK > 31 </FONT></B>
<B><I><FONT SIZE=+1 COLOR=BLACK ><A HREF="http://www.31.ca"> Day number 31 </A></FONT></I></B>
<FONT SIZE=+0 COLOR=BLACK >
 <U><I>
 <BR><A HREF="http://www.31.com/"> </I></U><FONT COLOR=#FF99FF SIZE=+0> <I> Text 1 for 31 </I></FONT><U><I> </A>
<BR>Second 31 text </I></U><FONT COLOR=#FF7070 SIZE=+1> <U> Second 31 text </U></FONT><U><I> </A>
<BR><A HREF="http://www.31.net/"> </I></U><FONT COLOR=#FFB0B0 SIZE=+0> <B> 31 bit of text </B></FONT><U><I> </A>
</I></U></FONT></TD>
<TD BGCOLOR=#66FFFF ALIGN=LEFT VALIGN=TOP HEIGHT=100 WIDTH=100>
<B><I><FONT SIZE=+1 COLOR=BLACK >  </FONT></I></B>
<FONT SIZE=+0 COLOR=BLACK >
 <U><I>
 <BR> </I></U><FONT COLOR=b SIZE=+0>   Comment one  </FONT><U><I> 
</I></U></FONT></TD>
<TD BGCOLOR=#66FFFF ALIGN=LEFT VALIGN=TOP HEIGHT=100 WIDTH=100>
<B><I><FONT SIZE=+1 COLOR=BLACK >  </FONT></I></B>
<FONT SIZE=+0 COLOR=BLACK >
 <U><I>
 <BR> </I></U><FONT COLOR=g SIZE=+1> <B> Comment two </B></FONT><U><I> 
<BR> </I></U><FONT COLOR=g SIZE=+1> <B> and so on </B></FONT><U><I> 
</I></U></FONT></TD>
<TD BGCOLOR=#66FFFF ALIGN=LEFT VALIGN=TOP HEIGHT=100 WIDTH=100>
<B><I><FONT SIZE=+1 COLOR=BLACK >  </FONT></I></B>
<FONT SIZE=+0 COLOR=BLACK >
 <U><I>
 <BR> </I></U><FONT COLOR=b SIZE=+3> <B><I> Comment three </I></B></FONT><U><I> 
</I></U></FONT></TD>
<TD WIDTH=100 BGCOLOR=#66FFFF>&nbsp;  </TD>
</TR>
<TR>
</TABLE>
TEST1

	$test2 = <<'TEST2';
<TABLE BORDER=0 BGCOLOR=#66FFFF WIDTH=80 >
<TR><TD COLSPAN=7 WIDTH=80 ><CENTER><A HREF="http://www.lookithere.org/the_whole_month"><B><FONT SIZE=+1>March 1998</FONT></B></A></CENTER>
</TD></TR>
<TR>
<TD ALIGN=center VALIGN=bottom WIDTH=11 NOSAVE NOWRAP><B>S</B></TD>
<TD ALIGN=center VALIGN=bottom WIDTH=11 NOSAVE NOWRAP><B>M</B></TD>
<TD ALIGN=center VALIGN=bottom WIDTH=11 NOSAVE NOWRAP><B>T</B></TD>
<TD ALIGN=center VALIGN=bottom WIDTH=11 NOSAVE NOWRAP><B>W</B></TD>
<TD ALIGN=center VALIGN=bottom WIDTH=11 NOSAVE NOWRAP><B>T</B></TD>
<TD ALIGN=center VALIGN=bottom WIDTH=11 NOSAVE NOWRAP><B>F</B></TD>
<TD ALIGN=center VALIGN=bottom WIDTH=11 NOSAVE NOWRAP><B>S</B></TD>
</TR>
<TR>
<TD BGCOLOR=#33cc00 ALIGN=LEFT VALIGN=TOP HEIGHT=11 WIDTH=11><A href="http://some.org/name_number_1">
<B><FONT SIZE=+0 COLOR=BLACK > 1 </FONT></B>
<B><I><FONT SIZE=-1 COLOR=BLACK >  </FONT></I></B>
<FONT SIZE=-1 COLOR=BLACK >
  
  </FONT></A></TD>
<TD BGCOLOR=#FF99FF ALIGN=LEFT VALIGN=TOP HEIGHT=11 WIDTH=11><A href="http://some.org/name_number_2">
<B><FONT SIZE=+0 COLOR=BLACK > 2 </FONT></B>
<B><I><FONT SIZE=-1 COLOR=BLACK >  </FONT></I></B>
<FONT SIZE=-1 COLOR=BLACK >
  
  </FONT></A></TD>
<TD BGCOLOR=#FF7070 ALIGN=LEFT VALIGN=TOP HEIGHT=11 WIDTH=11><A href="http://some.org/name_number_3">
<B><FONT SIZE=+0 COLOR=BLACK > 3 </FONT></B>
<B><I><FONT SIZE=-1 COLOR=BLACK >  </FONT></I></B>
<FONT SIZE=-1 COLOR=BLACK >
  
  </FONT></A></TD>
<TD BGCOLOR=#FFB0B0 ALIGN=LEFT VALIGN=TOP HEIGHT=11 WIDTH=11><A href="http://some.org/name_number_4">
<B><FONT SIZE=+0 COLOR=BLACK > 4 </FONT></B>
<B><I><FONT SIZE=-1 COLOR=BLACK >  </FONT></I></B>
<FONT SIZE=-1 COLOR=BLACK >
  
  </FONT></A></TD>
<TD BGCOLOR=WHITE ALIGN=LEFT VALIGN=TOP HEIGHT=11 WIDTH=11><A href="http://some.org/name_number_5">
<B><FONT SIZE=+0 COLOR=BLACK > 5 </FONT></B>
<B><I><FONT SIZE=-1 COLOR=BLACK >  </FONT></I></B>
<FONT SIZE=-1 COLOR=BLACK >
  
  </FONT></A></TD>
<TD BGCOLOR=#33cc00 ALIGN=LEFT VALIGN=TOP HEIGHT=11 WIDTH=11><A href="http://some.org/name_number_6">
<B><FONT SIZE=+0 COLOR=BLACK > 6 </FONT></B>
<B><I><FONT SIZE=-1 COLOR=BLACK >  </FONT></I></B>
<FONT SIZE=-1 COLOR=BLACK >
  
  </FONT></A></TD>
<TD BGCOLOR=#FF99FF ALIGN=LEFT VALIGN=TOP HEIGHT=11 WIDTH=11><A href="http://some.org/name_number_7">
<B><FONT SIZE=+0 COLOR=BLACK > 7 </FONT></B>
<B><I><FONT SIZE=-1 COLOR=BLACK >  </FONT></I></B>
<FONT SIZE=-1 COLOR=BLACK >
  
  </FONT></A></TD>
</TR>
<TR>
<TD BGCOLOR=#FF7070 ALIGN=LEFT VALIGN=TOP HEIGHT=11 WIDTH=11><A href="http://some.org/name_number_8">
<B><FONT SIZE=+0 COLOR=BLACK > 8 </FONT></B>
<B><I><FONT SIZE=-1 COLOR=BLACK >  </FONT></I></B>
<FONT SIZE=-1 COLOR=BLACK >
  
  </FONT></A></TD>
<TD BGCOLOR=#FFB0B0 ALIGN=LEFT VALIGN=TOP HEIGHT=11 WIDTH=11><A href="http://some.org/name_number_9">
<B><FONT SIZE=+0 COLOR=BLACK > 9 </FONT></B>
<B><I><FONT SIZE=-1 COLOR=BLACK >  </FONT></I></B>
<FONT SIZE=-1 COLOR=BLACK >
  
  </FONT></A></TD>
<TD BGCOLOR=WHITE ALIGN=LEFT VALIGN=TOP HEIGHT=11 WIDTH=11><A href="http://some.org/name_number_10">
<B><FONT SIZE=+0 COLOR=BLACK > 10 </FONT></B>
<B><I><FONT SIZE=-1 COLOR=BLACK >  </FONT></I></B>
<FONT SIZE=-1 COLOR=BLACK >
  
  </FONT></A></TD>
<TD BGCOLOR=#33cc00 ALIGN=LEFT VALIGN=TOP HEIGHT=11 WIDTH=11><A href="http://some.org/name_number_11">
<B><FONT SIZE=+0 COLOR=BLACK > 11 </FONT></B>
<B><I><FONT SIZE=-1 COLOR=BLACK >  </FONT></I></B>
<FONT SIZE=-1 COLOR=BLACK >
  
  </FONT></A></TD>
<TD BGCOLOR=#FF99FF ALIGN=LEFT VALIGN=TOP HEIGHT=11 WIDTH=11><A href="http://some.org/name_number_12">
<B><FONT SIZE=+0 COLOR=BLACK > 12 </FONT></B>
<B><I><FONT SIZE=-1 COLOR=BLACK >  </FONT></I></B>
<FONT SIZE=-1 COLOR=BLACK >
  
  </FONT></A></TD>
<TD BGCOLOR=#FF7070 ALIGN=LEFT VALIGN=TOP HEIGHT=11 WIDTH=11><A href="http://some.org/name_number_13">
<B><FONT SIZE=+0 COLOR=BLACK > 13 </FONT></B>
<B><I><FONT SIZE=-1 COLOR=BLACK >  </FONT></I></B>
<FONT SIZE=-1 COLOR=BLACK >
  
  </FONT></A></TD>
<TD BGCOLOR=#FFB0B0 ALIGN=LEFT VALIGN=TOP HEIGHT=11 WIDTH=11><A href="http://some.org/name_number_14">
<B><FONT SIZE=+0 COLOR=BLACK > 14 </FONT></B>
<B><I><FONT SIZE=-1 COLOR=BLACK >  </FONT></I></B>
<FONT SIZE=-1 COLOR=BLACK >
  
  </FONT></A></TD>
</TR>
<TR>
<TD BGCOLOR=WHITE ALIGN=LEFT VALIGN=TOP HEIGHT=11 WIDTH=11><A href="http://some.org/name_number_15">
<B><FONT SIZE=+0 COLOR=BLACK > 15 </FONT></B>
<B><I><FONT SIZE=-1 COLOR=BLACK >  </FONT></I></B>
<FONT SIZE=-1 COLOR=BLACK >
  
  </FONT></A></TD>
<TD BGCOLOR=#33cc00 ALIGN=LEFT VALIGN=TOP HEIGHT=11 WIDTH=11><A href="http://some.org/name_number_16">
<B><FONT SIZE=+0 COLOR=BLACK > 16 </FONT></B>
<B><I><FONT SIZE=-1 COLOR=BLACK >  </FONT></I></B>
<FONT SIZE=-1 COLOR=BLACK >
  
  </FONT></A></TD>
<TD BGCOLOR=#FF99FF ALIGN=LEFT VALIGN=TOP HEIGHT=11 WIDTH=11><A href="http://some.org/name_number_17">
<B><FONT SIZE=+0 COLOR=BLACK > 17 </FONT></B>
<B><I><FONT SIZE=-1 COLOR=BLACK >  </FONT></I></B>
<FONT SIZE=-1 COLOR=BLACK >
  
  </FONT></A></TD>
<TD BGCOLOR=#FF7070 ALIGN=LEFT VALIGN=TOP HEIGHT=11 WIDTH=11><A href="http://some.org/name_number_18">
<B><FONT SIZE=+0 COLOR=BLACK > 18 </FONT></B>
<B><I><FONT SIZE=-1 COLOR=BLACK >  </FONT></I></B>
<FONT SIZE=-1 COLOR=BLACK >
  
  </FONT></A></TD>
<TD BGCOLOR=#FFB0B0 ALIGN=LEFT VALIGN=TOP HEIGHT=11 WIDTH=11><A href="http://some.org/name_number_19">
<B><FONT SIZE=+0 COLOR=BLACK > 19 </FONT></B>
<B><I><FONT SIZE=-1 COLOR=BLACK >  </FONT></I></B>
<FONT SIZE=-1 COLOR=BLACK >
  
  </FONT></A></TD>
<TD BGCOLOR=WHITE ALIGN=LEFT VALIGN=TOP HEIGHT=11 WIDTH=11><A href="http://some.org/name_number_20">
<B><FONT SIZE=+0 COLOR=BLACK > 20 </FONT></B>
<B><I><FONT SIZE=-1 COLOR=BLACK >  </FONT></I></B>
<FONT SIZE=-1 COLOR=BLACK >
  
  </FONT></A></TD>
<TD BGCOLOR=#33cc00 ALIGN=LEFT VALIGN=TOP HEIGHT=11 WIDTH=11><A href="http://some.org/name_number_21">
<B><FONT SIZE=+0 COLOR=BLACK > 21 </FONT></B>
<B><I><FONT SIZE=-1 COLOR=BLACK >  </FONT></I></B>
<FONT SIZE=-1 COLOR=BLACK >
  
  </FONT></A></TD>
</TR>
<TR>
<TD BGCOLOR=#FF99FF ALIGN=LEFT VALIGN=TOP HEIGHT=11 WIDTH=11><A href="http://some.org/name_number_22">
<B><FONT SIZE=+0 COLOR=BLACK > 22 </FONT></B>
<B><I><FONT SIZE=-1 COLOR=BLACK >  </FONT></I></B>
<FONT SIZE=-1 COLOR=BLACK >
  
  </FONT></A></TD>
<TD BGCOLOR=#FF7070 ALIGN=LEFT VALIGN=TOP HEIGHT=11 WIDTH=11><A href="http://some.org/name_number_23">
<B><FONT SIZE=+0 COLOR=BLACK > 23 </FONT></B>
<B><I><FONT SIZE=-1 COLOR=BLACK >  </FONT></I></B>
<FONT SIZE=-1 COLOR=BLACK >
  
  </FONT></A></TD>
<TD BGCOLOR=#FFB0B0 ALIGN=LEFT VALIGN=TOP HEIGHT=11 WIDTH=11><A href="http://some.org/name_number_24">
<B><FONT SIZE=+0 COLOR=BLACK > 24 </FONT></B>
<B><I><FONT SIZE=-1 COLOR=BLACK >  </FONT></I></B>
<FONT SIZE=-1 COLOR=BLACK >
  
  </FONT></A></TD>
<TD BGCOLOR=WHITE ALIGN=LEFT VALIGN=TOP HEIGHT=11 WIDTH=11><A href="http://some.org/name_number_25">
<B><FONT SIZE=+0 COLOR=BLACK > 25 </FONT></B>
<B><I><FONT SIZE=-1 COLOR=BLACK >  </FONT></I></B>
<FONT SIZE=-1 COLOR=BLACK >
  
  </FONT></A></TD>
<TD BGCOLOR=#33cc00 ALIGN=LEFT VALIGN=TOP HEIGHT=11 WIDTH=11><A href="http://some.org/name_number_26">
<B><FONT SIZE=+0 COLOR=BLACK > 26 </FONT></B>
<B><I><FONT SIZE=-1 COLOR=BLACK >  </FONT></I></B>
<FONT SIZE=-1 COLOR=BLACK >
  
  </FONT></A></TD>
<TD BGCOLOR=#FF99FF ALIGN=LEFT VALIGN=TOP HEIGHT=11 WIDTH=11><A href="http://some.org/name_number_27">
<B><FONT SIZE=+0 COLOR=BLACK > 27 </FONT></B>
<B><I><FONT SIZE=-1 COLOR=BLACK >  </FONT></I></B>
<FONT SIZE=-1 COLOR=BLACK >
  
  </FONT></A></TD>
<TD BGCOLOR=#FF7070 ALIGN=LEFT VALIGN=TOP HEIGHT=11 WIDTH=11><A href="http://some.org/name_number_28">
<B><FONT SIZE=+0 COLOR=BLACK > 28 </FONT></B>
<B><I><FONT SIZE=-1 COLOR=BLACK >  </FONT></I></B>
<FONT SIZE=-1 COLOR=BLACK >
  
  </FONT></A></TD>
</TR>
<TR>
<TD BGCOLOR=#FFB0B0 ALIGN=LEFT VALIGN=TOP HEIGHT=11 WIDTH=11><A href="http://some.org/name_number_29">
<B><FONT SIZE=+0 COLOR=BLACK > 29 </FONT></B>
<B><I><FONT SIZE=-1 COLOR=BLACK >  </FONT></I></B>
<FONT SIZE=-1 COLOR=BLACK >
  
  </FONT></A></TD>
<TD BGCOLOR=WHITE ALIGN=LEFT VALIGN=TOP HEIGHT=11 WIDTH=11><A href="http://some.org/name_number_30">
<B><FONT SIZE=+0 COLOR=BLACK > 30 </FONT></B>
<B><I><FONT SIZE=-1 COLOR=BLACK >  </FONT></I></B>
<FONT SIZE=-1 COLOR=BLACK >
  
  </FONT></A></TD>
<TD BGCOLOR=#33cc00 ALIGN=LEFT VALIGN=TOP HEIGHT=11 WIDTH=11><A href="http://some.org/name_number_31">
<B><FONT SIZE=+0 COLOR=BLACK > 31 </FONT></B>
<B><I><FONT SIZE=-1 COLOR=BLACK >  </FONT></I></B>
<FONT SIZE=-1 COLOR=BLACK >
  
  </FONT></A></TD>
<TD WIDTH=11 BGCOLOR=#66FFFF>&nbsp;  </TD>
<TD WIDTH=11 BGCOLOR=#66FFFF>&nbsp;  </TD>
<TD WIDTH=11 BGCOLOR=#66FFFF>&nbsp;  </TD>
<TD WIDTH=11 BGCOLOR=#66FFFF>&nbsp;  </TD>
</TR>
<TR>
</TABLE>
TEST2

#---------------------------------------- normal month

	my $month = PlotCalendar::Month->new($mon, $year);

	#	 These are values with default settings, so these are optional

	# global values, to be applied to all cells

	$month -> size(700,700); # width, height in pixels
	$month -> font('14','10','8');
	$month -> cliptext('yes');
	$month -> firstday('Sun'); # First column is Sunday
	$month -> artwork('/home/ajackson/public_html/cgi-bin/Calendar/Calendar_art3/'); 

	#	arrays of values, if not an array, apply to all cells, if an array
	#  apply to each cell, indexed by day-of-month

	my @text;
	my @daynames;
	my @nameref;
	my @bgcolor;
	my @colors = ('WHITE','#33cc00','#FF99FF','#FF7070','#FFB0B0',);
	my (@textcol,@textsize,@textstyle,@textref);
	my @style = ('i','u','b',);
	my @url;


	for (my $i=1;$i<=31;$i++) {
		$daynames[$i] = "Day number $i";
		$nameref[$i] = "<A HREF=\"http://www.$i.ca\">";
		$bgcolor[$i] = $colors[$i%5];
		@{$text[$i]} = ("Text 1 for $i","Second $i text","$i bit of text",);
		@{$textref[$i]} = ("<A HREF=\"http://www.$i.com/\">","Second $i text","<A HREF=\"http://www.$i.net/\">",);
		@{$textcol[$i]} = ($colors[($i+1)%5],$colors[($i+2)%5],$colors[($i+3)%5]);
		@{$textsize[$i]} = ("8","10","8",);
		@{$textstyle[$i]} = @style;
		@style = reverse(@style);
		$url[$i] = '<A href="http://some.org/name_number_' . $i . '">';
	}

	$month -> fgcolor('BLACK',); #  Global foreground color
	$month -> bgcolor(@bgcolor); # Background color per day
	$month -> styles('b','bi','ui',); # Global text styles

	#	Comments

	my @prefs = ('before','after','after');
	my @comments = (['Comment one'],["Comment two","and so on"],['Comment three']);
	my @comcol = qw(b g b);
	my @comstyle = qw(n b bi);
	my @comsize = qw(8 10 14);

	$month->comments(\@prefs,\@comments,\@comcol,\@comstyle,\@comsize);

	$month -> dayname(@daynames);
	$month -> nameref(@nameref);

	$month -> text(@text);
	$month -> textcolor(@textcol);
	$month -> textsize(@textsize);
	$month -> textstyle(@textstyle);
	$month -> textref(@textref);

	my $html = $month -> gethtml;

		if ($html eq $test1) {
		print "ok 1\n";
	}
	else {
		print "not ok 1\n";
	}

#---------------------------------------- tiny month

	my $tinymonth = PlotCalendar::Month->new($mon, $year);

	#	 These are values with default settings, so these are optional

	# global values, to be applied to all cells

	$tinymonth -> size(80,80); # width, height in pixels
	$tinymonth -> font('8','6','6');
	$tinymonth -> cliptext('yes');
	$tinymonth -> firstday('Sun'); # First column is Sunday

	#	arrays of values, if not an array, apply to all cells, if an array
	#  apply to each cell, indexed by day-of-month

	@colors = ('WHITE','#33cc00','#FF99FF','#FF7070','#FFB0B0',);

	for (my $i=1;$i<=31;$i++) {
		$nameref[$i] = "<A HREF=\"http://www.$i.ca\">";
		$bgcolor[$i] = $colors[$i%5];
		$url[$i] = '<A href="http://some.org/name_number_' . $i . '">';
	}

	$tinymonth -> fgcolor('BLACK',); #  Global foreground color
	$tinymonth -> bgcolor(@bgcolor); # Background color per day

	$tinymonth -> htmlref(@url);
	$tinymonth -> monthref('<A HREF="http://www.lookithere.org/the_whole_month">');

	#	So, what do we have now?

	$html = $tinymonth -> gethtml;

		if ($html eq $test2) {
		print "ok 2\n";
	}
	else {
		print "not ok 2\n";
	}



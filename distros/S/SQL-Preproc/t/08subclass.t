#
#	SQL::Preproc subclass tests
#	requires DBIx::Chart/DBD::Chart
#	adapted from DBIx::Chart plottest.t
#
use vars qw($testnum $loaded);
BEGIN { 
	my $tests = 45; 
	$^W= 1; 
	$| = 1; 
	eval {
		require DBIx::Chart;
	};
	print "1..0 # Skipped: no DBIx::Chart\n" and
	exit 0
		if ($@);
	
	eval {
		require DBD::Chart;
	};
	print "1..0 # Skipped: no DBD::Chart\n" and
	exit 0
		if ($@);
	print "1..$tests\n";
}
END {print "not ok $testnum\n" unless $loaded;}

use SQL::Preproc
	relax => 1,
	subclass => 'Chart';

use DBI;
use DBI qw(:sql_types);
use DBIx::Chart;
use SQL::Preproc::ExceptContainer;

use strict;

$testnum = 0;

use constant PI => 3.1415926;

my @x = ( 10, 20, 30, 40, 50);
my @y1 = ( 23, -39, 102, 67, 80);
my @y2 = ( 53, 39, 127, 89, 108);
my @y3 = ( 35, 45, 55, 65, 75);
my @xtmstamp = ( '2002-12-24 10:33:00', '2002-12-24 13:33:06', 
	'2002-12-24 17:20:00', '2002-12-25 00:13:34', '2002-12-25 04:44:44');
my @xdate = ( '2002-12-24', '2002-12-25', '2002-12-26', '2002-12-27', '2002-12-28');
my @ytime = ( '0:12:34', '11:29:00', '5:57:33', '22:22:22', '4:06:01');
my @xdate2 = ( '1970-01-24', '1975-01-25', '1985-01-26', '1997-01-27', '2030-01-28');
my @ytime2 = ( '0:12:34', '11:29:00', '255:57:33', '2222:22:22', '4328:06:01');
my @xbox = ();
my @xfreq = ();
my @yfreq = ();
my %xbhash = ();
my @z = qw (Q1 Q2 Q3 Q4 Q1 Q2 Q3 Q4 Q1 Q2 Q3 Q4 Q1 Q2 Q3 Q4);
my @x3d = qw(North North North North 
East East East East South South South South West West West West);
my @y3d = (
	123, 354, 987, 455,
	346, 978, 294, 777,
	765, 99,  222, 409,
	687, 233, 555, 650);

open(HTMLF, ">t/plottest.html");
print HTMLF <<'HTML-TEXT';
<html><body>
<table border=1>
<tr><th>Chart</th><th>Rendering SQL</th></tr>
<tr><td valign=top align=center><img src=imgs/simpline.png alt='simpline' usemap=#simpline></td>
<td valign=top align=left>
<pre>	
select * from simpline
    returning linegraph(*), imagemap 
    where WIDTH=500 
    AND HEIGHT=500 
    AND X_AXIS='Some Domain' 
    AND Y_AXIS='Some Range' 
    AND TITLE='Linegraph Test' 
    AND SIGNATURE='(C)2002, GOWI Systems' 
    AND LOGO='t/gowilogo.png' 
    AND FORMAT='PNG' 
    AND SHOWGRID=1 
    AND LINEWIDTH=4 
    AND MAPNAME='simpline' 
    AND MAPURL='http://www.gowi.com/cgi-bin/sample.pl?x=:X&y=:Y&z=:Z&plotno=:PLOTNUM'
    AND MAPTYPE='HTML' 
    AND COLOR='newcolor'
    AND SHAPE='fillcircle'
    AND SHOWVALUES=1
</pre></td></tr>
<tr><td valign=top align=center><img src=imgs/simpscat.png alt='simpscat' usemap=#simpscat></td>
<td valign=top align=left>
<pre>
select * from simpline
    returning pointgraph(x,y), imagemap 
    where WIDTH=500 
    AND HEIGHT=500 
    AND X_AXIS='Some Domain' 
    and Y_AXIS='Some Range' 
    AND TITLE='Scattergraph Test' 
    AND SIGNATURE='(C)2002, GOWI Systems' 
    AND LOGO='t/gowilogo.png' 
    AND FORMAT='PNG' 
    AND SHOWGRID=0 
    AND MAPNAME='simpscat' 
    AND MAPURL='http://www.gowi.com/cgi-bin/sample.pl?x=:X&y=:Y&z=:Z&plotno=:PLOTNUM'
    AND MAPTYPE='HTML' 
    AND SHOWVALUES=1
</pre></td></tr>
<tr><td valign=top align=center><img src=imgs/simparea.png alt='simparea' usemap=#simparea></td>
<td valign=top align=left><pre>
select * from simpline
    returning areagraph(*), imagemap 
    where WIDTH=500 
    AND HEIGHT=500 
    AND X_AXIS='Some Domain' 
    AND Y_AXIS='Some Range' 
    AND TITLE='Areagraph Test' 
    AND SIGNATURE='(C)2002, GOWI Systems' 
    AND LOGO='t/gowilogo.png' 
    AND FORMAT='PNG' 
    AND SHOWGRID=1 
    AND MAPNAME='simparea' 
    AND COLOR='newcolor' 
    AND MAPURL='http://www.gowi.com/cgi-bin/sample.pl?x=:X&y=:Y&z=:Z&plotno=:PLOTNUM'
    AND MAPTYPE='HTML' AND SHOWVALUES=0
</pre></td></tr>
<tr><td valign=top align=center><img src=imgs/symline.png alt='symline' usemap=#symline></td>
<td valign=top align=left><pre>
select * from symline
    returning linegraph(*), imagemap 
    where WIDTH=500 AND HEIGHT=500 
    AND X_AXIS='Some Domain' 
    and Y_AXIS='Some Range' 
    AND TITLE='Symbolic Domain Linegraph Test' 
    AND SIGNATURE='(C)2002, GOWI Systems' 
    AND LOGO='t/gowilogo.png' 
    AND FORMAT='PNG' 
    AND SHOWGRID=1 
    AND MAPNAME='symline' 
    AND MAPURL='http://www.gowi.com/cgi-bin/sample.pl?x=:X&y=:Y&z=:Z&plotno=:PLOTNUM'
    AND MAPTYPE='HTML' AND COLOR=newcolor AND SHAPE=fillcircle
    </pre></td></tr>
<tr><td valign=top align=center><img src=imgs/simpbar.png alt='simpbar' usemap=#simpbar></td>
<td valign=top align=left><pre>
select * from symline
    returning barchart(*), imagemap 
    where WIDTH=500 AND HEIGHT=500 
    AND X_AXIS='Some Domain' 
    and Y_AXIS='Some Range' 
    AND TITLE='Barchart Test' 
    AND SIGNATURE='(C)2002, GOWI Systems' 
    AND FORMAT='PNG' 
    AND SHOWVALUES=1 
    AND MAPNAME='simpbar' 
    AND MAPURL='http://www.gowi.com/cgi-bin/sample.pl?x=:X&y=:Y&z=:Z&plotno=:PLOTNUM'
    AND MAPTYPE='HTML' AND COLOR=newcolor
</pre></td></tr>
<tr><td valign=top align=center><img src=imgs/iconbars.png alt='iconbars' usemap=#iconbars></td>
<td valign=top align=left><pre>
select * from symline
    returning barchart(*), imagemap 
    where WIDTH=500 
    AND HEIGHT=500 
    AND X_AXIS='Some Domain' 
    and Y_AXIS='Some Range'
    AND TITLE='Iconic Barchart Test' 
    AND SIGNATURE='(C)2002, GOWI Systems'
    AND FORMAT='PNG' 
    AND SHOWVALUES=1 
    AND ICON='t/pumpkin.png' 
    AND MAPNAME='iconbars' 
    AND SHOWGRID=1 
    AND GRIDCOLOR='blue' 
    AND TEXTCOLOR='dbrown' 
    AND MAPSCRIPT='ONCLICK="alert(''Got X=:X, Y=:Y'')"'
    AND MAPURL='http://www.gowi.com/cgi-bin/sample.pl?x=:X&y=:Y&z=:Z&plotno=:PLOTNUM'
    AND MAPTYPE='HTML'
</pre></td></tr>
<tr><td valign=top align=center><img src=imgs/iconhisto.png alt='iconhisto' usemap=#iconhisto></td>
<td valign=top align=left><pre>
select * from symline
    returning histogram(*), imagemap
    where WIDTH=500
    AND HEIGHT=500
    AND X_AXIS='Some Domain'
    AND Y_AXIS='Some Range'
    AND TITLE='Iconic Histogram Test'
    AND SIGNATURE='(C)2002, GOWI Systems'
    AND FORMAT='PNG'
    AND ICON='t/pumpkin.png'
    AND MAPNAME='iconhisto'
    AND SHOWGRID=1
    AND GRIDCOLOR='red'
    AND TEXTCOLOR='newcolor'
    AND MAPSCRIPT='ONCLICK="alert(''Got X=:X, Y=:Y'')"'
    AND MAPURL='http://www.gowi.com/cgi-bin/sample.pl?x=:X&y=:Y&z=:Z&plotno=:PLOTNUM'
    AND MAPTYPE='HTML'
</pre></td></tr>
<tr><td valign=top align=center><img src=imgs/simpbox.png alt='simpbox' usemap=#simpbox></td>
<td valign=top align=left><pre>
select * from simpbox
    returning boxchart(*), imagemap
    where WIDTH=500
    AND HEIGHT=500 
    AND X_AXIS='Some Domain'
    AND TITLE='Boxchart Test' 
    AND SIGNATURE='(C)2002, GOWI Systems'
    AND FORMAT='PNG'
    AND COLORS IN ('newcolor', 'red')
    AND SHOWVALUES=1
    AND MAPNAME='simpbox'
    AND MAPURL='http://www.gowi.com/cgi-bin/sample.pl?x=:X&y=:Y&z=:Z&plotno=:PLOTNUM'
    AND MAPTYPE='HTML'
</pre></td></tr>
<tr><td valign=top align=center><img src=imgs/simpcandle.png alt='simpcandle' usemap=#simpcandle></td>
<td valign=top align=left><pre>
select * from simpcandle
    returning candlestick(*), imagemap 
    where WIDTH=500
    AND HEIGHT=500
    AND X_AXIS='Some Domain'
    AND Y_AXIS = 'Price'
    AND TITLE='Candlestick Test'
    AND SIGNATURE='(C)2002, GOWI Systems'
    AND FORMAT='PNG'
    AND COLORS IN ('newcolor')
    AND SHAPE='fillsquare'
    AND SHOWVALUES=1
    AND SHOWGRID=1
    AND MAPNAME='simpcandle'
    AND MAPURL='http://www.gowi.com/cgi-bin/sample.pl?x=:X&y=:Y&z=:Z&plotno=:PLOTNUM'
    AND MAPTYPE='HTML'
</pre></td></tr>
<tr><td valign=top align=center><img src=imgs/simppie.png alt='simppie' usemap=#simppie></td>
<td valign=top align=left><pre>
select * from simppie
    returning piechart(*), imagemap 
    where WIDTH=500
    AND HEIGHT=500
    AND X_AXIS='Some Domain'
    AND TITLE='Piechart Test'
    AND SIGNATURE='(C)2002, GOWI Systems'
    AND FORMAT='PNG'
    AND COLORS IN ('red', 'blue', 'newcolor', 'green', 'yellow')
    AND MAPNAME='simppie'
    AND MAPURL='http://www.gowi.com/cgi-bin/sample.pl?x=:X&y=:Y&z=:Z&plotno=:PLOTNUM'
    AND MAPTYPE='HTML'
</pre></td></tr>
<tr><td valign=top align=center><img src=imgs/pie3d.png alt='pie3d' usemap=#pie3d></td>
<td valign=top align=left><pre>
select * from simppie
    returning piechart(*), imagemap 
    where WIDTH=500
    AND HEIGHT=500
    AND X_AXIS='Some Domain'
    AND TITLE='3-D Piechart Test'
    AND SIGNATURE='(C)2002, GOWI Systems'
    AND FORMAT='PNG'
    AND COLORS IN ('red', 'blue', 'newcolor', 'green', 'yellow')
    AND THREE_D=1
    AND MAPNAME='pie3d'
    AND MAPURL='http://www.gowi.com/cgi-bin/sample.pl?x=:X&y=:Y&z=:Z&plotno=:PLOTNUM'
    AND MAPTYPE='HTML'
</pre></td></tr>
<tr><td valign=top align=center><img src=imgs/bar3d.png alt='bar3d' usemap=#bar3d></td>
<td valign=top align=left><pre>
select * from simpline
    returning barchart(*), imagemap 
    where WIDTH=500
    AND HEIGHT=500
    AND X_AXIS='Some Domain'
    AND Y_AXIS='Some Range'
    AND TITLE='3-D Barchart Test'
    AND SIGNATURE='(C)2002, GOWI Systems'
    AND FORMAT='PNG'
    AND COLORS IN ('orange')
    AND THREE_D=1
    AND SHOWGRID=1
    AND MAPNAME='bar3d'
    AND MAPURL='http://www.gowi.com/cgi-bin/sample.pl?x=:X&y=:Y&z=:Z&plotno=:PLOTNUM'
    AND MAPTYPE='HTML'
</pre></td></tr>
<tr><td valign=top align=center><img src=imgs/bar3axis.png alt='bar3axis' usemap=#bar3axis></td>
<td valign=top align=left><pre>
select * from bar3axis
    returning barchart(*), imagemap 
    where WIDTH=500
    AND HEIGHT=500
    AND TITLE='3 Axis Barchart Test'
    AND SIGNATURE='(C)2002, GOWI Systems'
    AND X_AXIS='Region'
    AND Y_AXIS='Sales'
    AND Z-AXIS='Quarter'
    AND FORMAT='PNG'
    AND COLORS IN ('red')
    AND SHOWGRID=1
    AND SHOWVALUES=1
    AND MAPNAME='bar3axis'
    AND MAPURL='http://www.gowi.com/cgi-bin/sample.pl?x=:X&y=:Y&z=:Z&plotno=:PLOTNUM'
    AND MAPTYPE='HTML'
</pre></td></tr>
<tr><td valign=top align=center><img src=imgs/simphisto.png alt='simphisto' usemap=#simphisto></td>
<td valign=top align=left><pre>
select * from simppie
    returning histogram(*), imagemap 
    where WIDTH=500
    AND HEIGHT=500
    AND TITLE='Histogram Test'
    AND SIGNATURE='(C)2002, GOWI Systems'
    AND X_AXIS='Some Domain'
    AND Y_AXIS='Some Range'
    AND FORMAT='PNG'
    AND COLOR IN ('red', 'green', 'orange', 'blue', 'newcolor')
    AND SHOWGRID=1
    AND SHOWVALUES=1
    AND MAPNAME='simphisto'
    AND MAPURL='http://www.gowi.com/cgi-bin/sample.pl?x=:X&y=:Y&z=:Z&plotno=:PLOTNUM'
    AND MAPTYPE='HTML'
</pre></td></tr>
<tr><td valign=top align=center><img src=imgs/histo3d.png alt='histo3d' usemap=#histo3d></td>
<td valign=top align=left><pre>
select * from simppie
    returning histogram(*), imagemap 
    where WIDTH=500
    AND HEIGHT=500
    AND TITLE='Histogram Test'
    AND SIGNATURE='(C)2002, GOWI Systems'
    AND X_AXIS='Some Domain'
    AND Y_AXIS='Some Range'
    AND FORMAT='PNG'
    AND COLOR='orange'
    AND THREE_D=1
    AND SHOWGRID=1
    AND SHOWVALUES=1
    AND MAPNAME='histo3d'
    AND MAPURL='http://www.gowi.com/cgi-bin/sample.pl?x=:X&y=:Y&z=:Z&plotno=:PLOTNUM'
    AND MAPTYPE='HTML'
</pre></td></tr>
<tr><td valign=top align=center><img src=imgs/histo3axis.png alt='histo3axis' usemap=#histo3axis></td>
<td valign=top align=left><pre>
select * from bar3axis
    returning histogram(*), imagemap
    where WIDTH=500
    AND HEIGHT=500
    AND TITLE='3 Axis Histogram Test'
    AND SIGNATURE='(C)2002, GOWI Systems'
    AND X_AXIS='Region'
    AND Y_AXIS='Sales'
    AND Z_AXIS='Quarter'
    AND FORMAT='PNG'
    AND COLORS='red'
    AND SHOWGRID=1
    AND SHOWVALUES=1
    AND MAPNAME='histo3axis'
    AND MAPURL='http://www.gowi.com/cgi-bin/sample.pl?x=:X&y=:Y&z=:Z&plotno=:PLOTNUM'
    AND MAPTYPE='HTML'
</pre></td></tr>
<tr><td valign=top align=center><img src=imgs/templine.png alt='templine' usemap=#templine></td>
<td valign=top align=left><pre>
select * from templine
    returning linegraph(xdate, y), imagemap 
    where WIDTH=500
    AND HEIGHT=500
    AND TITLE='Temporal Domain Linegraph Test'
    AND SIGNATURE='(C)2002, GOWI Systems'
    AND X_AXIS='Some Domain'
    AND Y_AXIS='Some Range'
    AND X_ORIENT='VERTICAL'
    AND LOGO='t/gowilogo.png'
    AND FORMAT='PNG'
    AND COLORS=newcolor
    AND SHOWGRID=1
    AND SHOWVALUES=1
    AND MAPNAME='templine'
    AND MAPURL='http://www.gowi.com/cgi-bin/sample.pl?x=:X&y=:Y&z=:Z&plotno=:PLOTNUM'
    AND MAPTYPE='HTML'
</pre></td></tr>
<tr><td valign=top align=center><img src=imgs/templine2.png alt='templine2' usemap=#templine2></td>
<td valign=top align=left><pre>
select * from templine2
    returning linegraph(*), imagemap 
    where WIDTH=500
    AND HEIGHT=500
    AND TITLE='Temporal Range Linegraph Test'
    AND SIGNATURE='(C)2002, GOWI Systems'
    AND X_AXIS='Some Domain'
    AND Y_AXIS='Some Range'
    AND X_ORIENT='VERTICAL'
    AND LOGO='t/gowilogo.png'
    AND FORMAT='PNG'
    AND COLORS=newcolor
    AND SHOWGRID=1
    AND SHOWVALUES=1
    AND SHAPE=fillcircle
    AND MAPNAME='templine2'
    AND MAPURL='http://www.gowi.com/cgi-bin/sample.pl?x=:X&y=:Y&z=:Z&plotno=:PLOTNUM'
    AND MAPTYPE='HTML'
</pre></td></tr>
<tr><td valign=top align=center><img src=imgs/logtempline.png alt='logtempline' usemap=#logtempline></td>
<td valign=top align=left><pre>
select * from logtempline
    returning linegraph(*), imagemap 
    where WIDTH=500
    AND HEIGHT=500
    AND TITLE='Logarithmic Temporal Range Linegraph Test'
    AND SIGNATURE='(C)2002, GOWI Systems'
    AND X_AXIS='Some Domain'
    AND Y_AXIS='Some Range'
    AND X_ORIENT='VERTICAL'
    AND Y-LOG=1
    AND FORMAT='PNG'
    AND COLORS=newcolor
    AND SHOWGRID=1
    AND SHOWVALUES=1
    AND SHAPE=fillcircle
    AND MAPNAME='logtempline'
    AND MAPURL='http://www.gowi.com/cgi-bin/sample.pl?x=:X&y=:Y&z=:Z&plotno=:PLOTNUM'
    AND MAPTYPE='HTML'
</pre></td></tr>
<tr><td valign=top align=center><img src=imgs/tempbar.png alt='tempbar' usemap=#tempbar></td>
<td valign=top align=left><pre>
select * from templine
    returning barchart(*), imagemap 
    where WIDTH=500
    AND HEIGHT=500
    AND TITLE='Temporal Barchart Test'
    AND SIGNATURE='(C)2002, GOWI Systems'
    AND X_AXIS='Some Domain'
    AND Y_AXIS='Some Range'
    AND FORMAT='PNG'
    AND COLORS=red
    AND SHOWVALUES=1
    AND MAPNAME='tempbar'
    AND MAPURL='http://www.gowi.com/cgi-bin/sample.pl?x=:X&y=:Y&z=:Z&plotno=:PLOTNUM'
    AND MAPTYPE='HTML'
</pre></td></tr>
<tr><td valign=top align=center><img src=imgs/temphisto.png alt='temphisto' usemap=#temphisto></td>
<td valign=top align=left><pre>
select * from templine2
    returning histogram(*), imagemap
    where WIDTH=500
    AND HEIGHT=500
    AND TITLE='Temporal Histogram Test'
    AND SIGNATURE='(C)2002, GOWI Systems'
    AND X_AXIS='Some Domain'
    AND Y_AXIS='Some Range'
    AND FORMAT='PNG'
    AND COLORS=blue
    AND SHOWVALUES=1
    AND MAPNAME='temphisto'
    AND MAPURL='http://www.gowi.com/cgi-bin/sample.pl?x=:X&y=:Y&z=:Z&plotno=:PLOTNUM'
    AND MAPTYPE='HTML'
</pre></td></tr>
<tr><td valign=top align=center><img src=imgs/complinept.png alt='complinept' usemap=#complinept></td>
<td valign=top align=left><pre>
select * from
    (select * from simpline
    returning linegraph(*)
        where color=newcolor
        AND shape='fillcircle') simpline,
    (select  * from simppie
    returning pointgraph(*)
        where color=blue
        AND shape='opensquare') simppt
    returning image, imagemap
    where WIDTH=500
    AND HEIGHT=500
    AND TITLE='Composite Line/Pointgraph Test'
    AND SIGNATURE='(C)2002, GOWI Systems'
    AND X_AXIS='Some Domain'
    AND Y_AXIS='Some Range'
    AND FORMAT='PNG'
    AND MAPNAME='complinept'
    AND MAPURL='http://www.gowi.com/cgi-bin/sample.pl?x=:X&y=:Y&z=:Z&plotno=:PLOTNUM'
    AND MAPTYPE='HTML'
</pre></td></tr>
<tr><td valign=top align=center><img src=imgs/complpa.png alt='complpa' usemap=#complpa></td>
<td valign=top align=left><pre>
select * from
    (select * from simpline
    returning linegraph(*)
        where color=newcolor
        AND shape=fillcircle) simpline,
    (select * from simppie
    returning pointgraph(*) 
        where color=blue
        AND shape=opensquare) simppt,
    (select * from complpa
    returning areagraph(*) 
        where color=red) simparea
    returning image, imagemap 
    where WIDTH=500
    AND HEIGHT=500
    AND TITLE='Composite Line/Point/Areagraph Test'
    AND SIGNATURE='(C)2002, GOWI Systems'
    AND X_AXIS='Some Domain'
    AND Y_AXIS='Some Range'
    AND FORMAT='PNG'
    AND MAPNAME='complpa'
    AND MAPURL='http://www.gowi.com/cgi-bin/sample.pl?x=:X&y=:Y&z=:Z&plotno=:PLOTNUM'
    AND MAPTYPE='HTML'
</pre></td></tr>
<tr><td valign=top align=center><img src=imgs/compblpa.png alt='compblpa' usemap=#compblpa></td>
<td valign=top align=left><pre>
select * from
    (select * from simpline
    returning linegraph(*)
        where color=newcolor
        AND shape=fillcircle) simpline,
    (select * from simppie
    returning pointgraph(*) 
        where color=blue
        AND shape=opensquare) simppt,
    (select * from complpa
    returning areagraph(*) 
        where color=green) simparea,
    (select * from complpa
    returning barchart(*)
        where color=red) simpbar
    returning image, imagemap 
    where WIDTH=500
    AND HEIGHT=500
    AND TITLE='Composite Bar/Line/Point/Areagraph Test'
    AND SIGNATURE='(C)2002, GOWI Systems'
    AND X_AXIS='Some Domain'
    AND Y_AXIS='Some Range'
    AND FORMAT='PNG'
    AND MAPNAME='compblpa'
    AND MAPURL='http://www.gowi.com/cgi-bin/sample.pl?x=:X&y=:Y&z=:Z&plotno=:PLOTNUM'
    AND MAPTYPE='HTML'
</pre></td></tr>
<tr><td valign=top align=center><img src=imgs/complnbox.png alt='complnbox' usemap=#complnbox></td>
<td valign=top align=left><pre>
select * from
    (select * from complnbox
    returning linegraph(*) 
    where color=red
    AND shape=fillcircle) simpline,
    (select * from simpbox
    returning boxchart(*) 
        where color=newcolor) simpbox
    returning image, imagemap 
    where WIDTH=500
    AND HEIGHT=500
    AND TITLE='Composite Box
    AND Line Test'
    AND SIGNATURE='(C)2002, GOWI Systems'
    AND X_AXIS='Some Domain'
    AND Y_AXIS='Some Range'
    AND FORMAT='PNG'
    AND MAPNAME='complnbox'
    AND MAPURL='http://www.gowi.com/cgi-bin/sample.pl?x=:X&y=:Y&z=:Z&plotno=:PLOTNUM'
    AND MAPTYPE='HTML'
</pre></td></tr>
<tr><td valign=top align=center><img src=imgs/compllbb.png alt='compllbb' usemap=#compllbb></td>
<td valign=top align=left><pre>
select * from
    (select * from complnbox
    returning linegraph(*) 
    where color=newcolor
    AND shape=fillcircle
        and showvalues=1) simpline,
    (select * from simpbox
    returning boxchart(*) 
    where color=newcolor) simpbox,
    (select * from compllbb
    returning linegraph(*) 
    where color=red
    AND shape=fillcircle
        and showvalues=0) simpline2,
    (select * from simpbox2
    returning boxchart(*) 
    where color=red) simpbox2
    returning image, imagemap 
    where WIDTH=500
    AND HEIGHT=500
    AND TITLE='Composite Multiple Box
    AND Line Test'
    AND SIGNATURE='(C)2002, GOWI Systems'
    AND X_AXIS='Some Domain'
    AND Y_AXIS='Some Range'
    AND FORMAT='PNG'
    AND MAPNAME='compllbb'
    AND MAPURL='http://www.gowi.com/cgi-bin/sample.pl?x=:X&y=:Y&z=:Z&plotno=:PLOTNUM'
    AND MAPTYPE='HTML'
</pre></td></tr>
<tr><td valign=top align=center><img src=imgs/comphisto.png alt='comphisto' usemap=#comphisto></td>
<td valign=top align=left><pre>
select * from
    (select * from simppie returning histogram(*) 
        where color=red) histo1,
    (select * from complpa returning histogram(*) 
        where color=blue) histo2
    returning image, imagemap 
    where WIDTH=500
    AND HEIGHT=500
    AND TITLE='Composite Histogram Test'
    AND SIGNATURE='(C)2002, GOWI Systems'
    AND X_AXIS='Some Domain'
    AND Y_AXIS='Some Range'
    AND FORMAT='PNG'
    AND THREE_D=1
    AND SHOWVALUES = 1
    AND MAPNAME='comphisto'
    AND MAPURL='http://www.gowi.com/cgi-bin/sample.pl?x=:X&y=:Y&z=:Z&plotno=:PLOTNUM'
    AND MAPTYPE='HTML'
</pre></td></tr>
<tr><td valign=top align=center><img src=imgs/compbars.png alt='compbars' usemap=#compbars></td>
<td valign=top align=left><pre>
select * from
    (select * from simppie
    returning barchart(*) 
        where color=red) bars1,
    (select * from complpa
    returning barchart(*) 
        where color=blue) bars2
    returning image, imagemap 
    where WIDTH=500
    AND HEIGHT=500
    AND TITLE='Composite Barchart Test'
    AND SIGNATURE='(C)2002, GOWI Systems'
    AND X_AXIS='Some Domain'
    AND Y_AXIS='Some Range'
    AND FORMAT='PNG'
    AND SHOWVALUES = 1
    AND SHOWGRID=1
    AND MAPNAME='compbars'
    AND ICONS=('t/pumpkin.png', 't/turkey.png' )
    AND MAPURL='http://www.gowi.com/cgi-bin/sample.pl?x=:X&y=:Y&z=:Z&plotno=:PLOTNUM'
    AND MAPTYPE='HTML'
</pre></td></tr>
<tr><td valign=top align=center><img src=imgs/denseline.png alt='denseline'></td>
<td valign=top align=left><pre>
select * from
    (select * from densesin
    returning linegraph(*) 
        where color=red) densesin,
    (select * from densecos
    returning linegraph(*)
        where color=blue) densecos
    returning image 
    where WIDTH=500
    AND HEIGHT=500
    AND TITLE='Composite Dense Linegraph Test'
    AND SIGNATURE='(C)2002, GOWI Systems'
    AND X_AXIS='Angle (Radians)'
    AND Y_AXIS='Sin/Cos'
    AND FORMAT='PNG'
</pre></td></tr>
<tr><td valign=top align=center><img src=imgs/densearea.png alt='densearea'></td>
<td valign=top align=left><pre>
select * from
    (select * from densesin
    returning areagraph(*) 
        where color=red) densesin,
    (select * from densecos
    returning areagraph(*) 
        where color=blue) densecos
    returning image
    where WIDTH=500
    AND HEIGHT=500
    AND TITLE='Composite Dense Areagraph Test'
    AND SIGNATURE='(C)2002, GOWI Systems'
    AND X_AXIS='Angle (Radians)'
    AND Y_AXIS='Sin/Cos'
    AND FORMAT='PNG'
</pre></td></tr>
<tr><td valign=top align=center><img src=imgs/simpgantt.png alt='simpgantt' usemap=#simpgantt></td>
<td valign=top align=left><pre>
select * from simpgantt
    returning gantt(*), imagemap 
    where WIDTH=500
    AND HEIGHT=500
    AND TITLE='Simple Gantt Chart Test'
    AND SIGNATURE='(C)2002, GOWI Systems'
    AND X_AXIS='Tasks'
    AND Y_AXIS='Schedule'
    AND COLOR=red
    AND LOGO='t/gowilogo.png'
    AND MAPNAME='simpgantt'
    AND MAPURL='http://www.gowi.com/cgi-bin/sample.pl?x=:X&y=:Y&z=:Z&plotno=:PLOTNUM'
    AND MAPTYPE='HTML'
    AND X_ORIENT='VERTICAL'
    AND FORMAT='PNG'
</pre></td></tr>
<tr><td valign=top align=center><img src=imgs/stackbar.png alt='stackbar' usemap=#stackbar></td>
<td valign=top align=left><pre>
select * from stackbar
    returning barchart(*), imagemap 
    where WIDTH=500
    AND HEIGHT=500
    AND X_AXIS='Some Domain'
    AND Y_AXIS='Some Range'
    AND TITLE='Stacked Barchart Test'
    AND SIGNATURE='(C)2002, GOWI Systems'
    AND FORMAT='PNG'
    AND SHOWVALUES=1
    AND STACK=1
    AND MAPNAME='stackbar'
    AND MAPURL='http://www.gowi.com/cgi-bin/sample.pl?x=:X\&y=:Y\&z=:Z\&plotno=:PLOTNUM'
    AND MAPTYPE='HTML'
    AND COLORS IN ('yellow', 'blue')
</pre></td></tr>
<tr><td valign=top align=center><img src=imgs/stackicon.png alt='stackicon' usemap=#stackicon></td>
<td valign=top align=left><pre>
select * from stackbar
    returning barchart(*), imagemap 
    where WIDTH=500
    AND HEIGHT=500 
    AND X_AXIS='Some Domain' 
    and Y_AXIS='Some Range'
    AND TITLE='Stacked Iconic Barchart Test' 
    AND SIGNATURE='(C)2002, GOWI Systems' 
    AND FORMAT='PNG' 
    AND SHOWVALUES=1 
    AND STACK=1 
    AND ICONS IN ('t/pumpkin.png', 't/turkey.png') 
    AND MAPNAME='stackbar' 
    AND MAPURL='http://www.gowi.com/cgi-bin/sample.pl?x=:X\&y=:Y\&z=:Z\&plotno=:PLOTNUM'
    AND MAPTYPE='HTML'</pre></td></tr>
<tr><td valign=top align=center><img src=imgs/stackarea.png alt='stackarea' usemap=#stackarea></td>
<td valign=top align=left><pre>
select * from stackbar
    returning areagraph(*), imagemap 
    where WIDTH=500
    AND HEIGHT=500
    AND X_AXIS='Some Domain'
    AND Y_AXIS='Some Range'
    AND TITLE='Stacked Areagraph Test'
    AND SIGNATURE='(C)2002, GOWI Systems'
    AND FORMAT='PNG'
    AND SHOWVALUES=1
    AND STACK=1
    AND MAPNAME='stackarea'
    AND MAPURL='http://www.gowi.com/cgi-bin/sample.pl?x=:X\&y=:Y\&z=:Z\&plotno=:PLOTNUM'
    AND MAPTYPE='HTML'
    AND COLORS IN ('red', 'green')
</pre></td></tr>
<tr><td valign=top align=center><img src=imgs/stackhisto.png alt='stackhisto' usemap=#stackhisto></td>
<td valign=top align=left><pre>
select * from stackbar
    returning histogram(*), imagemap 
    where WIDTH=500
    AND HEIGHT=500 
    AND X_AXIS='Some Domain'
    AND Y_AXIS='Some Range'
    AND TITLE='Stacked Histogram Test'
    AND SIGNATURE='(C)2002, GOWI Systems'
    AND FORMAT='PNG'
    AND SHOWVALUES=1
    AND STACK=1
    AND MAPNAME='stackhisto'
    AND MAPURL='http://www.gowi.com/cgi-bin/sample.pl?x=:X\&y=:Y\&z=:Z\&plotno=:PLOTNUM'
    AND MAPTYPE='HTML'
    AND COLORS IN ('red', 'green')
</pre></td></tr>
<tr><td valign=top align=center><img src=imgs/stackcandle.png alt='stackcandle' usemap=#stackcandle></td>
<td valign=top align=left><pre>
select * from stackcandle
    returning candlestick(*), imagemap 
    where WIDTH=300
    AND HEIGHT=500 
    AND X_AXIS='Some Domain' 
    AND Y_AXIS = 'Price' 
    AND TITLE='Stacked Candlestick Test' 
    AND SIGNATURE='(C)2002, GOWI Systems' 
    AND FORMAT='PNG' 
    AND COLORS IN ('newcolor', 'red') 
    AND SHOWGRID=1 
    AND STACK=1 
    AND MAPNAME='stackcandle' 
    AND LINEWIDTH=5 
    AND MAPURL='http://www.gowi.com/cgi-bin/sample.pl?x=:X&y=:Y&z=:Z&plotno=:PLOTNUM'
    AND MAPTYPE='HTML'
</pre></td></tr>
<tr><td valign=top align=center><img src=imgs/multilinemm.png alt='multilinemm' usemap=#multilinemm></td>
<td valign=top align=left><pre>
select * from stackbar
    returning linegraph(*), imagemap
    where WIDTH=500
    AND HEIGHT=500
    AND X_AXIS='Some Domain'
    AND Y_AXIS='Some Range'
    AND TITLE='Multiline NULL Shape, Map Modifier Test'
    AND SIGNATURE='(C)2002, GOWI Systems'
    AND FORMAT='PNG'
    AND SHOWVALUES=1
    AND MAPNAME='multilinemm'
    AND MAPURL='http://www.gowi.com/cgi-bin/sample.pl?x=:X\&y=:Y\&z=:Z\&plotno=:PLOTNUM'
    AND MAPTYPE='HTML'
    AND COLORS IN ('red', 'green')
    AND SHAPES IN (NULL, 'filldiamond')
</pre></td></tr>
<tr><td valign=top align=center><img src=imgs/quadtree.png alt='quadtree' usemap=#quadtree></td>
<td valign=top align=left><pre>
SELECT * FROM myquad
returning QUADTREE(*), IMAGEMAP
WHERE COLORS IN ('red', 'black', 'green')
    AND WIDTH=500
    AND HEIGHT=500
    AND TITLE='My Quadtree'
    AND MAPTYPE='HTML'
    AND MAPNAME='quadtree'
    AND MAPURL=
'http://www.presicient.com/cgi-bin/quadtree.pl?group=:X\&item=:Y\&value=:Z\&intensity=:PLOTNUM'
</pre></td></tr>
<tr><td valign=top align=center><img src=imgs/stack3Dbar.png alt='stack3Dbar' usemap=#stack3Dbar></td>
<td valign=top align=left><pre>
select * from stackbar
    returning barchart(*), imagemap 
    where WIDTH=500 
    AND HEIGHT=500 
    AND X_AXIS='Some Domain' 
    AND Y_AXIS='Some Range' 
    AND TITLE='Stacked 3-D Barchart Test' 
    AND SIGNATURE='(C)2002, GOWI Systems' 
    AND FORMAT='PNG' 
    AND SHOWVALUES=1 
    AND STACK=1 
    AND THREE_D=1
    AND MAPNAME='stack3Dbar'
    AND MAPURL='http://www.gowi.com/cgi-bin/sample.pl?x=:X\&y=:Y\&z=:Z\&plotno=:PLOTNUM'
    AND MAPTYPE='HTML' 
    AND COLORS IN ('yellow', 'blue')
</pre></td></tr>
<tr><td valign=top align=center><img src=imgs/stack3Dhisto.png alt='stack3Dhisto' usemap=#stack3Dhisto></td>
<td valign=top align=left><pre>
select * from stackbar
    returning histogram(*), imagemap 
    where WIDTH=500 
    AND HEIGHT=500 
    AND X_AXIS='Some Domain' 
    AND Y_AXIS='Some Range' 
    AND TITLE='Stacked 3-D Histogram Test' 
    AND SIGNATURE='(C)2002, GOWI Systems' 
    AND FORMAT='PNG' 
    AND SHOWVALUES=1 
    AND STACK=1 
    AND THREE_D=1
    AND MAPNAME='stack3Dhisto'
    AND MAPURL='http://www.gowi.com/cgi-bin/sample.pl?x=:X\&y=:Y\&z=:Z\&plotno=:PLOTNUM'
    AND MAPTYPE='HTML' 
    AND COLORS IN ('red', 'green')
</pre></td></tr>
<tr><td valign=top align=center><img src=imgs/tmstamp.png alt='tmstamp' usemap=#tmstamp></td>
<td valign=top align=left><pre>
select * from tmstamp
    returning linegraph(*), imagemap 
    where WIDTH=500 
    AND HEIGHT=500 
    AND X_AXIS='Some Domain' 
    AND Y_AXIS='Some Range' 
    AND TITLE='Timestamp Domain Test' 
    AND SIGNATURE='(C)2002, GOWI Systems' 
    AND FORMAT='PNG' 
    AND SHOWVALUES=1 
    AND MAPNAME='tmstamp' 
    AND MAPURL='http://www.gowi.com/cgi-bin/sample.pl?x=:X\&y=:Y\&z=:Z\&plotno=:PLOTNUM'
    AND MAPTYPE='HTML' 
    AND COLORS IN ('yellow', 'blue')
</pre></td></tr>
<tr><td valign=top align=center><img src=imgs/floatarea.png alt='floatarea' usemap=#floatarea></td>
<td valign=top align=left><pre>
select * from floatbar
    returning areagraph(*), imagemap 
    where WIDTH=500 
    AND HEIGHT=500 
    AND X_AXIS='Some Domain' 
    AND Y_AXIS='Some Range' 
    AND TITLE='Floating Stacked Areagraph Test' 
    AND SIGNATURE='(C)2002, GOWI Systems' 
    AND FORMAT='PNG' 
    AND SHOWVALUES=1 
    AND STACK=1 
    AND ANCHORED=0
    AND MAPNAME='floatarea' 
    AND MAPURL='http://www.gowi.com/cgi-bin/sample.pl?x=:X\&y=:Y\&z=:Z\&plotno=:PLOTNUM'
    AND MAPTYPE='HTML' 
    AND COLORS IN ('green', 'yellow', 'red')
</pre></td></tr>
<tr><td valign=top align=center><img src=imgs/floathisto.png alt='floathisto' usemap=#floathisto></td>
<td valign=top align=left><pre>
select * from floatbar
    returning histogram(*), imagemap 
    where WIDTH=500 
    AND HEIGHT=500 
    AND X_AXIS='Some Domain' 
    and Y_AXIS='Some Range' 
    AND TITLE='Floating Stacked Histogram Test' 
    AND SIGNATURE='(C)2002, GOWI Systems' 
    AND FORMAT='PNG' 
    AND SHOWVALUES=1 
    AND STACK=1 
    AND ANCHORED=0
    AND MAPNAME='floathisto' 
    AND MAPURL='http://www.gowi.com/cgi-bin/sample.pl?x=:X\&y=:Y\&z=:Z\&plotno=:PLOTNUM'
    AND MAPTYPE='HTML' 
    AND COLORS IN ('red', 'green', 'orange')
</pre></td></tr>
<tr><td valign=top align=center><img src=imgs/floatbar.png alt='floatbar' usemap=#floatbar></td>
<td valign=top align=left><pre>
select * from floatbar
    returning barchart(*), imagemap 
    where WIDTH=500 
    AND HEIGHT=500 
    AND X_AXIS='Some Domain' 
    AND Y_AXIS='Some Range' 
    AND TITLE='Floating Stacked Barchart Test' 
    AND SIGNATURE='(C)2002, GOWI Systems' 
    AND FORMAT='PNG' 
    AND SHOWVALUES=1 
    AND STACK=1 
    AND ANCHORED=0
    AND MAPNAME='floatbar' 
    AND MAPURL='http://www.gowi.com/cgi-bin/sample.pl?x=:X\&y=:Y\&z=:Z\&plotno=:PLOTNUM'
    AND MAPTYPE='HTML' 
    AND COLORS IN ('yellow', 'blue', 'red')
</pre></td></tr>
<tr><td valign=top align=center><img src=imgs/multwidth.png alt='multwidth' usemap=#multwidth></td>
<td valign=top align=left><pre>
select * from
    (select * from floatbar 
    returning areagraph(*) 
    where anchored=0
        and stack=1
    AND colors in ('blue', 'yellow', 'red')),
    (select * from regline
    returning linegraph(*)
        where color='newcolor'
    AND showvalues=1 ) regline,
    (select * from fatline
    returning linegraph(*)
        where color='lgray'
    AND linewidth=10) fatline,
    (select * from midline
    returning linegraph(*)
        where color='green'
    AND linewidth=4) midline\
    returning image, imagemap 
    where WIDTH=500
    AND HEIGHT=500
    AND TITLE='Variable Width Linegraph Test'
    AND SIGNATURE='(C)2002, GOWI Systems'
    AND X_AXIS='Some Domain'
    AND Y_AXIS='Some Range'
    AND FORMAT='PNG'
    AND MAPNAME='multwidth'
    AND MAPURL='http://www.gowi.com/cgi-bin/sample.pl?x=:X&y=:Y&z=:Z&plotno=:PLOTNUM'
    AND MAPTYPE='HTML'
</pre></td></tr></table>
HTML-TEXT

foreach (1..200) {
    push @xbox, int(rand(51)+10);
    $xbhash{$xbox[$#xbox]} += 1, next
        if $xbhash{$xbox[$#xbox]};
    $xbhash{$xbox[$#xbox]} = 1;
}

push(@xfreq, $_),
push (@yfreq, $xbhash{$_} ? $xbhash{$_} : 0)
    foreach (10..60);

my @xfreq2 = ();
my @yfreq2 = ();
my @xbox2 = ();
my %xbhash2 = ();
foreach (1..200) {
	push @xbox2, int(rand(61)+10);
	$xbhash2{$xbox2[$#xbox2]} += 1, next
		if $xbhash2{$xbox2[$#xbox2]};
	$xbhash2{$xbox2[$#xbox2]} = 1;
}

my ($image, $imagemap);
push(@xfreq2, $_),
push (@yfreq2, $xbhash2{$_} ? $xbhash2{$_} : 0)
	foreach (10..70);
#
#	now we can start testing...
#
my $ppctxt;

DECLARE CONTEXT $ppctxt;

CONNECT TO 'CSV:';
#
#	test colormap adjustments
#

UPDATE chart.colormap set redvalue=255, greenvalue=0, bluevalue=0
	where name='red';
UPDATE chart.colormap set redvalue=0, greenvalue=0, bluevalue=255
	where name='blue';
INSERT into chart.colormap values('newcolor', 124, 37, 97);

#
#	simple line chart
#
simpline:
DROP table simpline;

CREATE table simpline (x integer, y integer);

PREPARE simpline_load AS INSERT into simpline values(:@x, :@y1);

EXECUTE simpline_load;

#
#	simple scatter chart
#
simpscat:
EXEC SQL 
	{ chart_type_map => [ 
		{ NAME => 'x', TYPE => SQL_INTEGER },
		{ NAME => 'y', TYPE => SQL_INTEGER } ] 
	}
SELECT * INTO :$image, :$imagemap from simpline
	returning pointgraph(x,y), imagemap 
	where WIDTH=500 
	AND HEIGHT=500 
	AND X_AXIS='Some Domain' 
	and Y_AXIS='Some Range' 
	AND TITLE='Scattergraph Test' 
	AND SIGNATURE='(C)2002, GOWI Systems' 
	AND LOGO='t/imgs/gowilogo.png' 
	AND FORMAT='PNG' 
	AND SHOWGRID=0 
	AND MAPNAME='simpscat' 
	AND MAPURL='http://www.gowi.com/cgi-bin/sample.pl?x=:X&y=:Y&z=:Z&plotno=:PLOTNUM'
	AND MAPTYPE='HTML' 
	AND SHOWVALUES=1;

dump_img($image, $imagemap, 'png', 'simpscat');
$testnum++;
print "ok $testnum simpscat OK\n";

EXEC SQL 
	{ chart_type_map => [ 
		{ NAME => 'x', TYPE => SQL_INTEGER },
		{ NAME => 'y', TYPE => SQL_INTEGER } ] 
	}
SELECT * INTO :$image, :$imagemap from simpline
	returning linegraph(*), imagemap 
	where WIDTH=500 
	AND HEIGHT=500 
	AND X_AXIS='Some Domain' 
	AND Y_AXIS='Some Range' 
	AND TITLE='Linegraph Test' 
	AND SIGNATURE='(C)2002, GOWI Systems' 
	AND LOGO='t/imgs/gowilogo.png' 
	AND FORMAT='PNG' 
	AND SHOWGRID=1 
	AND LINEWIDTH=4 
	AND MAPNAME='simpline' 
	AND MAPURL='http://www.gowi.com/cgi-bin/sample.pl?x=:X&y=:Y&z=:Z&plotno=:PLOTNUM'
	AND MAPTYPE='HTML' 
	AND COLOR='newcolor'
	AND SHAPE='fillcircle'
	AND SHOWVALUES=1;

dump_img($image, $imagemap, 'png', 'simpline');
$testnum++;
print "ok $testnum simpline OK\n";
#
#	simple area chart
#
simparea:
EXEC SQL 
	{ chart_type_map => [ 
		{ NAME => 'x', TYPE => SQL_INTEGER },
		{ NAME => 'y', TYPE => SQL_INTEGER } ] 
	}
SELECT * from simpline
	returning areagraph(*), imagemap 
	where WIDTH=500 
	AND HEIGHT=500 
	AND X_AXIS='Some Domain' 
	AND Y_AXIS='Some Range' 
	AND TITLE='Areagraph Test' 
	AND SIGNATURE='(C)2002, GOWI Systems' 
	AND LOGO='t/imgs/gowilogo.png' 
	AND FORMAT='PNG' 
	AND SHOWGRID=1 
	AND MAPNAME='simparea' 
	AND COLOR='newcolor' 
	AND MAPURL='http://www.gowi.com/cgi-bin/sample.pl?x=:X&y=:Y&z=:Z&plotno=:PLOTNUM'
	AND MAPTYPE='HTML' AND SHOWVALUES=0;

dump_img(@_, 'png', 'simparea');
$testnum++;
print "ok $testnum simparea OK\n";
#
#	simple linechart w/ sym domain and icons
#
symline:
DROP table symline;
CREATE table symline (xdate varchar(20), y integer);

INSERT into symline values(:@xdate, :@y1);

EXEC SQL
	{ 
		chart_type_map => [ 
			{ NAME => 'xdate', TYPE => SQL_VARCHAR, PRECISION => 20 }, 
			{ NAME => 'y', TYPE => SQL_INTEGER } ] 
	}
SELECT * from symline
	returning linegraph(*), imagemap 
	where WIDTH=500 AND HEIGHT=500 
	AND X_AXIS='Some Domain' 
	and Y_AXIS='Some Range' 
	AND TITLE='Symbolic Domain Linegraph Test' 
	AND SIGNATURE='(C)2002, GOWI Systems' 
	AND LOGO='t/imgs/gowilogo.png' 
	AND FORMAT='PNG' 
	AND SHOWGRID=1 
	AND MAPNAME='symline' 
	AND MAPURL='http://www.gowi.com/cgi-bin/sample.pl?x=:X&y=:Y&z=:Z&plotno=:PLOTNUM'
	AND MAPTYPE='HTML' AND COLOR='newcolor' AND SHAPE='fillcircle';

dump_img(@_, 'png', 'symline');
$testnum++;
print "ok $testnum symline OK\n";
#
#	simple bar chart
#
simpbar:
EXEC SQL
	{ 
		chart_type_map => [ 
			{ NAME => 'xdate', TYPE => SQL_VARCHAR, PRECISION => 20 }, 
			{ NAME => 'y', TYPE => SQL_INTEGER } ] 
	}
SELECT * from symline
	returning barchart(*), imagemap 
	where WIDTH=500 AND HEIGHT=500 
	AND X_AXIS='Some Domain' and Y_AXIS='Some Range' AND
	TITLE='Barchart Test' AND SIGNATURE='(C)2002, GOWI Systems' AND
	FORMAT='PNG' AND SHOWVALUES=1 AND
	MAPNAME='simpbar' AND
	MAPURL='http://www.gowi.com/cgi-bin/sample.pl?x=:X&y=:Y&z=:Z&plotno=:PLOTNUM'
	AND MAPTYPE='HTML' AND COLOR='newcolor';

dump_img(@_, 'png', 'simpbar');
$testnum++;
print "ok $testnum simpbar OK\n";
#
#	simple bar chart w/ icons
#
iconbars:
EXEC SQL
	{ 
		chart_type_map => [ 
			{ NAME => 'xdate', TYPE => SQL_VARCHAR, PRECISION => 20 }, 
			{ NAME => 'y', TYPE => SQL_INTEGER } ] 
	}
SELECT * from symline
	returning barchart(*), imagemap 
	where WIDTH=500 AND HEIGHT=500 
	AND X_AXIS='Some Domain' and Y_AXIS='Some Range' AND
	TITLE='Iconic Barchart Test' AND SIGNATURE='(C)2002, GOWI Systems' AND
	FORMAT='PNG' AND SHOWVALUES=1 AND ICON='t/imgs/pumpkin.png' AND
	MAPNAME='iconbars' AND SHOWGRID=1 AND GRIDCOLOR='blue' AND
	TEXTCOLOR='dbrown' AND
	MAPSCRIPT='ONCLICK="alert(''Got X=:X, Y=:Y'')"' AND
	MAPURL='http://www.gowi.com/cgi-bin/sample.pl?x=:X&y=:Y&z=:Z&plotno=:PLOTNUM'
	AND MAPTYPE='HTML';

dump_img(@_, 'png', 'iconbars');
$testnum++;
print "ok $testnum iconbars OK\n";
#
#	simple bar chart w/ icons
#
iconhisto:
EXEC SQL
	{ 
		chart_type_map => [ 
			{ NAME => 'xdate', TYPE => SQL_VARCHAR, PRECISION => 20 }, 
			{ NAME => 'y', TYPE => SQL_INTEGER } ] 
	}
SELECT * from symline
	returning histogram(*), imagemap
	where WIDTH=500 AND HEIGHT=500 AND X_AXIS='Some Domain' and 
	Y_AXIS='Some Range' AND
	TITLE='Iconic Histogram Test' AND SIGNATURE='(C)2002, GOWI Systems' AND
	FORMAT='PNG' AND ICON='t/imgs/pumpkin.png' AND
	MAPNAME='iconhisto' AND SHOWGRID=1 AND GRIDCOLOR='red' AND
	TEXTCOLOR='newcolor' AND
	MAPSCRIPT='ONCLICK="alert(''Got X=:X, Y=:Y'')"' AND
	MAPURL='http://www.gowi.com/cgi-bin/sample.pl?x=:X&y=:Y&z=:Z&plotno=:PLOTNUM'
	AND MAPTYPE='HTML';

dump_img(@_, 'png', 'iconhisto');
$testnum++;
print "ok $testnum iconhisto OK\n";
#
#	simple boxchart
#
simpbox:
DROP table simpbox;

CREATE table simpbox (xbox integer, xbox2 integer);
INSERT into simpbox values(:@xbox, :@xbox2);

EXEC SQL
	{ 
		chart_type_map => [ 
			{ NAME => 'xbox', TYPE => SQL_INTEGER }, 
			{ NAME => 'xbox2', TYPE => SQL_INTEGER } ] 
	}
SELECT * from simpbox
	returning boxchart(*), imagemap
	where WIDTH=500 AND HEIGHT=500 
	AND X_AXIS='Some Domain' AND
	TITLE='Boxchart Test' 
	AND SIGNATURE='(C)2002, GOWI Systems' AND
	FORMAT='PNG' AND 
	COLORS IN ('newcolor', 'red') AND SHOWVALUES=1 AND
	MAPNAME='simpbox' AND 
	MAPURL='http://www.gowi.com/cgi-bin/sample.pl?x=:X&y=:Y&z=:Z&plotno=:PLOTNUM'
	AND MAPTYPE='HTML';

dump_img(@_, 'png', 'simpbox');
$testnum++;
print "ok $testnum simpbox OK\n";
#
#	simple candlestick
#
simpcandle:
DROP table simpcandle;
CREATE table simpcandle (x integer, ylo integer, yhi integer);
INSERT into simpcandle values(:@x, :@y1, :@y2);

EXEC SQL
	{ 
		chart_type_map => [ 
			{ NAME => 'x', TYPE => SQL_INTEGER }, 
			{ NAME => 'ylo', TYPE => SQL_INTEGER },
			{ NAME => 'yhi', TYPE => SQL_INTEGER } 
			] 
	}
SELECT * from simpcandle
	returning candlestick(*), imagemap 
	where WIDTH=500 AND HEIGHT=500 AND X_AXIS='Some Domain' AND
	Y_AXIS = 'Price' AND
	TITLE='Candlestick Test' AND SIGNATURE='(C)2002, GOWI Systems' AND
	FORMAT='PNG' AND COLORS IN ('newcolor') AND SHAPE='fillsquare' AND
	SHOWVALUES=1 AND SHOWGRID=1 AND
	MAPNAME='simpcandle' AND 
	MAPURL='http://www.gowi.com/cgi-bin/sample.pl?x=:X&y=:Y&z=:Z&plotno=:PLOTNUM'
	AND MAPTYPE='HTML';

dump_img(@_, 'png', 'simpcandle');
$testnum++;
print "ok $testnum simpcandle OK\n";
#
#	simple pie chart
#
simppie:
DROP table simppie;
CREATE table simppie (x integer, y2 integer);
INSERT into simppie values(:@x, :@y2);

EXEC SQL
	{ 
		chart_type_map => [ 
			{ NAME => 'x', TYPE => SQL_INTEGER }, 
			{ NAME => 'y2', TYPE => SQL_INTEGER } 
			] 
	}
SELECT * from simppie
	returning piechart(*), imagemap 
	where WIDTH=500 AND HEIGHT=500 AND X_AXIS='Some Domain' AND
	TITLE='Piechart Test' AND SIGNATURE='(C)2002, GOWI Systems' AND
	FORMAT='PNG' AND COLORS IN ('red', 'blue', 'newcolor', 'green', 'yellow') AND
	MAPNAME='simppie' AND 
	MAPURL='http://www.gowi.com/cgi-bin/sample.pl?x=:X&y=:Y&z=:Z&plotno=:PLOTNUM'
	AND MAPTYPE='HTML';

dump_img(@_, 'png', 'simppie');
$testnum++;
print "ok $testnum simppie OK\n";
#
#	3-D pie chart
#
pie3d:
EXEC SQL
	{ 
		chart_type_map => [ 
			{ NAME => 'x', TYPE => SQL_INTEGER }, 
			{ NAME => 'y2', TYPE => SQL_INTEGER } 
			]
	}
SELECT * from simppie
	returning piechart(*), imagemap 
	where WIDTH=500 AND HEIGHT=500 AND X_AXIS='Some Domain' AND
	TITLE='3-D Piechart Test' AND SIGNATURE='(C)2002, GOWI Systems' AND
	FORMAT='PNG' AND COLORS IN ('red', 'blue', 'newcolor', 'green', 'yellow') AND
	THREE_D=1 AND
	MAPNAME='pie3d' AND 
	MAPURL='http://www.gowi.com/cgi-bin/sample.pl?x=:X&y=:Y&z=:Z&plotno=:PLOTNUM'
	AND MAPTYPE='HTML';

dump_img(@_, 'png', 'pie3d');
$testnum++;
print "ok $testnum pie3d OK\n";
#
#	simple histogram
#
simphisto:
EXEC SQL
	{ 
		chart_type_map => [ 
			{ NAME => 'x', TYPE => SQL_INTEGER }, 
			{ NAME => 'y2', TYPE => SQL_INTEGER } 
			] 
	}
SELECT * from simppie
	returning histogram(*), imagemap 
	where WIDTH=500 AND HEIGHT=500 AND 
	TITLE='Histogram Test' AND SIGNATURE='(C)2002, GOWI Systems' AND
	X_AXIS='Some Domain' AND Y_AXIS='Some Range' AND
	FORMAT='PNG' AND COLOR IN ('red', 'green', 'orange', 'blue', 'newcolor') AND
	SHOWGRID=1 AND SHOWVALUES=1 AND
	MAPNAME='simphisto' AND 
	MAPURL='http://www.gowi.com/cgi-bin/sample.pl?x=:X&y=:Y&z=:Z&plotno=:PLOTNUM'
	AND MAPTYPE='HTML';

dump_img(@_, 'png', 'simphisto');
$testnum++;
print "ok $testnum simphisto OK\n";
#
#	linechart w/ temporal domain
#
templine:
DROP table templine;
CREATE table templine (xdate varchar(20), y integer);
INSERT into templine values(:@xdate, :@y1);

EXEC SQL
	{ 
		chart_type_map => [ 
			{ NAME => 'xdate', TYPE => SQL_DATE }, 
			{ NAME => 'y', TYPE => SQL_INTEGER } 
			] 
	}
SELECT * from templine
	returning linegraph(xdate, y), imagemap 
	where WIDTH=500 AND HEIGHT=500 AND 
	TITLE='Temporal Domain Linegraph Test' AND 
	SIGNATURE='(C)2002, GOWI Systems' AND
	X_AXIS='Some Domain' AND Y_AXIS='Some Range' AND
	X_ORIENT='VERTICAL' AND LOGO='t/imgs/gowilogo.png' AND
	FORMAT='PNG' AND COLORS=newcolor AND
	SHOWGRID=1 AND SHOWVALUES=1 AND
	MAPNAME='templine' AND 
	MAPURL='http://www.gowi.com/cgi-bin/sample.pl?x=:X&y=:Y&z=:Z&plotno=:PLOTNUM'
	AND MAPTYPE='HTML';

dump_img(@_, 'png', 'templine');
$testnum++;
print "ok $testnum templine OK\n";
#
#	linechart w/ temporal domain and range
#
templine2:
DROP table templine2;
CREATE table templine2 (xdate varchar(20), y varchar(20));
INSERT into templine2 values(:@xdate, :@ytime);

EXEC SQL
	{ 
		chart_type_map => [ 
			{ NAME => 'xdate', TYPE => SQL_DATE }, 
			{ NAME => 'y', TYPE => SQL_INTERVAL } 
			] 
	}
SELECT * from templine2
	returning linegraph(*), imagemap 
	where WIDTH=500 AND HEIGHT=500 AND 
	TITLE='Temporal Range Linegraph Test' AND 
	SIGNATURE='(C)2002, GOWI Systems' AND
	X_AXIS='Some Domain' AND Y_AXIS='Some Range' AND
	X_ORIENT='VERTICAL' AND LOGO='t/imgs/gowilogo.png' AND
	FORMAT='PNG' AND COLORS=newcolor AND
	SHOWGRID=1 AND SHOWVALUES=1 AND SHAPE=fillcircle AND
	MAPNAME='templine2' AND 
	MAPURL='http://www.gowi.com/cgi-bin/sample.pl?x=:X&y=:Y&z=:Z&plotno=:PLOTNUM'
	AND MAPTYPE='HTML';

dump_img(@_, 'png', 'templine2');
$testnum++;
print "ok $testnum templine2 OK\n";
#
#	log linechart w/ temporal domain and range
#
logtempline:
DROP table logtempline;
CREATE table logtempline (xdate varchar(20), y varchar(20));
INSERT into logtempline values(:@xdate, :@ytime);

EXEC SQL
	{ 
		chart_type_map => [ 
			{ NAME => 'xdate', TYPE => SQL_DATE }, 
			{ NAME => 'y', TYPE => SQL_INTERVAL } 
			] 
	}
SELECT * from logtempline
	returning linegraph(*), imagemap 
	where WIDTH=500 AND HEIGHT=500 AND 
	TITLE='Logarithmic Temporal Range Linegraph Test' AND 
	SIGNATURE='(C)2002, GOWI Systems' AND
	X_AXIS='Some Domain' AND Y_AXIS='Some Range' AND
	X_ORIENT='VERTICAL' AND Y-LOG=1 AND
	FORMAT='PNG' AND COLORS=newcolor AND
	SHOWGRID=1 AND SHOWVALUES=1 AND SHAPE=fillcircle AND
	MAPNAME='logtempline' AND 
	MAPURL='http://www.gowi.com/cgi-bin/sample.pl?x=:X&y=:Y&z=:Z&plotno=:PLOTNUM'
	AND MAPTYPE='HTML';

dump_img(@_, 'png', 'logtempline');
$testnum++;
print "ok $testnum logtempline OK\n";
#
#	barchart w/ temp. domain
#
tempbar:
EXEC SQL
	{ 
		chart_type_map => [ 
			{ NAME => 'xdate', TYPE => SQL_DATE }, 
			{ NAME => 'y', TYPE => SQL_INTEGER } 
			] 
	}
SELECT * from templine
	returning barchart(*), imagemap 
	where WIDTH=500 AND HEIGHT=500 AND 
	TITLE='Temporal Barchart Test' AND 
	SIGNATURE='(C)2002, GOWI Systems' AND
	X_AXIS='Some Domain' AND Y_AXIS='Some Range' AND
	FORMAT='PNG' AND COLORS=red AND
	SHOWVALUES=1 AND 
	MAPNAME='tempbar' AND 
	MAPURL='http://www.gowi.com/cgi-bin/sample.pl?x=:X&y=:Y&z=:Z&plotno=:PLOTNUM'
	AND MAPTYPE='HTML';

dump_img(@_, 'png', 'tempbar');
$testnum++;
print "ok $testnum tempbar OK\n";
#
#	histo w/ temp domain
#
temphisto:
EXEC SQL
	{ 
		chart_type_map => [ 
			{ NAME => 'xdate', TYPE => SQL_DATE }, 
			{ NAME => 'y', TYPE => SQL_INTERVAL } 
			] 
	}
SELECT * from templine2
	returning histogram(*), imagemap
	where WIDTH=500 AND HEIGHT=500 AND 
	TITLE='Temporal Histogram Test' AND 
	SIGNATURE='(C)2002, GOWI Systems' AND
	X_AXIS='Some Domain' AND Y_AXIS='Some Range' AND
	FORMAT='PNG' AND COLORS=blue AND
	SHOWVALUES=1 AND 
	MAPNAME='temphisto' AND 
	MAPURL='http://www.gowi.com/cgi-bin/sample.pl?x=:X&y=:Y&z=:Z&plotno=:PLOTNUM'
	AND MAPTYPE='HTML';

dump_img(@_, 'png', 'temphisto');
$testnum++;
print "ok $testnum temphisto OK\n";
#
#	composite (line, scatter)
#
complinept:
EXEC SQL
	{ 
		chart_type_map => [ 
		[ { NAME => 'x', TYPE => SQL_INTEGER }, 
		{ NAME => 'y', TYPE => SQL_INTEGER } ],	
		[ { NAME => 'x', TYPE => SQL_INTEGER }, 
		{ NAME => 'y2', TYPE => SQL_INTEGER } ],	
	] }
SELECT * from
	(select * from simpline
	returning linegraph(*)
		where color=newcolor and shape='fillcircle') simpline,
	(select  * from simppie
	returning pointgraph(*)
		where color=blue and shape='opensquare') simppt
	returning image, imagemap
	where WIDTH=500 AND HEIGHT=500 AND 
	TITLE='Composite Line/Pointgraph Test' AND 
	SIGNATURE='(C)2002, GOWI Systems' AND
	X_AXIS='Some Domain' AND Y_AXIS='Some Range' AND
	FORMAT='PNG' AND 
	MAPNAME='complinept' AND 
	MAPURL='http://www.gowi.com/cgi-bin/sample.pl?x=:X&y=:Y&z=:Z&plotno=:PLOTNUM'
	AND MAPTYPE='HTML';

dump_img(@_, 'png', 'complinept');
$testnum++;
print "ok $testnum complinept OK\n";
#
#	composite (area, line, scatter)
#
complpa:
DROP table complpa;
CREATE table complpa (x integer, y integer);
INSERT into complpa values(:@x, :@y3);

EXEC SQL
	{ 
		chart_type_map => [ 
		[ { NAME => 'x', TYPE => SQL_INTEGER }, 
		{ NAME => 'y', TYPE => SQL_INTEGER } ],
		[ { NAME => 'x', TYPE => SQL_INTEGER }, 
		{ NAME => 'y', TYPE => SQL_INTEGER } ],
		[ { NAME => 'x', TYPE => SQL_INTEGER }, 
		{ NAME => 'y2', TYPE => SQL_INTEGER } ]
		] 
	}
SELECT * from
	(select * from simpline
	returning linegraph(*)
		where color=newcolor and shape=fillcircle) simpline,
	(select * from simppie
	returning pointgraph(*) 
		where color=blue and shape=opensquare) simppt,
	(select * from complpa
	returning areagraph(*) 
		where color=red) simparea
	returning image, imagemap 
	where WIDTH=500 AND HEIGHT=500 AND 
	TITLE='Composite Line/Point/Areagraph Test' AND 
	SIGNATURE='(C)2002, GOWI Systems' AND
	X_AXIS='Some Domain' AND Y_AXIS='Some Range' AND
	FORMAT='PNG' AND 
	MAPNAME='complpa' AND 
	MAPURL='http://www.gowi.com/cgi-bin/sample.pl?x=:X&y=:Y&z=:Z&plotno=:PLOTNUM'
	AND MAPTYPE='HTML';

dump_img(@_, 'png', 'complpa');
$testnum++;
print "ok $testnum complpa OK\n";
#
#	composite (area, bar, line, scatter)
#
compblpa:
EXEC SQL
	{ 
		chart_type_map => [ 
		[ { NAME => 'x', TYPE => SQL_INTEGER }, 
		{ NAME => 'y', TYPE => SQL_INTEGER } ],	
		[ { NAME => 'x', TYPE => SQL_INTEGER }, 
		{ NAME => 'y', TYPE => SQL_INTEGER } ],	
		[ { NAME => 'x', TYPE => SQL_INTEGER }, 
		{ NAME => 'y', TYPE => SQL_INTEGER } ],	
		[ { NAME => 'x', TYPE => SQL_INTEGER }, 
		{ NAME => 'y2', TYPE => SQL_INTEGER } ],
	] }
SELECT * from
	(select * from simpline
	returning linegraph(*)
		where color=newcolor and shape=fillcircle) simpline,
	(select * from simppie
	returning pointgraph(*) 
		where color=blue and shape=opensquare) simppt,
	(select * from complpa
	returning areagraph(*) 
		where color=green) simparea,
	(select * from complpa
	returning barchart(*)
		where color=red) simpbar
	returning image, imagemap 
	where WIDTH=500 AND HEIGHT=500 AND 
	TITLE='Composite Bar/Line/Point/Areagraph Test' AND 
	SIGNATURE='(C)2002, GOWI Systems' AND
	X_AXIS='Some Domain' AND Y_AXIS='Some Range' AND
	FORMAT='PNG' AND 
	MAPNAME='compblpa' AND 
	MAPURL='http://www.gowi.com/cgi-bin/sample.pl?x=:X&y=:Y&z=:Z&plotno=:PLOTNUM'
	AND MAPTYPE='HTML';

dump_img(@_, 'png', 'compblpa');
$testnum++;
print "ok $testnum compblpa OK\n";
#
#	composite (line, box)
#
complnbox:
DROP table simpbox;
DROP table complnbox;
CREATE table simpbox (x integer);
INSERT into simpbox values(:@xbox);
CREATE table complnbox (xfreq integer, yfreq integer);
INSERT into complnbox values(:@xfreq, :@yfreq);

EXEC SQL
	{ 
		chart_type_map => [ 
		[ { NAME => 'xfreq', TYPE => SQL_INTEGER }, 
		{ NAME => 'yfreq', TYPE => SQL_INTEGER } ],	
		[ { NAME => 'x', TYPE => SQL_INTEGER }, 
		{ NAME => 'y2', TYPE => SQL_INTEGER } ],	
	] }
SELECT * from
	(select * from complnbox
	returning linegraph(*) 
	where color=red and shape=fillcircle) simpline,
	(select * from simpbox
	returning boxchart(*) 
		where color=newcolor) simpbox
	returning image, imagemap 
	where WIDTH=500 AND HEIGHT=500 AND 
	TITLE='Composite Box and Line Test' AND 
	SIGNATURE='(C)2002, GOWI Systems' AND
	X_AXIS='Some Domain' AND Y_AXIS='Some Range' AND
	FORMAT='PNG' AND 
	MAPNAME='complnbox' AND 
	MAPURL='http://www.gowi.com/cgi-bin/sample.pl?x=:X&y=:Y&z=:Z&plotno=:PLOTNUM'
	AND MAPTYPE='HTML';

dump_img(@_, 'png', 'complnbox');
$testnum++;
print "ok $testnum complnbox OK\n";
#
#	composite (line, line, box, box)
#
compllbb:
DROP table simpbox2;
DROP table compllbb;
CREATE table simpbox2 (x integer);
INSERT into simpbox2 values(:@xbox);

CREATE table compllbb (xfreq2 integer, yfreq2 integer);
INSERT into compllbb values(:@xfreq, :@yfreq);

EXEC SQL
	{ 
		chart_type_map => [ 
		[ { NAME => 'xfreq', TYPE => SQL_INTEGER }, 
		{ NAME => 'yfreq', TYPE => SQL_INTEGER } ],	
		[ { NAME => 'xbox', TYPE => SQL_INTEGER } ], 
		[ { NAME => 'xfreq2', TYPE => SQL_INTEGER }, 
		{ NAME => 'yfreq2', TYPE => SQL_INTEGER } ],	
		[ { NAME => 'xbox2', TYPE => SQL_INTEGER } ]
	] }
SELECT * from
	(select * from complnbox
	returning linegraph(*) 
	where color=newcolor and shape=fillcircle
		and showvalues=1) simpline,
	(select * from simpbox
	returning boxchart(*) 
	where color=newcolor) simpbox,
	(select * from compllbb
	returning linegraph(*) 
	where color=red and shape=fillcircle
		and showvalues=0) simpline2,
	(select * from simpbox2
	returning boxchart(*) 
	where color=red) simpbox2
	returning image, imagemap 
	where WIDTH=500 AND HEIGHT=500 AND 
	TITLE='Composite Multiple Box and Line Test' AND 
	SIGNATURE='(C)2002, GOWI Systems' AND
	X_AXIS='Some Domain' AND Y_AXIS='Some Range' AND
	FORMAT='PNG' AND 
	MAPNAME='compllbb' AND 
	MAPURL='http://www.gowi.com/cgi-bin/sample.pl?x=:X&y=:Y&z=:Z&plotno=:PLOTNUM'
	AND MAPTYPE='HTML';

dump_img(@_, 'png', 'compllbb');
$testnum++;
print "ok $testnum compllbb OK\n";
#
#	composite (bar, bar, bar)
#
compbars:
EXEC SQL
	{ 
		chart_type_map => [ 
		[ { NAME => 'x', TYPE => SQL_INTEGER }, 
		{ NAME => 'y', TYPE => SQL_INTEGER } ],	
		[ { NAME => 'x', TYPE => SQL_INTEGER }, 
		{ NAME => 'y2', TYPE => SQL_INTEGER } ],	
	] }
SELECT * from
	(select * from simppie
	returning barchart(*) 
		where color=red) bars1,
	(select * from complpa
	returning barchart(*) 
		where color=blue) bars2
	returning image, imagemap 
	where WIDTH=500 AND HEIGHT=500 AND 
	TITLE='Composite Barchart Test' AND 
	SIGNATURE='(C)2002, GOWI Systems' AND
	X_AXIS='Some Domain' AND Y_AXIS='Some Range' AND
	FORMAT='PNG' AND SHOWVALUES = 1 AND SHOWGRID=1 AND
	MAPNAME='compbars' AND ICONS=('t/imgs/pumpkin.png', 't/imgs/turkey.png' ) AND
	MAPURL='http://www.gowi.com/cgi-bin/sample.pl?x=:X&y=:Y&z=:Z&plotno=:PLOTNUM'
	AND MAPTYPE='HTML';

dump_img(@_, 'png', 'compbars');
$testnum++;
print "ok $testnum compbars OK\n";
#
#	dense numeric graph (sin/cos)
denseline:
my $i = 0;
my ($sin_i, $cos_i);
DROP table densesin;
DROP table densecos;
CREATE table densesin (angle real, sine real);
CREATE table densecos (angle real, cosine real);
PREPARE densesin AS INSERT into densesin values(:$i, :$sin_i);
PREPARE densecos AS INSERT into densecos values(:$i, :$cos_i);

while ($i < 4*PI) {
	$sin_i = sin($i);
	$cos_i = cos($i);
	EXECUTE densesin;
	EXECUTE densecos;
	$i += (PI/180);
}

EXEC SQL
	{ 
		chart_type_map => [ 
		[ { NAME => 'x', TYPE => SQL_INTEGER }, 
		{ NAME => 'y', TYPE => SQL_INTEGER } ],	
		[ { NAME => 'x', TYPE => SQL_INTEGER }, 
		{ NAME => 'y2', TYPE => SQL_INTEGER } ],	
	] }
SELECT * from
	(select * from densesin
	returning linegraph(*) 
		where color=red) densesin,
	(select * from densecos
	returning linegraph(*)
		where color=blue) densecos
	returning image 
	where WIDTH=500 AND HEIGHT=500 AND 
	TITLE='Composite Dense Linegraph Test' AND 
	SIGNATURE='(C)2002, GOWI Systems' AND
	X_AXIS='Angle (Radians)' AND Y_AXIS='Sin/Cos' AND
	FORMAT='PNG';

dump_img($_[0], undef, 'png', 'denseline', 1);
$testnum++;
print "ok $testnum denseline OK\n";

densearea:
EXEC SQL
	{ 
		chart_type_map => [ 
		[ { NAME => 'x', TYPE => SQL_INTEGER }, 
		{ NAME => 'y', TYPE => SQL_INTEGER } ],	
		[ { NAME => 'x', TYPE => SQL_INTEGER }, 
		{ NAME => 'y2', TYPE => SQL_INTEGER } ],	
	] }
SELECT * from
	(select * from densesin
	returning areagraph(*) 
		where color=red) densesin,
	(select * from densecos
	returning areagraph(*) 
		where color=blue) densecos
	returning image
	where WIDTH=500 AND HEIGHT=500 AND 
	TITLE='Composite Dense Areagraph Test' AND 
	SIGNATURE='(C)2002, GOWI Systems' AND
	X_AXIS='Angle (Radians)' AND Y_AXIS='Sin/Cos' AND
	FORMAT='PNG';

dump_img($_[0], undef, 'png', 'densearea', 1);
$testnum++;
print "ok $testnum densearea OK\n";

simpgantt:
my @tasks = ( 'First task', '2nd Task', '3rd task', 'Another task', 'Final task');
my @starts = ( '2002-01-24', '2002-02-01', '2002-02-14', '2002-01-27', '2002-03-28');
my @ends = ( '2002-01-31', '2002-02-25', '2002-03-10', '2002-02-27', '2002-04-15');
my @assigned = ( 'DAA',       'DWE',       'SAM',       'KPD',        'WLA');
my @pct = (     25,            37,         0,          0,              0 );
my @depends = ( '3rd task',  'Final task', undef,    '2nd task',  undef);

DROP table simpgantt;
CREATE table simpgantt (
	task varchar(30),
	starts varchar(20), 
	ends varchar(20), 
	assignee varchar(3), 
	pctcomplete integer, 
	dependent varchar(30)
);

INSERT into simpgantt values(:@tasks, :@starts, :@ends, :@assigned, :@pct, :@depends);

EXEC SQL
	{ 
		chart_type_map => [ 
			{ NAME => 'task', TYPE => SQL_VARCHAR, PRECISION => 30 }, 
			{ NAME => 'starts', TYPE => SQL_DATE } ,
			{ NAME => 'ends', TYPE => SQL_DATE } ,
			{ NAME => 'assignee', TYPE => SQL_VARCHAR, PRECISION => 3 } ,
			{ NAME => 'pctcomplete', TYPE => SQL_INTEGER } ,
			{ NAME => 'dependent', TYPE => SQL_VARCHAR, PRECISION => 30 }
			] 
	}
SELECT * from simpgantt
	returning gantt(*), imagemap 
	where WIDTH=500 AND HEIGHT=500 AND 
	TITLE='Simple Gantt Chart Test' AND 
	SIGNATURE='(C)2002, GOWI Systems' AND
	X_AXIS='Tasks' AND Y_AXIS='Schedule' AND
	COLOR=red AND LOGO='t/imgs/gowilogo.png' AND
	MAPNAME='simpgantt' AND
	MAPURL='http://www.gowi.com/cgi-bin/sample.pl?x=:X&y=:Y&z=:Z&plotno=:PLOTNUM'
	AND MAPTYPE='HTML' AND
	X_ORIENT='VERTICAL' AND
	FORMAT='PNG';

dump_img(@_, 'png', 'simpgantt');
$testnum++;
print "ok $testnum simpgantt OK\n";
#
#	stacked bar chart
#
stackbar:
DROP table stackbar;
CREATE table stackbar (x integer, ylo integer, yhi integer);
INSERT into stackbar values(:@x, :@y1, :@y3);

EXEC SQL
	{
		chart_type_map => [ 
			{ NAME => 'x', TYPE => SQL_INTEGER },
			{ NAME => 'ylo', TYPE => SQL_INTEGER },
			{ NAME => 'yhi', TYPE => SQL_INTEGER }
	] }
SELECT * from stackbar
	returning barchart(*), imagemap 
	where WIDTH=500 AND HEIGHT=500 AND X_AXIS='Some Domain' and Y_AXIS='Some Range' AND
	TITLE='Stacked Barchart Test' AND SIGNATURE='(C)2002, GOWI Systems' AND
	FORMAT='PNG' AND SHOWVALUES=1 AND STACK=1 AND
	MAPNAME='stackbar' AND
	MAPURL='http://www.gowi.com/cgi-bin/sample.pl?x=:X\&y=:Y\&z=:Z\&plotno=:PLOTNUM'
	AND MAPTYPE='HTML' AND COLORS IN ('yellow', 'blue');

dump_img(@_, 'png', 'stackbar');
$testnum++;
print "ok $testnum stackbar OK\n";
#
#	stacked bar chart
#
stackicon:
EXEC SQL
	{
		chart_type_map => [ 
			{ NAME => 'x', TYPE => SQL_INTEGER },
			{ NAME => 'ylo', TYPE => SQL_INTEGER },
			{ NAME => 'yhi', TYPE => SQL_INTEGER }
	] }
SELECT * from stackbar
	returning barchart(*), imagemap 
	where WIDTH=500 AND HEIGHT=500 
	AND X_AXIS='Some Domain' 
	and Y_AXIS='Some Range'
	AND TITLE='Stacked Iconic Barchart Test' 
	AND SIGNATURE='(C)2002, GOWI Systems' 
	AND FORMAT='PNG' 
	AND SHOWVALUES=1 
	AND STACK=1 
	AND ICONS IN ('t/imgs/pumpkin.png', 't/imgs/turkey.png') 
	AND MAPNAME='stackbar' 
	AND MAPURL='http://www.gowi.com/cgi-bin/sample.pl?x=:X\&y=:Y\&z=:Z\&plotno=:PLOTNUM'
	AND MAPTYPE='HTML';

dump_img(@_, 'png', 'stackicon');
$testnum++;
print "ok $testnum stackicon OK\n";
#
#	stacked histogram chart
#
stackhisto:
EXEC SQL
	{
		chart_type_map => [ 
			{ NAME => 'x', TYPE => SQL_INTEGER },
			{ NAME => 'ylo', TYPE => SQL_INTEGER },
			{ NAME => 'yhi', TYPE => SQL_INTEGER }
	] }
SELECT * from stackbar
	returning histogram(*), imagemap 
	where WIDTH=500 AND HEIGHT=500 
	AND X_AXIS='Some Domain' and Y_AXIS='Some Range' AND
	TITLE='Stacked Histogram Test' AND SIGNATURE='(C)2002, GOWI Systems' AND
	FORMAT='PNG' AND SHOWVALUES=1 AND STACK=1 AND
	MAPNAME='stackhisto' AND
	MAPURL='http://www.gowi.com/cgi-bin/sample.pl?x=:X\&y=:Y\&z=:Z\&plotno=:PLOTNUM'
	AND MAPTYPE='HTML' AND COLORS IN ('red', 'green');

dump_img(@_, 'png', 'stackhisto');
$testnum++;
print "ok $testnum stackhisto OK\n";
#
#	stacked area chart
#
stackarea:
DROP table stackbar;
CREATE table stackbar (x integer, ylo integer, yhi integer);
INSERT into stackbar values(:@x, :@y2, :@y3);

EXEC SQL
	{
		chart_type_map => [ 
			{ NAME => 'x', TYPE => SQL_INTEGER },
			{ NAME => 'ylo', TYPE => SQL_INTEGER },
			{ NAME => 'yhi', TYPE => SQL_INTEGER }
	] }
SELECT * from stackbar
	returning areagraph(*), imagemap 
	where WIDTH=500 AND HEIGHT=500 AND X_AXIS='Some Domain' and Y_AXIS='Some Range' AND
	TITLE='Stacked Areagraph Test' AND SIGNATURE='(C)2002, GOWI Systems' AND
	FORMAT='PNG' AND SHOWVALUES=1 AND STACK=1 AND
	MAPNAME='stackarea' AND
	MAPURL='http://www.gowi.com/cgi-bin/sample.pl?x=:X\&y=:Y\&z=:Z\&plotno=:PLOTNUM'
	AND MAPTYPE='HTML' AND COLORS IN ('red', 'green');

dump_img(@_, 'png', 'stackarea');
$testnum++;
print "ok $testnum stackarea OK\n";
#
#	stacked candlestick
#
stackcandle:
DROP table stackcandle;
CREATE table stackcandle (x integer, ylo integer, ymid integer, yhi integer);
INSERT into stackcandle values(:@x, :@y1, :@y2, :@y3);

EXEC SQL
	{
		chart_type_map => [ 
			{ NAME => 'x', TYPE => SQL_INTEGER },
			{ NAME => 'ylo', TYPE => SQL_INTEGER },
			{ NAME => 'ymid', TYPE => SQL_INTEGER },
			{ NAME => 'yhi', TYPE => SQL_INTEGER }
	] }
SELECT * from stackcandle
	returning candlestick(*), imagemap 
	where WIDTH=300 AND HEIGHT=500 
	AND X_AXIS='Some Domain' 
	AND Y_AXIS = 'Price' 
	AND TITLE='Stacked Candlestick Test' 
	AND SIGNATURE='(C)2002, GOWI Systems' 
	AND FORMAT='PNG' 
	AND COLORS IN ('newcolor', 'red') 
	AND SHOWGRID=1 
	AND STACK=1 
	AND MAPNAME='stackcandle' 
	AND LINEWIDTH=5 
	AND MAPURL='http://www.gowi.com/cgi-bin/sample.pl?x=:X&y=:Y&z=:Z&plotno=:PLOTNUM'
	AND MAPTYPE='HTML';

dump_img(@_, 'png', 'stackcandle');
$testnum++;
print "ok $testnum stackcandle OK\n";
#
#	multiline w/ NULL shape and map modifier
#
multilinemm:
EXEC SQL
	{ 
		chart_map_modifier => \&modify_map,
		chart_type_map => [ 
			{ NAME => 'x', TYPE => SQL_INTEGER },
			{ NAME => 'ylo', TYPE => SQL_INTEGER },
			{ NAME => 'yhi', TYPE => SQL_INTEGER }
	] }
SELECT * from stackbar
	returning linegraph(*), imagemap
	where WIDTH=500 AND HEIGHT=500 AND 
	X_AXIS='Some Domain' and Y_AXIS='Some Range' AND
	TITLE='Multiline NULL Shape, Map Modifier Test' AND 
	SIGNATURE='(C)2002, GOWI Systems' AND
	FORMAT='PNG' AND SHOWVALUES=1 AND
	MAPNAME='multilinemm' AND
	MAPURL='http://www.gowi.com/cgi-bin/sample.pl?x=:X\&y=:Y\&z=:Z\&plotno=:PLOTNUM'
	AND MAPTYPE='HTML' AND COLORS IN ('red', 'green')
	AND SHAPES IN (NULL, 'filldiamond');

dump_img(@_, 'png', 'multilinemm');
$testnum++;
print "ok $testnum multilinemm OK\n";
#
#	Quadtree test
#
quadtree:
my @dataset = (
[ 'Retail', 'Specialty', 'Sharper Image', 100, 2.3 ],
[ 'Retail', 'Dept. Store', 'Nordstrom', 400, 1.2 ],
[ 'Retail', 'Discount', 'Walmart', 900, 1.5 ],
[ 'High Tech', 'Semiconductor', 'Intel', 1000, -2.1 ],
[ 'High Tech', 'Software', 'Microsoft', 1200, -1.1 ],
[ 'High Tech', 'Hardware', 'Dell', 800, 1.0 ],
[ 'High Tech', 'Biotech', 'Merck', 1000, 1.4 ],
[ 'Energy', 'Oil Producers', 'Exxon', 1200, -2 ],
[ 'Energy', 'Oil Discovery', 'Schumberger', 300, -1 ],
[ 'Energy', 'Power Utility', 'Edison', 800, -1.5 ],
[ 'Manufacturing', 'Automotive', 'GM', 1200, 3 ],
[ 'Manufacturing', 'Aerospace', 'Boeing', 1600, -3 ],
[ 'Manufacturing', 'Heavy Equipement', 'John Deere', 750, 0 ],
[ 'Manufacturing', 'Durable Goods', 'Whirlpool', 400, 2 ],
[ 'Manufacturing', 'Other', 'Fruit of the Loom', 100, -1.4 ],
[ 'Health Care', 'HMO', 'Kaiser', 1100, 2 ],
[ 'Health Care', 'Hospital', 'Bethel', 320, 0.5 ],
[ 'Health Care', 'Equipment', 'XYZ', 200, -0.4 ],
[ 'Health Care', 'Services', 'Medical Billing Inc', 250, 1.2 ],
[ 'Transportation', 'Airlines', 'UAL', 1000, -1 ],
[ 'Transportation', 'Trucking', 'Longhaul', 450, 1 ],
[ 'Transportation', 'Rails', 'Union Pacific', 1000, 2 ],
[ 'Telecomm', 'CLEC', 'Verizon', 1300, -1 ],
[ 'Telecomm', 'Long distance', 'ATT', 900, 1.1 ],
[ 'Telecomm', 'Wireless', 'Cingular', 550, 0.7 ],
[ 'Finance', 'Banks', 'Banc of America', 1400, 1.7 ],
[ 'Finance', 'Brokerages', 'Morgan Stanley', 760, 1 ],
[ 'Finance', 'Insurance', 'Allianz', 430, -1 ],
[ 'Service', 'Restaurant', 'YUM', 240, 1.1 ],
[ 'Service', 'Media', 'Tribune', 350, -1.3 ],
[ 'Service', 'Media', 'Disney', 690, -1 ]
);

DROP TABLE myquad;
CREATE TABLE myquad (
		Sector		varchar(30),
		Subsector	varchar(30),
		Stock		varchar(30),
		RelMktCap	integer,
		PctChange	real);
my ($sector, $subsector, $stock, $mktcap, $pctchange);
PREPARE quadtree AS
	insert into myquad values(:$sector, :$subsector, :$stock, :$mktcap, :$pctchange);

foreach my $ary (@dataset) {
	($sector, $subsector, $stock, $mktcap, $pctchange) = @$ary;
	EXECUTE quadtree;
}

EXEC SQL
	{
	chart_type_map => [ 
			{ NAME => 'Sector', TYPE => SQL_VARCHAR, PRECISION => 30 },
			{ NAME => 'Subsector', TYPE => SQL_VARCHAR, PRECISION => 30 },
			{ NAME => 'Stock', TYPE => SQL_VARCHAR, PRECISION => 30 },
			{ NAME => 'RelMktCap', TYPE => SQL_INTEGER },
			{ NAME => 'PctChange', TYPE => SQL_FLOAT }
	] }
SELECT * FROM myquad
returning QUADTREE(*), IMAGEMAP
WHERE COLORS IN ('red', 'black', 'green')
	AND WIDTH=500 AND HEIGHT=500
	AND TITLE='My Quadtree'
	AND MAPTYPE='HTML'
	AND MAPNAME='quadtree'
	AND MAPURL=
'http://www.presicient.com/cgi-bin/quadtree.pl?group=:X\&item=:Y\&value=:Z\&intensity=:PLOTNUM';

dump_img(@_, 'png', 'quadtree');
$testnum++;
print "ok $testnum quadtree OK\n";
#
#	3-D barchart
#
bar3d:
EXEC SQL
	{
		chart_type_map => [ 
			{ NAME => 'x', TYPE => SQL_INTEGER },
			{ NAME => 'y', TYPE => SQL_INTEGER }
	] }
SELECT * from simpline
	returning barchart(*), imagemap 
	where WIDTH=500 AND HEIGHT=500 AND X_AXIS='Some Domain' AND
	Y_AXIS='Some Range' AND
	TITLE='3-D Barchart Test' AND SIGNATURE='(C)2002, GOWI Systems' AND
	FORMAT='PNG' AND COLORS IN ('orange') AND
	THREE_D=1 AND SHOWGRID=1 AND
	MAPNAME='bar3d' AND 
	MAPURL='http://www.gowi.com/cgi-bin/sample.pl?x=:X&y=:Y&z=:Z&plotno=:PLOTNUM'
	AND MAPTYPE='HTML';

dump_img(@_, 'png', 'bar3d');
$testnum++;
print "ok $testnum bar3d OK\n";
#
#	3-axis bar chart
#
bar3axis:
DROP table bar3axis;
CREATE table bar3axis (Region varchar(10), Sales integer, Quarter CHAR(2));
INSERT into bar3axis values(:@x3d, :@y3d, :@z);

EXEC SQL
	{
		chart_type_map => [ 
			{ NAME => 'Region', TYPE => SQL_VARCHAR, PRECISION => 10},
			{ NAME => 'Sales', TYPE => SQL_INTEGER },
			{ NAME => 'Quater', TYPE => SQL_CHAR, PRECISION => 2 }
	] }
SELECT * from bar3axis
	returning barchart(*), imagemap 
	where WIDTH=500 AND HEIGHT=500 AND 
	TITLE='3 Axis Barchart Test' AND SIGNATURE='(C)2002, GOWI Systems' AND
	X_AXIS='Region' AND Y_AXIS='Sales' AND Z-AXIS='Quarter' AND
	FORMAT='PNG' AND COLORS IN ('red') AND
	SHOWGRID=1 AND SHOWVALUES=1 AND
	MAPNAME='bar3axis' AND 
	MAPURL='http://www.gowi.com/cgi-bin/sample.pl?x=:X&y=:Y&z=:Z&plotno=:PLOTNUM'
	AND MAPTYPE='HTML';

dump_img(@_, 'png', 'bar3axis');
$testnum++;
print "ok $testnum bar3axis OK\n";
#
#	3-D histogram
#
histo3d:
EXEC SQL
	{ 
		chart_type_map => [ 
			{ NAME => 'x', TYPE => SQL_INTEGER }, 
			{ NAME => 'y2', TYPE => SQL_INTEGER } 
			] 
	}
SELECT * from simppie
	returning histogram(*), imagemap 
	where WIDTH=500 AND HEIGHT=500 AND 
	TITLE='Histogram Test' AND SIGNATURE='(C)2002, GOWI Systems' AND
	X_AXIS='Some Domain' AND Y_AXIS='Some Range' AND
	FORMAT='PNG' AND COLOR='orange' AND THREE_D=1 AND
	SHOWGRID=1 AND SHOWVALUES=1 AND
	MAPNAME='histo3d' AND 
	MAPURL='http://www.gowi.com/cgi-bin/sample.pl?x=:X&y=:Y&z=:Z&plotno=:PLOTNUM'
	AND MAPTYPE='HTML';

dump_img(@_, 'png', 'histo3d');
$testnum++;
print "ok $testnum histo3d OK\n";
#
#	3-axis histogram
#
histo3axis:
EXEC SQL
	{
		chart_type_map => [ 
			{ NAME => 'Region', TYPE => SQL_VARCHAR, PRECISION => 10},
			{ NAME => 'Sales', TYPE => SQL_INTEGER },
			{ NAME => 'Quater', TYPE => SQL_CHAR, PRECISION => 2 }
	] }
SELECT * from bar3axis
	returning histogram(*), imagemap
	where WIDTH=500 AND HEIGHT=500 AND 
	TITLE='3 Axis Histogram Test' AND SIGNATURE='(C)2002, GOWI Systems' AND
	X_AXIS='Region' AND Y_AXIS='Sales' AND Z_AXIS='Quarter' AND
	FORMAT='PNG' AND COLORS='red' AND
	SHOWGRID=1 AND SHOWVALUES=1 AND
	MAPNAME='histo3axis' AND 
	MAPURL='http://www.gowi.com/cgi-bin/sample.pl?x=:X&y=:Y&z=:Z&plotno=:PLOTNUM'
	AND MAPTYPE='HTML';

dump_img(@_, 'png', 'histo3axis');
$testnum++;
print "ok $testnum histo3axis OK\n";
#
#	composite (histo, histo)
#
comphisto:
EXEC SQL
	{
		chart_type_map => [ 
		[ { NAME => 'x', TYPE => SQL_INTEGER }, 
		{ NAME => 'y', TYPE => SQL_INTEGER } ],	
		[ { NAME => 'x', TYPE => SQL_INTEGER }, 
		{ NAME => 'y2', TYPE => SQL_INTEGER } ],	
	] }
SELECT * from
	(select * from simppie returning histogram(*) 
		where color=red) histo1,
	(select * from complpa returning histogram(*) 
		where color=blue) histo2
	returning image, imagemap 
	where WIDTH=500 AND HEIGHT=500 AND 
	TITLE='Composite Histogram Test' AND 
	SIGNATURE='(C)2002, GOWI Systems' AND
	X_AXIS='Some Domain' AND Y_AXIS='Some Range' AND
	FORMAT='PNG' AND THREE_D=1 AND SHOWVALUES = 1 AND
	MAPNAME='comphisto' AND 
	MAPURL='http://www.gowi.com/cgi-bin/sample.pl?x=:X&y=:Y&z=:Z&plotno=:PLOTNUM'
	AND MAPTYPE='HTML';

dump_img(@_, 'png', 'comphisto');
$testnum++;
print "ok $testnum comphisto OK\n";
#
#	stacked bar chart
#
stack3Dbar:
DROP table stackbar;
CREATE table stackbar (x integer, ylo integer, yhi integer);
INSERT into stackbar values(:@x, :@y1, :@y3);

EXEC SQL
	{ 
		chart_type_map => [ 
			{ NAME => 'x', TYPE => SQL_INTEGER }, 
			{ NAME => 'ylo', TYPE => SQL_INTEGER } ,
			{ NAME => 'yhi', TYPE => SQL_INTEGER } ,
	] }
SELECT * from stackbar
	returning barchart(*), imagemap 
	where WIDTH=500 
	AND HEIGHT=500 
	AND X_AXIS='Some Domain' 
	AND Y_AXIS='Some Range' 
	AND TITLE='Stacked 3-D Barchart Test' 
	AND SIGNATURE='(C)2002, GOWI Systems' 
	AND FORMAT='PNG' 
	AND SHOWVALUES=1 
	AND STACK=1 
	AND THREE_D=1
	AND MAPNAME='stack3Dbar'
	AND MAPURL='http://www.gowi.com/cgi-bin/sample.pl?x=:X\&y=:Y\&z=:Z\&plotno=:PLOTNUM'
	AND MAPTYPE='HTML' 
	AND COLORS IN ('yellow', 'blue');

dump_img(@_, 'png', 'stack3Dbar');
$testnum++;
print "ok $testnum stack3Dbar OK\n";
#
#	stacked histogram chart
#
stack3Dhisto:
EXEC SQL
	{ 
		chart_type_map => [ 
			{ NAME => 'x', TYPE => SQL_INTEGER }, 
			{ NAME => 'ylo', TYPE => SQL_INTEGER } ,
			{ NAME => 'yhi', TYPE => SQL_INTEGER } ,
	] }
SELECT * from stackbar
	returning histogram(*), imagemap 
	where WIDTH=500 
	AND HEIGHT=500 
	AND X_AXIS='Some Domain' 
	AND Y_AXIS='Some Range' 
	AND TITLE='Stacked 3-D Histogram Test' 
	AND SIGNATURE='(C)2002, GOWI Systems' 
	AND FORMAT='PNG' 
	AND SHOWVALUES=1 
	AND STACK=1 
	AND THREE_D=1
	AND MAPNAME='stack3Dhisto' AND
	MAPURL='http://www.gowi.com/cgi-bin/sample.pl?x=:X\&y=:Y\&z=:Z\&plotno=:PLOTNUM'
	AND MAPTYPE='HTML' 
	AND COLORS IN ('red', 'green');

dump_img(@_, 'png', 'stack3Dhisto');
$testnum++;
print "ok $testnum stack3Dhisto OK\n";
#
#	timestamp linegraph test
#
tmstamp:
DROP table tmstamp;
CREATE table tmstamp (x varchar(30), y integer);
INSERT into tmstamp values(:@xtmstamp, :@y3);

EXEC SQL
	{ 
		chart_type_map => [ 
			{ NAME => 'x', TYPE => SQL_TIMESTAMP }, 
			{ NAME => 'y', TYPE => SQL_INTEGER }
	] }
SELECT * from tmstamp
	returning linegraph(*), imagemap 
	where WIDTH=500 
	AND HEIGHT=500 
	AND X_AXIS='Some Domain' 
	AND Y_AXIS='Some Range' 
	AND TITLE='Timestamp Domain Test' 
	AND SIGNATURE='(C)2002, GOWI Systems' 
	AND FORMAT='PNG' 
	AND SHOWVALUES=1 
	AND MAPNAME='tmstamp' 
	AND MAPURL='http://www.gowi.com/cgi-bin/sample.pl?x=:X\&y=:Y\&z=:Z\&plotno=:PLOTNUM'
	AND MAPTYPE='HTML' 
	AND COLORS IN ('yellow', 'blue');

dump_img(@_, 'png', 'tmstamp');
$testnum++;
print "ok $testnum tmstamp OK\n";
#
#	floated stacked bar chart
#
floatbar:
DROP table floatbar;
CREATE table floatbar (x integer, ylo integer, ymid integer, yhi integer);
INSERT into floatbar values(:@x, :@y1, :@y2, :@y3);

EXEC SQL
	{ 
		chart_type_map => [ 
			{ NAME => 'x', TYPE => SQL_INTEGER }, 
			{ NAME => 'ylo', TYPE => SQL_INTEGER } ,
			{ NAME => 'ymid', TYPE => SQL_INTEGER } ,
			{ NAME => 'yhi', TYPE => SQL_INTEGER } ,
	] }
SELECT * from floatbar
	returning barchart(*), imagemap 
	where WIDTH=500 
	AND HEIGHT=500 
	AND X_AXIS='Some Domain' 
	AND Y_AXIS='Some Range' 
	AND TITLE='Floating Stacked Barchart Test' 
	AND SIGNATURE='(C)2002, GOWI Systems' 
	AND FORMAT='PNG' 
	AND SHOWVALUES=1 
	AND STACK=1 
	AND ANCHORED=0
	AND MAPNAME='floatbar' 
	AND MAPURL='http://www.gowi.com/cgi-bin/sample.pl?x=:X\&y=:Y\&z=:Z\&plotno=:PLOTNUM'
	AND MAPTYPE='HTML' 
	AND COLORS IN ('yellow', 'blue', 'red');

dump_img(@_, 'png', 'floatbar');
$testnum++;
print "ok $testnum floatbar OK\n";
#
#	floating stacked histogram chart
#
floathisto:
EXEC SQL
	{ 
		chart_type_map => [ 
			{ NAME => 'x', TYPE => SQL_INTEGER }, 
			{ NAME => 'ylo', TYPE => SQL_INTEGER } ,
			{ NAME => 'ymid', TYPE => SQL_INTEGER } ,
			{ NAME => 'yhi', TYPE => SQL_INTEGER } ,
	] }
SELECT * from floatbar
	returning histogram(*), imagemap 
	where WIDTH=500 
	AND HEIGHT=500 
	AND X_AXIS='Some Domain' 
	and Y_AXIS='Some Range' 
	AND TITLE='Floating Stacked Histogram Test' 
	AND SIGNATURE='(C)2002, GOWI Systems' 
	AND FORMAT='PNG' 
	AND SHOWVALUES=1 
	AND STACK=1 
	AND ANCHORED=0
	AND MAPNAME='floathisto' 
	AND MAPURL='http://www.gowi.com/cgi-bin/sample.pl?x=:X\&y=:Y\&z=:Z\&plotno=:PLOTNUM'
	AND MAPTYPE='HTML' 
	AND COLORS IN ('red', 'green', 'orange');

dump_img(@_, 'png', 'floathisto');
$testnum++;
print "ok $testnum floathisto OK\n";
#
#	floating stacked area chart
#
floatarea:
EXEC SQL
	{ 
		chart_type_map => [ 
			{ NAME => 'x', TYPE => SQL_INTEGER }, 
			{ NAME => 'ylo', TYPE => SQL_INTEGER } ,
			{ NAME => 'ymid', TYPE => SQL_INTEGER } ,
			{ NAME => 'yhi', TYPE => SQL_INTEGER } ,
	] }
SELECT * from floatbar
	returning areagraph(*), imagemap 
	where WIDTH=500 
	AND HEIGHT=500 
	AND X_AXIS='Some Domain' 
	AND Y_AXIS='Some Range' 
	AND TITLE='Floating Stacked Areagraph Test' 
	AND SIGNATURE='(C)2002, GOWI Systems' 
	AND FORMAT='PNG' 
	AND SHOWVALUES=1 
	AND STACK=1 
	AND ANCHORED=0
	AND MAPNAME='floatarea' 
	AND MAPURL='http://www.gowi.com/cgi-bin/sample.pl?x=:X\&y=:Y\&z=:Z\&plotno=:PLOTNUM'
	AND MAPTYPE='HTML' 
	AND COLORS IN ('green', 'yellow', 'red');

dump_img(@_, 'png', 'floatarea');
$testnum++;
print "ok $testnum floatarea OK\n";
#
#	multline multiwidth chart
#
multwidth:
DROP table floatbar;
DROP table regline;
DROP table fatline;
DROP table midline;
CREATE table floatbar (x integer, baseline integer, cold integer, warm integer, hot integer);
INSERT into floatbar values(10, -50, -10, 50, 140);
INSERT into floatbar values(50, -50, -10, 50, 140);

CREATE table regline (x integer, ylo integer);
CREATE table fatline (x integer, ymid integer);
CREATE table midline (x integer, yhi integer);
INSERT into regline values(:@x, :@y1);
INSERT into fatline values(:@x, :@y2);
INSERT into midline values(:@x, :@y3);

EXEC SQL
	{ 
		chart_type_map => [ 
		[ { NAME => 'x', TYPE => SQL_INTEGER }, 
		{ NAME => 'baseline', TYPE => SQL_INTEGER },
		{ NAME => 'cold', TYPE => SQL_INTEGER },
		{ NAME => 'warm', TYPE => SQL_INTEGER },
		{ NAME => 'hot', TYPE => SQL_INTEGER } ],
		[ { NAME => 'x', TYPE => SQL_INTEGER }, 
		{ NAME => 'y1', TYPE => SQL_INTEGER } ],
		[ { NAME => 'x', TYPE => SQL_INTEGER }, 
		{ NAME => 'y2', TYPE => SQL_INTEGER } ],
		[ { NAME => 'x', TYPE => SQL_INTEGER }, 
		{ NAME => 'y3', TYPE => SQL_INTEGER } ]
	] }
SELECT * from
	(select * from floatbar 
	returning areagraph(*) 
	where anchored=0
		and stack=1 and colors in ('blue', 'yellow', 'red')),
	(select * from regline
	returning linegraph(*)
		where color='newcolor' and showvalues=1 ) regline,
	(select * from fatline
	returning linegraph(*)
		where color='lgray' and linewidth=10) fatline,
	(select * from midline
	returning linegraph(*)
		where color='green' and linewidth=4) midline
	returning image, imagemap 
	where WIDTH=500 AND HEIGHT=500 AND 
	TITLE='Variable Width Linegraph Test' AND 
	SIGNATURE='(C)2002, GOWI Systems' AND
	X_AXIS='Some Domain' AND Y_AXIS='Some Range' AND
	FORMAT='PNG' AND 
	MAPNAME='multwidth' AND 
	MAPURL='http://www.gowi.com/cgi-bin/sample.pl?x=:X&y=:Y&z=:Z&plotno=:PLOTNUM'
	AND MAPTYPE='HTML';

dump_img(@_, 'png', 'multwidth');
$testnum++;
print "ok $testnum multwidth OK\n";

print HTMLF "</hmtl></body>\n";
close HTMLF;

DROP table simpline;
DROP table symline;
DROP table simpbox;
DROP table simpcandle;
DROP table simppie;
DROP table templine;
DROP table templine2;
DROP table logtempline;
DROP table complpa;
DROP table simpbox2;
DROP table compllbb;
DROP table complnbox;
DROP table densesin;
DROP table densecos;
DROP table simpgantt;
DROP table stackbar;
DROP table stackcandle;
DROP table bar3axis;
DROP table stackbar;
DROP table tmstamp;
DROP table floatbar;
DROP table regline;
DROP table fatline;
DROP table midline;
DROP table myquad;

$loaded = 1;

sub dump_img {
	my ($image, $imagemap, $fmt, $fname, $nomap) = @_;
	open(OUTF, ">t/imgs/$fname.$fmt") || die $!;
	binmode OUTF;
	print OUTF $image;
	close OUTF;

	print HTMLF $imagemap, "\n" unless $nomap;
	1;
}

sub modify_map {
	my ($maphash) = @_;

	print 'Bad mapname ', $maphash->{Name}, "\n"
		if ($maphash->{Name} ne 'multilinemm');

	$maphash->{URL} = 'http://www.presicient.com/tdredux',
	$maphash->{AltText} = 'Changed it!',
	return 1
		if ($maphash->{PLOTNUM} == 1);

	$maphash->{URL} = 'http://www.google.com';
	$maphash->{AltText} = $maphash->{X} . ' secs, $' . $maphash->{Y};
	return 1;
}

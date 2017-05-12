#!/usr/local/bin/perl

use strict;
use CGI;
use RCGI::Config;

my($cgi) = new CGI;

my($log_file) = $RCGI::Config::path . "/sar";
my($load_file) = $RCGI::Config::path ."/load";

my($alarm_red) = 45;

my(%SAR);
my(%DATETIME);
my($datetime, $usr, $delta_usr, $sys, $delta_sys, $wio, $delta_wio);
my($idle, $delta_idle);
my($machine);
my($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) =
    localtime(time());
$mon++;
my($timestring) = sprintf("%2.2d/%2.2d/%2.2d %2.2d:%2.2d:%2.2d",
			  $mon, $mday, $year, $hour, $min, $sec);
my($machine_color);

dbmopen(%SAR,$log_file,0664);
print $cgi->header(-type => 'text/html',
		     -status => '200 OK');
print $cgi->start_html(-title => "System Activity Report for IBC",
			 -author => 'brian@ibc.wustl.edu',
			 -BGCOLOR => 'teal');

my($cell_width) = 15;		# percent
my($bar_width) = int((100 - 2 * 15)/4);		# percent
my($halfbar_width) = int($bar_width / 2);		# percent
my($bars_width) = $bar_width * 4;
my($multiplier) = ( 100 - 2 * $cell_width ) / 100;


print "<H1 ALIGN=\"CENTER\">IBC System Activity Report $timestring</H1>\n";

print "<TABLE ALIGN=\"center\" BORDER=\"4\" WIDTH=\"100%\" CELLSPACING=\"2\" BGCOLOR=\"WHITE\" BORDERCOLORDARK=\"BLACK\" BORDERCOLORLIGHT=\"WHITE\">\n";

print "<TR>\n\t<TH WIDTH=\"$cell_width%\" BGCOLOR=\"WHITE\">Machine</TH>\n\t<TH WIDTH=\"$cell_width%\" BGCOLOR=\"WHITE\">Last Time</TH>";

print "\n\t<TH WIDTH=\"$bar_width%\" BGCOLOR=\"CYAN\"><FONT COLOR=\"BLACK\">USR</FONT></TH>\n\t<TH WIDTH=\"$bar_width%\" BGCOLOR=\"RED\"><FONT COLOR=\"WHITE\">SYS</FONT></TH>\n\t<TH WIDTH=\"$bar_width%\" BGCOLOR=\"PURPLE\"><FONT COLOR=\"WHITE\">W_IO</FONT></TH>\n\t<TH WIDTH=\"$halfbar_width%\" BGCOLOR=\"GREEN\">R_IDLE</TH>\n\t<TH WIDTH=\"$halfbar_width%\" BGCOLOR=\"LIME\">IDLE</TH>\n</TR>\n";

my(%RESERVE);
my($number_processors, $processes_per_processor, $reserve);

my($server_file) = $RCGI::Config::path ."/server.conf";
open(SERVER,"$server_file");
while(<SERVER>) {
    # Remove comments
    s/\#.*$//;
    if (/^\s*$/) {
	next;
    }
    s/\s+/\t/g;
    ($machine, $number_processors, $processes_per_processor, $reserve) =
	split("\t");
    $RESERVE{$machine} = $reserve;
}
close(SERVER);


my($usable_idle, $reserve_idle);
my($prc_usr, $prc_sys, $prc_wio, $prc_idle, $prc_ridle);
foreach $machine (sort (keys %SAR)) {
    ( $datetime, $usr, $delta_usr,
     $sys, $delta_sys,
     $wio, $delta_wio,
     $idle ,$delta_idle ) =
	 split("\t",$SAR{$machine});
    $DATETIME{$machine} = $datetime;
    $usable_idle = ($idle > $RESERVE{$machine}) ?
	$idle - $RESERVE{$machine} : 0;
    $reserve_idle = $idle - $usable_idle;
    $prc_usr = int( $multiplier * $usr);
    $prc_sys = int( $multiplier * $sys);
    $prc_wio = int( $multiplier * $wio);
    $prc_idle = int( $multiplier * $usable_idle);
    $prc_ridle = int( $multiplier * $reserve_idle);
    my($machine_mon, $machine_mday, $machine_year,
       $machine_hour, $machine_min, $machine_sec) = $datetime =~
	   /^\s*(\d+)\/(\d+)\/(\d+)\s+(\d+)\:(\d+)\:(\d+)\s*$/;

    my($machine_time) = ($machine_min * 60) + $machine_sec;
    my($local_time) = ($min * 60) + $sec;
    if ($machine_hour > $hour) {
	$local_time += (($hour + 24) - $machine_hour) * 60 * 60;
    } elsif ($machine_hour < $hour) {
	$local_time += ($hour - $machine_hour) * 60 * 60;
    }
	
    if ($machine_year == $year &&
	$machine_mon == $mon &&
	$machine_mday == $mday &&
	$machine_time + ($alarm_red * 60) > $local_time) {
	$machine_color = 'WHITE';
    } else {
	$machine_color = 'RED';
    }
	
    print "<TR>\n\t<TD ALIGN=\"CENTER\" WIDTH=\"$cell_width%\" BGCOLOR=\"$machine_color\">$machine</TD>";
    print "\n\t<TD ALIGN=\"CENTER\" WIDTH=\"$cell_width%\" BGCOLOR=\"$machine_color\">$datetime</TD>";
    print "\n\t<TD WIDTH=\"$bars_width%\" COLSPAN=\"5\">\n";
    print "\t\t<TABLE BORDER=\"0\" CELLSPACING=\"0\" WIDTH=\"100%\">\n\t\t\t<TR>\n";
    if ($prc_usr) {
	print "\n\t\t\t\t<TD WIDTH=\"$prc_usr%\" BGCOLOR=\"CYAN\" ALIGN=\"RIGHT\"><FONT COLOR=\"BLACK\">$usr</FONT></TD>";
    }
    if ($prc_sys) {
	print "\n\t\t\t\t<TD WIDTH=\"$prc_sys%\" BGCOLOR=\"RED\" ALIGN=\"RIGHT\"><FONT COLOR=\"WHITE\">$sys</FONT></TD>";
    }
    if ($prc_wio) {
	print "\n\t\t\t\t<TD WIDTH=\"$prc_wio%\" BGCOLOR=\"PURPLE\" ALIGN=\"RIGHT\"><FONT COLOR=\"WHITE\">$wio</FONT></TD>";
    }
    if ($prc_ridle) {
	print "\n\t\t\t\t<TD WIDTH=\"$prc_ridle%\" BGCOLOR=\"GREEN\" ALIGN=\"RIGHT\">$reserve_idle</TD>";
    }
    if ($prc_idle) {
	print "\n\t\t\t\t<TD WIDTH=\"$prc_idle%\" BGCOLOR=\"LIME\" ALIGN=\"RIGHT\">$idle</TD>";
    }
    print "\n\t\t\t</TR>\n\t</TABLE>\n\t</TD>\n</TR>";
}
print "</TABLE>\n";
dbmclose(%SAR);


my($cell_width) = 15;		# percent
my($bar_width) = int(100 - 2 * 15);		# percent
my($bars_width) = $bar_width * 1;
my($multiplier) = 1;
#my($multiplier) = ( 100 - 2 * $cell_width ) / 100;


print "<H1 ALIGN=\"CENTER\">IBC RCGI Current Calculated Loads</H1>\n";
print "<TABLE ALIGN=\"center\" BORDER=\"4\" WIDTH=\"100%\" CELLSPACING=\"2\" BGCOLOR=\"WHITE\" BORDERCOLORDARK=\"BLACK\" BORDERCOLORLIGHT=\"WHITE\">\n";
print "<TR>\n\t<TH WIDTH=\"$cell_width%\" BGCOLOR=\"WHITE\">Machine</TH>\n\t<TH WIDTH=\"$cell_width%\" BGCOLOR=\"WHITE\">Last Time</TH>";
print "\n\t<TH WIDTH=\"$bar_width%\">IDLE</TH>\n</TR>\n";

my(%LOAD);
my($prc_remainder);
my($prc_uidle);
dbmopen(%LOAD,$load_file,0664);
foreach $machine (sort (keys %LOAD)) {
    if ($machine =~ /^\s*$/ ) {
	next;
    }
    ( $datetime, $idle) = split("\t",$LOAD{$machine});
    if ($datetime ne $DATETIME{$machine}) {
	next;
    }
    $usable_idle = ($idle > $RESERVE{$machine}) ?
	$idle - $RESERVE{$machine} : 0;
    $reserve_idle = $idle - $usable_idle;
    $prc_uidle = int( $multiplier * $usable_idle);
    $prc_ridle = int( $multiplier * $reserve_idle);
    $prc_idle = ($idle >= 0) ? int( $multiplier * $idle) : 0;
    $prc_remainder = ($idle >= 0) ? int( $multiplier * (100 - $idle)) :
	$multiplier * 100;
    print "<TR>\n\t<TD ALIGN=\"CENTER\" WIDTH=\"$cell_width%\" BGCOLOR=\"WHITE\">$machine</TD>";
    print "\n\t<TD ALIGN=\"CENTER\" WIDTH=\"$cell_width%\" BGCOLOR=\"WHITE\">$datetime</TD>";
    print "\n\t<TD WIDTH=\"$bars_width%\" COLSPAN=\"2\">\n";
    print "\t\t<TABLE BORDER=\"0\" CELLSPACING=\"0\" WIDTH=\"100%\">\n\t\t\t<TR>\n";
    if ($prc_idle) {
	if ($prc_ridle) {
	    print "\n\t\t\t\t<TD WIDTH=\"$prc_ridle%\" BGCOLOR=\"GREEN\" ALIGN=\"RIGHT\">$reserve_idle</TD>";
	}
	if ($prc_uidle) {
	    print "\n\t\t\t\t<TD WIDTH=\"$prc_uidle%\" BGCOLOR=\"LIME\" ALIGN=\"RIGHT\">$idle</TD>";
	}
    }
    if ($prc_remainder) {
	print "\n\t\t\t\t<TD WIDTH=\"$prc_remainder%\" BGCOLOR=\"BLACK\" ALIGN=\"RIGHT\">&nbsp;</TD>";
    }
    print "\n\t\t\t</TR>\n\t</TABLE>\n\t</TD>\n</TR>";
}
print "</TABLE>\n";
dbmclose(%LOAD);

print $cgi->end_html;


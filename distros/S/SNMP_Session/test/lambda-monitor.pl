#!/usr/local/bin/perl -w

use strict;

use SNMP_Session;
use SNMP_util;

sub show_light_trail (@);
sub show_bitmap ($$);
sub print_html_header ();
sub print_html_trailer ();

my $html_file = "/opt/www/htdocs/lan/switchlambda/status.html";

my $inverse_video = 0;

snmpmapOID (qw(amplifierOperStatus 1.3.6.1.4.1.2522.1.5.1.1.0
	       amplifierLastChange 1.3.6.1.4.1.2522.1.5.1.2.0
	       amplifierGain-dB 1.3.6.1.4.1.2522.1.5.1.3.0
	       inputPowerStatus 1.3.6.1.4.1.2522.1.5.1.4.0
	       inputPowerLevel 1.3.6.1.4.1.2522.1.5.1.5.0
	       outputPowerStatus 1.3.6.1.4.1.2522.1.5.1.6.0
	       outputPowerLevel 1.3.6.1.4.1.2522.1.5.1.7.0));

my @eastbound_amps = qw(public@muxCE1-A8  
	      public@muxLS1-A1  
	      public@muxLS1-A8  
	      public@muxBE1-A1
	      public@muxBE1-A8
	      public@muxBA1-A1  
	      public@muxBA1-A8
	      public@muxEZ1-A1);


my @westbound_amps = qw(
	      public@muxEZ1-A2
	      public@muxBA1-A7  
	      public@muxBA1-A2  
	      public@muxBE1-A7
	      public@muxBE1-A2
	      public@muxLS1-A7  
	      public@muxLS1-A2  
			);

my @amps = (@eastbound_amps, @westbound_amps);

for (;;) {
    open (HTML, ">$html_file.new");
    print_html_header ();
    my $localtime = localtime();
    print "",$localtime,"\n";

    print HTML "<p> Last updated: $localtime </p>\n";

    print "\nEastbound:\n";
    print HTML "<table width=\"100%\"><tr><td align=\"left\" valign=\"top\" width=\"45%\"><h2> Eastbound </h2>\n";
    show_light_trail (@eastbound_amps);

    print HTML "</td><td align=\"right\" valign=\"top\" width=\"45%\"><h2> Westbound </h2>";
    print "\nWestbound:\n";
    show_light_trail (@westbound_amps);

    print HTML "</td></tr></table>\n";
    print "-"x 75,"\n";
    print_html_trailer ();
    close (HTML);
    rename ($html_file.".new",$html_file);
    sleep (292);
}
1;

sub show_light_trail (@) {
    my @amps = @_;
    printf "%-16s%-8s%-8s\n", "node", "  in pwr", " out pwr";
    printf "%-16s%-8s%-8s\n", "name", "   dBm", "   dBm";

    print HTML "<table>\n <tr>\n  <th>Amplifier</th>\n  <th>Input<br>Power<br>(dBm)</th>\n  <th>Output<br>Power<br>(dBm)</th>\n </tr>\n";
    foreach my $amp (@amps) {
	my ($community,$nodename) = split (/@/,$amp);
	my ($amp_status,
	    $in_status, $in,
	    $out_status, $out)
	    = snmpget ($amp, qw(amplifierOperStatus
					   inputPowerStatus inputPowerLevel
					   outputPowerStatus outputPowerLevel));
	printf "%-16s%8.2f%8.2f\t%-8s%-8s%-8s\n",
	$nodename, $in, $out,
	show_bitmap ($amp_status, 5),
	pretty_power_status ($in_status),
	pretty_power_status ($out_status);
	my ($amp_class, $in_class, $out_class)
	    = (class_for_amp_status ($amp_status),
	       class_for_level_status ($in_status),
	       class_for_level_status ($out_status));
	print HTML "<tr><td class=\"$amp_class\">$nodename</td><td class=\"$in_class\">$in</td><td class=\"$out_class\">$out</td></tr>\n";
    }
    print HTML "</table>\n";
}

sub show_bitmap ($$) {
    my ($bits,$n) = @_;
    my ($k,$result);
    for ($k = 0, $result = ''; $k < $n; ++$k) {
	$result .= (($bits & (1<<$k)) ? '*' : ' ');
    }
    return $result;
}

sub pretty_power_status ($) {
    return (qw(???? ---- minr majr CRIT))[$_[0]];
}

sub class_for_level_status ($) {
    return (qw(weird normal minor major critical))[$_[0]];
}

sub class_for_amp_status ($) {
    return 'failed' if $_[0] & 1<<4;
    return 'critical' if $_[0] & 1<<3;
    return 'major' if $_[0] & 1<<2;
    return 'minor' if $_[0] & 1<<1;
    return 'normal' if $_[0] & 1<<0;
    return 'normal';
}

sub print_html_header () {
    my $expires = time + 300;
    my $expire_string = http_date_string ($expires);
    my ($c_bg, $c_normal, $c_minor, $c_major, $c_critical, $c_failed)
	= $inverse_video
	    ? qw(#000000 #ffffff #ff8080 #ff4040 #ff0000 #ff8000)
		 : qw(#ffffff #000000 #804040 #ff4040 #ff0000 #ff8000);
    print HTML <<EOM;
<html><head>
<title>SWITCHlambda Amplifier Status</title>
<meta http-equiv="Refresh" content="300">
<meta http-equiv="Expires" content="$expire_string">
<style type="text/css">
.normal {color: $c_normal}
.minor {color: $c_minor}
.major {color: $c_major}
.critical {color: $c_critical; font-weight: bold}
.failed {color: $c_failed; font-weight: bold; font-style: italic}
</style>
</head><body bgcolor="$c_bg" text="$c_normal">\n<h1>SWITCHlambda Amplifier Status</h1>
EOM
}

sub print_html_trailer () {
    print HTML <<EOM;
<h3> Color Legend </h3>
<p><span class="normal">normal</span>
- <span class="minor">minor</span>
- <span class="major">major</span>
- <span class="critical">critical</span>
- <span class="failed">failed</span></p>
</body></html>
EOM
}

sub http_date_string ($) {
    my ($time) = @_;
    my @gmtime = gmtime $time;
    my ($wday) = (qw(Sun Mon Tue Wed Thu Fri Sat))[$gmtime[6]];
    my ($month) = (qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec))[$gmtime[4]];
    my ($mday, $year, $hour, $min, $sec) = @gmtime[3,5,2,1,0];
    return sprintf ("%s, %02d %s %04d %02d:%02d:%02d GMT",
		    $wday, $mday, $month, $year+1900, $hour, $min, $sec);
}

#!/usr/local/bin/perl -w

use strict;

use SNMP_Session;
use SNMP_util;

sub make_amp_html_page ($$);
sub show_light_trail ($@);
sub print_html_header ();
sub print_html_trailer ();

my $html_file = "/opt/www/htdocs/lan/switchlambda/status-new.html";
my $html_file_iv = "/opt/www/htdocs/lan/switchlambda/status-iv.html";

my $inverse_video = 0;

snmpmapOID (qw(amplifierOperStatus 1.3.6.1.4.1.2522.1.5.1.1.0
	       amplifierLastChange 1.3.6.1.4.1.2522.1.5.1.2.0
	       amplifierGain-dB 1.3.6.1.4.1.2522.1.5.1.3.0
	       inputPowerStatus 1.3.6.1.4.1.2522.1.5.1.4.0
	       inputPowerLevel 1.3.6.1.4.1.2522.1.5.1.5.0
	       outputPowerStatus 1.3.6.1.4.1.2522.1.5.1.6.0
	       outputPowerLevel 1.3.6.1.4.1.2522.1.5.1.7.0

	       aType 1.3.6.1.4.1.2522.1.2.1.1.0
	       aTypeValue 1.3.6.1.4.1.2522.1.2.1.2.0
	       aChannel 1.3.6.1.4.1.2522.1.2.1.3.0
	       aTxLaserOn 1.3.6.1.4.1.2522.1.2.1.4.0
	       aTxLaserOutput 1.3.6.1.4.1.2522.1.2.1.5.0
	       aTxLaserTemp 1.3.6.1.4.1.2522.1.2.1.6.0
	       aTxLossOfSignal 1.3.6.1.4.1.2522.1.2.1.7.0
	       aRxOpticalPower 1.3.6.1.4.1.2522.1.2.1.8.0
	       aRxLossOfSignal 1.3.6.1.4.1.2522.1.2.1.9.0
	       aRxAPDBias 1.3.6.1.4.1.2522.1.2.1.10.0
	       bType 1.3.6.1.4.1.2522.1.2.2.1.0
	       bTypeValue 1.3.6.1.4.1.2522.1.2.2.2.0
	       bChannel 1.3.6.1.4.1.2522.1.2.2.3.0
	       bTxLaserOn 1.3.6.1.4.1.2522.1.2.2.4.0
	       bTxLaserOutput 1.3.6.1.4.1.2522.1.2.2.5.0
	       bTxLaserTemp 1.3.6.1.4.1.2522.1.2.2.6.0
	       bTxLossOfSignal 1.3.6.1.4.1.2522.1.2.2.7.0
	       bRxOpticalPower 1.3.6.1.4.1.2522.1.2.2.8.0
	       bRxLossOfSignal 1.3.6.1.4.1.2522.1.2.2.9.0
	       bRxAPDBias 1.3.6.1.4.1.2522.1.2.2.10.0
));

my @eastbound_amps = qw(public@mCE11-A8  
	      public@mLS11-A1  
	      public@mLS11-A8  
	      public@mBE11-A1
	      public@mBE11-A8
	      public@mBA11-A1  
	      public@mBA11-A8
	      public@mEZ11-A1);

my @westbound_amps = qw(public@mEZ11-A2
	      public@mBA11-A7  
	      public@mBA11-A2  
	      public@mBE11-A7
	      public@mBE11-A2
	      public@mLS11-A7  
	      public@mLS11-A2);

my @amps = (@eastbound_amps, @westbound_amps);

for (;;) {
    my $amp_status = get_amp_status (@amps);
    $inverse_video = 0;
    make_amp_html_page ($html_file, $amp_status);
    $inverse_video = 1;
    make_amp_html_page ($html_file_iv, $amp_status);
    sleep (292);
}
1;

sub get_amp_status (@) {
    my (@amps) = @_;
    my %status = ();
    foreach my $amp (@amps) {
	my ($amp_status,
	    $in_status, $in,
	    $out_status, $out)
	    = snmpget ($amp, qw(amplifierOperStatus
				inputPowerStatus inputPowerLevel
				outputPowerStatus outputPowerLevel));
	$status{$amp} = {amp_status => $amp_status,
			 in_status => $in_status,
			 in => $in,
			 out_status => $out_status,
			 out => $out};
    }
    return \%status;
}

sub make_amp_html_page ($$) {
    my ($out_file, $status) = @_;
    open (HTML, ">$out_file.new");
    print_html_header ();
    my $localtime = localtime();

    print HTML "<table width=\"100%\"><tr><td align=\"left\" valign=\"top\" width=\"45%\"><h2> Eastbound </h2>\n";
    show_light_trail ($status, @eastbound_amps);

    print HTML "</td><td align=\"right\" valign=\"top\" width=\"45%\"><h2> Westbound </h2>";
    show_light_trail ($status, @westbound_amps);

    print HTML "</td></tr></table>\n";
    print HTML "<p> Last updated: $localtime </p>\n";
    print_html_trailer ();
    close (HTML);
    rename ($out_file.".new",$out_file);
}

sub show_light_trail ($@) {
    my ($status, @amps) = @_;

    print HTML "<table width=\"90%\">\n <tr>\n  <th>Amplifier</th>\n  <th>Input<br>Power<br>(dBm)</th>\n  <th>Output<br>Power<br>(dBm)</th>\n </tr>\n";
    foreach my $amp (@amps) {
	my ($community,$nodename) = split (/@/,$amp);
	my $values = $status->{$amp};
	my ($amp_status,
	    $in_status, $in,
	    $out_status, $out)
	    = ($values->{amp_status},
	       $values->{in_status},$values->{in},
	       $values->{out_status},$values->{out});
	my ($amp_class, $in_class, $out_class)
	    = (class_for_amp_status ($amp_status),
	       class_for_level_status ($in_status),
	       class_for_level_status ($out_status));
	print HTML "<tr><td class=\"$amp_class\">$nodename</td><td class=\"$in_class\">$in</td><td class=\"$out_class\">$out</td></tr>\n";
    }
    print HTML "</table>\n";
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
    return 'offline';
}

sub print_html_header () {
    my $expires = time + 300;
    my $expire_string = http_date_string ($expires);
    my ($c_bg, $c_normal, $c_offline, $c_minor, $c_major, $c_critical, $c_failed)
	= $inverse_video
	    ? ('#000000', '#ffffff', '#606060', '#ff7070', '#ff3030', '#ff0000', '#ff8000')
		 : ('#ffffff', '#000000', '#a0a0a0', '#c06060', '#ff4040', '#ff0000', '#ff8000');
    print HTML <<EOM;
<html><head>
<title>SWITCHlambda Amplifier Status</title>
<meta http-equiv="Refresh" content="300">
<meta http-equiv="Expires" content="$expire_string">
<style type="text/css">
p {font-family: helvetica,arial}
h1 {font-family: helvetica,arial}
h2 {font-family: helvetica,arial}
th {font-family: helvetica,arial}
td {font-family: lucidatypewriter,courier,helvetica,arial}
.normal {color: $c_normal; }
.offline {color: $c_offline; }
.minor {color: $c_minor; }
.major {color: $c_major; }
.critical {color: $c_critical; font-weight: bold; }
.failed {color: $c_failed; font-weight: bold; font-style: italic; }
.trailer {font-size: 70%; }
</style>
</head><body bgcolor="$c_bg" text="$c_normal">\n<h1>SWITCHlambda Amplifier Status</h1>
EOM
}

sub print_html_trailer () {
    print HTML <<EOM;

<p> <b>Color Legend:</b>
  <span class="normal">normal</span>
- <span class="offline">offline</span>
- <span class="minor">minor</span>/<span class="major">major</span>/<span class="critical">critical
alarm condition</span>
- <span class="failed">failed</span></p>

<p class="trailer"> Generated by a script using the <a
href="http://www.switch.ch/misc/leinen/snmp/perl/">SNMP_Session.pl</a>.<br>

Script by <a href="http://www.switch.ch/misc/leinen/">Simon
Leinen</a>, <a href="http://www.switch.ch/">SWITCH</a>, 2001. </p>

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

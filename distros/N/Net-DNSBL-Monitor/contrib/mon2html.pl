#!/usr/bin/perl
#
# mon2html.pl	version 1.01, 1-19-08
#
#
print STDERR qq|
usage: $0 out_filename stats/path/name report/path/name

prints out the file with out_filename imbedded

| if @ARGV < 2;
my($FILEname,$IN1,$IN2) = @ARGV;
die "could not find $IN1\n"
	unless $IN1 &&
		-e $IN1 &&
		open(F,$IN1);
my $txt = q|<html>
<head>
<title>DNSBL Monitor Report</title>
</head>
<body bgcolor=white>
<center>
<font size=+2>DNSBL Monitor Report</font>
<p>
<font size=+1>|. $FILEname .q(
<p>
</center>
<a href="/">HOME</a> | <a href="../dnsbl_monitor.shtml">DNSBL Monitor Reports</a></font>
<hr>
Survey results are for selected DNSBLs and IP ranges..
The union of all results includes any IP for which there was a DNSBL
response matching the lookup response criteria.
<p>
<center>
<table cellspacing=2 cellpadding=2 border=2>
);

{
	undef $/;
	$txt .= <F>;
}
close F;

$txt .= q(</table>
<p>
<hr>
<table cellspacing=2 cellpadding=2 border=2>
);

die "could not find $IN2\n"
	unless $IN2 &&
		-e $IN2 &&
		open(F,$IN2);
{
	undef $/;
	$txt .= <F>;
}
close F;

$txt .= q(</table>
<p>
<hr>
This report was prepared using <a
href="http://search.cpan.org/search?query=Net%3A%3ADNSBL%3A%3AMonitor&mode=all">Net::DNSBL::Monitor</a>
available at <a href="http://cpan.org/">CPAN</a>
</center
<hr>
<font size=+1><a href="/">HOME</a> | <a href="../dnsbl_monitor.shtml">DNSBL Monitor Reports</a></font>
</body>
</html>
);
print $txt;

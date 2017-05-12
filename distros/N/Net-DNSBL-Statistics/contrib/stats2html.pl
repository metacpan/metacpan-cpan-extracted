#!/usr/bin/perl
#
# stats2html.pl	version 1.01, 1-6-08
#
#
print STDERR qq|
usage: $0 out_filename in_file/path/name

prints out the file with out_filename imbedded

| if @ARGV < 2;
my($FILEname,$IN) = @ARGV;
die "could not find $IN\n"
	unless $IN &&
		-e $IN &&
		open(F,$IN);
my $txt = q|<html>
<head>
<title>DNSBLs Compared</title>
</head>
<body bgcolor=white>
<center>
<font size=+2>DNSBLs Compared</font>
<p>
<font size=+1>|. $FILEname .q(
<p>
</center>
<a href="/">HOME</a> | <a href="../dnsbl_compare.shtml">DNSBLs Compared</a></font>
<hr>
Survey results are for all DNSBLs used by the mail hosts at at this site.
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
This report was prepared using <a
href="http://search.cpan.org/search?query=Net%3A%3ADNSBL%3A%3AStatistics&mode=all">Net::DNSBL::Statistics</a>
available at <a href="http://cpan.org/">CPAN</a>
</center
<hr>
<font size=+1><a href="/">HOME</a> | <a href="../dnsbl_compare.shtml">DNSBLs Compared</a></font>
</body>
</html>
);
print $txt;

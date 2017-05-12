#!/usr/bin/perl
#
# stat2generic.pl
# version 1.00, 1-6-08
#
# extract the GENERIC section from the sc_BlackList.conf file
# or other compatible file
#

if (@ARGV < 2) {
  print qq|
usage: $0 path/to/statistics.conf /path/to/outfile.html

$0 will update the output file 
if it is older than the input file

|;
  exit;
}

my ($in,$out) = @ARGV;
die "could not find '$in'\n"
	unless -e $in;
exit if -e $out && (stat($in))[9] < (stat($out))[9];

my $conf = '';
open (F,$in) or die "could not open input file\n";
{
	undef local $/;
	$conf .= <F>;
}
close F;

my $html = q|<html>
<head>
<title>GENERIC PTR Record Criteria</title>
</head>
<body bgcolor=white>
<center><font size=+2>GENERIC PTR Record Criteria</font></center>
<p>
<b>Generic rDNS</b> means that a DNS query on the IP address resolves
to something like&#058; 
123-45-67-8.your.isp.com, a repeating or <nobr>psuedo-random-string.your.isp.com</nobr>, or some similar alph-numeric sequence.
The opposite of generic rDNS is a &quot;unique reverse pointer&quot; which is usually something like &quot;mail.your-domain.com.&quot;</p>
<p>
See: <a href="http://serverauthority.net/draft-lorenzen-marid-mxout-00.txt">NS Naming Convention for Outbound Internet Email Servers</a>
<p>
It is not unreasonable to require that a competent mail administrator should offer the 
accountability provided by a proper reverse pointer without having to query whois.</p>
<p>
For the vast majority of these generic hosts, a whois on
the IP points to the provider anyway. This is aggravated by the fact that
very few ISPs are responsible enough to provide or publish their dynamic
ranges and rarely respond aggressively to abuse complaints.

<p>
<b>The bottom line</b>:</p>
<ol style="list-style-type: square"><li>If you have a static IP then you
should have a unique reverse pointer.
<li>When obtaining or changing providers, a unique PTR record should be a requirement.
<li>It is now trivial for an ISP to provide a unique PTR record.
If they will not do so then you need a different ISP! There should be no
cost for a PTR record.
<li>If you already have established static service then your ISP should
provide a PTR record. 
<li>Most will do so within an hour or so of a request -- but you have to ask.
</ol>
<hr>
<blockquote>
<pre>
|;

$conf =~ /'GENERIC'.+regexp.+=>\s+\[/s;
$' =~ /],/s;
@_ = split("\n",$`);
foreach(@_) {
  next if $_ =~ /^#/;		# remove comment lines beginning with '#'
  $html .= $_ ."\n";
}

$html .= q|
</pre>
</blockquote>
</body>
</html>
|;
open(F,'>'. $out .'.tmp') or die "could not open output '${out}.tmp'";
print F $html;
close F;

rename $out .'.tmp', $out or die "could not rename ${out}.tmp\n";

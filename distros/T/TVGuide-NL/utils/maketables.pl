#!/usr/bin/perl 

#
# This script connects to http://gids.omroep.nl/, fetches a list with
# all the station names and abbreviations and writes it to a perl
# package file.
#

use strict;
use warnings;

use encoding 'utf8';
use utf8;

use Data::Dumper;
use HTML::Entities;
use LWP::UserAgent;
use Encode;

my $HTTP_Useragent = "Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.5a) Gecko";
my %HTTP_Headers = ( 'Accept' => 'text/xml,application/xml,application/xhtml+xml,'.
                                 'text/html;q=0.9,text/plain;q=0.8,video/x-mng,',
                     'Accept-Language' => 'en,en-us;q=0.5' );

# initialize HTTP client funtion
my $ua = LWP::UserAgent->new;
$ua->agent($HTTP_Useragent);

########################################################################
## first, get a cookie
########################################################################
my $cookie;
my $response = $ua->get('http://gids.omroep.nl/', %HTTP_Headers);
if ($response->is_success and
	$response->header('Set-Cookie') =~ m/^EPGSESSID=(.*?);/)
{
	$cookie = "EPGSESSID=$1";
}
else
{
	die("Couldn't get cookie");
}


########################################################################
## then, get a summary of all available stations
########################################################################
my $url = 'http://gids.omroep.nl/core/content.php';
$response = $ua->get($url, %HTTP_Headers, "Cookie" => $cookie);
if (!$response->is_success) {
	die("Error while retrieving url $url: ".$response->status_line);
}

my $content = Encode::decode('iso-8859-1', $response->content);

$content =~ m{<table\s[^>]+summary="Zenderoverzicht".*?</table>}s
#$content =~ m{<table.*?</table>}s
	or die("Couldn't find table `Zenderoverzicht'");
my $zendertable = $&;

#print $zendertable, "\n";

my @zenders = ();
while ($zendertable =~ m{<tr>.*?</tr>}sgc)
{
	my $row = $&;
	next unless ($row =~ m{<td\s?[^>]*>([^<]+)</td>.*?<input [^>]*name="(Z\d+)"});
	#print $row,"\n";
	my $name = decode_entities($1);
	my $code = $2;
	
	push @zenders, { 'code' => $code, 'naam' => $name };
}

die("no stations found!") unless @zenders;

########################################################################
## finally, find all stations and their logo/code
########################################################################
# we can only process 10 stations at a time
for (my $i=0; $i<=int($#zenders/10); $i++)
{
	my @zend;
	if (10*$i+9 <= $#zenders)
	{
		@zend = @zenders[(10*$i)..(10*$i+9)];
	}
	else
	{
		@zend = @zenders[(10*$i)..$#zenders];
	}

	my $url = "http://gids.omroep.nl/core/content.php?Z=&".
		"dag=0&tijd=ochtend&genre=Alle+genres";

	foreach my $z (@zend)
	{
		$url .= '&'.$z->{code}.'=on';
	}
	
	# get the url
	$response = $ua->get($url, %HTTP_Headers, "Cookie" => $cookie);
	if (!$response->is_success) {
		die("Error while retrieving url $url: ".$response->status_line);
	}
	my $content = Encode::decode('iso-8859-1', $response->content);

	# find the logo's section
	$content =~ m{<div\s[^>]*id="logosDiv".*?</div>}s;
	my $logos = $&;

	#print $logos, "\n";

	my $j = 10*$i;
	while ($logos =~ m{<img src="/Z/(tv-[^.]+).gif"}sgc)
	{
		die("too many logo's found: $j/".(10*($i+1)).'/'.$#zenders)
			if ($j>=10*($i+1) or $j>$#zenders);

		$zenders[$j]->{logo} = $1;
		#print "$i\t$j\t$1\n";
		$j++;
	}
	die("not enough logo's found: $j/".(10*($i+1)).'/'.$#zenders)
		unless ($j==$#zenders+1 or $j==10*($i+1));
}

########################################################################
## print the tables we need
########################################################################

# table for nice human readable abbreviations
our %logo2afk = (
	'mov' => [ 'mov' ],
	'nl1' => [ 'ned1', 'nl1' ],
	'nl2' => [ 'ned2', 'nl2' ],
	'nl3' => [ 'ned3', 'nl3' ],
	'rt4' => [ 'rtl4', 'rt4' ],
	'rt5' => [ 'rtl5', 'rt5' ],
	'nt5' => [ 'net5', 'nt5' ],
	'sbs' => [ 'sbs6', 'sbs' ],
	'ver' => [ 'rtl7', 'yorin', 'yor' ],
	'fox' => [ 'vero', 'ver' ],
	'tal' => [ 'talpa', 'talp', 'nick' ],
	'vrt' => [ 'één', 'vrt', 'een', 'vrt1' ],
	'ket' => [ 'canvas', 'ket', 'can', 'ketnet', 'vrt2' ],
	'vtm' => [ 'vtm' ],
	'vt4' => [ 'vt4' ],
	'lau' => [ 'la-une', 'laune', 'lau', 'une', 'rbtf1' ],
	'lad' => [ 'la-deux', 'lad', 'ladeux', 'deux', 'rbtf2' ],
	'ka2' => [ 'kan2', 'ka2', 'kanaal2' ],
	'bb1' => [ 'bbc1', 'bb1' ],
	'bb2' => [ 'bbc2', 'bb2' ],
	'ard' => [ 'ard' ],
	'zdf' => [ 'zdf' ],
	'ndr' => [ 'ndr' ],
	'wdr' => [ 'wdr' ],
	'swf' => [ 'südwest', 'swf', 'sudwest', 'sud', 'süd', 'sudw', 'südw' ],
	'3st' => [ '3sat', '3st' ],
	'rtl' => [ 'rtl+', 'rtl' ],
	'pr7' => [ 'pro7', 'pr7' ],
	'sa1' => [ 'sat1', 'sa1' ],
	'bvn' => [ 'bvn' ],
	'tv5' => [ 'tv5' ],
	'tve' => [ 'tve' ],
	'rai' => [ 'rai', 'raiuno' ],
	'trt' => [ 'trt', 'trtint', 'trt-int' ],
	'cnw' => [ 'cartoon', 'cart', 'cnw' ],
	'dis' => [ 'disc', 'dis', 'discovery' ],
	'ngc' => [ 'ngc' ],
	'apt' => [ 'animal', 'apt' ],
	'tmf' => [ 'tmf' ],
	'mtb' => [ 'mtv', 'mtve' ],
	'cnn' => [ 'cnn' ],
	'bbw' => [ 'bbcw', 'bbw', 'bbcworld' ],
	'eur' => [ 'eurosp', 'eur', 'euro', 'eurosport' ],
	'cp1' => [ 'c+r', 'cp1', 'cpr', 'rood', 'canal+rood' ],
	'cp2' => [ 'c+b', 'cp2', 'cpb', 'blauw', 'canal+blauw' ],
	'tcm' => [ 'tcm' ],
	'ret_tv_noord-holland' => [ 'n-h', 'noord-holland' ],
	'at5' => [ 'at5' ],
	'ret_tv_west' => [ 'tvw', 'tvwest', 'tv-west' ],
	'ret_tv_rijnmond' => [ 'rijnm', 'rijnmond' ],
	'ret_regio_tv_utrecht' => [ 'utr', 'utrecht' ],
	'ret_tv_flevoland' => [ 'flevo', 'flevoland' ],
	'ret_omrop_fryslan' => [ 'frys', 'fryslan', 'friesland', 'fries' ],
	'ret_tv_noord' => [ 'tvnoord', 'tvn', 'tv-noord' ],
	'ret_tv_drenthe' => [ 'drent', 'drenthe' ],
	'ret_tv_oost' => [ 'oost', 'tvoost', 'tvo', 'tv-oost' ],
	'ret_tv_gelderland' => [ 'geld', 'gelderland', 'tvg', 'tv-geld', 'tvgeld' ],
	'ret_omroep_brabant_tv' => [ 'brabant', 'bra' ],
	'ret_l1_tv' => [ 'l1', 'limburg', 'limbo' ],
	'ret_omroep_zeeland' => [ 'zee', 'zeeland' ],
);


# wrie package header
print <<'EOF';
package TVGuide::NL::Names;
#
# This file is automatically generated by the TVGuide::NL distribution
#
use warnings;
use strict;

require 5.008_001;
use encoding 'utf8';
use utf8;
require Exporter;

use vars qw( @ISA @EXPORT_OK );

# symbols to be exported
our (
	%STATION_LOOKUP,
	%CODE_LOOKUP,
	%STATION_PIC_LOOKUP,
	%STATION_ORDER,
	%STATION_NAMES
);

@ISA = qw( Exporter );
@EXPORT_OK = qw( 
	%STATION_LOOKUP
	%CODE_LOOKUP
	%STATION_PIC_LOOKUP
	%STATION_ORDER
	%STATION_NAMES
);

EOF

# version is set to version fo main module plus timestamp of 
# download of the data from the web
my $version = '0.14.' . time;
print <<"EOF";
# set the version of this module
our \$VERSION;
\$VERSION = \'$version\';

EOF

print "\%STATION_LOOKUP = (\n";
print "\t'mov' => 'Z0',\n";
for (my $i=0; $i<@zenders; $i++)
{
	my $l = $zenders[$i]->{logo};
	my $c = $zenders[$i]->{code};

	$l =~ s/^tvs?-//;
	
	# lookup the code in the manual table
	# if it exists, use it, otherwise use logo abbr.
	if ( exists $logo2afk{$l} and @{$logo2afk{$l}}>0 )
	{
		foreach my $a (@{$logo2afk{$l}})
		{
			print "\t'$a' => '$c',\n"
		}
	}
	else
	{
		print "\t'$l' => '$c',\n"
	}
}
print ");\n";

# TODO: use manual lookup table for logo->afk
print "\%CODE_LOOKUP = (\n";
print "\t'Z0' => 'mov',\n";
for (my $i=0; $i<@zenders; $i++)
{
	my $l = $zenders[$i]->{logo};
	my $c = $zenders[$i]->{code};

	$l =~ s/^tvs?-//;

	# lookup the code in the manual table
	# if it exists, use it, otherwise use logo abbr.
	if ( exists $logo2afk{$l} and @{$logo2afk{$l}}>0 )
	{
		my $a = $logo2afk{$l}->[0];
		print "\t'$c' => '$a',\n";
	}
	else
	{
		print "\t'$c' => '$l',\n";
	}
}
print ");\n";

print "\%STATION_PIC_LOOKUP = (\n";
for (my $i=0; $i<@zenders; $i++)
{
	my $l = $zenders[$i]->{logo};
	my $c = $zenders[$i]->{code};
	print "\t'$l' => '$c',\n";
	$l =~ s/^tv-/tvs-/;
	print "\t'$l' => '$c',\n";
}
print ");\n";

print "\%STATION_ORDER = (\n";
print "\t'Z0' => 0,\n";
for (my $i=0; $i<@zenders; $i++)
{
	my $c = $zenders[$i]->{code};
	my $n = $i+1;
	print "\t'$c' => $n,\n";
}
print ");\n";

print "\%STATION_NAMES = (\n";
print "\t'Z0' => 'Movies',\n";
for (my $i=0; $i<@zenders; $i++)
{
	my $c = $zenders[$i]->{code};
	my $n = $zenders[$i]->{naam};
	print "\t'$c' => '$n',\n";
}
print ");\n";

print "42;\n";
print "__END__\n";


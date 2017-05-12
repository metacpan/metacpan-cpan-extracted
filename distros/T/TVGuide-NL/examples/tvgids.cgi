#!/usr/bin/perl

#
# Films.rss - example cgi script for TVGuide::NL
# Copyright (c) 2004-2006 by Bas Zoetekouw <bas@debian.org>
# $Id: tvgids.cgi 67 2006-04-22 13:04:20Z bas $
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of either the Artistic license, or
# version 2 of the GNU General Public License.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#

use warnings;
use strict;

use encoding 'utf8';
use utf8;

use lib '../blib/lib/';

use TVGuide::NL;
use HTML::Entities;
use Data::Dumper;


$|=1;

my $statnum;

# == declare subs =====================================================
sub progtable;
sub movietable;

# == CGI init =========================================================

# load module
use CGI qw{ :cgi :cgi-lib };

# avoid DoS
$CGI::POST_MAX=1024 * 10;  # max 10K posts
$CGI::DISABLE_UPLOADS = 1;  # no uploads

my $SCRIPT = $ENV{'SCRIPT_NAME'} || '(none)';
my ($PATH) = $SCRIPT =~ m{^(.*/)};
my $SERVER = $ENV{'SERVER_NAME'} || '(none)';

# == vars =============================================================

# default zenders
my @zenders_default = (
'Z0',
'ned1', 'ned2', 'ned3', 'rtl4', 'rtl5', 'yorin', 'sbs6', 'vero',
'net5', 'nick', 'bbc1', 'bbc2', 'vrt1', 'vrt2', 
'bbcw', 'disc', 'ngc', 'animal', 'mtv', 'cartoon',
);

# get stations to display
sub GetStations
{
	my $guide = shift;
	my $cookie = shift;
	my @params = param;
	my @zenders = ();

	my $i=0;
	while (my $stat = param("s$i"))
	{
		($stat = 'Z67') if ($stat =~ m{^z68$}i);
		last unless ($guide->is_valid_station($stat));
		
		push(@zenders, $stat);
		$i++;
	}
	return @zenders if (@zenders);
	
	if (exists $$cookie[0])
	{
		my @output;
		foreach my $stat (@$cookie)
		{
			($stat = 'Z67') if ($stat =~ m{^z68$}i);
			push(@output, $stat) if ($guide->is_valid_station($stat));
		}
		return @output;
	}
	
	return @zenders_default;
}

# retrieve cookie
my @cookieval = cookie('zenders');
my $cookie = undef;
# and update expiry date
if (@cookieval)
{
    $cookie = cookie(
        -name       => 'zenders',
        -value      => \@cookieval,
        -expires    => '+100d',
        -domain     => $SERVER,
        -path       => $PATH,
    );
}

# == main =============================================================

# start by printing the http headers
# do this before any TVGuide things, so that error will be shown
# rather than just a 500 error
my $contenttype = 'application/xhtml+xml';
my $xmlheader   = '<?xml version="1.0" encoding="UTF-8"?>'."\n";
unless (grep(m{^application/xhtml\+xml}, Accept))
{
	$contenttype = 'text/html';
	$xmlheader = '';
}

my %headers = (
	'-type'		=> $contenttype,
	'-charset'	=> 'utf-8',
	'-expires'  => '+30m',
	);
$headers{'-cookie'} = $cookie if ($cookie);

print header(%headers), $xmlheader;


# now initialize the TVGuide stuff
my $g = TVGuide::NL->new(debug=>0);
my @zenders = $g->station_code(GetStations($g,\@cookieval));
# update the info of all stations
$g->update_schedule(@zenders);


print <<"EOF";
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN" 
   "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="nl">
<head>
 <title>Wat is er op TV vandaag?</title>
 <link rel="alternate" type="text/xml" title="Films RSS Feed" href="films.rss" />
 <link rel="stylesheet" type="text/css" href="tvgids.css"/>
 <script type="text/javascript" src="tvgids.js"></script>
</head>
<body>
<h1>Wat is er op TV vandaag?</h1>
<p class="prefs"><a href="prefs.cgi">Instellingen</a></p>
EOF

my $i = 0;
for my $zender (@zenders)
{
	if ($zender eq 'Z0') 
	{
		print movietable($g, $i, @zenders);
	}
	else 
	{
		print progtable($g, $zender, $i);
	}
	$i++;
}

print <<"EOF";
</body>
</html>
EOF

exit(0);



sub progtable
{
	my $guide = shift;
	my $station = shift;
	my $num = shift || 0;

	my $result = '';
	
	my $clear = ''; 
	$clear = ' style="clear: left"' if ($num%3==0);
	
	$result .= '<div class="channel" id="'
		. $guide->station_abbr($station). "\" $clear>\n";
	$result .= " <h2>". encode_entities($guide->station_name($station),'<>&"') 
		. "</h2>\n";
	$result .= " <table class=\"channel\">\n";

	my $i = 0;
	foreach my $prog ( $guide->whats_on_today($station) )
	{
		my $odd = ($i++%2)?'odd':'even';
		$result .= "  <tr class=\"$odd\">";
		$result .= '<td class="time">';
		$result .= $prog->{'time'}; 
		$result .= '</td>';
		$result .= '<td class="program">';
		$result .= '<div class="title">';
		$result .= encode_entities($prog->{'title'},'<>&"');
		$result .= '</div>';
		$result .= '<div class="desc">';
		$result .= encode_entities($prog->{'desc'},'<>&"');
		$result .= '</div>';
		$result .= '</td></tr>';
		$result .= "\n";
	}
	$result .= " </table>\n";
	$result .= "</div>\n";

	return $result;
}

sub movietable
{
	my $guide = shift;
	my $num = shift || 0;
	my @stations = @_;

	my $result = '';
	
	my $clear = ''; 
	$clear = ' style="clear: left"' if ($num%3==0);
	
	$result .= '<div class="movies" id="movies"' . "$clear>\n";
	$result .= " <h2>Films</h2>\n";
	$result .= " <table class=\"movies\">\n";

	my $i = 0;
	foreach my $prog ( $guide->movies_today(0,@stations) )
	{
		my $odd = ($i++%2)?'odd':'even';
		$result .= "  <tr class=\"$odd\">";
		$result .= '<td class="time">';
		$result .= $prog->{'time'} . "&ndash;" . $prog->{stop}; 
		$result .= '</td>';
		$result .= '<td class="program">';
		$result .= '<div class="title">';
		$result .= encode_entities($prog->{'title'},'<>&"');
		$result .= '</div>';
		$result .= '<div class="desc">';
		$result .= encode_entities($prog->{'desc'},'<>&"');
		$result .= '</div>';
		$result .= '</td>';
		$result .= '<td class="station">';
		$result .= '('.$guide->station_abbr($prog->{station}).')'; 
		$result .= '</td></tr>';
		$result .= "\n";
	}
	$result .= " </table>\n";
	$result .= "</div>\n";

	return $result;
}

__END__


#!/usr/bin/perl

#
# prefs.cgi - example cgi script for TVGuide::NL
# Copyright (c) 2004-2006 by Bas Zoetekouw <bas@debian.org>
# $Id: NL.pm 60 2006-04-22 12:10:59Z bas $
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

# == CGI init =========================================================

# load module
use CGI qw{ :cgi :cgi-lib };

# avoid DoS
$CGI::POST_MAX=1024 * 10;  # max 10K posts
$CGI::DISABLE_UPLOADS = 1;  # no uploads

my $SCRIPT = $ENV{'SCRIPT_NAME'};
my ($PATH) = $SCRIPT =~ m{^(.*/)};
my $SERVER = $ENV{'SERVER_NAME'};


# == HTTP/XML init ====================================================

my $contenttype = 'application/xhtml+xml';
my $xmlheader   = '<?xml version="1.0" encoding="UTF-8"?>'."\n";
unless (grep m{^application/xhtml\+xml}, Accept )
{   
    $contenttype = 'text/html';
    $xmlheader = '';
}

# handle args
my $params = Vars;
if (exists $params->{save} and lc $params->{save} eq 'yes')
{
	my @stations = ();
	my $i = 0;
	while (exists $params->{"s$i"})
	{
		push @stations, $params->{"s$i"};
		$i++;
	}
	
	my $cookie = cookie( 
		-name		=> 'zenders',
		-value		=> \@stations,
		-expires	=> '+100d',
		-domain		=> $SERVER,
		-path		=> $PATH,
	);
	print header(
		'-cookie'	=> $cookie,
		'-location'	=> 'tvgids.cgi',
	);
	exit 0;
}


print header(
    '-type'     => $contenttype,
    '-charset'  => 'utf-8',
    );
print $xmlheader;

print <<"EOF";
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN" 
   "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="nl">
<head>
 <title>Wat is er op TV vandaag?</title>
 <link rel="stylesheet" type="text/css" href="prefs.css"/>
 <script type="text/javascript" src="prefs.js"></script>
</head>
<body>
EOF

print <<"EOF";
<h1>TVGids &mdash; Instellingen</h1>

<form action="prefs.cgi" method="post">
<div class="zenders">
  <select class="zenders" id="avail" multiple="multiple" size="20" name="z-avail">
EOF

my $g = TVGuide::NL->new();

foreach my $code ($g->all_station_codes)
{
	my $station = Encode::decode('utf8',$g->station_name($code));
	print "    <option value=\"$code\">", encode_entities($station),
		"</option>\n"; 
}

print <<"EOF";
  </select>
  <div class="knopjes">
    <button type="button" onclick="toLeft()"><img src="pics/left.png"/></button>
    <button type="button" onclick="toRight()"><img src="pics/right.png"/></button>
  </div>
  <select class="zenders" id="select" multiple="multiple" size="20" name="z-select">
  </select>
  <div class="knopjes">
    <button type="button" onclick="moveUp()"  ><img src="pics/up.png"/></button>
    <button type="button" onclick="moveDown()"><img src="pics/down.png"/></button>
  </div>
  <div class="submitknopjes">
	<button type="button" onclick="submitForm()">Save</button>
    <!-- <input type="reset"/> -->
  </div>
</div>
</form>
EOF


print <<"EOF";
</body>
</html>
EOF



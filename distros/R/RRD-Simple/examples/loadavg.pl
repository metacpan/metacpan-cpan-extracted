#!/usr/bin/perl -w
############################################################
#
#   $Id: loadavg.pl 965 2007-03-01 19:11:23Z nicolaw $
#   loadavg.pl - Example script bundled as part of RRD::Simple
#
#   Copyright 2005,2006 Nicola Worthington
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
#
############################################################

use strict;
use lib qw(../lib);
use RRD::Simple;

my $rrd = new RRD::Simple;
my $rrdfile = 'load.rrd';
my @avg = `uptime` =~ /([\d\.]+)[,\s]+([\d\.]+)[,\s]+([\d\.]+)\s*$/;

$rrd->create($rrdfile, map { ($_ => 'GAUGE') } qw(1min 5min 15min))
	unless -f $rrdfile;

$rrd->update($rrdfile,
		'1min' => $avg[0],
		'5min' => $avg[1],
		'15min' => $avg[2],
	);

$rrd->graph($rrdfile,
		sources => [ qw(1min 5min 15min) ], 
		source_colors => [ qw(ffbb00 cc0000 0000cc) ],
		source_drawtypes => [ qw(AREA LINE1 LINE1) ],
		vertical_label => 'Load'
	);



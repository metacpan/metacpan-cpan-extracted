#!/usr/bin/perl -w
############################################################
#
#   $Id: graph2.pl 965 2007-03-01 19:11:23Z nicolaw $
#   graph2.pl - Example script bundled as part of RRD::Simple
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
use lib qw(../lib/ ./lib/);
use RRD::Simple 1.35;

my $rrdfile = 'graph2.rrd';
my $end = time();
my $start = $end - (60 * 60 * 24 * 31);
my @ds = qw(nicola hannah jennifer hedley heather baya);

# A salt offset for putting random shit in as the data points later
my %offset = (map { $_ => (index("@ds",$_) * 2) } @ds);

# Make a new object
my $rrd = RRD::Simple->new();

unless (-f $rrdfile) {
	$rrd->create($rrdfile,
			map { $_ => 'GAUGE' } @ds
		);

	for (my $t = $start; $t <= $end; $t += 300) {
		$rrd->update($rrdfile,$t,
				# Put any old random crap in as the data points :)
				map { $_ => cos( (($t+($offset{$_}*500))/20000)-($offset{$_}*10) )
							* (100-$offset{$_}) } @ds
			);
	}
}

# Graph the data
$rrd->graph($rrdfile,
		'title' => 'Random Graph of Some People',
		'vertical-label' => 'Weirdness',
		'line-thickness' => 2,
		'extended-legend' => 1,
	);



#!/usr/bin/perl -w
############################################################
#
#   $Id: df.pl 965 2007-03-01 19:11:23Z nicolaw $
#   df.pl - Example script bundled as part of RRD::Simple
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

my $rrdfile = 'disk-capacity.rrd';
my %capacity;
my %labels;

my @data = split(/\n/, ($^O =~ /linux/ ? `df -P -x iso9660` : `df -P`));
shift @data;

for (@data) {
	my ($fs,$blocks,$used,$avail,$capacity,$mount) = split(/\s+/,$_);
	next if ($fs eq 'none' || $mount =~ m#^/dev/#);

	if (my ($val) = $capacity =~ /(\d+)/) {
		(my $ds = $mount) =~ s/\//_/g;
		$labels{$ds} = $mount;
		$capacity{$ds} = $val;
	} 
}

$rrd->create($rrdfile,
		map { ( $_ => 'GAUGE' ) } sort keys %capacity
	) unless -f $rrdfile;

$rrd->update($rrdfile, %capacity);

$rrd->graph($rrdfile,
		title          => 'Disk Capacity',
		line_thickness => 2,
		vertical_label => '% used',
		units_exponent => 0,
		upper_limit    => 100,
		sources        => [ sort keys %capacity ],
		source_labels  => [ map { $labels{$_} } sort keys %labels ],
		color          => [ ('BACK#F5F5FF','SHADEA#C8C8FF','SHADEB#9696BE',
		                     'ARROW#61B51B','GRID#404852','MGRID#67C6DE') ],
	);



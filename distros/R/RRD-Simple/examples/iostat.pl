#!/usr/bin/perl -w
############################################################
#
#   $Id: iostat.pl 965 2007-03-01 19:11:23Z nicolaw $
#   iostat.pl - Example script bundled as part of RRD::Simple
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
use RRD::Simple 1.34;
use RRDs;

BEGIN {
	warn "This may only run on Linux 2.6 kernel systems"
		unless `uname -s` =~ /Linux/i && `uname -r` =~ /^2\.6\./;
}

my $cmd = '/usr/bin/iostat -k';
my $rrd = new RRD::Simple;

my %update = ();
open(PH,'-|',$cmd) || die "Unable to open file handle PH for command '$cmd': $!";
while (local $_ = <PH>) {
	if (my ($dev,$r,$w) = $_ =~ /^([\w\d]+)\s+\S+\s+\S+\s+\S+\s+(\d+)\s+(\d+)$/) {
		$update{$dev} = { 'read' => $r, 'write' => $w };
	}
}
close(PH) || die "Unable to close file handle PH for command '$cmd': $!";

for my $dev (keys %update) {
	my $rrdfile = "iostat-$dev.rrd";
	unless (-f $rrdfile) {
		$rrd->create($rrdfile, map { ($_ => 'DERIVE') }
				sort keys %{$update{$dev}} );
		RRDs::tune($rrdfile,'-i',"$_:0") for keys %{$update{$dev}};
	}

	$rrd->update($rrdfile, %{$update{$dev}});
	$rrd->graph($rrdfile,
			sources => [ qw(read write) ],
			source_drawtypes => [ qw(AREA LINE2) ],
			source_colors => [ qw(00ee00 dd0000) ],
			vertical_label => 'kilobytes/sec',
		);
}




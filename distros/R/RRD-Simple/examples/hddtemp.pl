#!/usr/bin/perl
############################################################
#
#   $Id: hddtemp.pl 965 2007-03-01 19:11:23Z nicolaw $
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
use RRD::Simple 1.35;

BEGIN {
	warn "This may only run on Linux 2.4 or higher kernel systems"
		unless `uname -s` =~ /Linux/i && `uname -r` =~ /^2\.[4-9]\./;
}

use constant HDDTEMP => '/usr/sbin/hddtemp -q /dev/hd? /dev/sd?';

my %update = ();
open(PH,'-|',HDDTEMP) || die $!;
while (local $_ = <PH>) {
	if (my ($dev,$temp) = $_ =~ m,^/dev/([a-z]+):\s+.+?:\s+(\d+)..?C,) {
		$update{$dev} = $temp;
	}
}
close(PH) || warn $!;

my $rrd = new RRD::Simple;
$rrd->update(%update);
$rrd->graph(
	vertical_label => 'Celsius',
	line_thickness => 2,
	sources => [ sort $rrd->sources ],
	extended_legend => 1,
);


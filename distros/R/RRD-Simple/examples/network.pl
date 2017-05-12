#!/usr/bin/perl -w
############################################################
#
#   $Id: network.pl 965 2007-03-01 19:11:23Z nicolaw $
#   network.pl - Example script bundled as part of RRD::Simple
#
#   Copyright 2006 Nicola Worthington
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

my $rrd = new RRD::Simple;

my @keys = ();
my %update = ();
open(FH,'<','/proc/net/dev') || die "Unable to open '/proc/net/dev': $!";
while (local $_ = <FH>) {
	s/^\s+|\s+$//g;
	if ((my ($dev,$data) = $_ =~ /^(.+?):\s*(\d+.+)\s*$/) && @keys) {
		$update{$dev} = [ split(/\s+/,$data) ];
	} else {
		my ($rx,$tx) = (split(/\s*\|\s*/,$_))[1,2];
		@keys = (map({"RX$_"} split(/\s+/,$rx)), map{"TX$_"} split(/\s+/,$tx));
	}
}
close(FH) || die "Unable to close '/proc/net/dev': $!";

for my $dev (keys %update) {
	my $rrdfile = "network-$dev.rrd";
	unless (-f $rrdfile) {
		$rrd->create($rrdfile, map { ($_ => 'DERIVE') } @keys);
		RRDs::tune($rrdfile,'-i',"$_:0") for @keys;
	}

	my %tmp;
	for (my $i = 0; $i < @keys; $i++) {
		$tmp{$keys[$i]} = $update{$dev}->[$i];
	}

	$rrd->update($rrdfile, %tmp);
	$rrd->graph($rrdfile,
			vertical_label => 'bytes/sec',
			#sources => [ sort grep(/.X(bytes|packets|errs)/,@keys) ],
			sources => [ qw(TXbytes RXbytes) ],
			source_labels => [ qw(transmit recieve) ],
			source_drawtypes => [ qw(AREA LINE) ],
			source_colors => [ qw(00dd00 0000dd) ],
			extended_legend => 1,
		);
}



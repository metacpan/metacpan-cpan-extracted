#!/usr/bin/perl -w
############################################################
#
#   $Id: processes.pl 965 2007-03-01 19:11:23Z nicolaw $
#   processes.pl - Example script bundled as part of RRD::Simple
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
use RRD::Simple 1.37;

my %update = ();
if (-f '/bin/ps' && -x '/bin/ps') {
	open(PH,'-|','/bin/ps -eo pid,s') || die $!;
	while (local $_ = <PH>) {
		if (/^\s*\d+\s+(\w+)\s*$/) {
			$update{$1}++;
		}
	}
	close(PH) || warn $!;
} else {
	eval "use Proc::ProcessTable";
	die "Please install /bin/ps or Proc::ProcessTable\n" if $@;
	my $p = new Proc::ProcessTable("cache_ttys" => 1 );
	for (@{$p->table}) {
		$update{$_->{state}}++;
	}
}

my $rrdfile = 'processes.rrd';
my $rrd = new RRD::Simple;

$rrd->create($rrdfile, map { ($_ => 'GAUGE') } sort keys %update )
	unless -f $rrdfile;

my @sources = sort $rrd->sources($rrdfile);
$update{$_} ||= 0 for @sources;
$rrd->update($rrdfile, %update);

my %legend = (qw(D iowait R run S sleep
	T stopped W paging X dead Z zombie));

my @types = ('AREA');
for (my $i = 2; $i <= @sources; $i++) {
	push @types, 'STACK';
}

$rrd->graph($rrdfile,
		vertical_label => 'Processes',
		sources => \@sources,
		source_drawtypes => \@types,
		source_labels => \%legend,
		extended_legend => 1,
	);



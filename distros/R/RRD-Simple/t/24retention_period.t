# $Id: 24retention_period.t 965 2007-03-01 19:11:23Z nicolaw $

chdir('t') if -d 't';
my $rrdfile = -d 't' ? 't/24test.rrd' : '24test.rrd';
unlink $rrdfile if -f $rrdfile;

use strict;

BEGIN {
	use Test::More;
	eval "use RRDs";
	plan skip_all => "RRDs.pm *MUST* be installed!" if $@;
	plan tests => 31 if !$@;
}

use lib qw(./lib ../lib);
use RRD::Simple 1.35 ();

use vars qw($rra %retention_periods %scheme_graphs @schemes %graph_return);
require 'answers.pl';

ok(my $rrd = RRD::Simple->new(),'new');

for my $p (keys %retention_periods) {
	ok($rrd->create($rrdfile, $p,
			bytesIn => 'GAUGE',
			bytesOut => 'GAUGE',
		),"$p create");

	ok($rrd->update($rrdfile,
			bytesIn => 100,
			bytesOut => 100,
		),"$p update");

	ok(join(',',sort $rrd->sources($rrdfile)) eq 'bytesIn,bytesOut',
		"$p sources");

	ok(my $period = $rrd->retention_period($rrdfile),"$p retention_period");
	ok($period > ($retention_periods{$p} * 0.95) &&
		$period < ($retention_periods{$p} * 1.05),
		"$p retention_period result");

	unlink $rrdfile if -f $rrdfile;
}

unlink $rrdfile if -f $rrdfile;

1;


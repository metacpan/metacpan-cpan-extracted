# $Id: 30assume_rrd_filename.t 965 2007-03-01 19:11:23Z nicolaw $

my $rrdfile = -d 't' ? 't/30assume_rrd_filename.rrd' : '30assume_rrd_filename.rrd';
unlink $rrdfile if -f $rrdfile;

use strict;

BEGIN {
	use Test::More;
	eval "use RRDs";
	plan skip_all => "RRDs.pm *MUST* be installed!" if $@;
	plan tests => 4 if !$@;
}

use lib qw(./lib ../lib);
use RRD::Simple 1.35 ();

ok(RRD::Simple->create(
		bytesIn => 'GAUGE',
		bytesOut => 'GAUGE',
		faultsPerSec => 'COUNTER'
	),'create');

my $updated = time();
ok(RRD::Simple->update(
		bytesIn => 10039,
		bytesOut => 389,
		faultsPerSec => 0.4
	),'update');

ok(RRD::Simple->last() - $updated < 5 && RRD::Simple->last(),
	'last');

ok(join(',',sort RRD::Simple->sources()) eq 'bytesIn,bytesOut,faultsPerSec',
	'sources');

unlink $rrdfile if -f $rrdfile;

1;


# $Id: 32exported_function_interface.t 965 2007-03-01 19:11:23Z nicolaw $

chdir('t') if -d 't';
my $rrdfile = -d 't' ? 't/32test.rrd' : '32test.rrd';
unlink $rrdfile if -f $rrdfile;

use strict;

BEGIN {
	use Test::More;
	eval "use RRDs";
	plan skip_all => "RRDs.pm *MUST* be installed!" if $@;
	plan tests => 12 if !$@;
}

use lib qw(./lib ../lib);
use RRD::Simple 1.35 qw(:all);

use vars qw($rra %retention_periods %scheme_graphs @schemes %graph_return);
require 'answers.pl';

ok(create($rrdfile,
		bytesIn => 'GAUGE',
		bytesOut => 'GAUGE',
		faultsPerSec => 'COUNTER'
	),'create');

my $updated = time();
ok(update($rrdfile,
		bytesIn => 10039,
		bytesOut => 389,
		faultsPerSec => 0.4
	),'update');

ok(last_update($rrdfile) - $updated < 5 && last_update($rrdfile),
	'last_update');

ok(join(',',sort(sources($rrdfile))) eq 'bytesIn,bytesOut,faultsPerSec',
	'sources');

ok(my $period = retention_period($rrdfile),'retention_period');

my $default_period = $RRD::Simple::VERSION >= 1.33 ? 'mrtg' : 'year';
ok(abs($retention_periods{$default_period} - $period) < 1000,'retention_period result');

SKIP: {
	my $deep = 0;
	eval {
		require Test::Deep;
		Test::Deep->import();
		$deep = 1;
	};
	if (!$deep || $@) {
		skip 'Test::Deep not available', 1;
	}

	my $info = info($rrdfile);
	cmp_deeply(
			$info->{rra},
			$rra,
			"info rra",
		);
}

(my $imgbasename = $rrdfile) =~ s/\.rrd$//;

ok(graph($rrdfile,destination => './'),'graph');

# By default we only have up to a year to graph
# for unless we specify the 3 year scheme, so
# dont bother checking for a 3years graph image.

for (qw(daily weekly monthly annual)) {
	my $img = "$imgbasename-$_.png";
	ok(-f $img,"$img");
	unlink $img if -f $img;
}

unlink $_ for glob('*.png');
unlink $rrdfile if -f $rrdfile;

1;


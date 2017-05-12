# $Id: 34populate_test_data.t 965 2007-03-01 19:11:23Z nicolaw $

my $rrdfile = -d 't' ? 't/34test.rrd' : '34test.rrd';
unlink $rrdfile if -f $rrdfile;

use strict;

BEGIN {
	use Test::More;
	eval "use RRDs";
	plan skip_all => "RRDs.pm *MUST* be installed!" if $@;
	plan tests => 5765 if !$@;
}

use lib qw(./lib ../lib);
use RRD::Simple 1.35 ();

ok(my $rrd = RRD::Simple->new(),'new');

my $end = time() - 3600;
my $start = $end - (60 * 60 * 24 * 4);
my @ds = qw(nicola hannah jennifer hedley heather baya);

ok($rrd->create($rrdfile,'week',
		map { $_ => 'GAUGE' } @ds
	),'create');

for (my $t = $start; $t <= $end; $t += 60) {
	ok($rrd->update($rrdfile,$t,
			map { $_ => int(rand(100)) } @ds
		),'update');
}

ok($rrd->last($rrdfile) == $end, 'last');

ok(join(',',sort $rrd->sources($rrdfile)) eq join(',',sort(@ds)),
	'sources');

unlink $rrdfile if -f $rrdfile;

1;


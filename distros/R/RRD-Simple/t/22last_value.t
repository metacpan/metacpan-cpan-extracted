# $Id: 22last_value.t 965 2007-03-01 19:11:23Z nicolaw $

my $rrdfile = -d 't' ? 't/22test.rrd' : '22test.rrd';
unlink $rrdfile if -f $rrdfile;

use strict;

BEGIN {
	use Test::More;
	eval "use RRDs";
	plan skip_all => "RRDs.pm *MUST* be installed!" if $@;
	plan tests => 368 if !$@;
}

use lib qw(./lib ../lib);
use RRD::Simple 1.35 ();

ok(my $rrd = RRD::Simple->new(cf => [ qw(AVERAGE LAST) ]),'new');

my $end = time();
my $start = $end - (60 * 60 * 6);

ok($rrd->create($rrdfile,'day',
		foo => 'GAUGE',
		bar => 'GAUGE'
	),'create');

my $lastValue = 0;
for (my $t = $start; $t <= $end; $t += 60) {
	#$lastValue = int(rand(999));
	$lastValue = 100;
	ok($rrd->update($rrdfile,$t,
			foo => $lastValue,
			bar => $lastValue+100
		),'update');
}

ok($rrd->last($rrdfile) == $end, 'last');

ok(join(',',sort($rrd->sources($rrdfile))) eq join(',',sort(qw(foo bar))),
	'sources');

#print "Last value inserted for 'bar' = " . ($lastValue + 100) . "\n";
#print "Last value inserted for 'foo' = " . $lastValue . "\n";

my %rtn;
ok(%rtn = $rrd->last_values($rrdfile),'last_values');

SKIP: {
#	skip "last_values() method not yet completed", 2;
	ok($rtn{foo} == $lastValue, "$rtn{foo} == $lastValue (foo)");
	ok($rtn{bar} == ($lastValue + 100), "$rtn{bar} == ($lastValue + 100) (bar)");
}

unlink $rrdfile if -f $rrdfile;

1;


# $Id: 25info.t 965 2007-03-01 19:11:23Z nicolaw $

my $rrdfile = -d 't' ? 't/25test.rrd' : '25test.rrd';
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

ok(RRD::Simple->create($rrdfile,
		foo => 'GAUGE',
		bar => 'COUNTER'
	),'create');

ok(RRD::Simple->update($rrdfile,
		foo => 1024,
		bar => 4096,
	),'update');

my $info = {};
ok($info = RRD::Simple->info($rrdfile),'get info'); 
ok($info->{ds}->{foo}->{type} eq 'GAUGE','check info');

unlink $rrdfile if -f $rrdfile;

1;


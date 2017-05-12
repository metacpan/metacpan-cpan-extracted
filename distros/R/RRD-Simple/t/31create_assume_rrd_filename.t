# $Id: 31create_assume_rrd_filename.t 965 2007-03-01 19:11:23Z nicolaw $

my $rrdfile = -d 't' ? 't/31create_assume_rrd_filename.rrd' : '31create_assume_rrd_filename.rrd';
unlink $rrdfile if -f $rrdfile;

use strict;

BEGIN {
	use Test::More;
	eval "use RRDs";
	plan skip_all => "RRDs.pm *MUST* be installed!" if $@;
	plan tests => 6 if !$@;
}

use lib qw(./lib ../lib);
use RRD::Simple 1.35 ();

my $created = time();

#
# Forcing RRD::Simple to create an RRD with an update method call
# while perl warnings are enabled will cause a warning message to
# be displayed. This might alarm some people if it were to happen
# during unit tests - for this reason we disable warnings for this
# particular part of the tests.
#

my $oldW = $^W; $^W = 0;

ok(RRD::Simple->update(
		ds0 => 1024,
		ds1 => 4096,
		ds2 => 512
	),'update (lazy create)');

$^W = $oldW;

ok(RRD::Simple->last() - $created < 5 && RRD::Simple->last(),
	'last');

ok(join(',',sort RRD::Simple->sources()) eq 'ds0,ds1,ds2',
	'sources');

unlink $rrdfile if -f $rrdfile;

$created = time();

$^W = 0;

ok(RRD::Simple->update((time()-3600),
		ds3 => 1024,
		ds4 => 4096,
		ds5 => 512
	),'update (lazy create)');

$^W = $oldW;

ok(RRD::Simple->last() - $created < 5 && RRD::Simple->last(),
	'last');

ok(join(',',sort RRD::Simple->sources()) eq 'ds3,ds4,ds5',
	'sources');

unlink $rrdfile if -f $rrdfile;

1;


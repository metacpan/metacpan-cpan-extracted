# $Id: 35average_hrule.t 965 2007-03-01 19:11:23Z nicolaw $

my $rrdfile = -d 't' ? 't/36test.rrd' : '36test.rrd';
unlink $rrdfile if -f $rrdfile;

use strict;

BEGIN {
	use Test::More;
	eval "use RRDs";
	plan skip_all => "RRDs.pm *MUST* be installed!" if $@;
	plan skip_all => "RRDs version less than 1.2" if $RRDs::VERSION < 1.2;
	plan tests => 197 if !$@;
}

use lib qw(./lib ../lib);
use RRD::Simple 1.44 ();

ok(my $rrd = RRD::Simple->new(),'new');

my $end = time();
my $start = $end - (60 * 60 * 3);

ok($rrd->create($rrdfile,'day',
		knickers => 'GAUGE',
	),'create');

my $lastValue = 0;
my $x = rand ( 10 );
for (my $t = $start; $t <= $end; $t += 60) {
	$lastValue = ( cos($t / 1000 ) + rand(2) ) + $x;
	$lastValue = 6 if $lastValue > 6;
	ok($rrd->update($rrdfile,$t,
			knickers => $lastValue,
		),'update');
}

for my $sources (('',undef)) {
	for my $file (glob('36test-*.png')) { unlink $file; }
	my $str = $rrd->graph($rrdfile,
			sources => $sources,
			'CDEF:mycdef1=knickers,100,*' => '',
			'CDEF:mycdef2=knickers,2,*' => '',
			'CDEF:mycdef3=knickers,300,*' => '',
			'LINE1:mycdef2#00ff00:MyCDef2' => '',
			'PRINT:mycdef2:MIN:mycdef2 min %1.2lf' => '',
			'PRINT:mycdef2:MAX:mycdef2 max %1.2lf' => '',
			'PRINT:mycdef2:LAST:mycdef2 last %1.2lf' => '',
			'GPRINT:mycdef2:MIN:   min\:%10.2lf\g' => '',
			'GPRINT:mycdef2:MAX:   max\:%10.2lf\g' => '',
			'GPRINT:mycdef2:LAST:   last\:%10.2lf\l' => '',
		);
	for my $p (qw(daily)) {
		ok($str->{$p}->[0] eq '36test-daily.png', 'graph without sources: rtn filename');
		ok(defined $str->{$p}->[1]->[0]
			&& $str->{$p}->[1]->[0] =~ /^mycdef2 min /
			&& $str->{$p}->[1]->[0] !~ /knickers/,
			'graph without sources: rtn ds values');
		ok(defined $str->{$p}->[1]->[1]
			&& $str->{$p}->[1]->[1] =~ /^mycdef2 max /
			&& $str->{$p}->[1]->[1] !~ /knickers/,
			'graph without sources: rtn ds values');
		ok(defined $str->{$p}->[1]->[2]
			&& $str->{$p}->[1]->[2] =~ /^mycdef2 last /
			&& $str->{$p}->[1]->[2] !~ /knickers/,
			'graph without sources: rtn ds values');
		ok($str->{$p}->[2] =~ /^\d+$/ && $str->{$p}->[2] > 100, 'graph without sources: rtn width');
		ok($str->{$p}->[3] =~ /^\d+$/ && $str->{$p}->[3] > 100, 'graph without sources: rtn height');
	}
	ok(-e '36test-daily.png','created 36test-daily.png on disk');
}

unlink $rrdfile if -f $rrdfile;
unlink '36test-daily.png' if -f '36test-daily.png';
for my $file (glob('36test-*.png')) { unlink $file; }

1;


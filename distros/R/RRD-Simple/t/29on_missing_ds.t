# $Id: 26add_source.t 965 2007-03-01 19:11:23Z nicolaw $

my $rrdfile = -d 't' ? 't/29test.rrd' : '29test.rrd';

use strict;

BEGIN {
	use Test::More;
	#plan skip_all => "unit test not written yet";

	my $okay = 1;
	for (qw(RRDs File::Temp File::Copy)) {
		eval "use $_";
		if ($@) {
			plan skip_all => "$_ *MUST* be installed!";
			$okay = 0;
		}
	}
	plan tests => 28 if $okay;
}

use lib qw(./lib ../lib);
use RRD::Simple 1.44 ();

my @correct_sources = (
		'bytesDropped,bytesIn,bytesOut,faultsPerSec,totalFaults',
		'bytesDropped,bytesIn,bytesOut,faultsPerSec',
		'bytesDropped,bytesIn,bytesOut,faultsPerSec',
		'bytesDropped,bytesIn,bytesOut,faultsPerSec,totalFaults',
	);

my $i = -1;
for my $on_missing_ds (('add','ignore','die',undef)) {
	$i++;

	unlink $rrdfile if -f $rrdfile;
	ok(my $rrd = RRD::Simple->new( file => $rrdfile, on_missing_ds => $on_missing_ds ),'new');

	ok($rrd->create($rrdfile, "year",
			bytesIn => 'GAUGE',
			bytesOut => 'GAUGE',
			faultsPerSec => 'COUNTER',
			bytesDropped => 'GAUGE'
		),'create');

	ok(join(',',sort $rrd->sources($rrdfile)) eq 'bytesDropped,bytesIn,bytesOut,faultsPerSec',
		'expected sources okay');

	SKIP: {
		my $info = {};
		ok($info = $rrd->info($rrdfile),'info');
	
	# add_source() now works on all current RRD versions
	#	skip("RRD file version $info->{rrd_version} is too new to add data source",2)
	#		if ($info->{rrd_version}+1-1) > 1;
	
		eval {
			$rrd->update($rrdfile,
					bytesIn => 10039,
					bytesOut => 389,
					totalFaults => 992
				);
		};
	
		ok(join(',',sort $rrd->sources($rrdfile)) eq $correct_sources[$i],
			'expected sources okay');
	
		ok($rrd->add_source($rrdfile,wibble => 'DERIVE'),'add_source()');
		ok(grep(/^wibble$/,$rrd->sources($rrdfile)),'added source okay')
	}
}

unlink $rrdfile if -f $rrdfile;

1;


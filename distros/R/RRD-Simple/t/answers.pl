# $Id: answers.pl 965 2007-03-01 19:11:23Z nicolaw $

%scheme_graphs = (
		'3years' => [ qw(daily weekly monthly annual 3years) ],
		'year'   => [ qw(daily weekly monthly annual) ],
		'month'  => [ qw(daily weekly monthly) ],
		'week'   => [ qw(daily weekly) ],
		'day'    => [ qw(daily) ],
	);

%retention_periods = (
	'3years' => 118195200,
	'mrtg'   => 69120000,
	'year'   => 39398400,
	'month'  => 3348000,
	'week'   => 756000,
	'day'    => 108000,);

%graph_return = (
	'daily' => [(
			'bytesIn min 100.00', 'bytesIn max 100.00', 'bytesIn last 100.00',
			'bytesOut min 50.00', 'bytesOut max 50.00', 'bytesOut last 50.00'
		)],
	'weekly' => [(
			'bytesIn min 100.00', 'bytesIn max 100.00', 'bytesIn last 100.00',
			'bytesOut min 50.00', 'bytesOut max 50.00', 'bytesOut last 50.00'
		)],
	'monthly' => [(
			'bytesIn min nan', 'bytesIn max nan', 'bytesIn last nan',
			'bytesOut min nan', 'bytesOut max nan', 'bytesOut last nan'
		)],
	'annual' => [(
			'bytesIn min nan', 'bytesIn max nan', 'bytesIn last nan',
			'bytesOut min nan', 'bytesOut max nan', 'bytesOut last nan'
		)],
	'3years' => [(
			'bytesIn min nan', 'bytesIn max nan', 'bytesIn last nan',
			'bytesOut min nan', 'bytesOut max nan', 'bytesOut last nan'
		)],
	);

@schemes = keys %retention_periods;

# Default values for 1.33 and higher
$rra = [
	{
		'xff'         => '0.5',
		'pdp_per_row' => 1,
		'cdp_prep'    => undef,
		'cf'          => 'AVERAGE',
		'rows'        => 800
	},
	{
		'xff'         => '0.5',
		'pdp_per_row' => 6,
		'cdp_prep'    => undef,
		'cf'          => 'AVERAGE',
		'rows'        => 800
	},
	{
		'xff'         => '0.5',
		'pdp_per_row' => 24,
		'cdp_prep'    => undef,
		'cf'          => 'AVERAGE',
		'rows'        => 800
	},
	{
		'xff'         => '0.5',
		'pdp_per_row' => 288,
		'cdp_prep'    => undef,
		'cf'          => 'AVERAGE',
		'rows'        => 800
	},
	{
		'xff'         => '0.5',
		'pdp_per_row' => 1,
		'cdp_prep'    => undef,
		'cf'          => 'MAX',
		'rows'        => 800
	},
	{
		'xff'         => '0.5',
		'pdp_per_row' => 6,
		'cdp_prep'    => undef,
		'cf'          => 'MAX',
		'rows'        => 800
	},
	{
		'xff'         => '0.5',
		'pdp_per_row' => 24,
		'cdp_prep'    => undef,
		'cf'          => 'MAX',
		'rows'        => 800
	},
	{
		'xff'         => '0.5',
		'pdp_per_row' => 288,
		'cdp_prep'    => undef,
		'cf'          => 'MAX',
		'rows'        => 800
	}];

# Old default values for 1.32
$rra = [
	{
		'xff'         => '0.5',
		'pdp_per_row' => 1,
		'cdp_prep'    => undef,
		'cf'          => 'AVERAGE',
		'rows'        => 1800
	},
	{
		'xff'         => '0.5',
		'pdp_per_row' => 30,
		'cdp_prep'    => undef,
		'cf'          => 'AVERAGE',
		'rows'        => 420
	},
	{
		'xff'         => '0.5',
		'pdp_per_row' => 120,
		'cdp_prep'    => undef,
		'cf'          => 'AVERAGE',
		'rows'        => 465
	},
	{
		'xff'         => '0.5',
		'pdp_per_row' => 1440,
		'cdp_prep'    => undef,
		'cf'          => 'AVERAGE',
		'rows'        => 456
	},
	{
		'xff'         => '0.5',
		'pdp_per_row' => 1,
		'cdp_prep'    => undef,
		'cf'          => 'MAX',
		'rows'        => 1800
	},
	{
		'xff'         => '0.5',
		'pdp_per_row' => 30,
		'cdp_prep'    => undef,
		'cf'          => 'MAX',
		'rows'        => 420
	},
	{
		'xff'         => '0.5',
		'pdp_per_row' => 120,
		'cdp_prep'    => undef,
		'cf'          => 'MAX',
		'rows'        => 465
	},
	{
		'xff'         => '0.5',
		'pdp_per_row' => 1440,
		'cdp_prep'    => undef,
		'cf'          => 'MAX',
		'rows'        => 456
	}] if $RRD::Simple::VERSION < 1.33;

1;

# perl -I./lib/ -MRRD::Simple=:all -e'for (qw(day week month year mrtg 3years)) { $x="f";unlink $x;create($x,$_,ds=>"COUNTER");print "Retention period in seconds for $_ => ".retention_period($x)."\n";}'

# RRD::Simple version 1.31 or less
#my %periods = (
#		'3years' => 164160000,
#		'year'   => 54446400,
#		'month'  => 18000000,
#		'week'   => 5400000,
#		'day'    => 900000,
#	);

# RRD::Simple version 1.32
#my %periods = (
#		'3years' => 118195200,
#		'mrtg'   => 69120000,
#		'year'   => 39398400,
#		'month'  => 3348000,
#		'week'   => 756000,
#		'day'    => 108000,
#	);



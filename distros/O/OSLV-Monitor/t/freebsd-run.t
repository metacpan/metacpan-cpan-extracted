#!perl
use 5.006;
use strict;
use warnings;
use Test::More;
use File::Temp   qw(tempdir);
use File::Slurp  qw(read_file);
use JSON         qw(decode_json);
use Scalar::Util qw(looks_like_number);

use OSLV::Monitor;
use OSLV::Monitor::Backends::FreeBSD;

if ( $^O ne 'freebsd' ) {
	plan skip_all => 'not freebsd';
}

sub jail_names {
	my $output = `/usr/sbin/jls -h --libxo json 2> /dev/null`;
	if ( $? != 0 ) {
		return undef;
	}

	my $jls;
	eval { $jls = decode_json($output); };
	if ( $@ || ref($jls) ne 'HASH' ) {
		return undef;
	}

	my @names;
	foreach my $jail ( @{ $jls->{'jail-information'}{jail} } ) {
		if ( defined( $jail->{name} ) && defined( $jail->{jid} ) ) {
			push( @names, $jail->{name} );
		}
	}

	return \@names;
} ## end sub jail_names

my $jails = jail_names();
if ( !defined($jails) ) {
	plan skip_all => 'jls is not usable';
}
if ( !defined( $jails->[0] ) ) {
	plan skip_all => 'no jails are running';
}

my $ps_test = `/bin/ps ax --libxo json -o pid 2> /dev/null`;
if ( $? != 0 || !defined($ps_test) || $ps_test !~ /\{/ ) {
	plan skip_all => 'ps is not usable';
}

plan tests => 19;

my @stats = (
	'copy-on-write-faults',         'cpu-time',
	'data-size',                    'elapsed-times',
	'involuntary-context-switches', 'major-faults',
	'minor-faults',                 'percent-cpu',
	'percent-memory',               'read-blocks',
	'received-messages',            'rss',
	'sent-messages',                'stack-size',
	'swaps',                        'system-time',
	'text-size',                    'user-time',
	'virtual-size',                 'voluntary-context-switches',
	'written-blocks',               'signals-taken',
	'procs',
);

sub new_backend {
	my $base_dir = $_[0];
	my $obj      = $_[1];

	if ( !defined($obj) ) {
		$obj = OSLV::Monitor->new( base_dir => $base_dir, backend => 'FreeBSD' );
	}

	return OSLV::Monitor::Backends::FreeBSD->new( base_dir => $base_dir, obj => $obj );
} ## end sub new_backend

#
# the first run has no proc cache to compute the counter deltas against, so
# nothing is reported for it
#

my $base_dir = tempdir( CLEANUP => 1 );
my $data     = new_backend($base_dir)->run;

is( ref($data),                         'HASH', 'run returns a hash ref' );
is( join( ', ', @{ $data->{errors} } ), '',     'the first run has no errors' );
is( scalar( keys( %{ $data->{oslvms} } ) ), 0, 'the first run reports no oslvms' );

my @non_zero;
foreach my $total ( sort( keys( %{ $data->{totals} } ) ) ) {
	if ( $data->{totals}{$total} != 0 ) {
		push( @non_zero, $total );
	}
}
is( join( ', ', @non_zero ), '', 'the first run has zeroed totals' );

ok( -f $base_dir . '/freebsd_proc_cache.json', 'the first run saved the proc cache' );

my $proc_cache;
eval { $proc_cache = decode_json( scalar( read_file( $base_dir . '/freebsd_proc_cache.json' ) ) ); };
is( ref($proc_cache), 'HASH', 'the saved proc cache decodes' );

# the per CPU idle threads make ps report about ncpu*100 for percent-cpu, so if
# it is being cached it is also being summed in and inflating everything
my @idle = grep { $_ =~ /\-\[idle\]$/ } keys( %{$proc_cache} );
is( join( ', ', @idle ), '', 'the idle process is not recorded' );

#
# the second run has the cache from the first, so it reports for real... a fresh
# backend object is used as that is how it is polled
#

$jails = jail_names();
$data  = new_backend($base_dir)->run;

is( join( ', ', @{ $data->{errors} } ), '', 'the second run has no errors' );
ok( scalar( keys( %{ $data->{oslvms} } ) ) > 0, 'the second run reports oslvms' );

my @missing;
foreach my $jail ( @{$jails} ) {
	if ( !defined( $data->{oslvms}{$jail} ) ) {
		push( @missing, $jail );
	}
}
is( join( ', ', @missing ), '', 'every jail jls listed is reported' );

#
# what each jail reports
#

my @bad_stats;
my @negative;
my @bad_paths;
my @dup_paths;
my @bad_ips;
my $procs = 0;
my $rss   = 0;
foreach my $jail ( sort( keys( %{ $data->{oslvms} } ) ) ) {
	my $oslvm = $data->{oslvms}{$jail};

	foreach my $stat (@stats) {
		if ( !defined( $oslvm->{$stat} ) || !looks_like_number( $oslvm->{$stat} ) ) {
			push( @bad_stats, $jail . '/' . $stat );
			next;
		}
		if ( $oslvm->{$stat} < 0 ) {
			push( @negative, $jail . '/' . $stat . '=' . $oslvm->{$stat} );
		}
	}

	# jls always reports a path for a jail, so one missing means the jls info was
	# not processed
	if ( ref( $oslvm->{path} ) ne 'ARRAY' || !defined( $oslvm->{path}[0] ) ) {
		push( @bad_paths, $jail );
	} else {
		my %seen;
		foreach my $path ( @{ $oslvm->{path} } ) {
			if ( $seen{$path} ) {
				push( @dup_paths, $jail . ' -> ' . $path );
			}
			$seen{$path} = 1;
		}
	}

	if ( ref( $oslvm->{ip} ) ne 'ARRAY' ) {
		push( @bad_ips, $jail . ' -> not a array' );
	} else {
		foreach my $ip ( @{ $oslvm->{ip} } ) {
			if ( ref($ip) ne 'HASH' || !defined( $ip->{ip} ) || $ip->{ip} eq '' ) {
				push( @bad_ips, $jail );
			}
		}
	}

	$procs = $procs + $oslvm->{procs};
	$rss   = $rss + $oslvm->{rss};
} ## end foreach my $jail ( sort( keys( %{ $data->{oslvms}...})))

is( join( ', ', @bad_stats ), '', 'every oslvm has a numeric value for every stat' );
is( join( ', ', @negative ),  '', 'no oslvm has a negative value for a stat' );
is( join( ', ', @bad_paths ), '', 'every oslvm has a path' );
is( join( ', ', @dup_paths ), '', 'no oslvm has a duplicate path' );
is( join( ', ', @bad_ips ),   '', 'every ip for a oslvm has the ip it is for' );

# the stats for each jail are summed into the totals as they are summed into the
# jail, so this only holds if neither is dropping or double counting anything
is( $procs, $data->{totals}{procs}, 'the procs for each oslvm sum to the total' );
is( $rss,   $data->{totals}{rss},   'the rss for each oslvm sums to the total' );

#
# excludes are honored, as those are checked by the backend and not by whatever
# is calling it
#

my $excluded = $jails->[0];
$base_dir = tempdir( CLEANUP => 1 );
my $obj = OSLV::Monitor->new(
	base_dir => $base_dir,
	backend  => 'FreeBSD',
	exclude  => [ '^' . quotemeta($excluded) . '$' ]
);

new_backend( $base_dir, $obj )->run;
$data = new_backend( $base_dir, $obj )->run;

ok( !defined( $data->{oslvms}{$excluded} ), 'a excluded jail is not reported' );
is( scalar( keys( %{ $data->{oslvms} } ) ),
	scalar( @{$jails} ) - 1,
	'every jail other than the excluded one is reported'
);

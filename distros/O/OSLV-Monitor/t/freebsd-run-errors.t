#!perl
use 5.006;
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Slurp qw(write_file);
use JSON        qw(encode_json);

use OSLV::Monitor;
use OSLV::Monitor::Backends::FreeBSD;

# with no jls to call, run takes the path where the jls output can not be
# decoded, which is what it will hit any time jls is not there or is broken... it
# must come back with a sane data structure and a error instead of dying
if ( -e '/usr/sbin/jls' ) {
	plan skip_all => 'jls is present, so the undecodable jls output path is not reachable';
}

plan tests => 9;

sub new_backend {
	my $base_dir = $_[0];
	my $obj      = OSLV::Monitor->new( base_dir => $base_dir, backend => 'FreeBSD' );
	return OSLV::Monitor::Backends::FreeBSD->new( base_dir => $base_dir, obj => $obj );
}

#
# no jls means the output can not be decoded
#

my $base_dir = tempdir( CLEANUP => 1 );
my $data     = new_backend($base_dir)->run;

is( ref($data), 'HASH', 'run returns a hash ref' );

my @decode_errors = grep { $_ =~ /decoding output from "jls/ } @{ $data->{errors} };
is( scalar(@decode_errors), 1, 'run reports a error for the undecodable jls output' );

is( scalar( keys( %{ $data->{oslvms} } ) ), 0, 'run reports no oslvms' );

my @non_zero;
foreach my $total ( sort( keys( %{ $data->{totals} } ) ) ) {
	if ( $data->{totals}{$total} != 0 ) {
		push( @non_zero, $total );
	}
}
is( join( ', ', @non_zero ), '', 'the totals are all zero' );

# what the backend can provide is not conditional on anything, so it is always
# the same and is what the consumer keys off of for what to graph
is_deeply(
	$data->{has},
	{
		'linux_mem_stats' => 0,
		'rwdops'          => 0,
		'rwdbytes'        => 0,
		'rwdblocks'       => 1,
		'signals-taken'   => 1,
		'recv_sent_msgs'  => 1,
		'cows'            => 1,
		'stack-size'      => 1,
		'swaps'           => 1,
		'sock'            => 0,
	},
	'has is filled in'
);

is( $data->{cache_failure}, 0, 'cache_failure is 0 when there is no proc cache yet' );

#
# a corrupt proc cache is a cache failure and not a death... a truncated write is
# how one is likely to happen
#

$base_dir = tempdir( CLEANUP => 1 );
write_file( $base_dir . '/freebsd_proc_cache.json', '{"foo":' );
$data = new_backend($base_dir)->run;

is( $data->{cache_failure}, 1, 'a corrupt proc cache is a cache failure' );
my @cache_errors = grep { $_ =~ /reading proc cache/ } @{ $data->{errors} };
is( scalar(@cache_errors), 1, 'a corrupt proc cache is reported as a error' );

#
# a good proc cache is not a cache failure
#

$base_dir = tempdir( CLEANUP => 1 );
write_file( $base_dir . '/freebsd_proc_cache.json', encode_json( { '1-0-0-foo-init' => { 'cpu-time' => 1 } } ) );
$data = new_backend($base_dir)->run;

is( $data->{cache_failure}, 0, 'a readable proc cache is not a cache failure' );

#!perl
use 5.014;
use strict;
use warnings;
use FindBin;
use lib $FindBin::Bin . '/lib';
use Test::More;
use Monitoring::Sneck::Checks;

my $run = sub { return Monitoring::Sneck::Checks->run(@_) };

# not loaded, -1
foreach my $bad (
	[ 'base',          qr/base is what checks are built on/ ],
	[ 'no_such_check', qr/failed to load Monitoring::Sneck::Checks::no_such_check/ ],
	[ 'broken',        qr/broken on purpose/ ],
	[ 'not_a_check',   qr/is not a check/ ],
	[ '../../etc',     qr/is not valid/ ],
	[ 'Http',          qr/is not valid/ ],
	[ 'http::foo',     qr/is not valid/ ],
	[ undef,           qr/is not valid/ ]
	)
{
	my $return = $run->( check => $bad->[0] );
	is( $return->{code}, -1, 'check ' . ( $bad->[0] // 'undef' ) . ' is -1' );
	like( $return->{stderr}, $bad->[1], 'and why' );
	is( $return->{combined}, $return->{stderr}, 'combined is stderr' );
	is( $return->{stdout},   '',                'nothing on stdout' );
} ## end foreach my $bad ( [ 'base', qr/base is what checks are built on/...])
# load on its own, as sneck_check uses it for --help
is( Monitoring::Sneck::Checks->load('testing'), 'Monitoring::Sneck::Checks::testing', 'load returns the module' );
ok( !eval { Monitoring::Sneck::Checks->load('base'); 1 }, 'load dies on base' );
like( $@, qr/base is what checks are built on/, 'and says why' );

# list, which reads the files and loads none of them
my $checks = Monitoring::Sneck::Checks->list;
is( ref($checks),         'HASH',                                       'list returns a hash ref' );
is( $checks->{file_mode}, 'checks the mode, owner, and group of files', 'with what a check is for' );
is( $checks->{testing},   '',                                           'empty for one with no POD' );
ok( exists( $checks->{broken} ),                'a check that can not load is still listed' );
ok( !exists( $checks->{base} ),                 'base is not' );
ok( !$INC{'Monitoring/Sneck/Checks/broken.pm'}, 'and nothing was loaded' );

my $return = $run->( check => 'testing', args => q{--out 'unbalanced} );
is( $return->{code},   3,                                                 'unbalanced quotes in args are UNKNOWN' );
is( $return->{stderr}, "TESTING UNKNOWN - args have unbalanced quotes\n", 'and says so' );
is_deeply(
	$run->( check => 'testing', args => q{--out "it's \"here\"" --err 'a b'} ),
	{ code => 0, stdout => qq{it's "here"\n}, stderr => "a b\n", combined => qq{it's "here"\na b\n} },
	'quoted string args split by Getopt::Long'
);

# codes
$return = $run->( check => 'testing', args => [ '--code', 2, '--out', 'some output', '--err', 'an error' ] );
is_deeply(
	$return,
	{ code => 2, stdout => "some output\n", stderr => "an error\n", combined => "some output\nan error\n" },
	'code, stdout, stderr, and combined'
);
is( $run->( check => 'testing', args => '--code 1' )->{code}, 1, 'args as a string' );
foreach my $odd ( 4, -1, 'undef', 'yes' ) {
	$return = $run->( check => 'testing', args => [ '--code', $odd ] );
	is( $return->{code}, 3, 'returning ' . $odd . ' is UNKNOWN' );
	like( $return->{stderr}, qr/\ATESTING UNKNOWN - returned "\Q$odd\E", not 0, 1, 2, or 3/, 'and says so' );
}

# dying, bad args, and timing out are UNKNOWN
$return = $run->( check => 'testing', args => [ '--out', 'before', '--die', 'it broke' ] );
is( $return->{code},     3,                                      'dying is UNKNOWN' );
is( $return->{combined}, "before\nTESTING UNKNOWN - it broke\n", 'output before it died is kept' );
$return = $run->( check => 'testing', args => [ '--nope', 'extra', '-w', 'bad' ] );
is( $return->{code}, 3, 'bad args are UNKNOWN' );
is(
	$return->{stderr},
	'TESTING UNKNOWN - Unknown option: nope, unexpected arg "extra", --warning "bad" is not a valid range' . "\n",
	'every problem with them listed'
);
$return = $run->( check => 'testing', args => [ '--sleep', 3 ], timeout => 0.5 );
is( $return->{code}, 3, 'timing out is UNKNOWN' );
like( $return->{stderr}, qr/timed out after 0.5 seconds/, 'and says so' );
is( alarm(0), 0, 'no alarm left behind' );

# a alarm going off right as the eval ends, as after the check died on its own, must not get out of run,
# with the cancel after the eval standing in for it going off then
{
	no warnings 'redefine';
	my $armed = 0;
	local *Time::HiRes::alarm = sub {
		my ($seconds) = @_;
		if ($seconds) { $armed = 1; return 0 }
		return 0 if !$armed;
		$armed = 0;
		$SIG{ALRM}->();
		return 0;
	};
	$return = eval { $run->( check => 'testing', args => [ '--die', 'it broke' ], timeout => 0.5 ) };
	is( $@,                          '', 'a alarm going off as the eval ends stays in run' );
	is( ( $return // {} )->{stderr}, "TESTING UNKNOWN - it broke\n", 'and what the check died of is what is said' );
}
my $started = time;
$return = $run->(
	check   => 'testing',
	args    => [ '--run', $^X, '--run', '-e', '--run', '$SIG{TERM} = "IGNORE"; sleep 30' ],
	timeout => 0.5
);
is( $return->{code}, 3, 'a command that hangs times out' );
like( $return->{stderr}, qr/timed out after 0.5 seconds/, 'and says so' );
cmp_ok( time - $started, '<', 10, 'the command was killed, not waited for' );
is(
	$run->( check => 'testing', args => [ '--run', $^X, '--run', '-e', '--run', 'print "ran\n"' ] )->{stdout},
	"exit 0\nran\n",
	'a command that finishes runs as before'
);

# stray prints and warnings are caught
$return = $run->( check => 'testing', args => [ '--print', "printed\n", '--warn', 'warned' ] );
is( $return->{stdout},   "printed\n",         'printed goes to stdout' );
is( $return->{stderr},   "warned\n",          'warned goes to stderr' );
is( $return->{combined}, "printed\nwarned\n", 'and combined' );

# finish and perfdata through a check
$return = $run->( check => 'testing', args => [ '--value', 15, '-w', 10, '-c', 20 ] );
is( $return->{code},   1,                                                  'value over warning' );
is( $return->{stdout}, "TESTING WARNING - value is 15 | value=15;10;20\n", 'status line and perfdata' );

done_testing();

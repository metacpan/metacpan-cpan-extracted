#!perl
use 5.014;
use strict;
use warnings;
use FindBin;
use lib $FindBin::Bin . '/lib';
use Test::More;
use TestTmp;
use Monitoring::Sneck::Checks;
use Monitoring::Sneck::Checks::base;

my $dir = TestTmp::dir();
local $Monitoring::Sneck::Checks::base::STATE_DIR = $dir . '/state';
my $log    = $dir . '/auth.log';
my $append = sub {
	open( my $fh, '>>', $log ) or die($!);
	print $fh @_;
	close($fh);
};
my $run = sub { return Monitoring::Sneck::Checks->run( check => 'log', args => [ '-f', $log, @_ ] ) };

$append->("old Failed password for root\n");
my $return = $run->( '-r', 'Failed password', '-x', 'invalid user' );
is( $return->{code},   0, 'first time starts at the end' );
is( $return->{stdout}, "LOG OK - 0 matching lines in $log, starting at the end of it | lines=0;0;;0\n", 'output' );
ok( -d $dir . '/state', 'state directory made' );

$append->(
	"Accepted publickey for admin\nFailed password for root from 192.0.2.7\nFailed password for invalid user test from 192.0.2.8\nhalf a line"
);
$return = $run->( '-r', 'Failed password', '-x', 'invalid user' );
is( $return->{code}, 1, 'a new match is WARNING' );
is(
	$return->{stdout},
	"LOG WARNING - 1 matching line in $log | lines=1;0;;0\nFailed password for root from 192.0.2.7\n",
	'the line listed, excluded left out'
);
$append->(" finished, Failed password\n");
is(
	$run->( '-r', 'Failed password', '-x', 'invalid user' )->{stdout},
	"LOG WARNING - 1 matching line in $log | lines=1;0;;0\nhalf a line finished, Failed password\n",
	'a line half written waits for the rest'
);
is( $run->( '-r', 'Failed password', '-x', 'invalid user' )->{code}, 0, 'nothing new is OK' );

# hold
is( $run->( '-r', 'Failed password',       '-x', 'admin' )->{code}, 0, 'other excludes have their own state' );
is( $run->( '-r', 'Failed password again', '-H', 600 )->{code},     0, 'other regexes have their own state' );
$append->("Failed password again\n");
is( $run->( '-r', 'Failed password again', '-H', 600 )->{code}, 1, 'matched' );
like(
	$run->( '-r', 'Failed password again', '-H', 600 )->{stdout},
	qr/\ALOG WARNING - 1 matching line in \S+, held from \d+ seconds ago \| lines=0;0;;0\nFailed password again\n\z/,
	'held'
);

# rotation, ranges, and lines
my $state = $dir . '/own.json';
$run->( '-r', 'x', '-s', $state );
unlink($log);
$append->( map { "x $_\n" } 1 .. 8 );
$return = $run->( '-r', 'x', '-s', $state, '-c', 5, '-n', 2 );
is( $return->{code}, 2, 'rotated log read from the start, over critical' );
is(
	$return->{stdout},
	"LOG CRITICAL - 8 matching lines in $log | lines=8;0;5;0\nx 1\nx 2\nand 6 more\n",
	'cut at --lines'
);
open( my $fh, '>', $log ) or die($!);
print $fh "x 9\n";
close($fh);
is(
	$run->( '-r', 'x', '-s', $state )->{stdout},
	"LOG WARNING - 1 matching line in $log | lines=1;0;;0\nx 9\n",
	'truncated read from the start'
);
is( $run->( '-r', 'x', '-s', $dir . '/fresh.json', '--from-start' )->{code}, 1, '--from-start' );

# problems
like( $run->( '-r', 'x', '-s', $dir . '/nope/x.json' )->{stdout}, qr/\ALOG OK/, 'state directory made for --state' );
open( $fh, '>', $dir . '/broken.json' ) or die($!);
print $fh "not json\n";
close($fh);
like(
	$run->( '-r', 'x', '-s', $dir . '/broken.json' )->{stdout},
	qr/\ALOG UNKNOWN - can not read the state in/,
	'bad state'
);
like(
	Monitoring::Sneck::Checks->run( check => 'log', args => [ '-f', $dir . '/missing.log', '-r', 'x' ] )->{stdout},
	qr/\ALOG UNKNOWN - can not read \S+missing.log/,
	'log missing'
);
is( $run->()->{code},            3, 'no --regex' );
is( $run->( '-r', '(' )->{code}, 3, 'bad --regex' );

done_testing();

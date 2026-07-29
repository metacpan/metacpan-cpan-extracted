#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

BEGIN {
	$ENV{ANSI_COLORS_DISABLED} = 1;
}

plan tests => 38;

use_ok('Proc::ProcessTable::ncps') || print "Bail out!\n";

#
# new, defaults, and args handling
#
my $ncps = Proc::ProcessTable::ncps->new;
isa_ok( $ncps, 'Proc::ProcessTable::ncps' );
is( $ncps->{stats},        0, 'stats defaults to 0' );
is( $ncps->{jid},          0, 'jid defaults to 0' );
is( $ncps->{tty},          0, 'tty defaults to 0' );
is( $ncps->{major_faults}, 0, 'major_faults defaults to 0' );

my $ncps_args = Proc::ProcessTable::ncps->new( { stats => 1, tty => 1 } );
is( $ncps_args->{stats},        1, 'stats arg is used' );
is( $ncps_args->{major_faults}, 0, 'unspecified args keep their defaults' );

#
# nextColor
#
my $ncps_color = Proc::ProcessTable::ncps->new;
is( $ncps_color->nextColor, 'BRIGHT_YELLOW',  'first color' );
is( $ncps_color->nextColor, 'BRIGHT_CYAN',    'second color' );
is( $ncps_color->nextColor, 'BRIGHT_MAGENTA', 'third color' );
is( $ncps_color->nextColor, 'BRIGHT_BLUE',    'fourth color' );
is( $ncps_color->nextColor, 'BRIGHT_YELLOW',  'colors wrap around' );

#
# timeString
#
# on Linux the time field is in microseconds and timeString expects that
my $time_multiplier = 1;
if ( $^O =~ /^linux$/ ) {
	$time_multiplier = 1000000;
}
is( $ncps->timeString( 0 * $time_multiplier ),      '0',       'timeString zero' );
is( $ncps->timeString( 59.6 * $time_multiplier ),   '59.6',    'timeString fractional seconds' );
is( $ncps->timeString( 59.678 * $time_multiplier ), '59.68',   'timeString rounds to two decimal places' );
is( $ncps->timeString( 125 * $time_multiplier ),    '2:5',     'timeString minutes' );
is( $ncps->timeString( 3725.5 * $time_multiplier ), '1:2:5.5', 'timeString hours with fractional seconds' );
is( $ncps->timeString( 36061 * $time_multiplier ),  '10:1:1',  'timeString ten plus hours' );

#
# memString
#
is( $ncps->memString( 5000,          'rss' ), '5000',     'memString bytes' );
is( $ncps->memString( 8523.33333,    'rss' ), '8523.33',  'memString rounds fractional bytes' );
is( $ncps->memString( 10000,         'rss' ), '10k',      'memString k threshold' );
is( $ncps->memString( 123456,        'rss' ), '123.456k', 'memString k' );
is( $ncps->memString( 123456.789012, 'rss' ), '123.457k', 'memString rounds fractional k' );
is( $ncps->memString( 15892000,      'vsz' ), '15.892M',  'memString M' );
is( $ncps->memString( 5000000000,    'vsz' ), '5.000G',   'memString G' );

#
# startString
#
like( $ncps->startString(time),      qr/^[0-9]{2}\:[0-9]{2}$/,           'startString for today' );
like( $ncps->startString(946684800), qr/^[0-9]{8}\-[0-9]{2}\:[0-9]{2}$/, 'startString for a previous year' );

#
# physmem
#
my $physmem = Proc::ProcessTable::ncps->physmem;
ok( ( !defined($physmem) ) || ( $physmem =~ /^[0-9]+$/ ), 'physmem is undef or numeric' );

#
# run
#
my @warnings;
local $SIG{__WARN__} = sub { push( @warnings, $_[0] ) };

my $ncps_run   = Proc::ProcessTable::ncps->new( { stats => 1 } );
my $run_output = $ncps_run->run;
ok( defined($run_output) && ( $run_output ne '' ), 'run returns output' );
like( $run_output, qr/PID/,    'run output has a PID header' );
like( $run_output, qr/StdDev/, 'run output has a stats section when asked for' );
is( scalar(@warnings), 0, 'run does not warn' ) || diag( join( '', @warnings ) );

#
# run with a match that matches nothing
#
@warnings = ();
my $ncps_empty = Proc::ProcessTable::ncps->new(
	{
		stats => 1,
		match => {
			checks => [
				{
					type   => 'PID',
					invert => 0,
					args   => {
						pids => [-42],
					},
				},
			],
		},
	}
);
my $empty_output = $ncps_empty->run;
ok( defined($empty_output), 'run with a empty match returns output' );
unlike( $empty_output, qr/StdDev/, 'no stats section for a empty match' );
is( scalar(@warnings), 0, 'run with a empty match does not warn' ) || diag( join( '', @warnings ) );

#
# a dying match check warns once instead of failing silently
#
@warnings = ();
my $ncps_death = Proc::ProcessTable::ncps->new(
	{
		match => {
			checks => [
				{
					type   => 'PID',
					invert => 0,
					args   => {
						pids => [1],
					},
				},
			],
		},
	}
);
{
	no warnings qw( redefine once );
	local *Proc::ProcessTable::Match::match = sub { die('test match death') };
	$ncps_death->run;
}
is( scalar(@warnings), 1, 'a dying match check warns once' );
like( $warnings[0], qr/test match death/, 'the match warning includes the error' );

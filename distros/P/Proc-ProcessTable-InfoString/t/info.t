#!perl
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

use Proc::ProcessTable;
use Proc::ProcessTable::InfoString;

# builds a synthetic process object; real tables are OS dependent while
# these run anywhere, with $^O forced per test block
sub fake_proc {
	return bless(
				 {
				  pid    => 999999999,
				  rss    => 4096,
				  sess   => 1000,
				  ttynum => -1,
				  flags  => '0x0',
				  state  => 'sleep',
				  @_,
				  },
				 'Proc::ProcessTable::Process'
				 );
}

my $info_string_handler = Proc::ProcessTable::InfoString->new;
isa_ok( $info_string_handler, 'Proc::ProcessTable::InfoString' );

#
# input validation
#
is( $info_string_handler->info(undef),          '', 'undef proc returns empty string' );
is( $info_string_handler->info( {} ),           '', 'non-Process ref returns empty string' );
is( $info_string_handler->info('some string'),  '', 'non-ref returns empty string' );

#
# state mapping, on a OS with no flag handling so only the state shows
#
{
	local $^O = 'netbsd';
	my %state_to_expected = (
							 'sleep'       => 'S ',
							 'zombie'      => 'Z ',
							 'wait'        => 'W ',
							 'run'         => 'R ',
							 'stop'        => 'T ',
							 'idle'        => 'I ',
							 'lock'        => 'L ',
							 'defunct'     => 'Z ',
							 'uwait'       => 'D ',
							 'tracingstop' => 't ',
							 'dead'        => 'X ',
							 'wakekill'    => 'K ',
							 'parked'      => 'P ',
							 'meepmeep'    => '? ',
							 );
	foreach my $state ( sort( keys(%state_to_expected) ) ) {
		is( $info_string_handler->info( fake_proc( state => $state ) ),
			$state_to_expected{$state}, "state '$state'" );
	}
	is( $info_string_handler->info( fake_proc( state => undef ) ), '? ', 'undef state' );

	# wchan comes from the object on non-Linux systems
	is( $info_string_handler->info( fake_proc( wchan => 'select' ) ), 'S select', 'wchan appended' );
	is( $info_string_handler->info( fake_proc() ), 'S ', 'missing wchan field handled' );

	# swapped out marker
	is( $info_string_handler->info( fake_proc( rss => 0 ) ), 'SO ', 'rss 0 gets O' );
	is( $info_string_handler->info( fake_proc( rss => 0, state => 'zombie' ) ),  'Z ', 'zombie rss 0 gets no O' );
	is( $info_string_handler->info( fake_proc( rss => 0, state => 'defunct' ) ), 'Z ', 'defunct rss 0 gets no O' );
}

#
# FreeBSD flag handling... flags is a 0x prefixed hex string there
#
{
	local $^O = 'freebsd';
	my @freebsd_tests = (
						 [ 'session leader',        fake_proc( sess => 999999999 ),                        'Ss ' ],
						 [ 'has controlling tty',   fake_proc( flags => '0x2' ),                           'S+ ' ],
						 [ 'active controlling tty', fake_proc( flags => '0x2', ttynum => 34816 ),         'S+c ' ],
						 [ 'being forked, P_PPWAIT', fake_proc( flags => '0x10' ),                         'SF ' ],
						 [ 'exiting, P_WEXIT',      fake_proc( flags => '0x2000' ),                        'SE ' ],
						 [ 'kernel proc no O, P_KPROC', fake_proc( flags => '0x4', rss => 0 ),             'S ' ],
						 [ 'traced, P_TRACED',      fake_proc( flags => '0x800' ),                         'SX ' ],
						 [ 'advisory lock, P_ADVLOCK', fake_proc( flags => '0x1' ),                        'SL ' ],
						 );
	foreach my $freebsd_test (@freebsd_tests) {
		my ( $description, $proc, $expected ) = @{$freebsd_test};
		is( $info_string_handler->info($proc), $expected, "freebsd: $description" );
	}
}

#
# Linux flag handling... flags is a plain decimal number there
#
{
	local $^O = 'linux';
	my @linux_tests = (
					   [ 'session leader',           fake_proc( flags => 0, sess => 999999999, ttynum => 0 ), 'Ss ' ],
					   [ 'has controlling tty',      fake_proc( flags => 0, ttynum => 34816 ),                'S+ ' ],
					   [ 'exiting, PF_EXITING',      fake_proc( flags => 0x4, ttynum => 0 ),                  'SE ' ],
					   [ 'forked no exec yet',       fake_proc( flags => 0x40, ttynum => 0 ),                 'SF ' ],
					   [ 'kernel thread no O or F',  fake_proc( flags => 0x00200040, ttynum => 0, rss => 0, state => 'idle' ), 'I ' ],
					   [ 'traced via tracer field',  fake_proc( flags => 0, ttynum => 0, tracer => 123 ),     'SX ' ],
					   [ 'tracer field absent',      fake_proc( flags => 0, ttynum => 0 ),                    'S ' ],
					   [ 'tracer zero',              fake_proc( flags => 0, ttynum => 0, tracer => 0 ),       'S ' ],
					   );
	foreach my $linux_test (@linux_tests) {
		my ( $description, $proc, $expected ) = @{$linux_test};
		is( $info_string_handler->info($proc), $expected, "linux: $description" );
	}
}

#
# colors
#
{
	local $^O = 'netbsd';
	require Term::ANSIColor;
	my $colored_handler = Proc::ProcessTable::InfoString->new( { flags_color => 'red', wchan_color => 'blue' } );
	my $expected =
		Term::ANSIColor::color('red') . 'S'
		. Term::ANSIColor::color('reset') . ' '
		. Term::ANSIColor::color('blue') . 'select'
		. Term::ANSIColor::color('reset');
	is( $colored_handler->info( fake_proc( wchan => 'select' ) ), $expected, 'flags_color and wchan_color applied' );
	is( $info_string_handler->info( fake_proc( wchan => 'select' ) ), 'S select', 'no colors when not asked for' );
}

done_testing;

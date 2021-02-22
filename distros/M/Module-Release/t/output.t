#!/usr/bin/perl
use strict;
use warnings;

use Test::More 1.0 'no_plan';
use Test::Output;

use Cwd;

require 't/lib/setup_common.pl';

my $class = 'Module::Release';
subtest setup => sub {
	use_ok( $class );
	can_ok( $class, 'new' );
	};

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
my @fh_subs = qw(
	output_fh
	null_fh
	debug_fh
	);

my @toggle_subs = map { $_, "turn_${_}_on", "turn_${_}_off" }
	qw(quiet debug);

my @internal = qw(
	_print
	_dashes
	_debug
	_die
	_warn
	);

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Create test object
my $release = $class->new;
isa_ok( $release, $class );

can_ok( $release, @fh_subs, @toggle_subs, @internal );

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Variations on settings. Each should return something that can
# print
$release->turn_quiet_on;
$release->turn_debug_on;

my @test_pairs =
	map { [ "turn_quiet_$_->[0]", "turn_debug_$_->[1]" ] }
		(
		[ qw(off off) ],
		[ qw(on  off) ],
		[ qw(off  on) ],
		[ qw( on  on) ]
		);

foreach my $pair ( @test_pairs )
	{
	#diag( "Trying @$pair" );
	$release->$_() for @$pair;

	foreach my $sub ( @fh_subs )
		{
		#diag( "Trying $sub" );
		ok( defined $release->$sub(), "$sub returns something that is defined" );
		can_ok( $release->$sub(), 'print' );

		my $fh = $release->$sub();
		my $class = ref $fh;

		{
		no warnings; # IO::Null emits warning because it's not an open filehandle

		ok(
			eval { print { $release->$sub() } ''; 1},
			"print for $sub seems to work fine"
			);
		}

		}
	}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Ways that I can get the null filehandle
{
$release->turn_quiet_on;
isa_ok( $release->null_fh,   'IO::Null' );
isa_ok( $release->output_fh, 'IO::Null' );
}

{
$release->turn_debug_off;
isa_ok( $release->null_fh,   'IO::Null' );
isa_ok( $release->debug_fh,  'IO::Null' );
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Fallback filehandles
{
$release->turn_quiet_off;
my $old_output = $release->{output_fh};
$release->{output_fh} = undef;
can_ok( $release->output_fh, 'print' );
$release->{output_fh} = $old_output;
}

{
$release->turn_debug_on;
$release->{debug_fh} = undef;
can_ok( $release->debug_fh, 'print' );
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Now test the output when it should output
{
$release->turn_quiet_off;
can_ok( $release->output_fh, 'print' );
stdout_is { $release->_print( 'Buster' ) } 'Buster';
}

{
$release->turn_debug_on;
can_ok( $release->debug_fh, 'print' );
stderr_is { $release->_debug( 'Buster' ) } 'Buster';
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Now test the output when it should not output
{
$release->turn_quiet_on;
can_ok( $release->output_fh, 'print' );
stdout_is { $release->_print( 'Buster' ) } '';
stderr_is { $release->_warn(  'Mimi'   ) } '';
}

{
$release->turn_debug_off;
can_ok( $release->debug_fh, 'print' );
stderr_is { $release->_debug( 'Buster' ) } '';
}

{
$release->turn_quiet_off;
stderr_like { $release->_warn(  'Mimi'   ) } qr/\QMimi at $0 line \E\d+/;
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# dashes
like( $release->_dashes, qr/-{2,}/, "There are dashes from _dashes" );

__END__


# Declare our package
package POE::Devel::Benchmarker::GetInstalledLoops;
use strict; use warnings;

# Initialize our version
use vars qw( $VERSION );
$VERSION = '0.05';

# auto-export the only sub we have
use base qw( Exporter );
our @EXPORT = qw( getPOEloops );

# Import what we need from the POE namespace
use POE qw( Session Filter::Line Wheel::Run );
use base 'POE::Session::AttributeBased';

# Get the utils
use POE::Devel::Benchmarker::Utils qw ( knownloops );

# analyzes the installed perl directory for available loops
sub getPOEloops {
	my $quiet_mode = shift;
	my $forceloops = shift;

	# create our session!
	POE::Session->create(
		POE::Devel::Benchmarker::GetInstalledLoops->inline_states(),
		'heap'	=>	{
			'quiet_mode'	=> $quiet_mode,
			'loops'		=> $forceloops,
		},
	);
}

# Starts up our session
sub _start : State {
	# set our alias
	$_[KERNEL]->alias_set( 'Benchmarker::GetInstalledLoops' );

	# load our known list of loops
	# known impossible loops:
	#	XS::EPoll ( must be POE > 1.003 and weird way of loading )
	#	XS::Poll ( must be POE > 1.003 and weird way of loading )
	if ( ! defined $_[HEAP]->{'loops'} ) {
		$_[HEAP]->{'loops'} = knownloops();
	}

	# First of all, we need to find out what loop libraries are installed
	$_[HEAP]->{'found_loops'} = [];
	$_[KERNEL]->yield( 'find_loops' );

	return;
}

sub _stop : State {
	# tell the wheel to kill itself
	if ( defined $_[HEAP]->{'WHEEL'} ) {
		$_[HEAP]->{'WHEEL'}->kill( 9 );
		undef $_[HEAP]->{'WHEEL'};
	}

	return;
}

# loops over the "known" loops and sees if they are installed
sub find_loops : State {
	# get the loop to test
	$_[HEAP]->{'current_loop'} = shift @{ $_[HEAP]->{'loops'} };

	# do we have something to test?
	if ( ! defined $_[HEAP]->{'current_loop'} ) {
		# we're done!
		$_[KERNEL]->alias_remove( 'Benchmarker::GetInstalledLoops' );
		$_[KERNEL]->post( 'Benchmarker', 'found_loops', $_[HEAP]->{'found_loops'} );
		return;
	} else {
		if ( ! $_[HEAP]->{'quiet_mode'} ) {
			print "[LOOPSEARCH] Trying to find if POE::Loop::" . $_[HEAP]->{'current_loop'} . " is installed...\n";
		}

		# set the flag
		$_[HEAP]->{'test_failure'} = 0;
	}

	# Okay, create the wheel::run to handle this
	$_[HEAP]->{'WHEEL'} = POE::Wheel::Run->new(
		'Program'	=>	$^X,
		'ProgramArgs'	=>	[	'-MPOE',
						'-MPOE::Loop::' . $_[HEAP]->{'current_loop'},
						'-e',
						'1',
					],

		# Kill off existing FD's
		'CloseOnCall'	=>	1,

		# setup our data handlers
		'StdoutEvent'	=>	'Got_STDOUT',
		'StderrEvent'	=>	'Got_STDERR',

		# the error handler
		'ErrorEvent'	=>	'Got_ERROR',
		'CloseEvent'	=>	'Got_CLOSED',

		# set our filters
		'StderrFilter'	=>	POE::Filter::Line->new(),
		'StdoutFilter'	=>	POE::Filter::Line->new(),
	);
	if ( ! defined $_[HEAP]->{'WHEEL'} ) {
		die '[LOOPSEARCH] Unable to create a new wheel!';
	} else {
		# smart CHLD handling
		if ( $_[KERNEL]->can( "sig_child" ) ) {
			$_[KERNEL]->sig_child( $_[HEAP]->{'WHEEL'}->PID => 'Got_CHLD' );
		} else {
			$_[KERNEL]->sig( 'CHLD', 'Got_CHLD' );
		}
	}
	return;
}

# Got a CHLD event!
sub Got_CHLD : State {
	$_[KERNEL]->sig_handled();
	return;
}

# Handles child STDERR output
sub Got_STDERR : State {
	my $input = $_[ARG0];

	# since we got an error, must be a failure
	$_[HEAP]->{'test_failure'} = 1;

	return;
}

# Handles child STDOUT output
sub Got_STDOUT : State {
	my $input = $_[ARG0];

	return;
}

# Handles child error
sub Got_ERROR : State {
	# Copied from POE::Wheel::Run manpage
	my ( $operation, $errnum, $errstr ) = @_[ ARG0 .. ARG2 ];

	# ignore exit 0 errors
	if ( $errnum != 0 ) {
		warn "Wheel::Run got an $operation error $errnum: $errstr\n";
	}

	return;
}

# Handles child DIE'ing
sub Got_CLOSED : State {
	# Get rid of the wheel
	undef $_[HEAP]->{'WHEEL'};

	# Did we pass this test or not?
	if ( ! $_[HEAP]->{'test_failure'} ) {
		push( @{ $_[HEAP]->{'found_loops'} }, $_[HEAP]->{'current_loop'} );
	}

	# move on to the next loop
	$_[KERNEL]->yield( 'find_loops' );
	return;
}

1;
__END__
=head1 NAME

POE::Devel::Benchmarker::GetInstalledLoops - Automatically detects the installed POE loops

=head1 SYNOPSIS

	Don't use this module directly. Please use POE::Devel::Benchmarker.

=head1 ABSTRACT

This package implements the guts of searching for POE loops via fork/exec.

=head1 EXPORT

Automatically exports the getPOEloops() sub

=head1 SEE ALSO

L<POE::Devel::Benchmarker>

=head1 AUTHOR

Apocalypse E<lt>apocal@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2009 by Apocalypse

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut


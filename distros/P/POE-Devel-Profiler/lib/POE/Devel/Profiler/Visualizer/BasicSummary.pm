# Declare our package
package POE::Devel::Profiler::Visualizer::BasicSummary;

# Standard stuff to catch errors
use strict qw(subs vars refs);				# Make sure we can't mess up
use warnings FATAL => 'all';				# Enable warnings to catch errors

# Initialize our version
our $VERSION = '0.01';

# Okay, we need to receive the arguments
sub GET_ARGS {
	# We don't care!
	return 1;
}

# The actual work is here
sub OUTPUT {
	# Get the data structure
	my( undef, $data ) = @_;

	# Print the first line
	print "Visualizer::BasicSummary ( " . $data->{'PROGNAME'} . " started at " . scalar gmtime( $data->{'TIME'}->{'START'} ) . " )\n";

	# Print the number of sessions
	print "Total number of sessions: " . ( keys %{ $data->{'SESSION'} } ) . "\n";

	# Print the total number of events
	my $events = 0;
	foreach my $sess ( keys %{ $data->{'SESSION'} } ) {
		if ( exists $data->{'SESSION'}->{ $sess }->{'HITS'} ) {
			$events += $data->{'SESSION'}->{ $sess }->{'HITS'};
		}
	}
	print "Total number of events profiled: $events\n";

	# Print the total number of alarms
	my $alarms = 0;
	foreach my $sess ( keys %{ $data->{'SESSION'} } ) {
		if ( exists $data->{'SESSION'}->{ $sess }->{'ALARMS'} ) {
			$alarms += scalar( @{ $data->{'SESSION'}->{ $sess }->{'ALARMS'} } );
		}
	}
	print "Total number of alarms profiled: $alarms\n";

	# Print the total number of delays
	my $delays = 0;
	foreach my $sess ( keys %{ $data->{'SESSION'} } ) {
		if ( exists $data->{'SESSION'}->{ $sess }->{'DELAYS'} ) {
			$delays += scalar( @{ $data->{'SESSION'}->{ $sess }->{'DELAYS'} } );
		}
	}
	print "Total number of delays profiled: $delays\n";

	# Print the total number of signals
	my $signals = 0;
	foreach my $sess ( keys %{ $data->{'SESSION'} } ) {
		if ( exists $data->{'SESSION'}->{ $sess }->{'SIGNALS'} ) {
			$signals += scalar( @{ $data->{'SESSION'}->{ $sess }->{'SIGNALS'} } );
		}
	}
	print "Total number of signals profiled: $signals\n";
	
	# Print the number of GC passes
	my $gc = 0;
	foreach my $sess ( keys %{ $data->{'SESSION'} } ) {
		if ( exists $data->{'SESSION'}->{ $sess }->{'GC'} ) {
			$gc += scalar( @{ $data->{'SESSION'}->{ $sess }->{'GC'} } );
		}
	}
	print "Total number of GC passes: $gc\n";

	# Print the footer
	print "Runtime: " . $data->{'TIME'}->{'WALL'} . " wallclock seconds\n";
}

# End of module
1;
__END__

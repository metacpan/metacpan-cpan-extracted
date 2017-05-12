# Declare our package
package POE::Devel::Profiler::Visualizer::BasicGraphViz;

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
	
	# Okay, start drawing the graph!
	print "digraph " . fix_label( $data->{'PROGNAME'} ) . " {\n";
	
	# Draw the sessions
	foreach my $sess ( keys %{ $data->{'SESSION'} } ) {
		print "	subgraph cluster_session_" . fix_label( $sess ) . " {\n";
		
		# Make a nice label
		if ( exists $data->{'SESSION'}->{ $sess }->{'ALIASES'} ) {
			my $alias = ( keys %{ $data->{'SESSION'}->{ $sess }->{'ALIASES'} } )[ rand( scalar( keys %{ $data->{'SESSION'}->{ $sess }->{'ALIASES'} } ) ) ];
			print "		label=\"$alias\";\n";
		} else {
			print "		label=\"Session $sess\";\n";
		}
		
		# List the states
		foreach my $state ( sort keys %{ $data->{'SESSION'}->{ $sess }->{'STATES'} } ) {
			print "		ses_" . fix_label( $sess ) . "_" . fix_label( $state ) . " [ label = \"$state\"];\n";
		}
		
		# End of session
		print "	}\n\n";
	}
	
	# Now, connect the dots!
	foreach my $sess ( keys %{ $data->{'SESSION'} } ) {
		# Loop over the states
		foreach my $state ( keys %{ $data->{'SESSION'}->{ $sess }->{'STATES'} } ) {
			my $label_from = "ses_" . fix_label( $sess ) . "_" . fix_label( $state );
			
			# Loop over CALL/YIELD/POST
			foreach my $type ( qw( CALL YIELD POST ) ) {
				# Did this state do this?
				if ( ! exists $data->{'SESSION'}->{ $sess }->{'STATES'}->{ $state }->{ $type } ) {
					next;
				}
				
				# Are we yielding?
				if ( $type eq 'YIELD' ) {
					foreach my $yield_state ( keys %{ $data->{'SESSION'}->{ $sess }->{'STATES'}->{ $state }->{ $type } } ) {
						# About time!
						my $label_to = "ses_" . fix_label( $sess ) . "_" . fix_label( $yield_state );
						print "	$label_from -> $label_to;\n";
					}
				} else {
					# Loop over all call/post
					foreach my $ID ( keys %{ $data->{'SESSION'}->{ $sess }->{'STATES'}->{ $state }->{ $type } } ) {
						# Now, we got the ID, loop over the states
						foreach my $ID_state ( keys %{ $data->{'SESSION'}->{ $sess }->{'STATES'}->{ $state }->{ $type }->{ $ID } } ) {
							# About time!
							print "	$label_from -> ses_" . fix_label( $ID ) . "_" . fix_label( $ID_state ) . ";\n";
						}
					}
				}
			}
		}
	}
	
	# End the graph!
	print "}\n";
}

# Fixes annoying label typos
sub fix_label {
	my $label = shift;
	$label =~ s/\W+/_/g;
	return $label;
}

# End of module
1;
__END__

# Declare our package
package POE::Devel::Profiler::Parser;

# Standard stuff to catch errors
use strict qw(subs vars refs);				# Make sure we can't mess up
use warnings FATAL => 'all';				# Enable warnings to catch errors

# Initialize our version
our $VERSION = '0.01';

# Export our routines
use Exporter;
our @ISA = qw( Exporter );
our @EXPORT_OK = qw( load_profile );

# Okay, here is the core of this module :)
sub load_profile {
	# Get the filename
	my $file = shift;

	# Check if we can read this and etc...
	open( PARSE, "< $file" ) or die $!;

	# Construct our data structure
	#	PROGNAME
	#	TIME -> {
	#		START
	#		END
	#		WALL
	#		USER
	#		SYSTEM
	#		CUSER
	#		CSYSTEM
	#	SESSION
	#		ID -> {
	#			GC -> [
	#				TIME
	#			ALARMS -> [
	#				EVENT
	#				TIME_ALARM
	#				FILE
	#				LINE
	#				TIME
	#			DELAYS -> [
	#				EVENT
	#				TIME_ALARM
	#				FILE
	#				LINE
	#				TIME
	#			SIGNALS -> [
	#				DEST
	#				SIGNAL
	#				FILE
	#				LINE
	#				TIME
	#			ALIASES -> {
	#				NAME -> {
	#					TIME
	#					FILE
	#					LINE
	#			TIME
	#			HITS
	#			CREATE -> {
	#				TIME
	#				FILE
	#				LINE
	#				PARENT
	#			DIETIME
	#			STATES -> {
	#				NAME -> {
	#					FAILURES -> HITS
	#					DEAFULT -> HITS
	#					TIME
	#					HITS
	#					CALLS -> {
	#						ID -> {
	#							STATE -> [
	#								FILE
	#								LINE
	#								TIME
	#					POSTS -> {
	#						ID -> {
	#							STATE -> [
	#								FILE
	#								LINE
	#								TIME
	#					YIELD -> {
	#						STATE -> [
	#							FILE
	#							LINE
	#							TIME
	my %data = ();

	# The stack for entertimes -> used to figure out time spent in state/session
	my @stack = ();

	# Loop through the file
	while ( my $line = <PARSE> ) {
		# What kind of line is this?
		if ( $line =~ /^ENTERSTATE\s+\"([^\"]+)\"\s+\"([^\"]+)\"\s+\"([^\"]+)\"\s+\"([^\"]+)\"\s+\"([^\"]+)\"\s+\"([^\"]+)\"$/ ) {
			# ENTERSTATE	current_session_id	statename	caller_session_id	caller_file_name	caller_file_line	time

			# Put on the top of the stack the entertime
			unshift( @stack, $6 );

			if ( ! exists $data{'SESSION'}->{ $1 }->{'HITS'} ) {
				$data{'SESSION'}->{ $1 }->{'HITS'} = 0;
			}
			if ( ! exists $data{'SESSION'}->{ $1 }->{'STATES'}->{ $2 }->{'HITS'} ) {
				$data{'SESSION'}->{ $1 }->{'STATES'}->{ $2 }->{'HITS'} = 0;
			}

			# Add the hits for this session and state
			$data{'SESSION'}->{ $1 }->{'HITS'}++;
			$data{'SESSION'}->{ $1 }->{'STATES'}->{ $2 }->{'HITS'}++;
		} elsif ( $line =~ /^LEAVESTATE\s+\"([^\"]+)\"\s+\"([^\"]+)\"\s+\"([^\"]+)\"$/ ) {
			# LEAVESTATE	current_session_id	statename	time

			# Subtract the time
			my $diff = $3 - shift( @stack );

			# Make sure the diff output makes sense
			$diff = sprintf( "%.6f", $diff );

			# Tally up the time for this session + state
			if ( ! exists $data{'SESSION'}->{ $1 }->{'TIME'} ) {
				$data{'SESSION'}->{ $1 }->{'TIME'} = 0;
			}
			if ( ! exists $data{'SESSION'}->{ $1 }->{'STATES'}->{ $2 }->{'TIME'} ) {
				$data{'SESSION'}->{ $1 }->{'STATES'}->{ $2 }->{'TIME'} = 0;
			}

			$data{'SESSION'}->{ $1 }->{'TIME'} += $diff;
			$data{'SESSION'}->{ $1 }->{'STATES'}->{ $2 }->{'TIME'} += $diff;
		} elsif ( $line =~ /^YIELD\s+\"([^\"]+)\"\s+\"([^\"]+)\"\s+\"([^\"]+)\"\s+\"([^\"]+)\"\s+\"([^\"]+)\"\s+\"([^\"]+)\"$/ ) {
			# YIELD	current_session_id	statename	yield_event	file	line	time

			push( @{ $data{'SESSION'}->{ $1 }->{'STATES'}->{ $2 }->{'YIELD'}->{ $3 } }, {
				'FILE'	=>	$4,
				'LINE'	=>	$5,
				'TIME'	=>	$6,
			} );
		} elsif ( $line =~ /^POST\s+\"([^\"]+)\"\s+\"([^\"]+)\"\s+\"([^\"]+)\"\s+\"([^\"]+)\"\s+\"([^\"]+)\"\s+\"([^\"]+)\"\s+\"([^\"]+)\"$/ ) {
			# POST	current_session_id	statename	post_session	post_event	file	line	time

			push( @{ $data{'SESSION'}->{ $1 }->{'STATES'}->{ $2 }->{'POST'}->{ $3 }->{ $4 } }, {
				'FILE'	=>	$5,
				'LINE'	=>	$6,
				'TIME'	=>	$7,
			} );
		} elsif ( $line =~ /^CALL\s+\"([^\"]+)\"\s+\"([^\"]+)\"\s+\"([^\"]+)\"\s+\"([^\"]+)\"\s+\"([^\"]+)\"\s+\"([^\"]+)\"\s+\"([^\"]+)\"$/ ) {
			# CALL	current_session_id	statename	call_session	call_event	file	line	time

			push( @{ $data{'SESSION'}->{ $1 }->{'STATES'}->{ $2 }->{'CALL'}->{ $3 }->{ $4 } }, {
				'FILE'	=>	$5,
				'LINE'	=>	$6,
				'TIME'	=>	$7,
			} );
		} elsif ( $line =~ /^FAILSTATE\s+\"([^\"]+)\"\s+\"([^\"]+)\"\s+\"([^\"]+)\"\s+\"([^\"]+)\"\s+\"([^\"]+)\"\s+\"([^\"]+)\"$/ ) {
			# FAILSTATE	current_session_id	statename	caller_session_id	caller_file_name	caller_file_line	time

			if ( ! exists $data{'SESSION'}->{ $1 }->{'HITS'} ) {
				$data{'SESSION'}->{ $1 }->{'HITS'} = 0;
			}
			if ( ! exists $data{'SESSION'}->{ $1 }->{'STATES'}->{ $2 }->{'FAILURES'} ) {
				$data{'SESSION'}->{ $1 }->{'STATES'}->{ $2 }->{'FAILURES'} = 0;
			}

			# Add the hits for this session and state
			$data{'SESSION'}->{ $1 }->{'HITS'}++;
			$data{'SESSION'}->{ $1 }->{'STATES'}->{ $2 }->{'FAILURES'}++;
		} elsif ( $line =~ /^DEFAULTSTATE\s+\"([^\"]+)\"\s+\"([^\"]+)\"\s+\"([^\"]+)\"\s+\"([^\"]+)\"\s+\"([^\"]+)\"\s+\"([^\"]+)\"$/ ) {
			# DEFAULTSTATE	current_session_id	statename	caller_session_id	caller_file_name	caller_file_line	time

			# Put on the top of the stack the entertime
			unshift( @stack, $6 );
			
			if ( ! exists $data{'SESSION'}->{ $1 }->{'HITS'} ) {
				$data{'SESSION'}->{ $1 }->{'HITS'} = 0;
			}
			if ( ! exists $data{'SESSION'}->{ $1 }->{'STATES'}->{ $2 }->{'DEFAULT'} ) {
				$data{'SESSION'}->{ $1 }->{'STATES'}->{ $2 }->{'DEFAULT'} = 0;
			}

			# Add the hits for this session and state
			$data{'SESSION'}->{ $1 }->{'HITS'}++;
			$data{'SESSION'}->{ $1 }->{'STATES'}->{ $2 }->{'DEFAULT'}++;
		} elsif ( $line =~ /^STARTPROGRAM\s+\"([^\"]+)\"\s+\"([^\"]+)\"$/ ) {
			# STARTPROGRAM	name	time

			# Store the data
			$data{'PROGNAME'} = $1;
			$data{'TIME'}->{'START'} = $2;
		} elsif ( $line =~ /^ENDPROGRAM\s+\"([^\"]+)\"\s+\"([^\"]+)\"\s+\"([^\"]+)\"\s+\"([^\"]+)\"\s+\"([^\"]+)\"\s+\"([^\"]+)\"$/ ) {
			# ENDPROGRAM	time wall user system cuser csystem

			# Store the data
			$data{'TIME'}->{'END'} = $1;
			$data{'TIME'}->{'WALL'} = $2;
			$data{'TIME'}->{'USER'} = $3;
			$data{'TIME'}->{'SYSTEM'} = $4;
			$data{'TIME'}->{'CUSER'} = $5;
			$data{'TIME'}->{'CSYSTEM'} = $6;
		} elsif ( $line =~ /^SESSIONALIAS\s+\"([^\"]+)\"\s+\"([^\"]+)\"\s+\"([^\"]+)\"\s+\"([^\"]+)\"\s+\"([^\"]+)\"$/ ) {
			# SESSIONALIAS session_id alias file line time

			# Store it!
			$data{'SESSION'}->{ $1 }->{'ALIASES'}->{ $2 } = {
				'FILE'	=>	$3,
				'LINE'	=>	$4,
				'TIME'	=>	$5,
			};
		} elsif ( $line =~ /^SESSIONNEW\s+\"([^\"]+)\"\s+\"([^\"]+)\"\s+\"([^\"]+)\"\s+\"([^\"]+)\"\s+\"([^\"]+)\"$/ ) {
			# SESSIONNEW session_id parent_id file line time

			$data{'SESSION'}->{ $1 }->{'CREATE'} = {
				'PARENT'	=>	$2,
				'FILE'	=>	$3,
				'LINE'	=>	$4,
				'TIME'	=>	$5,
			};
		} elsif ( $line =~ /^SESSIONDIE\s+\"([^\"]+)\"\s+\"([^\"]+)\"$/ ) {
			# SESSIONDIE session_id time

			$data{'SESSION'}->{ $1 }->{'DIETIME'} = $2;
		} elsif ( $line =~ /^ALARMSET\s+\"([^\"]+)\"\s+\"([^\"]+)\"\s+\"([^\"]+)\"\s+\"([^\"]+)\"\s+\"([^\"]+)\"\s+\"([^\"]+)\"$/ ) {
			# ALARMSET session_id event_name time_alarm file line time
			
			push( @{ $data{'SESSION'}->{ $1 }->{'ALARMS'} }, {
				'EVENT'		=>	$2,
				'TIME_ALARM'	=>	$3,
				'FILE'		=>	$4,
				'LINE'		=>	$5,
				'TIME'		=>	$6,
			} );
		} elsif ( $line =~ /^DELAYSET\s+\"([^\"]+)\"\s+\"([^\"]+)\"\s+\"([^\"]+)\"\s+\"([^\"]+)\"\s+\"([^\"]+)\"\s+\"([^\"]+)\"$/ ) {
			# DELAYSET session_id event_name time_alarm file line time
			
			push( @{ $data{'SESSION'}->{ $1 }->{'DELAYS'} }, {
				'EVENT'		=>	$2,
				'TIME_ALARM'	=>	$3,
				'FILE'		=>	$4,
				'LINE'		=>	$5,
				'TIME'		=>	$6,
			} );
		} elsif ( $line =~ /^SIGNAL\s+\"([^\"]+)\"\s+\"([^\"]+)\"\s+\"([^\"]+)\"\s+\"([^\"]+)\"\s+\"([^\"]+)\"\s+\"([^\"]+)\"$/ ) {
			# SIGNAL session_id dest_id signal file line time
			
			push( @{ $data{'SESSION'}->{ $1 }->{'SIGNALS'} }, {
				'DEST'	=>	$2,
				'SIGNAL'	=>	$3,
				'FILE'	=>	$4,
				'LINE'	=>	$5,
				'TIME'	=>	$6,
			} );
		} elsif ( $line =~ /^GC\s+\"([^\"]+)\"\s+\"([^\"]+)\"$/ ) {
			# GC session_id time
			
			push( @{ $data{'SESSION'}->{ $1 }->{'GC'} }, $2 );
		} else {
			# Funky line...
			warn "Funky line: $line";
		}
	}

	# All done with the file
	close( PARSE ) or die $!;

	# Return the data structure
	return \%data;
}

# End of module
1;

__END__

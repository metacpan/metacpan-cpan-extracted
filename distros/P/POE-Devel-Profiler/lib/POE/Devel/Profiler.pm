# Declare our package
package POE::Devel::Profiler;

# Standard stuff to catch errors
use strict qw(subs vars refs);				# Make sure we can't mess up
use warnings FATAL => 'all';				# Enable warnings to catch errors

# Initialize our version
our $VERSION = '0.02';

# Okay, initialize POE so we can profile it
use POE;

# We need Time::HiRes to profile accurately
use Time::HiRes qw( time );

# Here comes the nasty hackery
sub BEGIN {
	# We need to replace several key subroutines

	# Turn off strictness for our nasty stuff
	no strict 'refs';

	# Oh boy, no warnings too :(
	no warnings 'redefine';

	# Replace Kernel::_data_alias_add()
	{
		# Get the old reference
		my $old_ref = \&POE::Kernel::_data_alias_add;

		# Construct the closure for the wrapper
		my $new_ref = sub {
			# Okay, call our profiling sub
			_PROFILE_ALIASSET( @_ );

			# When that is done, we call the original sub
			goto &$old_ref;
		};

		# Symbol table hackery
		*{'POE::Kernel::_data_alias_add'} = $new_ref;
	}

	# Replace Kernel::yield()
	{
		# Get the old reference
		my $old_ref = \&POE::Kernel::yield;

		# Construct the closure for the wrapper
		my $new_ref = sub {
			# Okay, call our profiling sub
			_PROFILE_YIELD( @_ );

			# When that is done, we call the original sub
			goto &$old_ref;
		};

		# Symbol table hackery
		*{'POE::Kernel::yield'} = $new_ref;
	}

	# Replace Kernel::post()
	{
		# Get the old reference
		my $old_ref = \&POE::Kernel::post;

		# Construct the closure for the wrapper
		my $new_ref = sub {
			# Okay, call our profiling sub
			_PROFILE_POST( @_ );

			# When that is done, we call the original sub
			goto &$old_ref;
		};

		# Symbol table hackery
		*{'POE::Kernel::post'} = $new_ref;
	}

	# Replace Kernel::call()
	{
		# Get the old reference
		my $old_ref = \&POE::Kernel::call;

		# Construct the closure for the wrapper
		my $new_ref = sub {
			# Okay, call our profiling sub
			_PROFILE_CALL( @_ );

			# When that is done, we call the original sub
			goto &$old_ref;
		};

		# Symbol table hackery
		*{'POE::Kernel::call'} = $new_ref;
	}

	# Replace Session::_invoke_state()
	{
		# Get the old reference
		my $old_ref = \&POE::Session::_invoke_state;

		# Construct the closure for the wrapper
		my $new_ref = sub {
			# Okay, call our profiling sub
			my $ret = _PROFILE_SESSINVOKE( @_ );

			# When that is done, we call the original sub
			my $return = undef;
			if ( wantarray ) {
				$return = [ $old_ref->( @_ ) ];
			} else {
				$return = $old_ref->( @_ );
			}

			# Print the LEAVESTATE only if we didn't get FAILSTATE
			if ( $ret ) {
				# Print it out!
				# LEAVESTATE	current_session_id	statename	time
				print OUT	"LEAVESTATE \"" . $POE::Kernel::poe_kernel->get_active_session->ID . '" "' .
						$_[2] . '" "' . time() . "\"\n";
			}

			# Okay, return the data
			if ( wantarray ) {
				return @{ $return };
			} else {
				return $return;
			}
		};

		# Symbol table hackery
		*{'POE::Session::_invoke_state'} = $new_ref;
	}

	# Replace Resources::Sessions::_data_ses_allocate()
	# NOTE: It masquerades itself into POE::Kernel's namespace
	{
		# Get the old reference
		my $old_ref = \&POE::Kernel::_data_ses_allocate;

		# Construct the closure for the wrapper
		my $new_ref = sub {
			# Okay, call our profiling sub
			_PROFILE_NEWSESS( @_ );

			# When that is done, we call the original sub
			my $return = undef;
			if ( wantarray ) {
				$return = [ $old_ref->( @_ ) ];
			} else {
				$return = $old_ref->( @_ );
			}

			# Okay, return the data
			if ( wantarray ) {
				return @{ $return };
			} else {
				return $return;
			}
		};

		# Symbol table hackery
		*{'POE::Kernel::_data_ses_allocate'} = $new_ref;
	}
	
	# Replace Kernel::_data_ses_free()
	{
		# Get the old reference
		my $old_ref = \&POE::Kernel::_data_ses_free;

		# Construct the closure for the wrapper
		my $new_ref = sub {
			# Okay, call our profiling sub
			_PROFILE_SESSDIE( @_ );

			# When that is done, we call the original sub
			goto &$old_ref;
		};

		# Symbol table hackery
		*{'POE::Kernel::_data_ses_free'} = $new_ref;
	}
	
	# Replace Kernel::alarm_set()
	{
		# Get the old reference
		my $old_ref = \&POE::Kernel::alarm_set;

		# Construct the closure for the wrapper
		my $new_ref = sub {
			# Okay, call our profiling sub
			_PROFILE_ALARMSET( @_ );

			# When that is done, we call the original sub
			goto &$old_ref;
		};

		# Symbol table hackery
		*{'POE::Kernel::alarm_set'} = $new_ref;
	}
	
	# Replace Kernel::delay_set()
	{
		# Get the old reference
		my $old_ref = \&POE::Kernel::delay_set;

		# Construct the closure for the wrapper
		my $new_ref = sub {
			# Okay, call our profiling sub
			_PROFILE_DELAYSET( @_ );

			# When that is done, we call the original sub
			goto &$old_ref;
		};

		# Symbol table hackery
		*{'POE::Kernel::delay_set'} = $new_ref;
	}
	
	# Replace Kernel::signal()
	{
		# Get the old reference
		my $old_ref = \&POE::Kernel::signal;

		# Construct the closure for the wrapper
		my $new_ref = sub {
			# Okay, call our profiling sub
			_PROFILE_SIGNAL( @_ );

			# When that is done, we call the original sub
			goto &$old_ref;
		};

		# Symbol table hackery
		*{'POE::Kernel::signal'} = $new_ref;
	}

	# Replace Kernel::_data_ses_collect_garbage()
	{
		# Get the old reference
		my $old_ref = \&POE::Kernel::_data_ses_collect_garbage;

		# Construct the closure for the wrapper
		my $new_ref = sub {
			# Okay, call our profiling sub
			_PROFILE_GC( @_ );

			# When that is done, we call the original sub
			goto &$old_ref;
		};

		# Symbol table hackery
		*{'POE::Kernel::_data_ses_collect_garbage'} = $new_ref;
	}

	# Check for the filename sub
	if ( ! defined &FILENAME ) {
		eval "sub FILENAME () { 'poep.out' }";
	}
}

# Open the filename, creating it if necessary
open( OUT, '> ' . FILENAME ) or die "Unable to open the output file: $!";

# Print the first line!
# STARTPROGRAM	name	time
print OUT	'STARTPROGRAM "' . $0 . '" "' . time() . "\"\n";

# Now, we wait for the stuff to come rolling in

# Capture alias_set for logging
sub _PROFILE_ALIASSET {
	# Get the alias name
	my ( $sess, $alias ) = @_[ 1, 2 ];

	# Get the caller's filename and etc
	# Bypass Kernel::alias_set's call frame
	my( $file, $line ) = ( caller( 2 ) )[1,2];

	# Print it out!
	# SESSIONALIAS session_id alias file line time
	print OUT 'SESSIONALIAS "' . $sess->ID . '" "' . $alias . '" "' . $file . '" "' . $line . '" "' . time() . "\"\n";

	# All done!
	return;
}

# Capture yields
sub _PROFILE_YIELD {
	# Get the event name
	my $event = $_[1];

	# Sanity checking
	if ( ! defined $event ) {
		return;
	}

	# Get the caller's filename and etc
	my( $file, $line ) = ( caller( 1 ) )[1,2];

	# Okay, print out what we need
	# YIELD	current_session_id	statename	yield_event	file	line	time
	print OUT	'YIELD "' . $POE::Kernel::poe_kernel->get_active_session->ID . '" "' . ${ $POE::Kernel::poe_kernel->[ POE::Kernel::KR_ACTIVE_EVENT ] } . '" "' .
			$event . '" "' . $file . '" "' . $line . '" "' . time() . "\"\n";

	# All done!
	return;
}

# Capture posts
sub _PROFILE_POST {
	# Get the session + event name
	my( $sess, $event ) = @_[ 1, 2];

	# Sanity checking
	if ( ! defined $sess or ! defined $event ) {
		return;
	}

	# Get the destination session's ID
	$sess = $_[0]->_resolve_session( $sess );

	# Check if it is valid
	if ( ! defined $sess ) {
		return;
	} else {
		# Get the ID
		$sess = $sess->ID;
	}

	# Get the caller's filename and etc
	my( $file, $line ) = ( caller( 1 ) )[1,2];

	# Okay, print out what we need
	# POST	current_session_id	statename	post_session	post_event	file	line	time
	print OUT	'POST "' . $POE::Kernel::poe_kernel->get_active_session->ID . '" "' . ${ $POE::Kernel::poe_kernel->[ POE::Kernel::KR_ACTIVE_EVENT ] } . '" "' .
			$sess . '" "' . $event . '" "' . $file . '" "' . $line . '" "' . time() . "\"\n";

	# All done!
	return;
}

# Capture calls
sub _PROFILE_CALL {
	# Get the session + event name
	my( $sess, $event ) = @_[ 1, 2];

	# Sanity checking
	if ( ! defined $sess or ! defined $event ) {
		return;
	}

	# Get the destination session's ID
	$sess = $_[0]->_resolve_session( $sess );

	# Check if it is valid
	if ( ! defined $sess ) {
		return;
	} else {
		# Get the ID
		$sess = $sess->ID;
	}

	# Get the caller's filename and etc
	my( $file, $line ) = ( caller( 1 ) )[1,2];

	# Okay, print out what we need
	# CALL	current_session_id	statename	call_session	call_event	file	line	time
	print OUT	'CALL "' . $POE::Kernel::poe_kernel->get_active_session->ID . '" "' . ${ $POE::Kernel::poe_kernel->[ POE::Kernel::KR_ACTIVE_EVENT ] } . '" "' .
			$sess . '" "' . $event . '" "' . $file . '" "' . $line . '" "' . time() . "\"\n";

	# All done!
	return;
}

# Capture enter state
# Profiles POE::Session only
sub _PROFILE_SESSINVOKE {
	# my ($self, $source_session, $state, $etc, $file, $line) = @_;

	# Set up the type
	my $type = 'ENTERSTATE';

	# Return success ( for now )
	my $return = 1;

	# Check if this state is valid
	if ( ! exists $_[0]->[ POE::Session::SE_STATES ]->{ $_[2] } ) {
		# Okay, check _default
		if ( exists $_[0]->[ POE::Session::SE_STATES ]->{ POE::Session::EN_DEFAULT } ) {
			# Whew, log it as _default
			$type = 'DEFAULTSTATE';
		} else {
			# We failed to invoke a state!
			$type = 'FAILSTATE';
			$return = undef;
		}
	}

	# Print it out!
	# ENTERSTATE	current_session_id	statename	caller_session_id	caller_file_name	caller_file_line	time
	# FAILSTATE	current_session_id	statename	caller_session_id	caller_file_name	caller_file_line	time
	# DEFAULTSTATE	current_session_id	statename	caller_session_id	caller_file_name	caller_file_line	time
	print OUT	"$type \"" . $_[0]->ID . '" "' . $_[2] . '" "' . $_[1]->ID . '" "' . $_[4] . '" "' . $_[5] . '" "' . time() . "\"\n";

	# All done!
	return $return;
}

# A new session is created, note this!
sub _PROFILE_NEWSESS {
	my( $sid, $parent ) = @_[ 2, 3 ];

	# Sanity checking
	if ( ! defined $parent ) {
		return;
	}

	# Okay, check if it would have failed
	if ( POE::Kernel::ASSERT_DATA ) {	
		if ( ! exists $POE::Kernel::poe_kernel->[ $POE::Kernel::KR_SESSIONS ]->{ $parent } ) {
			return;
		}
	}
	
	# Get the caller's filename and etc
	# Bypass Kernel::session_alloc
	# Bypass Session::new/create
	my( $file, $line ) = ( caller( 4 ) )[1,2];

	# Print it out!
	# SESSIONNEW session_id parent_id file line time
	print OUT 'SESSIONNEW "' . $sid . '" "' . $parent->ID . '" "' . $file . '" "' . $line . '" "' . time() . "\"\n";
}

# A session is now dying...
sub _PROFILE_SESSDIE {
	# Get the session
	my $sess = $_[1];
	
	# Print it out!
	# SESSIONDIE session_id time
	print OUT 'SESSIONDIE "' . $sess->ID . '" "' . time() . "\"\n";
}

# Somebody set us up the alarm!
sub _PROFILE_ALARMSET {
	my( $event, $time ) = @_[ 1, 2 ];

	# Sanity checks
	if ( ! defined $event ) { return }
	if ( ! defined $time ) { return }
	if ( POE::Kernel::ASSERT_USAGE ) {
		if ( exists $POE::Kernel::poes_own_events{ $event } ) { return }
	}

	# Get the caller's filename and etc
	my( $file, $line ) = ( caller( 1 ) )[1,2];

	# Print it out!
	# ALARMSET session_id event_name time_alarm file line time
	print OUT 'ALARMSET "' . $POE::Kernel::poe_kernel->get_active_session->ID . '" "' . $event . '" "' .
			$time . '" "' . $file . '" "' . $line . '" "' . time() . "\"\n";
}

# Somebody set us up the delay!
sub _PROFILE_DELAYSET {
	my( $event, $time ) = @_[ 1, 2 ];

	# Sanity checks
	if ( ! defined $event ) { return }
	if ( ! defined $time ) { return }
	if ( POE::Kernel::ASSERT_USAGE ) {
		if ( exists $POE::Kernel::poes_own_events{ $event } ) { return }
	}

	# Get the caller's filename and etc
	my( $file, $line ) = ( caller( 1 ) )[1,2];

	# Print it out!
	# DELAYSET session_id event_name time_alarm file line time
	print OUT 'DELAYSET "' . $POE::Kernel::poe_kernel->get_active_session->ID . '" "' . $event . '" "' .
			$time . '" "' . $file . '" "' . $line . '" "' . time() . "\"\n";
}

# Time to send some signals!
sub _PROFILE_SIGNAL {
	my( $dest, $signal ) = @_[ 1, 2 ];

	# Sanity checks
	if ( ! defined $dest ) { return }
	if ( ! defined $signal ) { return }
	
	# Get the destination session's ID
	$dest = $_[0]->_resolve_session( $dest );

	# Check if it is valid
	if ( ! defined $dest ) {
		return;
	} else {
		# Get the ID
		$dest = $dest->ID;
	}

	# Get the caller's filename and etc
	my( $file, $line ) = ( caller( 1 ) )[1,2];

	# Print it out!
	# SIGNAL session_id dest_id signal file line time
	print OUT 'SIGNAL "' . $POE::Kernel::poe_kernel->get_active_session->ID . '" "' . $dest . '" "' .
			$signal . '" "' . $file . '" "' . $line . '" "' . time() . "\"\n";
}

# Keeps track of how many times a session was GC'ed
sub _PROFILE_GC {
	my $session = $_[ 1 ];

	# Print it out!
	# GC session_id time
	print OUT 'GC "' . $session->ID . '" "' . time() . "\"\n";
}

# Okay, when the program ends, we print our stuff!
sub END {
	# Collect time statistics
	my( $wall, $user, $system, $cuser, $csystem ) = ( ( time-$^T ), times() );

	# Print it out!
	# ENDPROGRAM	time wall user system cuser csystem
	print OUT	'ENDPROGRAM "' . time() . '" "' . $wall . '" "' . $user . '" "' . $system . '" "' .
			$cuser . '" "' . $csystem . "\"\n";

	# We're finally done!
	close( OUT ) or die $!;
}

# End of module
1;
__END__
=head1 NAME

POE::Devel::Profiler - profiles POE programs

=head1 SYNOPSIS

	perl -MPOE::Devel::Profiler myPOEapp.pl
	poepp BasicSummary

=head1 CHANGES

=head2 0.02

	Added the BasicGraphViz Visualizer -> use it like:
		poepp BasicGraphViz > output.dot
		dot -Tpng -o output.png output.dot

=head2 0.01

	First release!

=head1 ABSTRACT

	Profiles POE programs for useful data

=head1 DESCRIPTION

This module profiles POE programs, in the same way the Devel::DProf family of modules do.

Currently, POE::Devel::Profiler will profile the following:
	
	Program start/end
	Session create/destruction
	alarm_set
	delay_set
	signal
	alias_set
	yield/post/call from a session
	entering an event ( also includes _default states and failed states )
	Garbage Collection on a session

POE::Devel::Profiler will not profile:

	Anything not mentioned above :)

=head1 NOTES

=head2 Compatibility?

This module is currently compatible only with POE::Session, further work will be needed.

=head2 POE Options

If you want to set POE options like ASSERT_DEFAULT, it is currently not possible with this module. The
only way to do it is to set environment variables or hardcode the following in your program:

	sub POE::Kernel::ASSERT_DEFAULT () { 1 }
	use POE::Devel::Profiler;
	use POE;

=head2 Loading POE

POE::Devel::Profiler MUST be loaded before POE or craziness will ensue...

=head2 Profiler data

The profile data is stored in the file 'poep.out', don't ask me why :)

To interpret the data, use the program 'poepp' and any Visualizer you want, consult the poepp documentation.

=head1 SEE ALSO

	L<POE>

	L<POE::Devel::Profiler::Parser>

	L<poepp>

=head1 AUTHOR

Apocalypse E<lt>apocal@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2004 by Apocalypse

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

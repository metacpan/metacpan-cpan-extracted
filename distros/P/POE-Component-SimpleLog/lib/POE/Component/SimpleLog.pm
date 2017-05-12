# Declare our package
package POE::Component::SimpleLog;
use strict; use warnings;

# Initialize our version $LastChangedRevision: 16 $
our $VERSION = '1.05';

# Import what we need from the POE namespace
use POE;

# Other miscellaneous modules we need
use Carp;

# Set some constants
BEGIN {
	# Debug fun!
	if ( ! defined &DEBUG ) {
		eval "sub DEBUG () { 0 }";
	}
}

# Set things in motion!
sub new {
	# Get the OOP's type
	my $type = shift;

	# Sanity checking
	if ( @_ & 1 ) {
		croak( 'POE::Component::SimpleLog->new needs even number of options' );
	}

	# The options hash
	my %opt = @_;

	# Our own options
	my ( $ALIAS, $PRECISION );

	# You could say I should do this: $Stuff = delete $opt{'Stuff'}
	# But, that kind of behavior is not defined, so I would not trust it...

	# Get the session alias
	if ( exists $opt{'ALIAS'} ) {
		$ALIAS = $opt{'ALIAS'};
		delete $opt{'ALIAS'};
	} else {
		# Debugging info...
		if ( DEBUG ) {
			warn 'Using default ALIAS = SimpleLog';
		}

		# Set the default
		$ALIAS = 'SimpleLog';
	}

	# Get the precision
	if ( exists $opt{'PRECISION'} ) {
		$PRECISION = $opt{'PRECISION'};
		delete $opt{'PRECISION'};

		# Check if it is defined
		if ( defined $PRECISION ) {
			# Use Time::HiRes
			require Time::HiRes;
		}
	} else {
		# Set it to regular
		$PRECISION = undef;
	}

	# Anything left over is unrecognized
	if ( DEBUG ) {
		if ( keys %opt > 0 ) {
			croak 'Unrecognized options were present in POE::Component::SimpleLog->new -> ' . join( ', ', keys %opt );
		}
	}

	# Create a new session for ourself
	POE::Session->create(
		# Our subroutines
		'inline_states'	=>	{
			# Maintenance events
			'_start'	=>	\&StartLog,
			'_stop'		=>	sub {},

			# Register a log
			'REGISTER'	=>	\&Register,

			# Unregister a log
			'UNREGISTER'	=>	\&UnRegister,
			'REMOVESESSION'	=>	\&UnRegisterSession,

			# LOG SOMETHING!
			'LOG'		=>	\&Log,

			# We are done!
			'SHUTDOWN'	=>	\&StopLog,
		},

		# Set up the heap for ourself
		'heap'		=>	{
			# The logging relation table
			'LOGS'		=>	{},

			# Precision
			'PRECISION'	=>	$PRECISION,

			# Who wants to get *ALL* logs?
			'ALLLOGS'	=>	{},

			'ALIAS'		=>	$ALIAS,
		},
	) or die 'Unable to create a new session!';

	# Return success
	return 1;
}

# Registers a new log to watch
sub Register {
	# Get the arguments
	my %args = @_[ ARG0 .. $#_ ];

	# Validation - silently ignore errors
	if ( ! defined $args{'LOGNAME'} ) {
		if ( DEBUG ) {
			warn 'Did not get any arguments';
		}
		return undef;
	}

	if ( ! defined $args{'SESSION'} ) {
		if ( DEBUG ) {
			warn "Did not get a TargetSession for LogName: $args{'LOGNAME'}";
		}
		return undef;
	} else {
		# Convert actual POE::Session objects to their ID
		if ( UNIVERSAL::isa( $args{'SESSION'}, 'POE::Session') ) {
			$args{'SESSION'} = $args{'SESSION'}->ID;
		}
	}

	if ( ! defined $args{'EVENT'} ) {
		if ( DEBUG ) {
			warn "Did not get an Event for LogName: $args{'LOGNAME'} -> Target Session: $args{'SESSION'}";
	}
		return undef;
	}

	# Check if we are registering an *ALL* logger or not
	if ( $args{'LOGNAME'} eq 'ALL' ) {
		# Put this in ALL
		if ( ! exists $_[HEAP]->{'ALLLOGS'}->{ $args{'SESSION'} } ) {
			$_[HEAP]->{'ALLLOGS'}->{ $args{'SESSION'} } = {};
		}

		# Put it in the hash!
		if ( exists $_[HEAP]->{'ALLLOGS'}->{ $args{'SESSION'} }->{ $args{'EVENT'} } ) {
			# Duplicate record...
			if ( DEBUG ) {
				warn "Tried to register a duplicate! -> LogName: $args{'LOGNAME'} -> Target Session: $args{'SESSION'} -> Event: $args{'EVENT'}";
			}
		} else {
			$_[HEAP]->{'ALLLOGS'}->{ $args{'SESSION'} }->{ $args{'EVENT'} } = 1;
		}
	} else {
		# Verify our data structure
		if ( ! exists $_[HEAP]->{'LOGS'}->{ $args{'LOGNAME'} } ) {
			$_[HEAP]->{'LOGS'}->{ $args{'LOGNAME'} } = {};
		}

		if ( ! exists $_[HEAP]->{'LOGS'}->{ $args{'LOGNAME'} }->{ $args{'SESSION'} } ) {
			$_[HEAP]->{'LOGS'}->{ $args{'LOGNAME'} }->{ $args{'SESSION'} } = {};
		}

		# Finally put it in the hash :)
		if ( exists $_[HEAP]->{'LOGS'}->{ $args{'LOGNAME'} }->{ $args{'SESSION'} }->{ $args{'EVENT'} } ) {
			# Duplicate record...
			if ( DEBUG ) {
				warn "Tried to register a duplicate! -> LogName: $args{'LOGNAME'} -> Target Session: $args{'SESSION'} -> Event: $args{'EVENT'}";
			}
		} else {
			$_[HEAP]->{'LOGS'}->{ $args{'LOGNAME'} }->{ $args{'SESSION'} }->{ $args{'EVENT'} } = 1;
		}
	}

	# All done!
	return 1;
}

# Delete a watcher
sub UnRegister {
	# Get the arguments
	my %args = @_[ ARG0 .. $#_ ];

	# Validation - silently ignore errors
	if ( ! defined $args{'LOGNAME'} ) {
		if ( DEBUG ) {
			warn 'Did not get any arguments';
		}
		return undef;
	}

	if ( ! defined $args{'SESSION'} ) {
		if ( DEBUG ) {
			warn "Did not get a TargetSession for LogName: $args{'LOGNAME'}";
		}
		return undef;
	} else {
		# Convert actual POE::Session objects to their ID
		if ( UNIVERSAL::isa( $args{'SESSION'}, 'POE::Session') ) {
			$args{'SESSION'} = $args{'SESSION'}->ID;
		}
	}

	if ( ! defined $args{'EVENT'} ) {
		if ( DEBUG ) {
			warn "Did not get an Event for LogName: $args{'LOGNAME'} -> Target Session: $args{'SESSION'}";
		}
		return undef;
	}

	# Check if this is the special *ALL* log
	if ( $args{'LOGNAME'} eq 'ALL' ) {
		# Scan it for targetsession
		if ( exists $_[HEAP]->{'ALLLOGS'}->{ $args{'SESSION'} } ) {
			# Scan for the proper event!
			foreach my $evnt ( keys %{ $_[HEAP]->{'ALLLOGS'}->{ $args{'SESSION'} } } ) {
				if ( $evnt eq $args{'EVENT'} ) {
					# Found a match, delete it!
					delete $_[HEAP]->{'ALLLOGS'}->{ $args{'SESSION'} }->{ $evnt };
					if ( scalar keys %{ $_[HEAP]->{'ALLLOGS'}->{ $args{'SESSION'} } } == 0 ) {
						delete $_[HEAP]->{'ALLLOGS'}->{ $args{'SESSION'} };
					}

					# Return success
					return 1;
				}
			}
		}
	} else {
		# Search through the logs for this specific one
		if ( exists $_[HEAP]->{'LOGS'}->{ $args{'LOGNAME'} } ) {
			# Scan it for targetsession
			if ( exists $_[HEAP]->{'LOGS'}->{ $args{'LOGNAME'} }->{ $args{'SESSION'} } ) {
				# Scan for the proper event!
				foreach my $evnt ( keys %{ $_[HEAP]->{'LOGS'}->{ $args{'LOGNAME'} }->{ $args{'SESSION'} } } ) {
					if ( $evnt eq $args{'EVENT'} ) {
						# Found a match, delete it!
						delete $_[HEAP]->{'LOGS'}->{ $args{'LOGNAME'} }->{ $args{'SESSION'} }->{ $evnt };
						if ( scalar keys %{ $_[HEAP]->{'LOGS'}->{ $args{'LOGNAME'} }->{ $args{'SESSION'} } } == 0 ) {
							delete $_[HEAP]->{'LOGS'}->{ $args{'LOGNAME'} }->{ $args{'SESSION'} };
						}

						# Return success
						return 1;
					}
				}
			}
		}
	}

	# Found nothing...
	return undef;
}

# UnRegisters a whole session
sub UnRegisterSession {
	# ARG0 = Session ID
	my $TargetSession = $_[ARG0];

	# Validation
	if ( ! defined $TargetSession ) {
		# Hmpf
		if ( DEBUG ) {
			warn 'Did not get any arguments!';
		}
	}

	# Go through all of the logs, searching for this session
	foreach my $logname ( keys %{ $_[HEAP]->{'LOGS'} } ) {
		# Another loop!
		foreach my $session ( keys %{ $_[HEAP]->{'LOGS'}->{ $logname } } ) {
			# Check if they match
			if ( $session eq $TargetSession ) {
				# Remove this!
				delete $_[HEAP]->{'LOGS'}->{ $logname }->{ $TargetSession };
			}
		}
	}

	# Go through the *ALL* logs
	foreach my $session ( keys %{ $_[HEAP]->{'ALLLOGS'} } ) {
		# Check if they match
		if ( $session eq $TargetSession ) {
			# Remove this!
			delete $_[HEAP]->{'ALLLOGS'}->{ $TargetSession };
		}
	}

	# All done!
	return 1;
}

# The core part of this module :)
sub Log {
	# ARG0 = LogName, ARG1 = Message
	my( $logname, $message ) = @_[ ARG0, ARG1 ];

	# Check if this is an *ALL* log...
	if ( $logname eq 'ALL' ) {
		# Should not do this!
		if ( DEBUG ) {
			warn 'Sending a log named ALL is not allowed, read the documentation';
		}
	}

	# Figure out the time
	my $time;
	if ( defined $_[HEAP]->{'PRECISION'} ) {
		$time = [ Time::HiRes::gettimeofday ];
	} else {
		$time = time();
	}

	# Search for this log!
	if ( exists $_[HEAP]->{'LOGS'}->{ $logname } ) {
		# Okay, loop over each targetsession, checking if it is valid
		foreach my $TargetSession ( keys %{ $_[HEAP]->{'LOGS'}->{ $logname } } ) {
			# Find out if this session exists
			if ( ! $_[KERNEL]->ID_id_to_session( $TargetSession ) ) {
				# Argh...
				if ( DEBUG ) {
					warn "TargetSession ID $TargetSession does not exist";
				}
			} else {
				# Fire off all the events
				foreach my $event ( keys %{ $_[HEAP]->{'LOGS'}->{ $logname }->{ $TargetSession } } ) {
					# We call events with 5 arguments
					# ARG0 -> CALLER_FILE
					# ARG1 -> CALLER_LINE
					# ARG2 -> Time::HiRes [ gettimeofday ] or plain time()
					# ARG3 -> LOGNAME
					# ARG4 -> Message
					$_[KERNEL]->post(	$TargetSession,
								$event,
								$_[CALLER_FILE],
								$_[CALLER_LINE],
								$time,
								$logname,
								$message,
					);
				}
			}
		}
	} else {
		# Check if we have any *ALL* handlers
		if ( keys %{ $_[HEAP]->{'ALLLOGS'} } > 0 ) {
			# Oh boy, send the log!
			foreach my $TargetSession ( keys %{ $_[HEAP]->{'ALLLOGS'} } ) {
				# Find out if this session exists
				if ( ! $_[KERNEL]->ID_id_to_session( $TargetSession ) ) {
					# Argh...
					if ( DEBUG ) {
						warn "TargetSession ID $TargetSession does not exist";
					}
				} else {
					# Get all the events
					foreach my $event ( keys %{ $_[HEAP]->{'ALLLOGS'}->{ $TargetSession } } ) {
						# We call events with 5 arguments
						# ARG0 -> CALLER_FILE
						# ARG1 -> CALLER_LINE
						# ARG2 -> Time::HiRes [ gettimeofday ] or plain time()
						# ARG3 -> LOGNAME
						# ARG4 -> Message
						$_[KERNEL]->post(	$TargetSession,
									$event,
									$_[CALLER_FILE],
									$_[CALLER_LINE],
									$time,
									$logname,
									$message,
						);
					}
				}
			}
		} else {
			# Ignore this logname
			if ( DEBUG ) {
				warn "Got a LogName: $logname -> Ignoring it because it is not registered";
			}
		}
	}

	# All done!
	return 1;
}

# Starts the logger!
sub StartLog {
	# Create an alias for ourself
	$_[KERNEL]->alias_set( $_[HEAP]->{'ALIAS'} );

	# All done!
	return 1;
}

# Stops the logger
sub StopLog {
	# Remove our alias
	$_[KERNEL]->alias_remove( $_[HEAP]->{'ALIAS'} );

	# Clear our data
	delete $_[HEAP]->{'LOGS'};
	delete $_[HEAP]->{'ALLLOGS'};

	# All done!
	return 1;
}

# End of module
1;

__END__

=head1 NAME

POE::Component::SimpleLog - Perl extension to manage a simple logging system for POE.

=head1 SYNOPSIS

	use POE;
	use POE::Component::SimpleLog;

	# We don't want Time::HiRes
	POE::Component::SimpleLog->new(
		ALIAS		=> 'MyLog',
		PRECISION	=> undef,
	) or die 'Unable to create the Logger';

	# Create our own session to communicate with SimpleLog
	POE::Session->create(
		inline_states => {
			_start => sub {
				# Register for various logs
				$_[KERNEL]->post( 'MyLog', 'REGISTER',
					LOGNAME => 'FOO',
					SESSION => $_[SESSION],
					EVENT => 'GotFOOlog',
				);

				$_[KERNEL]->post( 'MyLog', 'REGISTER',
					LOGNAME => 'BAZ',
					SESSION => $_[SESSION],
					EVENT => 'GotBAZlog',
				);

				# Log something!
				$_[KERNEL]->post( 'MyLog', 'LOG', 'FOO', 'Wow, what a FOO!' );

				# This will be silently discarded -> nobody registered for it
				$_[KERNEL]->post( 'MyLog', 'LOG', 'BOO', 'Wow, what a BAZ!' );

				# OK, enough logging!
				$_[KERNEL]->post( 'MyLog', 'UNREGISTER',
					LOGNAME => 'FOO',
					SESSION => $_[SESSION],
					EVENT => 'GotFOOlog',
				);

				# Now, this log will go nowhere as we just unregistered for it
				$_[KERNEL]->post( 'MyLog', 'LOG', 'FOO', 'Wow, what a FOO!' );

				# Completely remove all registrations!
				$_[KERNEL]->post( 'MyLog', 'UNREGISTERSESSION', $_[SESSION] );

				# Now, this log will go nowhere as we just removed all logs pertaining to our session
				$_[KERNEL]->post( 'MyLog', 'LOG', 'BAZ', 'Wow, what a BAZ!' );

				# We want to eat all we can!
				$_[KERNEL]->post( 'MyLog', 'REGISTER',
					LOGNAME => 'ALL',
					SESSION => $_[SESSION],
					EVENT => 'GotLOG',
				);

				# Now, *ANY* log issued to SimpleLog will go to GotLOG
				$_[KERNEL]->post( 'MyLog', 'LOG', 'LAF', 'Wow, what a LAF!' );

				# We are done!
				$_[KERNEL]->post( 'MyLog', 'SHUTDOWN' );
			},

			'GotFOOlog' => \&gotFOO,
		},
	);

	sub gotFOO {
		# Get the arguments
		my( $file, $line, $time, $name, $message ) = @_[ ARG0 .. ARG4 ];

		# Assumes PRECISION is undef ( regular time() )
		print STDERR "$time ${name}-> $file : $line = $message\n";
	}

=head1 ABSTRACT

	Very simple, and flexible logging system tailored for POE.

=head1 DESCRIPTION

This module is a vastly simplified logging system that can do nice stuff.
Think of this module as a dispatcher for various logs.

This module *DOES NOT* do anything significant with logs, it simply routes them
to the appropriate place ( Events )

You register a log that you are interested in, by telling SimpleLog the target session
and target event. Once that is done, any log messages your program generates ( sent to SimpleLog of course )
will be massaged, then sent to the target session / target event for processing.

This enables an interesting logging system that can be changed during runtime and allow
pluggable interpretation of messages.

One nifty idea you can do with this is:

Your program generally creates logs with the name of 'DEBUG'. You DCC Chat your IRC bot, then
tell it to show all debug messages to you. All the irc bot have to do is register itself for all
'DEBUG' messages, and once you disconnect from the bot, it can unregister itself.

NOTE: There is no pre-determined log levels ( Like Log4j's DEBUG / INFO / FATAL / etc )
Arbitrary names can be used, to great effect. Logs with the names 'CONNECT', 'DB_QUERY', etc can be created.

The standard way to use this module is to do this:

	use POE;
	use POE::Component::SimpleLog;

	POE::Component::SimpleLog->new( ... );

	POE::Session->create( ... );

	POE::Kernel->run();

=head2 Starting SimpleLog

To start SimpleLog, just call it's new method:

	POE::Component::SimpleLog->new(
		'ALIAS'		=>	'MyLogger',
		'PRECISION'	=>	1,
	);

This method will die on error or return success.

This constructor accepts only 2 options.

=over 4

=item C<ALIAS>

This will set the alias SimpleLog uses in the POE Kernel.
This will default TO "SimpleLog"

=item C<PRECISION>

If this value is defined, SimpleLog will use Time::HiRes to get the timestamps.

=back

=head2 Events

SimpleLog is so simple, there are only 5 events available.

=over 4

=item C<REGISTER>

	This event accepts 3 arguments:

	LOGNAME	->	The name of the log to register for
	SESSION	->	The session where the log will go ( Also accepts Session ID's )
	EVENT	->	The event that will be called

	The act of registering for a log can fail if one of the above values are undefined.

	If the LOGNAME eq 'ALL', then that registration will get *ALL* the logs SimpleLog processes

	There is no such thing as an "non-existant" log, registration just makes sure that you will get this log *WHEN* it comes.

	Events that receive the logs will get these:
		ARG0 -> CALLER_FILE
		ARG1 -> CALLER_LINE
		ARG2 -> Time::HiRes [ gettimeofday ] or time()
		ARG3 -> LOGNAME
		ARG4 -> Message

	Here's an example:

	$_[KERNEL]->post( 'SimpleLog', 'REGISTER',
		LOGNAME => 'CONNECTION',
		SESSION => $_[SESSION],
		EVENT => 'GotLOG',
	);

	This is the subroutine that will get the GotLOG event
	sub gotlog {
		# Get the arguments
		my( $file, $line, $time, $name, $message ) = @_[ ARG0 .. ARG4 ];

		# Assumes PRECISION is undef ( regular time() )
		print STDERR "$time ${name}-> $file : $line = $message\n";

		# PRECISION = true ( Time::HiRes )
		print STDERR "$time->[0].$time->[1] ${name}-> $file : $line = $message\n";
	}

=item C<UNREGISTER>

	This event accepts 3 arguments:

	LOGNAME	->	The name of the log to unregister for
	SESSION	->	The session where the log will go ( Also accepts Session ID's )
	EVENT	->	The event that will be called

	Unregistering for a log will fail if the exact 3 arguments were not found in our registry.

	The act of unregistering will mean the session/event no longer receives any log messages.

	NOTE: There might be some logs still traversing POE's queue...

	Here's an example:

	$_[KERNEL]->post( 'SimpleLog', 'UNREGISTER',
		LOGNAME => 'CONNECTION',
		SESSION => $_[SESSION]->ID,
		EVENT => 'GotLOG',
	);

=item C<UNREGISTERSESSION>

	This event accepts 1 argument:

	ARG0	->	The session ( Also accepts Session ID's )

	This is useful for removing all the registrations for a specific session.

	Here's an example:

	$_[KERNEL]->post( 'SimpleLog', 'UNREGISTERSESSION', $_[SESSION] );

=item C<LOG>

	This event accepts 2 arguments:

	ARG0	->	Logname
	ARG1	->	Message

	This is where SimpleLog does it's work, sending the log to the proper events.

	The Logname can be anything, if there is no events registered for it, the message will simply be discarded.

	Here's an example:

	$_[KERNEL]->post( 'SimpleLog', 'LOG', 'CONNECTION', 'A Client just connected!' );

=item C<SHUTDOWN>

	This is the generic SHUTDOWN routine, it will stop all logging.

	Here's an example:

	$_[KERNEL]->post( 'SimpleLog', 'SHUTDOWN' );

=back

=head2 SimpleLog Notes

This module is very picky about capitalization!

All of the options are uppercase, to avoid confusion.

You can enable debugging mode by doing this:

	sub POE::Component::SimpleLog::DEBUG () { 1 }
	use POE::Component::SimpleLog;

=head2 EXPORT

Nothing.

=head1 SEE ALSO

L<POE>

=head1 AUTHOR

Apocalypse E<lt>apocal@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2008 by Apocalypse

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
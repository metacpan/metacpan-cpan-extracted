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
				EVENT => 'GotFOOlog',
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
				EVENT => 'GotFOOlog',
			);

			# Now, *ANY* log issued to SimpleLog will go to GotLOG
			$_[KERNEL]->post( 'MyLog', 'LOG', 'LAF', 'Wow, what a LAF!' );

			# We are done!
			$_[KERNEL]->post( 'MyLog', 'SHUTDOWN' );
		},

		'GotFOOlog' => \&gotFOO,
	},
);

# Start POE
POE::Kernel->run();
exit;

sub gotFOO {
	# Get the arguments
	my( $file, $line, $time, $name, $message ) = @_[ ARG0 .. ARG4 ];

	# Assumes PRECISION is undef ( regular time() )
	print STDERR "$time ${name}-> $file : $line = $message\n";
}
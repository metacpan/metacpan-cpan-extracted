# Declare our package
package POE::Component::Lightspeed::Hack::Kernel;

# Standard stuff to catch errors
use strict qw(subs vars refs);				# Make sure we can't mess up
use warnings FATAL => 'all';				# Enable warnings to catch errors

# Initialize our version
our $VERSION = '1.' . sprintf( "%04d", (qw($Revision: 1082 $))[1] );

# Hack the planet!
package POE::Kernel;

# Standard stuff to catch errors
use strict qw(subs vars refs);				# Make sure we can't mess up
use warnings FATAL => 'all';				# Enable warnings to catch errors

# The generic lightspeed resolve failure sub
sub _explain_lightspeed_failure {
	my( $self, $tag ) = @_;

	# Tell carp to go a few levels above us for the stacktrace
	local $Carp::CarpLevel = 2;

	if ( ASSERT_DATA ) {
		_trap "<dt> The Lightspeed destination '$tag' is not valid!";
	}

	# Complain away!
	$! = ESRCH;
	TRACE_RETVALS  and _carp "<rv> malformed destination: $!";
	ASSERT_RETVALS and _confess "<rv> malformed destination: $!";
}

sub _alias_31 {
	my ($self, $name) = @_;

	if (ASSERT_USAGE) {
		_confess "<us> undefined alias in alias_set()" unless defined $name;
	}

	# Don't overwrite another session's alias.
	my $existing_session = $self->_data_alias_resolve($name);
	if ( defined $existing_session ) {
		if ( $existing_session != ${ $self->[ KR_ACTIVE_SESSION ] } ) {
			$self->_explain_usage( "alias '$name' is in use by another session" );
			return EEXIST;
		}
		return 0;
	}

	# Make sure it doesn't contain any * or / or ,
	if ( $name =~ tr|*/,|| ) {
		$self->_explain_usage( "When Lightspeed is loaded, aliases cannot contain '*' or '/' or ','" );
		return EINVAL;
	}

	$self->_data_alias_add( ${ $self->[ KR_ACTIVE_SESSION ] }, $name );
	return 0;
}

sub _post_31 {
	my ($self, $dest_session, $event_name, @etc) = @_;

	if (ASSERT_USAGE) {
		_confess "<us> destination is undefined in post()" unless defined $dest_session;

		# Argh!
		if ( ! defined $event_name and ( ( ! ref( $dest_session ) and $dest_session =~ m|^poe://|i )
			or ( ref( $dest_session ) eq 'ARRAY' or ref( $dest_session ) eq 'HASH' or ref( $dest_session ) eq 'POE::Component::Lightspeed::Hack::Session' ) ) ) {
			_confess "<us> event is undefined in post()" unless defined $event_name;
		}

		_carp "<us> The '$event_name' event is one of POE's own.  Its effect cannot be achieved by posting it" if exists $POE::Kernel::poes_own_events{$event_name};
	};

	# Is this destination session a fake lightspeed one?
	my $session = $dest_session;
	if ( ! defined $session ) {
		return undef;
	} elsif ( ! ref( $session ) ) {
		if ( $session =~ m|^poe://|i ) {
			# Validate this
			$session = POE::Component::Lightspeed::Router::ValidateDestination( $session );

			# Sanity check
			if ( ! defined $session ) {
				$self->_explain_lightspeed_failure( $dest_session );
				return;
			}

			# Did we get a state?
			if ( ! defined $session->[ POE::Component::Lightspeed::Constants::DEST_STATE ] ) {
				# Sanity checks
				if ( ref( $event_name ) ) {
					if ( POE::Component::Lightspeed::Router::DEBUG ) {
						warn 'Missing state in the specifier, as the argument after the destination was not a plain scalar!';
					}
					return undef;
				}

				# Add it!
				$session->[ POE::Component::Lightspeed::Constants::DEST_STATE ] = $event_name;
			} else {
				# The event name actually is part of the args!
				unshift( @etc, $event_name );
			}
		} else {
			# Attempt to resolve the destination session reference against various things.
			$session = $self->_resolve_session( $session );
			unless ( defined $session ) {
				$self->_explain_resolve_failure( $dest_session );
				return;
			}
		}
	} elsif ( ref( $session ) eq 'HASH' or ref( $session ) eq 'ARRAY' ) {
		# Validate this
		$session = POE::Component::Lightspeed::Router::ValidateDestination( $session );

		# Sanity check
		if ( ! defined $session ) {
			$self->_explain_lightspeed_failure( $dest_session );
			return;
		}

		# Since we know it's a lightspeed specifier, shift the args
		unshift( @etc, $event_name );
	} elsif ( ref( $session ) eq 'POE::Component::Lightspeed::Hack::Session' ) {
		# Convert it :)
		$session = [];
		$session->[ POE::Component::Lightspeed::Constants::DEST_KERNEL ] = $dest_session->remote_kernel();
		$session->[ POE::Component::Lightspeed::Constants::DEST_SESSION ] = $dest_session->remote_session();

		# Sanity checks
		if ( ref( $event_name ) ) {
			if ( POE::Component::Lightspeed::Router::DEBUG ) {
				warn 'Missing state in the specifier, as the argument after the destination was not a plain scalar!';
			}
			return undef;
		}

		# Add it!
		$session->[ POE::Component::Lightspeed::Constants::DEST_STATE ] = $event_name;
	} else {
		# Attempt to resolve the destination session reference against various things.
		$session = $self->_resolve_session( $session );
		unless ( defined $session ) {
			$self->_explain_resolve_failure( $dest_session );
			return;
		}
	}

	# Send it off to lightspeed
	if ( ref( $session ) eq 'ARRAY' ) {
		$self->_data_ev_enqueue(
			$self->_resolve_session( $POE::Component::Lightspeed::Router::SES_ALIAS ),
			${ $self->[ KR_ACTIVE_SESSION ] },
			'post',
			ET_POST,
			[ $session, \@etc ],
			( caller )[1,2],
			${ $self->[ KR_ACTIVE_EVENT ] },
			time(),
		);
	} else {
		# Enqueue the event for "now", which simulates FIFO in our
		# time-ordered queue.
		$self->_data_ev_enqueue(
			$session, ${ $self->[ KR_ACTIVE_SESSION ] }, $event_name, ET_POST, \@etc,
			(caller)[1,2], ${ $self->[ KR_ACTIVE_EVENT ] }, time(),
		);
	}

	# All done!
	return 1;
}

sub _lightspeed_post_31 {
	my( $self, $fake_session, $dest_session, $event_name, $etc ) = @_;

	# Enqueue the event for "now", which simulates FIFO in our
	# time-ordered queue.
	$self->_data_ev_enqueue(
		$dest_session,
		$fake_session,
		$event_name,
		ET_POST,
		$etc,
		$fake_session->remote_file(),
		$fake_session->remote_line(),
		$fake_session->remote_state(),
		time(),
	);

	# All done!
	return 1;
}

sub _call_31 {
  	my ($self, $dest_session, $event_name, @etc) = @_;

  	if (ASSERT_USAGE) {
		_confess "<us> destination is undefined in call()" unless defined $dest_session;
		_confess "<us> event is undefined in call()" unless defined $event_name;
		_carp "<us> The '$event_name' event is one of POE's own.  Its effect cannot be achieved by calling it" if exists $POE::Kernel::poes_own_events{$event_name};
  	};

  	# Is this destination session a fake lightspeed one?
  	my $session = $dest_session;
  	if ( ! defined $session ) {
		return undef;
  	} elsif ( ! ref( $session ) ) {
		if ( $session =~ m|^poe://|i ) {
			# Validate the destination and the RSVP
			$session = POE::Component::Lightspeed::Router::ValidateDestination( $session );
			if ( ! defined $session ) {
				$self->_explain_lightspeed_failure( $dest_session );
				return;
			}

			# If we didn't receive the state, assume this is a call() without rsvp
			if ( ! defined $session->[ POE::Component::Lightspeed::Constants::DEST_STATE ] ) {
				# Sanity checks
				if ( ref( $event_name ) ) {
					if ( POE::Component::Lightspeed::Router::DEBUG ) {
						warn 'Missing state in the specifier, as the argument after the destination was not a plain scalar!';
					}
					return undef;
				}

				# Add it!
				$session->[ POE::Component::Lightspeed::Constants::DEST_STATE ] = $event_name;

				# Send it off!
				$self->_data_ev_enqueue(
					$self->_resolve_session( $POE::Component::Lightspeed::Router::SES_ALIAS ),
					${ $self->[ KR_ACTIVE_SESSION ] },
					'post',
					ET_POST,
					[ $session, \@etc ],
					( caller )[1,2],
					${ $self->[ KR_ACTIVE_EVENT ] },
					time(),
				);
			} else {
				my $rsvp = POE::Component::Lightspeed::Router::ValidateDestination( $event_name );
				if ( ! defined $rsvp ) {
					$self->_explain_lightspeed_failure( $event_name );
					return;
				}

				# Send it off!
				$self->_data_ev_enqueue(
					$self->_resolve_session( $POE::Component::Lightspeed::Router::SES_ALIAS ),
					${ $self->[ KR_ACTIVE_SESSION ] },
					'call',
					ET_POST,
					[ $session, $rsvp, \@etc ],
					( caller )[1,2],
					${ $self->[ KR_ACTIVE_EVENT ] },
					time(),
				);
			}

			# Always return undef
			return undef;
		} else {
			# Attempt to resolve the destination session reference against various things.
			$session = $self->_resolve_session( $session );
			unless ( defined $session ) {
				$self->_explain_resolve_failure( $dest_session );
				return;
			}
		}
  	} elsif ( ref( $session ) eq 'HASH' or ref( $session ) eq 'ARRAY' ) {
		# Validate the destination and the RSVP
		$session = POE::Component::Lightspeed::Router::ValidateDestination( $session );
		if ( ! defined $session ) {
			$self->_explain_lightspeed_failure( $dest_session );
			return;
		}

		my $rsvp = POE::Component::Lightspeed::Router::ValidateDestination( $event_name );
		if ( ! defined $rsvp ) {
			$self->_explain_lightspeed_failure( $event_name );
			return;
		}

		# Send it off!
		$self->_data_ev_enqueue(
			$self->_resolve_session( $POE::Component::Lightspeed::Router::SES_ALIAS ),
			${ $self->[ KR_ACTIVE_SESSION ] },
			'call',
			ET_POST,
			[ $session, $rsvp, \@etc ],
			( caller )[1,2],
			${ $self->[ KR_ACTIVE_EVENT ] },
			time(),
		);

		# Always return undef
		return undef;
  	} elsif ( ref( $session ) eq 'POE::Component::Lightspeed::Hack::Session' ) {
		# This is a plain call() without the rsvp

		# Sanity checks
		if ( ref( $event_name ) ) {
			if ( POE::Component::Lightspeed::Router::DEBUG ) {
				warn 'Malformed state';
			}
			return undef;
		}

		# Convert it!
		$session = [];
		$session->[ POE::Component::Lightspeed::Constants::DEST_KERNEL ] = $dest_session->remote_kernel();
		$session->[ POE::Component::Lightspeed::Constants::DEST_SESSION ] = $dest_session->remote_session();
		$session->[ POE::Component::Lightspeed::Constants::DEST_STATE ] = $event_name;

		# Send it off!
		$self->_data_ev_enqueue(
			$self->_resolve_session( $POE::Component::Lightspeed::Router::SES_ALIAS ),
			${ $self->[ KR_ACTIVE_SESSION ] },
			'post',
			ET_POST,
			[ $session, \@etc ],
			( caller )[1,2],
			${ $self->[ KR_ACTIVE_EVENT ] },
			time(),
		);

		# Always return undef
		return undef;
  	}

  	# Dispatch the event right now, bypassing the queue altogether.
  	# This tends to be a Bad Thing to Do.

  	# -><- The difference between synchronous and asynchronous events
  	# should be made more clear in the documentation, so that people
  	# have a tendency not to abuse them.  I discovered in xws that that
  	# mixing the two types makes it harder than necessary to write
  	# deterministic programs, but the difficulty can be ameliorated if
  	# programmers set some base rules and stick to them.

  	# What should we return?
  	if (wantarray) {
  	  my @return_value = (
  	    ($session == ${ $self->[ KR_ACTIVE_SESSION ] })
  	    ? $session->_invoke_state(
		$session, $event_name, \@etc, (caller)[1,2],
		${ $self->[ KR_ACTIVE_EVENT ] }
  	    )
  	    : $self->_dispatch_event(
		$session, ${ $self->[ KR_ACTIVE_SESSION ] },
		$event_name, ET_CALL, \@etc,
		(caller)[1,2], ${ $self->[ KR_ACTIVE_EVENT ] }, time(), -__LINE__
  	    )
  	  );

  	  $! = 0;
  	  return @return_value;
  	}

  	if (defined wantarray) {
  	  my $return_value = (
  	    $session == ${ $self->[ KR_ACTIVE_SESSION ] }
  	    ? $session->_invoke_state(
		$session, $event_name, \@etc, (caller)[1,2],
		${ $self->[ KR_ACTIVE_EVENT ] }
  	    )
  	    : $self->_dispatch_event(
		$session, ${ $self->[ KR_ACTIVE_SESSION ] },
		$event_name, ET_CALL, \@etc,
		(caller)[1,2], ${ $self->[ KR_ACTIVE_EVENT ] }, time(), -__LINE__
  	    )
  	  );

  	  $! = 0;
  	  return $return_value;
  	}

  	if ($session == ${ $self->[ KR_ACTIVE_SESSION ] }) {
  	  $session->_invoke_state(
  	    $session, $event_name, \@etc, (caller)[1,2],
  	    ${ $self->[ KR_ACTIVE_EVENT ] }
  	  );
  	}
  	else {
  	  $self->_dispatch_event(
  	    $session, ${ $self->[ KR_ACTIVE_SESSION ] },
  	    $event_name, ET_CALL, \@etc,
  	    (caller)[1,2], ${ $self->[ KR_ACTIVE_EVENT ] }, time(), -__LINE__
  	  );
  	}

  	$! = 0;
  	return;
}

sub _lightspeed_call_31 {
	my( $self, $fake_session, $dest_session, $event_name, $etc ) = @_;

	# Dispatch the event!
	my @return_value = (
		$self->_dispatch_event(
			$dest_session,
			$fake_session,
			$event_name,
			ET_CALL,
			$etc,
			$fake_session->remote_file(),
			$fake_session->remote_line(),
			$fake_session->remote_state(),
			time(),
			-__LINE__,
		)
	);

	# All done!
	return \@return_value;
}

# Scope our evil stuff :)
BEGIN {
	# Turn off strictness for our nasty stuff
	no strict 'refs';

	# Oh boy, no warnings too :(
	no warnings 'redefine';

	# Now, decide which version we should load...
	my %post_versions = (
		'0.31'		=>	\&_post_31,
		'0.3101'	=>	\&_post_31,
	);
	my %call_versions = (
		'0.31'		=>	\&_call_31,
		'0.3101'	=>	\&_call_31,
	);
	my %lightspeed_post_versions = (
		'0.31'		=>	\&_lightspeed_post_31,
		'0.3101'	=>	\&_lightspeed_post_31,
	);
	my %lightspeed_call_versions = (
		'0.31'		=>	\&_lightspeed_call_31,
		'0.3101'	=>	\&_lightspeed_call_31,
	);
	my %alias_versions = (
		'0.31'		=>	\&_alias_31,
		'0.3101'	=>	\&_alias_31,
	);

	# Make sure we have this version in the dispatch table
	if ( ! exists $post_versions{ $POE::VERSION } ) {
		die 'Your version of Lightspeed does not yet support POE-' . $POE::VERSION;
	}

	# Do our symbol table hackery
	*{'POE::Kernel::alias_set'} = $alias_versions{ $POE::VERSION };
	*{'POE::Kernel::post'} = $post_versions{ $POE::VERSION };
	*{'POE::Kernel::call'} = $call_versions{ $POE::VERSION };
	*{'POE::Kernel::lightspeed_fake_post'} = $lightspeed_post_versions{ $POE::VERSION };
	*{'POE::Kernel::lightspeed_fake_call'} = $lightspeed_call_versions{ $POE::VERSION };
	*{'POE::Kernel::_explain_lightspeed_failure'} = \&POE::Component::Lightspeed::Kernel::_explain_lightspeed_failure;
}

# End of module
1;
__END__

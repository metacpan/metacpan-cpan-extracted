# Declare our package
package POE::Component::Lightspeed::Introspection;

# Standard stuff to catch errors
use strict qw(subs vars refs);				# Make sure we can't mess up
use warnings FATAL => 'all';				# Enable warnings to catch errors

# Initialize our version
our $VERSION = '1.' . sprintf( "%04d", (qw($Revision: 1082 $))[1] );

# Load the constants
use POE::Component::Lightspeed::Constants qw( ACTION_INTROSPECTION FROM_KERNEL FROM_SESSION FROM_STATE FROM_FILE FROM_LINE DEST_KERNEL DEST_SESSION );

# Make sure the router instance is loaded no matter what
use POE::Component::Lightspeed::Router;

# Spawn the Router session to make sure :)
POE::Component::Lightspeed::Router->spawn();

# We export some stuff
require Exporter;
our @ISA = qw( Exporter );
our @EXPORT_OK = qw( list_kernels list_sessions list_states );

# Lists all kernels
sub list_kernels {
	# Get the heap from the router session
	my $heap = $POE::Kernel::poe_kernel->_resolve_session( $POE::Component::Lightspeed::Router::SES_ALIAS )->get_heap();

	# Get the list of kernels
	my @kernels = $heap->{'GRAPH'}->vertices();

	# Return it!
	return \@kernels;
}

# Lists all sessions in kernel X
sub list_sessions {
	my( $dest, $rsvp ) = @_;

	# Validate the kernel
	if ( ! defined $dest ) {
		return undef;
	} elsif ( ref( $dest ) ) {
		if ( ref( $dest ) eq 'POE::Component::Lightspeed::Hack::Session' ) {
			# Cool! Convert it :)
			$dest = $dest->remote_kernel();
		} elsif ( ref( $dest ) ne 'ARRAY' ) {
			return undef;
		}
	}

	# Validate the RSVP
	$rsvp = POE::Component::Lightspeed::Router::ValidateDestination( $rsvp );
	if ( ! defined $rsvp ) {
		return undef;
	}

	# Get the heap from the router session
	my $heap = $POE::Kernel::poe_kernel->_resolve_session( $POE::Component::Lightspeed::Router::SES_ALIAS )->get_heap();

	# Get the session alias
	my @list = $POE::Kernel::poe_kernel->alias_list( $POE::Kernel::poe_kernel->get_active_session() );
	if ( ! defined $list[0] ) {
		$list[0] = $POE::Kernel::poe_kernel->get_active_session()->ID;
	}

	# Construct the from array
	my $from = [];
	$from->[ FROM_KERNEL ] = $heap->{'MYKERNEL'};

	# Add the session
	$from->[ FROM_SESSION ] = $list[0];

	# Add the state
	$from->[ FROM_STATE ] = $POE::Kernel::poe_kernel->get_active_event();

	# Add the file/line
	push( @$from, (caller)[1,2] );

	# Is it a local introspection request?
	if ( $dest eq $heap->{'MYKERNEL'} or $dest eq '*' ) {
		# Send it to the router to emulate a "packet"
		$POE::Kernel::poe_kernel->post(
			$POE::Component::Lightspeed::Router::SES_ALIAS,
			'ACTION_' . ACTION_INTROSPECTION,
			[
				$heap->{'MYKERNEL'},			# MSG_TO
				$heap->{'MYKERNEL'},			# MSG_FROM
				ACTION_INTROSPECTION,			# MSG_ACTION
				[					# MSG_DATA
					'SESSION',			# INTROSPECTION_WHAT
					$from,				# INTROSPECTION_FROM
					$rsvp,				# INTROSPECTION_RSVP
				],
			],
		);
	}

	# Send it off!
	if ( $dest ne $heap->{'MYKERNEL'} ) {
		POE::Component::Lightspeed::Router::SendMessage( $heap, [
			$dest,			# MSG_TO
			undef,			# MSG_FROM
			ACTION_INTROSPECTION,	# MSG_ACTION
			[			# MSG_DATA
				'SESSION',	# INTROSPECTION_WHAT
				$from,		# INTROSPECTION_FROM
				$rsvp,		# INTROSPECTION_RSVP
			],
		] );
	}

	# All done!
	return 1;
}

# Lists all states in session X in kernel Y
sub list_states {
	my( $dest, $rsvp ) = @_;

	# Validate the destination
	if ( ! defined $dest ) {
		return undef;
	} elsif ( ! ref( $dest ) ) {
		# Okay, before we send it to ValidateDestination, we have to make sure there's a '/' at the end to make it happy
		if ( $dest =~ m|^poe://(?:[^/]+)/(?:[^/]+)$| ) {
			$dest .= '/';
		}

		# If it's terribly corrupt, who cares, ValidateDestination will catch it for us :)
		$dest = POE::Component::Lightspeed::Router::ValidateDestination( $dest );
		if ( ! defined $dest ) {
			return undef;
		}
	} elsif ( ref( $dest ) eq 'ARRAY' ) {
		# Must have 2 parts
		if ( scalar( @$dest ) != 2 ) {
			return undef;
		}
	} elsif ( ref( $dest ) eq 'HASH' ) {
		# Must have 2 parts
		if ( ! exists $dest->{'KERNEL'} or ! exists $dest->{'SESSION'} ) {
			return undef;
		} else {
			# Change it into an array
			$dest = [ $dest->{'KERNEL'}, $dest->{'SESSION'} ];
		}
	} elsif ( ref( $dest ) eq 'POE::Component::Lightspeed::Hack::Session' ) {
		# Cool! Convert it :)
		$dest = [ $dest->remote_kernel(), $dest->remote_session() ];
	} else {
		# What the hell is it?
		return undef;
	}

	# Validate the rsvp
	$rsvp = POE::Component::Lightspeed::Router::ValidateDestination( $rsvp );
	if ( ! defined $rsvp ) {
		return undef;
	}

	# Get the heap from the router session
	my $heap = $POE::Kernel::poe_kernel->_resolve_session( $POE::Component::Lightspeed::Router::SES_ALIAS )->get_heap();

	# Construct the from array
	my $from = [];
	$from->[ FROM_KERNEL ] = $heap->{'MYKERNEL'};

	# Add the session
	my @list = $POE::Kernel::poe_kernel->alias_list( $POE::Kernel::poe_kernel->get_active_session() );
	if ( ! defined $list[0] ) {
		$list[0] = $POE::Kernel::poe_kernel->get_active_session()->ID;
	}
	$from->[ FROM_SESSION ] = $list[0];

	# Add the state
	$from->[ FROM_STATE ] = $POE::Kernel::poe_kernel->get_active_event();

	# Add the file/line
	push( @$from, (caller)[1,2] );

	# Is it a local introspection request?
	if ( POE::Component::Lightspeed::Router::FindOurself( $heap->{'MYKERNEL'}, $dest->[ DEST_KERNEL ] ) ) {
		# Send it to the router to emulate a "packet"
		$POE::Kernel::poe_kernel->post(
			$POE::Component::Lightspeed::Router::SES_ALIAS,
			'ACTION_' . ACTION_INTROSPECTION,
			[
				$heap->{'MYKERNEL'},			# MSG_TO
				$heap->{'MYKERNEL'},			# MSG_FROM
				ACTION_INTROSPECTION,			# MSG_ACTION
				[					# MSG_DATA
					'STATE',			# INTROSPECTION_WHAT
					$from,				# INTROSPECTION_FROM
					$rsvp,				# INTROSPECTION_RSVP
					$dest->[ DEST_SESSION ],	# INTROSPECTION_ARGS
				],
			],
		);
	}

	# Send it off!
	POE::Component::Lightspeed::Router::SendMessage( $heap, [
		$dest->[ DEST_KERNEL ],			# MSG_TO
		undef,					# MSG_FROM
		ACTION_INTROSPECTION,			# MSG_ACTION
		[					# MSG_DATA
			'STATE',			# INTROSPECTION_WHAT
			$from,				# INTROSPECTION_FROM
			$rsvp,				# INTROSPECTION_RSVP
			$dest->[ DEST_SESSION ],	# INTROSPECTION_ARGS
		],
	] );

	# All done!
	return 1;
}

# End of module
1;
__END__

=head1 NAME

POE::Component::Lightspeed::Introspection - Discovering your network!

=head1 SYNOPSIS

	use POE;
	use POE::Component::Lightspeed::Client;
	use POE::Component::Lightspeed::Server;
	use POE::Component::Lightspeed::Introspection qw( list_kernels list_sessions list_states );

	# Spawn your client/server session here and connect to the network

	# Find out the kernels in the network
	my $kernels = list_kernels();
	print "Kernels:", join( " ,", @$kernels );

	# Query a specific kernel for it's sessions
		# Remember, we need a RSVP specifier here
		list_sessions( 'kernel1', 'poe://mykernel/mysession/got_sessions' );

		# This rsvp will get 2 events, one from each kernel it queried
		list_sessions( [ qw( kernel1 kernel2 ) ], 'poe://mykernel/mysession/got_sessions' );

		# Inside an event handler where $_[SENDER] is a remote kernel
		list_sessions( $_[SENDER], 'poe://mykernel/mysession/got_sessions' );

	# Query a specific kernel / session for it's states
		# Basically, this accepts the full destination specifier, only without the state parameter
		list_states( 'poe://kernel1/mysession', 'poe://mykernel/mysession/got_states' );

		# This is also allowed
		list_states( [ [ qw( kernel1 kernel2 ) ], 'mysession' ], 'poe://mykernel/mysession/got_states' );

		# Madness, madness!
		list_states( { 'KERNEL' => '*', 'SESSION' => '*' }, 'poe://mykernel/mysession/got_states' );

		# Inside an event handler where $_[SENDER] is a remote kernel
		list_states( $_[SENDER], 'poe://mykernel/mysession/got_states' );

=head1 ABSTRACT

	This module presents an easy API for finding information about the network.

=head1 DESCRIPTION

All you need to do is import the 3 subroutines provided.

=head1 METHODS

=head2 list_kernels

	Requires no arguments

	Returns an arrayref of kernel names

=head2 list_sessions

	Requires two arguments
		- The kernel name to query
			Can be a scalar with the kernel name, or '*'
			Can be an arrayref full of kernel names
			Can be $_[SENDER] when it's a remote kernel

		- The RSVP to send the results
			Must be a fully-qualified destination specifier as explained in the Lightspeed docs

	NOTE: This will return every alias a session has, not only the first alias!

	Returns nothing, the data will be sent to the RSVP
		ARG0 = kernel name
		ARG1 = arrayref of sessions
			Example:
				[
					[	'mysession',
						'secondalias',
						'thirdalias',
					],
					[	'weeble',
					],
					[	'frobnicate',
					]
				]

=head2 list_states

	Requires two arguments
		- The kernel/session to query
			Can be a fully-qualified destination specifier without the state, i.e. 'poe://kernel/session'
			Can be an arrayref as explained in the Lightspeed docs, without the 3rd element set
			Can be a hashref with the KERNEL and SESSION keys
			Can be $_[SENDER] when it's a remote kernel

		- The RSVP to send the results
			Must be a fully-qualified destination specifier as explained in the Lightspeed docs

	NOTE: This will return only one alias per session, to avoid confusion over duplicate aliases

	Returns nothing, the data will be sent to the RSVP
		ARG0 = kernel name
		ARG1 = hashref of sessions -> array of states
			Example:
				{
					'mysession'	=>	[	'_stop',
									'_default',
									'mystate',
									'mystate2',
								],
					'othersession'	=>	[	'floo',
									'bar',
								]
				}

=head1 EXPORT

Exports the 3 subs in EXPORT_OK

=head1 SEE ALSO

L<POE::Component::Lightspeed>

=head1 AUTHOR

Apocalypse E<lt>apocal@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2005 by Apocalypse

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

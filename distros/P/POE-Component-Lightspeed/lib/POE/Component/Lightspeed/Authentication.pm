# Declare our package
package POE::Component::Lightspeed::Authentication;

# Standard stuff to catch errors
use strict qw(subs vars refs);				# Make sure we can't mess up
use warnings FATAL => 'all';				# Enable warnings to catch errors

# Initialize our version
our $VERSION = '1.' . sprintf( "%04d", (qw($Revision: 1082 $))[1] );

# Make sure the router instance is loaded no matter what
use POE::Component::Lightspeed::Router;

# Spawn the Router session to make sure :)
POE::Component::Lightspeed::Router->spawn();

# We export some stuff
require Exporter;
our @ISA = qw( Exporter );
our @EXPORT_OK = qw( auth_register auth_unregister );

# The different types of hooks
our @HOOKS = qw( post call callreply introspection monitor_register monitor_unregister );

# Registers an authentication hook
sub auth_register {
	my( $hook, $sub, $arg ) = @_;

	# Test for a valid hook
	if ( ! defined $hook or ! Array_Search( \@HOOKS, $hook ) ) {
		# Error...
		return undef;
	}

	# Make sure we have a real sub
	if ( ! defined $sub or ! ref( $sub ) or ref( $sub ) ne 'CODE' ) {
		# Error...
		return undef;
	}

	# Make sure we have the argument
	if ( ! defined $arg ) {
		$arg = '*';
	}

	# Get the heap from the router session
	my $heap = $POE::Kernel::poe_kernel->_resolve_session( $POE::Component::Lightspeed::Router::SES_ALIAS )->get_heap();

	# Insert this hook!
	$heap->{'AUTH'}->{ $hook }->{ $arg } = $sub;

	# All done!
	return 1;
}

# Unregisters an authentication hook
sub auth_unregister {
	my( $hook, $arg ) = @_;

	# Test for a valid hook
	if ( defined $hook and Array_Search( \@HOOKS, $hook ) ) {
		# Make sure we have the argument
		if ( ! defined $arg ) {
			$arg = '*';
		}

		# Get the heap from the router session
		my $heap = $POE::Kernel::poe_kernel->_resolve_session( $POE::Component::Lightspeed::Router::SES_ALIAS )->get_heap();

		# Sanity check
		if ( exists $heap->{'AUTH'}->{ $hook } ) {
			if ( exists $heap->{'AUTH'}->{ $hook }->{ $arg } ) {
				# Delete the hook
				delete $heap->{'AUTH'}->{ $hook }->{ $arg };

				# Also, check the hook itself
				if ( keys %{ $heap->{'AUTH'}->{ $hook } } == 0 ) {
					delete $heap->{'AUTH'}->{ $hook };
				}

				# All done!
				return 1;
			}
		}
	}

	# Error...
	return undef;
}

# Searches for something in an array
sub Array_Search {
	# Get the pointer to array
	my $ary = shift;

	# Get the name
	my $name = shift;

	# Iterate over the array
	foreach my $tmp ( @{ $ary } ) {
		if ( $tmp eq $name ) {
			return 1;
		}
	}

	# Failed to find a match
	return 0;
}

# End of module
1;
__END__


=head1 NAME

POE::Component::Lightspeed::Authentication - Protect your local kernel!

=head1 SYNOPSIS

	use POE;
	use POE::Component::Lightspeed::Authentication qw( auth_register auth_unregister );

	# Spawn your client/server session here and connect to the network

	# Register a callback for incoming POST messages heading towards session 'MyPrivateSession'
	auth_register( 'post', \&MyAuthRoutine, 'MyPrivateSession' );

	# Register a callback for incoming CALL messages for any session
	auth_register( 'call', \&MyCallRoutine, '*' );

	# Remove our post callback
	auth_unregister( 'post', 'MyPrivateSession' );

=head1 ABSTRACT

	This module presents an easy API to insert Authentication hooks into Lightspeed

=head1 DESCRIPTION

All you need to do is import the 2 subroutines provided.

=head2 AVAILABLE HOOKS

=head3 post

Hooks into incoming post() calls from remote sessions. The hook subroutine will be given these arguments:

	- 'post'
	- Destination session
	- Destination state
	- The remote session ( extract information from it via $session->remote_kernel/session/state/file/line )

=head3 call

Hooks into incoming call() calls from remote sessions. The hook subroutine will be given these arguments:

	- 'call'
	- Destination session
	- Destination state
	- The RSVP in the format [ KERNEL, SESSION, STATE ]
	- The remote session ( extract information from it via $session->remote_kernel/session/state/file/line )

=head3 callreply

Hooks into incoming post() calls from remote sessions replying to a call(). The hook subroutine will be given these arguments:

	- 'callreply'
	- Destination session
	- Destination state
	- The remote session ( extract information from it via $session->remote_kernel/session/state/file/line )

=head3 introspection

Hooks into incoming introspection requests. The hook subroutine will be given these arguments:

	- 'introspection'
	- 'session' or 'state'

		# The session introspection request will only get 2 more argument:
		- The RSVP in the format [ KERNEL, SESSION, STATE ]
		- The remote session ( extract information from it via $session->remote_kernel/session/state/file/line )

		# The state introspection request will get 3 more arguments:
		- The Destination session
		- The RSVP in the format [ KERNEL, SESSION, STATE ]
		- The remote session ( extract information from it via $session->remote_kernel/session/state/file/line )

=head3 monitor_register

Hooks into incoming monitor requests. The hook subroutine will be given these arguments:

	- 'monitor_register'
	- The various monitor types
	- The argument for the monitor
	- The RSVP for the monitor
	- The remote session ( extract information from it via $session->remote_kernel/session/state/file/line )

=head3 monitor_unregister

Hooks into incoming monitor requests. The hook subroutine will be given these arguments:

	- 'monitor_unregister'
	- The various monitor types
	- The argument for the monitor
	- The RSVP for the monitor
	- The remote session ( extract information from it via $session->remote_kernel/session/state/file/line )

=head2 METHODS

=head3 auth_register

	Requires a minimum of 2 arguments
		- The hook type ( post/call/callreply/introspection )
		- The hook subroutine reference

	The extra argument is the session or the introspection type, defaults to '*' if none was supplied

	Returns true on success, undef on failure

=head3 auth_unregister

	Requires a minimum of 1 argument
		- The hook type ( post/call/callreply/introspection )

	The extra argument is the session or the introspection type, defaults to '*' if none was supplied

	Returns true on success, undef on failure

=head1 EXPORT

Exports the 2 subs in EXPORT_OK

=head1 QUIRKS

	- It will not run the specific auth hook and the generic auth hook ( '*' ), it picks only one to run!

	- Certain types of incoming results can have a RSVP going to our own kernel, those messages are not run through
	  the Authentication system, as it doesn't make sense to have the remote information point to ourself...

	- Yes, the monitor hooks won't work as the Lightspeed::Monitor module is still in the works =]

=head1 SEE ALSO

L<POE::Component::Lightspeed>

=head1 AUTHOR

Apocalypse E<lt>apocal@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2005 by Apocalypse

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

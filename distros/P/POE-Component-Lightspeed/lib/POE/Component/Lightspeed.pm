# Declare our package
package POE::Component::Lightspeed;

# Standard stuff to catch errors
use strict qw(subs vars refs);				# Make sure we can't mess up
use warnings FATAL => 'all';				# Enable warnings to catch errors

# Initialize our version
our $VERSION = '0.05';

# This module is just a documentation placeholder
1;
__END__

=head1 NAME

POE::Component::Lightspeed - The romping grounds of IKC2

=head1 SYNOPSIS

	use POE;
	use POE::Component::Lightspeed::Client;

	# Create a new client session
	POE::Component::Lightspeed::Client->spawn(
		'KERNEL'	=>	'testbox',
		'ADDRESS'	=>	'192.168.1.100',
	);

	# Create our own session to communicate with Lightspeed
	POE::Session->create(
		inline_states => {
			_start		=> sub {
				$_[KERNEL]->alias_set( 'mysession' );

				# Yes, a better way to "monitor" Lightspeed is on the way...
				# For now, just give POE some time to connect
				$_[KERNEL]->delay_set( 'do_stuff', 5 );

				# Demonstration of Lightspeed hackery
				$_[KERNEL]->delay_set( 'confused', 1 );
			},
			'do_stuff'	=> sub {
				# Perfect
				$_[KERNEL]->post( 'poe://otherbox/mysession/ping', 'how are you?' );

				# Wrong
				#$_[KERNEL]->post( 'poe://otherbox/mysession', 'ping', 'how are you?' );
			},
			'pong'		=> sub {
				print "Received 'pong' from " . $_[SENDER]->ID . "\n";
			},
			'confused'	=> sub {
				# Is this a lightspeed session?
				if ( $_[SENDER]->is_lightspeed ) {
					# Yay!
					print "Received Lightspeed request from: '";
				} else {
					print "Received regular request from: '";
				}

				print $_[SENDER]->ID . "' State '" . $_[CALLER_STATE] . "' File '" . $_[CALLER_FILE] . "' Line '" . $_[CALLER_LINE] . "'\n";
		},
	);

	--------

	use POE;
	use POE::Component::Lightspeed::Server;

	# Create a new server session
	POE::Component::Lightspeed::Server->spawn(
		'KERNEL'	=>	'otherbox',
		'ADDRESS'	=>	'192.168.1.100',
	);

	# Create our own session to listen for requests from Lightspeed
	POE::Session->create(
		inline_states => {
			_start		=> sub {
				$_[KERNEL]->alias_set( 'mysession' );
			},
			'ping'	=> sub {
				print "Received 'ping' from " . $_[SENDER]->ID . " -> " . $_[ARG0] . "\n";

				# Perfect
				$_[KERNEL]->post( $_[SENDER], 'pong', 'wassup!' );
				$_[KERNEL]->post( $_[SENDER]->ID, 'pong', 'wazzup!' );

				# Wrong
				#$_[KERNEL]->post( "$_[SENDER]", 'ping', 'wassup!' );

				# Demonstration of Lightspeed hackery
				$_[KERNEL]->post( 'poe://testbox/mysession/confused', 'huH!' );
			},
		},
	);

=head1 ABSTRACT

	This module aims to connect POE kernels into a network, a "botnet" of sorts.

	Furthermore, the venerable IKC is now under design & development towards IKC2.
	Think of this module as a playground for IKC2 ideas, so don't do any serious development around this unless I tell you it's ok!

=head1 CHANGES

=head2 0.05

	- Added POE-0.3101 support
	- Bumped versions of modules so the PAUSE indexer won't complain about it being a lower version

=head2 0.04

	- Added SSL to server/client connections
	- Added passwords to server/client connections
	- Documentation tweaks, as usual
	- Added the AUTHCLIENT parameter to Lightspeed::Server as a hook for accepting connections
	- Added Lightspeed::Authentication to have authentication hooks on the local kernel

=head2 0.03

	- A lot of internal cleanups and tweaks
	- Added the Introspection module

=head2 0.02

	- Documentation cleanups ( I am always a POD newbie )

=head2 0.01

	- Initial release to public :)

=head1 DESCRIPTION

In the Lightspeed world, you have either a server or a client. Obviously, the clients connect to servers. In order
for server kernels to connect to other kernels, you can run a client and a server session in the same process.

Please familiarize yourself with the concepts of IKC, especially it's "destination specifier" stuff.

The big difference between Lightspeed and IKC is that a lot of the bookkeeping stuff has been automated. You no longer
have to publish sessions, nor register for remote sessions. Sending messages is a snap, using the normal $_[KERNEL]->post()
interface everyone is accustomed to, instead of sending to a session to do the work.

Lightspeed goes a step beyond IKC, it does not create "proxy" sessions to relay data back to the remote kernel. Instead, it hacks
into POE::Kernel, POE::Session, and POE::Resource::Events to get them to recognize the destination specifiers and act upon them.

=head2 DESTINATION SPECIFIER

The IKC destination specifier has been expanded a little, now you can send to multiple kernels/sessions at the same time.

	'poe://kernel1,kernel2/session1,session2/state'

Furthermore, the special character '*' signifies "broadcast"

	'poe://*/session1/state'	->	Every kernel in the network ( excludes the current kernel )
	'poe://kernel1/*/state'		-> 	Every session in kernel1 with an alias
	'poe://kernel1/session1/*'	->	Just posts to the state named '*', nothing special here
	'poe://*/*/state'		->	A whole lot of fun!

Also, it's possible to pass the specifier as an arrayref or hashref

ARRAYREF:

	[ kernel, session, state ]

HASHREF:

	{
		'KERNEL'	=>	kernel,
		'SESSION'	=>	session,
		'STATE'		=>	state,
	}

=head2 POST

To post to a remote kernel, there are a few formats allowed.

	$kernel->post( 'poe://kernel/session/state', @args );	# The "Lightspeed" way to do it
	$kernel->post( $_[SENDER], 'state', @args );		# Will work nicely too
	$kernel->post( $_[SENDER]->ID, 'state', @args );	# Ditto
	$kernel->post( [ qw( kernel session state ) ], @args );	# Alternate method of supplying the specifier
	$kernel->post( $_[SENDER], $_[CALLER_STATE], @args )	# Yes, Lightspeed supplies this information too!

These ways will fail horrendously:

	$kernel->post( $_[SENDER], @args );			# No, Lightspeed will not automatically send it back to the originating kernel/session/state!
	$kernel->post( $_[SENDER]->ID, @args );			# Ditto.
	$kernel->post( $_[SENDER]->ID . 'state', @args );	# This will fail if $_[SENDER] is not a remote kernel, but WILL WORK!

=head2 CALL

The concept of a call() cannot be really applied to remote kernels, so you have to supply a "RSVP" destination, the place where
the resulting data from the call() should go.

To call a remote kernel, there are a few formats allowed.

	$kernel->call( 'poe://kernel/session/state', 'poe://kernel/session/state', @args );	# The "Lightspeed" way to do it
	$kernel->call( $_[SENDER], 'state', 'poe://kernel/session/state', @args );		# Will work nicely too
	$kernel->call( $_[SENDER]->ID, 'state', 'poe://kernel/session/state', @args );		# Ditto
	$kernel->call( $_[SENDER], 'state', [ qw( kernel session state ) ], @args );		# Alternate method of supplying the specifier
	$kernel->call( $_[SENDER], $_[CALLER_STATE], 'poe://kernel/session/state', @args );	# Yes, Lightspeed supplies this information too!

These ways will fail horrendously:

	$kernel->call( 'poe://kernel/session/state', @args );					# No RSVP specifier here!
	$kernel->call( $_[SENDER], 'poe://kernel/session/state', @args );			# No remote state!
	$kernel->call( $_[SENDER]->ID . 'state', 'poe://kernel/session/state', @args );		# This will fail if $_[SENDER] is not a remote kernel, but WILL WORK!

=head2 Lightspeed Extras

Being super-friendly as it is, Lightspeed gives the programmer a few extras to make their life easier!

	The predefined event fields will give you the correct information:
		- SENDER
		- CALLER_STATE
		- CALLER_FILE
		- CALLER_LINE

	A few methods has been added to POE::Session ( $_[SENDER] )
		- is_lightspeed
			It returns true if the calling session is on a remote kernel, false otherwise

		These methods are valid only if is_lightspeed() returns true:
			- remote_kernel
				Returns the name of the remote kernel

			- remote_session
				Returns the name of the remote session

			- remote_state
				Returns the name of the remote state

			- remote_file
				Returns the filename that initiated this request

			- remote_line
				Returns the line number that initiated this request

	The $session->ID method returns the following string. This can be used freely as a session specifier, but you still
	have to supply the state. So, it's very possible to do stuff like $_[SENDER]->ID . 'state' and get the right specifier
	to supply.
		'poe://kernel/session/'

	Lightspeed checks the POE Version and matches the appropriate hackery, so if you have an unsupported version
	of POE, it won't work because I don't want to totally screw up POE by using the wrong data. If there's a reason you
	absolutely must have support for POE version X, let me know and I can hack it up.

	Postbacks/Callbacks work properly with $_[SENDER], even when it is a remote kernel :)

=head1 GOTCHAS

	- If you're using a subclass of POE::Session that does not inherit from POE::Session, the lightspeed hackery won't work!

	- The versions of the serializer on both the client/server MUST be the same, Storable is very picky about this!

	- A client cannot connect to a server in the same process

	- Every kernel name in the network must be unique, the default POE::Kernel->ID is useful for this

	- This is not a spanning tree network, that means a cyclic network is allowed. This is the opposite of IRC networks.
		Spanning Tree:
			A - B - D
			    |
			    C

		Cyclic network:
			     /------\
			A - B - C - D
			 \------/

	- Unlike IKC, there is no need to "publish" sessions

	- You post events through the POE::Kernel instance, not to a special session
		$_[KERNEL]->post( 'poe://blah/blah/blah', @args );

	- The characters '*', '/', and ',' is not allowed in kernel names and session aliases

	- Keep in mind, when you are sending objects, that the appropriate modules are loaded in both the sender + receiver

=head1 KNOWN BUGS / TODO LIST

	- Having 2 clients connecting at the same time causes the routing system to go snafu :(

	- Argument parsing isn't as strict as it should be, and funky things will be allowed, like:
		$_[KERNEL]->post( 'poe://kernel1,kernel2,*/session1,session2,*/blah', @args );

	- As of now, Lightspeed will silently drop messages destined towards unknown kernels/sessions

	- Addition of a "monitor" system where you register for callbacks whenever specific things happen:
		- Client connect/disconnect
		- Messages leaving/arriving their destinations
		- General debugging junk

	- Adding the local ip/port to bind to for clients

	- Creating the ClientLite module, similar to the one found in IKC

	- Would be nice for the Lightspeed router to "weigh" specific links and adjust priority to accomodate lag/load

	- More documentation!

=head1 EXPORT

The only exportable stuff is in L<POE::Component::Lightspeed::Constants> which isn't for general consumption.

=head1 SEE ALSO

L<POE>

L<POE::Component::IKC>

L<POE::TIKC>

L<POE::Component::Lightspeed::Server>

L<POE::Component::Lightspeed::Client>

L<POE::Component::Lightspeed::Introspection>

L<POE::Component::Lightspeed::Authentication>

=head1 AUTHOR

Apocalypse E<lt>apocal@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2005 by Apocalypse

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

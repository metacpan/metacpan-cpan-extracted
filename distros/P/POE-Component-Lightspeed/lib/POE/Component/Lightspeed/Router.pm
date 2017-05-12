# Declare our package
package POE::Component::Lightspeed::Router;

# Standard stuff to catch errors
use strict qw(subs vars refs);				# Make sure we can't mess up
use warnings FATAL => 'all';				# Enable warnings to catch errors

# Initialize our version
our $VERSION = '1.' . sprintf( "%04d", (qw($Revision: 1082 $))[1] );

# Set some constants
BEGIN {
	# Debug fun!
	if ( ! defined &DEBUG ) {
		eval "sub DEBUG () { 0 }";
	}
}

# Import what we need
use Carp qw( croak );
use POE;
use Graph::Undirected;

# Time to hack POE!
use POE::Component::Lightspeed::Hack::Session;
use POE::Component::Lightspeed::Hack::Kernel;
use POE::Component::Lightspeed::Hack::Events;

# Import the message constants
use POE::Component::Lightspeed::Constants qw( :ALL );

# Our global session alias
our $SES_ALIAS = undef;

# Spawns an instance of the Router
sub spawn {
	# Are we already loaded?
	if ( defined $SES_ALIAS ) {
		# Debugging info
		if ( DEBUG ) {
			warn 'Tried to start a second instance of the Router, ignoring it...';
		}
		return undef;
	}

	# Get the OOP's type
	my $type = shift;

	# Get our lone option
	$SES_ALIAS = shift;

	# Get the session alias
	if ( ! defined $SES_ALIAS or ! length( $SES_ALIAS ) ) {
		# Debugging info...
		if ( DEBUG ) {
			warn 'Using default ALIAS = lightspeed_router';
		}

		# Set the default
		$SES_ALIAS = 'lightspeed_router';
	}

	# Create the graph object
	my $graph = Graph::Undirected->new;

	# Create the POE Session!
	POE::Session->create(
		'inline_states'	=>	{
			# Generic stuff
			'_start'	=>	sub { $_[KERNEL]->alias_set( $SES_ALIAS ); },
			'_stop'		=>	sub {},
			'_default'	=>	sub {
				warn "SES: ", Data::Dumper::Dumper( $_[SESSION] );
				return 0;
			},

			# Post/Call stuff
			'post'		=>	\&post,
			'call'		=>	\&call,

			# Events from client/server
			'killserver'	=>	\&Server_Shutdown,

			# Link status
			'link_down'	=>	\&Link_Down,
			'link_up'	=>	\&Link_Up,

			# Packet Action mapping
			'ACTION_' . ACTION_HELLO . ''		=>	\&A_HELLO,
			'ACTION_' . ACTION_ROUTEDEL . ''	=>	\&A_ROUTE_DEL,
			'ACTION_' . ACTION_ROUTENEW . ''	=>	\&A_ROUTE_NEW,
			'ACTION_' . ACTION_POST . ''		=>	\&A_POST,
			'ACTION_' . ACTION_CALL . ''		=>	\&A_CALL,
			'ACTION_' . ACTION_CALLREPLY . ''	=>	\&A_POST,
			'ACTION_' . ACTION_INTROSPECTION . ''	=>	\&A_INTROSPECTION,
		},

		# Our own heap
		'heap'		=>	{
			# Stores the sessions associated with specific links
			'SID_WID'	=>	{},
			'WID_SID'	=>	{},

			# Which wheels are part of servers or clients?
			'WID_TYPE'	=>	{},

			# Keep track of the kernels we know of
			# KERNEL => WID
			'KERNEL_WID'	=>	{},
			'WID_KERNEL'	=>	{},
			'MYKERNEL'	=>	undef,

			# Our graph object
			'GRAPH'		=>	$graph,
			'APSP'		=>	$graph->APSP_Floyd_Warshall,

			# Authentication stuff
			'AUTH'		=>	{},

			# Monitor stuff
			'MONITOR'	=>	{},
		},
	) or die 'Unable to create a new session!';

	# Return success
	return 1;
}

# A server session is going down, along with it's links
sub Server_Shutdown {
	# ARG0 = arrayref of wheel ID's

	# Get the real kernel names
	my @edges = ();
	foreach my $w ( @{ $_[ARG0] } ) {
		push( @edges, [ $_[HEAP]->{'MYKERNEL'}, $_[HEAP]->{'WID_KERNEL'}->{ $w } ] );
	}

	# Send it off!
	SendMessage( $_[HEAP], [
		undef,			# MSG_TO
		undef,			# MSG_FROM
		ACTION_ROUTEDEL,	# MSG_ACTION
		\@edges,		# MSG_DATA
	] );

	# All done!
	return 1;
}

# The kernel is telling us to post a message somewhere
sub post {
	# ARG0 = destination, ARG1: args
	my( $sender, $state, $file, $line, $dest, $args ) = @_[ SENDER, CALLER_STATE, CALLER_FILE, CALLER_LINE, ARG0, ARG1 ];

	# Assemble the message
	my @aliases = $_[KERNEL]->alias_list( $sender );

	# Does it have any alias?
	if ( ! defined $aliases[0] ) {
		$aliases[0] = $sender->ID;
	}

	# Which kernels?
	my @kernels = ();

	# Is it the broadcast kernel ( * )?
	if ( ref( $dest->[ DEST_KERNEL ] ) ) {
		if ( $dest->[ DEST_KERNEL ]->[0] eq '*' ) {
			@kernels = [ $_[HEAP]->{'GRAPH'}->vertices() ];
		} else {
			@kernels = @{ $dest->[ DEST_KERNEL ] };
		}
	} else {
		push( @kernels, $dest->[ DEST_KERNEL ] );
	}

	# Process each destination
	my @finalkern = ();
	foreach my $k ( @kernels ) {
		# Make sure it exists
		if ( ! $_[HEAP]->{'GRAPH'}->has_vertex( $k ) ) {
			if ( DEBUG ) {
				warn "Kernel $k does not exist!";
			}
			next;
		}

		# Are we sending to ourself?
		if ( $k eq $_[HEAP]->{'MYKERNEL'} ) {
			post_self(
				$_[HEAP],
				POE::Component::Lightspeed::Hack::Session->new(
					$_[HEAP]->{'MYKERNEL'},
					$aliases[0],
					$state,
					$file,
					$line,
				),
				$dest,
				$args,
			);
		} else {
			# Add it to the kernel list
			push( @finalkern, $k );
		}
	}

	# Send the message!
	SendMessage( $_[HEAP], [
		\@finalkern,				# MSG_TO
		undef,					# MSG_FROM
		ACTION_POST,				# MSG_ACTION
		[					# MSG_DATA
			$dest,				# POST_TO
			[				# POST_FROM
				$_[HEAP]->{'MYKERNEL'},	# DEST_KERNEL
				$aliases[0],		# DEST_SESSION
				$state,			# DEST_STATE
				$file,			# DEST_FILE
				$line,			# DEST_LINE
			],
			$args,				# POST_ARGS
		],
	] );

	# All done!
	return 1;
}

# The kernel is telling us to call a message somewhere
sub call {
	# ARG0 = destination, ARG1 = rsvp, ARG3 = args
	my( $sender, $state, $file, $line, $dest, $rsvp, $args ) = @_[ SENDER, CALLER_STATE, CALLER_FILE, CALLER_LINE, ARG0 .. ARG2 ];

	# Assemble the message
	my @aliases = $_[KERNEL]->alias_list( $sender );

	# Does it have any alias?
	if ( ! defined $aliases[0] ) {
		$aliases[0] = $sender->ID;
	}

	# Which kernels?
	my @kernels = ();

	# Is it the broadcast kernel ( * )?
	if ( ref( $dest->[ DEST_KERNEL ] ) ) {
		if ( $dest->[ DEST_KERNEL ]->[0] eq '*' ) {
			@kernels = [ $_[HEAP]->{'GRAPH'}->vertices() ];
		} else {
			@kernels = @{ $dest->[ DEST_KERNEL ] };
		}
	} else {
		push( @kernels, $dest->[ DEST_KERNEL ] );
	}

	# Process each destination
	my @finalkern = ();
	foreach my $k ( @kernels ) {
		# Make sure it exists
		if ( ! $_[HEAP]->{'GRAPH'}->has_vertex( $k ) ) {
			if ( DEBUG ) {
				warn "Kernel $k does not exist!";
			}
			next;
		}

		# Are we sending to ourself?
		if ( $k eq $_[HEAP]->{'MYKERNEL'} ) {
			# Create the fake session
			my $fake_session = POE::Component::Lightspeed::Hack::Session->new(
				$k,
				$aliases[0],
				$state,
				$file,
				$line,
			);

			# Is it the broadcast session ( * )?
			my @sessions = ();
			if ( ref( $dest->[ DEST_SESSION ] ) ) {
				if ( $dest->[ DEST_SESSION ]->[0] eq '*' ) {
					@sessions = GetSessions();
				} else {
					@sessions = @{ $dest->[ DEST_SESSION ] };
				}
			} else {
				push( @sessions, $dest->[ DEST_SESSION ] );
			}

			# Fire off each session!
			foreach my $s ( @sessions ) {
				# Check if it's a multiple-alias session
				if ( ref( $s ) ) {
					$s = $s->[0];
				}

				# Resolve it into a session ref
				$s = $_[KERNEL]->_resolve_session( $s );

				# Sanity check
				if ( ! defined $s ) {
					return undef;
				}

				# Route it through POE :)
				my @result = $_[KERNEL]->lightspeed_fake_call(
					$fake_session,
					$s,
					$dest->[ DEST_STATE ],
					$args,
				);

				# Where should the RSVP go?
				my @rsvpfinal = ();
				foreach my $r ( @{ $rsvp->[ DEST_KERNEL ] } ) {
					# Make sure it exists
					if ( ! $_[HEAP]->{'GRAPH'}->has_vertex( $r ) ) {
						if ( DEBUG ) {
							warn "Kernel $k does not exist!";
						}
						next;
					}

					# Are we sending to ourself?
					if ( $r eq $_[HEAP]->{'MYKERNEL'} ) {
						post_self(
							$_[HEAP],
							POE::Component::Lightspeed::Hack::Session->new(
								$_[HEAP]->{'MYKERNEL'},
								$aliases[0],
								$state,
								'Lightspeed.pm',
								325,
							),
							$rsvp,
							\@result,
						);
					} else {
						# Add it to the kernel list
						push( @rsvpfinal, $r );
					}
				}

				# Send the message!
				SendMessage( $_[HEAP], [
					\@rsvpfinal,				# MSG_TO
					undef,					# MSG_FROM
					ACTION_CALLREPLY,			# MSG_ACTION
					[					# MSG_DATA
						$rsvp,				# CALLREPLY_TO
						[				# CALLREPLY_FROM
							$_[HEAP]->{'MYKERNEL'},	# FROM_KERNEL
							$aliases[0],		# FROM_SESSION
							$state,			# FROM_STATE
							'Lightspeed.pm',	# FROM_FILE
							348,			# FROM_LINE
						],
						\@result,			# CALLREPLY_ARGS
					],
				] );
			}
		} else {
			# Add it to the kernel list
			push( @finalkern, $k );
		}
	}

	# Send the message!
	SendMessage( $_[HEAP], [
		\@finalkern,				# MSG_TO
		undef,					# MSG_FROM
		ACTION_CALL,				# MSG_ACTION
		[					# MSG_DATA
			$dest,				# CALL_TO
			[				# CALL_FROM
				$_[HEAP]->{'MYKERNEL'},	# FROM_KERNEL
				$aliases[0],		# FROM_SESSION
				$state,			# FROM_STATE
				$file,			# FROM_FILE
				$line,			# FROM_LINE
			],
			$rsvp,				# CALL_RSVP
			$args,				# CALL_ARGS
		],
	] );

	# All done!
	return 1;
}

# Helper to post messages to ourself
sub post_self {
	my( $heap, $fake_session, $dest, $args ) = @_;

	# Is it the broadcast session ( * )?
	my @sessions = ();
	if ( ref( $dest->[ DEST_SESSION ] ) ) {
		if ( $dest->[ DEST_SESSION ]->[0] eq '*' ) {
			@sessions = GetSessions();
		} else {
			@sessions = @{ $dest->[ DEST_SESSION ] };
		}
	} else {
		push( @sessions, $dest->[ DEST_SESSION ] );
	}

	# Fire off each session!
	foreach my $s ( @sessions ) {
		# Check if it's a multiple-alias session
		if ( ref( $s ) ) {
			$s = $s->[0];
		}

		# Resolve it into a session ref
		$s = $POE::Kernel::poe_kernel->_resolve_session( $s );

		# Sanity check
		if ( ! defined $s ) {
			next;
		}

		# Route it through POE :)
		$POE::Kernel::poe_kernel->lightspeed_fake_post(
			$fake_session,
			$s,
			$dest->[ DEST_STATE ],
			$args,
		);
	}

	# All done!
	return 1;
}

# A link is up!
sub Link_Up {
	# ARG0 = wheel id, ARG1 = our kernel name, ARG2 = remote name, ARG3 = Server/Client
	my( $ses, $id, $kernel, $remotekernel, $type ) = @_[ SENDER, ARG0 .. ARG3 ];
	$ses = $ses->ID;

	# The kernel name cannot include * or / or ,
	if ( $kernel =~ tr|*/,|| ) {
		die "The kernel name cannot include '*' or '/' or ','";
	}

	# Ah, now we know our name :)
	if ( ! defined $_[HEAP]->{'MYKERNEL'} ) {
		$_[HEAP]->{'MYKERNEL'} = $kernel;
	} else {
		# Sanity check...
		if ( $_[HEAP]->{'MYKERNEL'} ne $kernel ) {
			die 'Using different kernel names in the same process is not supported!';
		}
	}

	# We do some sanity checks here
	if ( $_[HEAP]->{'GRAPH'}->has_vertex( $remotekernel ) ) {
		# A new node wants to join, but we already have the same kernel name!
		warn "Detected same kernel name in use - $remotekernel";
		$_[KERNEL]->call( $ses, 'killclient', $id );
		return undef;
	}

	# Store it!
	push( @{ $_[HEAP]->{'SID_WID'}->{ $ses } }, $id );
	$_[HEAP]->{'WID_SID'}->{ $id } = $ses;
	$_[HEAP]->{'WID_TYPE'}->{ $id } = $type;
	$_[HEAP]->{'KERNEL_WID'}->{ $remotekernel } = $id;
	$_[HEAP]->{'WID_KERNEL'}->{ $id } = $remotekernel;

	# Get the edges
	my @edges = $_[HEAP]->{'GRAPH'}->edges();
	if ( scalar( @edges ) == 1 ) {
		@edges = ( $edges[0]->[0], $edges[0]->[1] );
	}

	# Send our kernel info
	$_[KERNEL]->post( $ses, 'send', $id, [
		$remotekernel,	# MSG_TO
		$kernel,	# MSG_FROM
		ACTION_HELLO,	# MSG_ACTION
		\@edges,	# MSG_DATA
	] );
}

# A link is down!
sub Link_Down {
	# ARG0 = wheel id
	my( $ses, $id ) = @_[ SENDER, ARG0 ];
	$ses = $ses->ID;
	my $kernel = $_[HEAP]->{'WID_KERNEL'}->{ $id };

	# Remove it from that session
	$_[HEAP]->{'SID_WID'}->{ $ses } = [ grep { $_ ne $id } @{ $_[HEAP]->{'SID_WID'}->{ $ses } } ];
	delete $_[HEAP]->{'WID_SID'}->{ $id };
	delete $_[HEAP]->{'SID_WID'}->{ $ses } if scalar( @{ $_[HEAP]->{'SID_WID'}->{ $ses } } ) == 0;

	# Delete this edge from our graph
	$_[HEAP]->{'GRAPH'}->delete_edge( $_[HEAP]->{'MYKERNEL'}, $kernel );

	# Update the APSP
	$_[HEAP]->{'APSP'} = $_[HEAP]->{'GRAPH'}->APSP_Floyd_Warshall;

	# Are any kernels isolated now ( no way to reach them )
	foreach my $node ( $_[HEAP]->{'GRAPH'}->vertices ) {
		if ( $node eq $_[HEAP]->{'MYKERNEL'} ) {
			next;
		}

		if ( ! $_[HEAP]->{'APSP'}->is_reachable( $_[HEAP]->{'MYKERNEL'}, $node ) ) {
			# This kernel is isolated, delete it
			$_[HEAP]->{'GRAPH'}->delete_vertex( $node );

			# Update the APSP
			$_[HEAP]->{'APSP'} = $_[HEAP]->{'GRAPH'}->APSP_Floyd_Warshall;
		}
	}

	# Remove it from the wheel mapping
	delete $_[HEAP]->{'KERNEL_WID'}->{ $kernel };
	delete $_[HEAP]->{'WID_KERNEL'}->{ $id };

	# Are we responsible?
	if ( $_[HEAP]->{'WID_TYPE'}->{ $id } eq 'Server' or ! $_[HEAP]->{'GRAPH'}->has_vertex( $kernel ) ) {
		# Let all kernels know
		SendMessage( $_[HEAP], [
			undef,					# MSG_TO
			undef,					# MSG_FROM
			ACTION_ROUTEDEL,			# MSG_ACTION
			[ $kernel, $_[HEAP]->{'MYKERNEL'} ],	# MSG_DATA
		] );
	}

	# One last piece of deletion
	delete $_[HEAP]->{'WID_TYPE'}->{ $id };

	# All done!
	return 1;
}

# Processes a HELLO message
sub A_HELLO {
	# ARG0 = data packet, ARG1 = wheel id
	my $msg = $_[ARG0];

	# Add it to our graph
	$_[HEAP]->{'GRAPH'}->add_weighted_edge( $_[HEAP]->{'MYKERNEL'}, $msg->[ MSG_FROM ], 1 );

	# Update the APSP
	$_[HEAP]->{'APSP'} = $_[HEAP]->{'GRAPH'}->APSP_Floyd_Warshall;

	# Store the new edges
	my @edges = ();
	if ( scalar( @{ $msg->[ MSG_DATA ] } ) > 0 ) {
		if ( ! ref( $msg->[ MSG_DATA ]->[0] ) ) {
			# Single edge
			if ( ! $_[HEAP]->{'GRAPH'}->has_edge( $msg->[ MSG_DATA ]->[0], $msg->[ MSG_DATA ]->[1] ) ) {
				push( @edges, [ $msg->[ MSG_DATA ]->[0], $msg->[ MSG_DATA ]->[1] ] );
			}
		} else {
			foreach my $e ( @{ $msg->[ MSG_DATA ] } ) {
				# Do we know about this already?
				if ( ! $_[HEAP]->{'GRAPH'}->has_edge( $e->[0], $e->[1] ) ) {
					# This is new to us
					push( @edges, $e );
				}
			}
		}
	}

	# This sucks.
	my @targets = $_[HEAP]->{'GRAPH'}->vertices;
	@targets = grep { $_ ne $msg->[ MSG_FROM ] } @targets;

	# Broadcast this new info to our network
	if ( scalar( @edges ) > 0 ) {
		# Add them all to the graph
		foreach my $e ( @edges ) {
			$_[HEAP]->{'GRAPH'}->add_weighted_edge( $e->[0], $e->[1], 1 );
		}

		# Update the APSP
		$_[HEAP]->{'APSP'} = $_[HEAP]->{'GRAPH'}->APSP_Floyd_Warshall;

		# Add our link to the edges
		push( @edges, [ $_[HEAP]->{'MYKERNEL'}, $msg->[ MSG_FROM ] ] );
	} else {
		# Add our link to the edges
		@edges = ( $_[HEAP]->{'MYKERNEL'}, $msg->[ MSG_FROM ] );
	}

	# Inform the network about our new link!
	SendMessage( $_[HEAP], [
		\@targets,		# MSG_TO
		undef,			# MSG_FROM
		ACTION_ROUTENEW,	# MSG_ACTION
		\@edges,		# MSG_DATA
	] );

	# All done!
	return 1;
}

# Processes ROUTE_NEW messages
sub A_ROUTE_NEW {
	# ARG0 = data packet, ARG1 = wheel id
	my $msg = $_[ARG0];

	# Is it for us?
	if ( FindOurself( $_[HEAP]->{'MYKERNEL'}, $msg->[ MSG_TO ] ) ) {
		# Process each edge
		my $edges = [];
		if ( ! ref( $msg->[ MSG_DATA ]->[0] ) ) {
			push( @$edges, [ $msg->[ MSG_DATA ]->[0], $msg->[ MSG_DATA ]->[1] ] );
		} else {
			$edges = $msg->[ MSG_DATA ];
		}

		# Do it!
		foreach my $e ( @$edges ) {
			# Do we know about this already?
			if ( ! $_[HEAP]->{'GRAPH'}->has_edge( $e->[0], $e->[1] ) ) {
				# Add it!
				$_[HEAP]->{'GRAPH'}->add_weighted_edge( $e->[0], $e->[1], 1 );
			} else {
				if ( DEBUG ) {
					warn "ROUTE_NEW -> discarding known edge: $e->[0] <=> $e->[1]";
				}
			}
		}

		# Update the APSP
		$_[HEAP]->{'APSP'} = $_[HEAP]->{'GRAPH'}->APSP_Floyd_Warshall;
	}

#	# Find LINK-MISS hits
#	foreach my $link ( $_[HEAP]->{'GRAPH'}->vertices() ) {
#		# Skip the sender and ourself
#		if ( $link eq $_[HEAP]->{'MYKERNEL'} or $link eq $msg->[ MSG_FROM ] ) { next }
#
#		# Find it in the REALTO
#		if ( ( ! ref( $msg->[ MSG_REALTO ] ) and $msg->[ MSG_REALTO ] ne $link ) or ! Array_Search( $msg->[ MSG_REALTO ], $link ) ) {
#			# Add this link to the message
#			if ( ! ref( $msg->[ MSG_TO ] ) ) {
#				$msg->[ MSG_TO ] = [ $msg->[ MSG_TO ], $link ];
#			} else {
#				push( @{ $msg->[ MSG_TO ] }, $link );
#			}
#
#			# Add it to the REALTO too
#			if ( ! ref( $msg->[ MSG_REALTO ] ) ) {
#				$msg->[ MSG_REALTO ] = [ $msg->[ MSG_REALTO ], $link ];
#			} else {
#				push( @{ $msg->[ MSG_REALTO ] }, $link );
#			}
#		}
#	}

	# Do whatever is necessary with this packet
	SendMessage( $_[HEAP], $msg );

	# All done!
	return 1;
}

# Processes a ROUTE_DEL message
sub A_ROUTE_DEL {
	# ARG0 = data packet, ARG1 = wheel id
	my $msg = $_[ARG0];

	# Is it for us?
	if ( FindOurself( $_[HEAP]->{'MYKERNEL'}, $msg->[ MSG_TO ] ) ) {
		# Process each edge
		my @edges = ();
		if ( ! ref( $msg->[ MSG_DATA ]->[0] ) ) {
			push( @edges, [ $msg->[ MSG_DATA ]->[0], $msg->[ MSG_DATA ]->[1] ] );
		} else {
			@edges = @{ $msg->[ MSG_DATA ] };
		}

		# Do it!
		foreach my $e ( @edges ) {
			# Delete this edge from our graph
			$_[HEAP]->{'GRAPH'}->delete_edge( $e->[0], $e->[1] );

			# Update the APSP
			$_[HEAP]->{'APSP'} = $_[HEAP]->{'GRAPH'}->APSP_Floyd_Warshall;

			# Are any kernels isolated now ( no way to reach them )
			foreach my $kernel ( $_[HEAP]->{'GRAPH'}->vertices ) {
				if ( $kernel eq $_[HEAP]->{'MYKERNEL'} ) {
					next;
				}

				if ( ! $_[HEAP]->{'APSP'}->is_reachable( $_[HEAP]->{'MYKERNEL'}, $kernel ) ) {
					# This kernel is isolated, delete it
					$_[HEAP]->{'GRAPH'}->delete_vertex( $kernel );

					# Update the APSP
					$_[HEAP]->{'APSP'} = $_[HEAP]->{'GRAPH'}->APSP_Floyd_Warshall;
				}
			}
		}
	}

#	# Find LINK-MISS hits
#	foreach my $link ( $_[HEAP]->{'GRAPH'}->vertices() ) {
#		# Skip the sender and ourself
#		if ( $link eq $_[HEAP]->{'MYKERNEL'} or $link eq $msg->[ MSG_FROM ] ) { next }
#
#		# Find it in the REALTO
#		if ( ( ! ref( $msg->[ MSG_REALTO ] ) and $msg->[ MSG_REALTO ] ne $link ) or ! Array_Search( $msg->[ MSG_REALTO ], $link ) ) {
#			# Add this link to the message
#			if ( ! ref( $msg->[ MSG_TO ] ) ) {
#				$msg->[ MSG_TO ] = [ $msg->[ MSG_TO ], $link ];
#			} else {
#				push( @{ $msg->[ MSG_TO ] }, $link );
#			}
#
#			# Add it to the REALTO too
#			if ( ! ref( $msg->[ MSG_REALTO ] ) ) {
#				$msg->[ MSG_REALTO ] = [ $msg->[ MSG_REALTO ], $link ];
#			} else {
#				push( @{ $msg->[ MSG_REALTO ] }, $link );
#			}
#		}
#	}

	# Do whatever is necessary with this packet
	SendMessage( $_[HEAP], $msg );

	# All done!
	return 1;
}

# Processes POST messages
sub A_POST {
	# ARG0 = data packet, ARG1 = wheel id
	my $msg = $_[ARG0];

	# Is it for us?
	if ( FindOurself( $_[HEAP]->{'MYKERNEL'}, $msg->[ MSG_TO ] ) ) {
		# Create the fake session
		my $fake_session = POE::Component::Lightspeed::Hack::Session->new( @{ $msg->[ MSG_DATA ]->[ POST_FROM ] } );

		# Determine the type
		my $type;
		if ( $_[STATE] eq 'ACTION_0' ) {
			$type = 'post';
		} else {
			$type = 'callreply';
		}

		# Short-circuit all our AUTH crap
		if ( ! exists $_[HEAP]->{'AUTH'}->{ $type } ) {
			# Okay, send it!
			post_self(
				$_[HEAP],
				$fake_session,
				$msg->[ MSG_DATA ]->[ POST_TO ],
				$msg->[ MSG_DATA ]->[ POST_ARGS ],
			);
		} else {
			# Find out the sessions
			my @sessions = ();
			if ( ! ref( $msg->[ MSG_DATA ]->[ POST_TO ]->[ DEST_SESSION ] ) ) {
				push( @sessions, $msg->[ MSG_DATA ]->[ POST_TO ]->[ DEST_SESSION ] );
			} else {
				push( @sessions, @{ $msg->[ MSG_DATA ]->[ POST_TO ]->[ DEST_SESSION ] } );
			}

			# Loop over the sessions
			foreach my $ses ( @sessions ) {
				# Authenticate it!
				if ( Authenticate( $_[HEAP], $type, $ses, $msg->[ MSG_DATA ]->[ POST_TO ]->[ DEST_STATE ], undef, $fake_session ) ) {
					# Okay, send it!
					post_self(
						$_[HEAP],
						$fake_session,
						[ $_[HEAP]->{'MYKERNEL'}, $ses, $msg->[ MSG_DATA ]->[ POST_TO ]->[ DEST_STATE ] ],
						$msg->[ MSG_DATA ]->[ POST_ARGS ],
					);
				} else {
					# Hook returned false, drop it
					if ( DEBUG ) {
						warn "Authentication hook returned false, not sending to session $ses";
					}
				}
			}
		}
	}

	# Do whatever is necessary with this packet
	SendMessage( $_[HEAP], $msg );

	# All done!
	return 1;
}

# Processes CALL messages
sub A_CALL {
	# ARG0 = data packet, ARG1 = wheel id
	my $msg = $_[ARG0];

	# Is it for us?
	if ( FindOurself( $_[HEAP]->{'MYKERNEL'}, $msg->[ MSG_TO ] ) ) {
		# Create the fake session
		my $fake_session = POE::Component::Lightspeed::Hack::Session->new( @{ $msg->[ MSG_DATA ]->[ CALL_FROM ] } );

		# Which session are we sending this to?
		my @sessions = ();
		if ( ! ref( $msg->[ MSG_DATA ]->[ CALL_TO ]->[ DEST_SESSION ] ) ) {
			# Are we doing all sessions?
			if ( $msg->[ MSG_DATA ]->[ CALL_TO ]->[ DEST_SESSION ] eq '*' ) {
				@sessions = GetSessions();
			} else {
				$sessions[0] = $msg->[ MSG_DATA ]->[ CALL_TO ]->[ DEST_SESSION ];
			}
		} else {
			@sessions = @{ $msg->[ MSG_DATA ]->[ CALL_TO ]->[ DEST_SESSION ] };
		}

		# Do our job!
		foreach my $ses ( @sessions ) {
			# Check if it's a multiple-alias session
			if ( ref( $ses ) ) {
				$ses = $ses->[0];
			}

			# Okay, check if the session exists
			my $sesreal = $_[KERNEL]->_resolve_session( $ses );
			if ( ! defined $sesreal ) {
				# Error...
				if ( DEBUG ) {
					warn "Unknown session: $ses\n" . Data::Dumper::Dumper( $msg );
				}
				next;
			}

			# Authenticate or move on
			if ( ! exists $_[HEAP]->{'AUTH'}->{'call'} or Authenticate( $_[HEAP], 'call', $ses, $msg->[ MSG_DATA ]->[ CALL_TO ]->[ DEST_STATE ], $msg->[ MSG_DATA ]->[ CALL_RSVP ], $fake_session ) ) {
				# Call it!
				my $args = $_[KERNEL]->lightspeed_fake_call(
					$fake_session,
					$sesreal,
					$msg->[ MSG_DATA ]->[ CALL_TO ]->[ DEST_STATE ],
					$msg->[ MSG_DATA ]->[ CALL_ARGS ],
				);

				# Return it back to the RSVP
				SendMessage( $_[HEAP], [
					$msg->[ MSG_DATA ]->[ CALL_RSVP ]->[ DEST_KERNEL ],		# MSG_TO
					undef,								# MSG_FROM
					ACTION_CALLREPLY,						# MSG_ACTION
					[								# MSG_DATA
						$msg->[ MSG_DATA ]->[ CALL_RSVP ],			# CALLREPLY_TO
						[							# CALLREPLY_FROM
							$_[HEAP]->{'MYKERNEL'},				# FROM_KERNEL
							$ses,						# FROM_SESSION
							$msg->[ MSG_DATA ]->[ CALL_TO ]->[ DEST_STATE ],# FROM_STATE
							'Lightspeed.pm',				# FROM_FILE
							1,						# FROM_LINE
						],
						$args,							# CALLREPLY_ARGS
					],
				] );
			} else {
				# Failed authentication
				if ( DEBUG ) {
					warn "Authentication hook returned false, not sending to session $ses";
				}
			}
		}
	}

	# Do whatever is necessary with this packet
	SendMessage( $_[HEAP], $msg );

	# All done!
	return 1;
}

# processes INTROSPECTION messages
sub A_INTROSPECTION {
	# ARG0 = data packet, ARG1 = wheel id
	my $msg = $_[ARG0];

	# Is it for us?
	if ( FindOurself( $_[HEAP]->{'MYKERNEL'}, $msg->[ MSG_TO ] ) ) {
		# Create the fake session
		my $fake_session = POE::Component::Lightspeed::Hack::Session->new( @{ $msg->[ MSG_DATA ]->[ INTROSPECTION_FROM ] } );

		# Okay, is it a SESSION or STATE request?
		if ( $msg->[ MSG_DATA ]->[ INTROSPECTION_WHAT ] eq 'SESSION' ) {
			# Authenticate or move on
			if ( ! exists $_[HEAP]->{'AUTH'}->{'introspection'} or Authenticate( $_[HEAP], 'introspection', 'session', undef, $msg->[ MSG_DATA ]->[ INTROSPECTION_RSVP ], $fake_session ) ) {
				# Get the list of sessions and send it back!
				my @sessions = GetSessions();

				# Now, is the rsvp towards ourself?
				if ( FindOurself( $_[HEAP]->{'MYKERNEL'}, $msg->[ MSG_DATA ]->[ INTROSPECTION_RSVP ]->[ DEST_KERNEL ] ) ) {
					# Send it to ourself...
					post_self(
						$_[HEAP],
						$fake_session,
						$msg->[ MSG_DATA ]->[ INTROSPECTION_RSVP ],
						[ $_[HEAP]->{'MYKERNEL'}, \@sessions ],
					);
				}

				# Send it back to the RSVP!
				SendMessage( $_[HEAP], [
					$msg->[ MSG_DATA ]->[ INTROSPECTION_RSVP ]->[ DEST_KERNEL ],	# MSG_TO
					undef,								# MSG_FROM
					ACTION_POST,							# MSG_ACTION
					[								# MSG_DATA
						$msg->[ MSG_DATA ]->[ INTROSPECTION_RSVP ],		# POST_TO
						$msg->[ MSG_DATA ]->[ INTROSPECTION_FROM ],		# POST_FROM
						[ $_[HEAP]->{'MYKERNEL'}, \@sessions ],			# POST_ARGS
					],
				] );
			} else {
				# Failed Authentication
				if ( DEBUG ) {
					warn "Authentication hook returned false, not doing introspection of sessions";
				}
			}
		} elsif ( $msg->[ MSG_DATA ]->[ INTROSPECTION_WHAT ] eq 'STATE' ) {
			# Authenticate or move on
			if ( ! exists $_[HEAP]->{'AUTH'}->{'introspection'} or Authenticate( $_[HEAP], 'introspection', 'state', $msg->[ MSG_DATA ]->[ INTROSPECTION_ARGS ], $msg->[ MSG_DATA ]->[ INTROSPECTION_RSVP ], $fake_session ) ) {
				# Loop through the sessions
				my %data = ();
				my @sessions = ();

				# Is it the special '*' session flag?
				if ( ! ref( $msg->[ MSG_DATA ]->[ INTROSPECTION_ARGS ] ) ) {
					if ( $msg->[ MSG_DATA ]->[ INTROSPECTION_ARGS ] eq '*' ) {
						@sessions = GetSessions();
					} else {
						$sessions[0] = $msg->[ MSG_DATA ]->[ INTROSPECTION_ARGS ];
					}
				} else {
					@sessions = @{ $msg->[ MSG_DATA ]->[ INTROSPECTION_ARGS ] };
				}

				foreach my $ses ( @sessions ) {
					# Check if it's a multiple-alias session
					if ( ref( $ses ) ) {
						$ses = $ses->[0];
					}

					# Is it a valid session?
					my $sesreal = $_[KERNEL]->_resolve_session( $ses );
					if ( ! defined $sesreal ) {
						# Error...
						if ( DEBUG ) {
							warn "Unknown session: $ses";
						}
						next;
					}

					# Okay, we have the session reference, HAX0R TIME!
					$data{ $ses } = [ keys %{ $sesreal->[ POE::Session::SE_STATES ] } ];
				}

				# Now, is the rsvp towards ourself?
				if ( FindOurself( $_[HEAP]->{'MYKERNEL'}, $msg->[ MSG_DATA ]->[ INTROSPECTION_RSVP ]->[ DEST_KERNEL ] ) ) {
					# Send it to ourself...
					post_self(
						$_[HEAP],
						$fake_session,
						$msg->[ MSG_DATA ]->[ INTROSPECTION_RSVP ],
						[ $_[HEAP]->{'MYKERNEL'}, \%data ],
					);
				}

				# Send it back to the RSVP!
				SendMessage( $_[HEAP], [
					$msg->[ MSG_DATA ]->[ INTROSPECTION_RSVP ]->[ DEST_KERNEL ],	# MSG_TO
					undef,								# MSG_FROM
					ACTION_POST,							# MSG_ACTION
					[								# MSG_DATA
						$msg->[ MSG_DATA ]->[ INTROSPECTION_RSVP ],		# POST_TO
						$msg->[ MSG_DATA ]->[ INTROSPECTION_FROM ],		# POST_FROM
						[ $_[HEAP]->{'MYKERNEL'}, \%data ],			# POST_ARGS
					],
				] );
			} else {
				# Failed Authentication
				if ( DEBUG ) {
					warn "Authentication hook returned false, not doing introspection of states";
				}
			}
		} else {
			# Unknown request!
			if ( DEBUG ) {
				warn "Unknown INTROSPECTION_WHAT -> " . Data::Dumper::Dumper( $msg );
			}
		}
	}

	# Do whatever is necessary with this packet
	SendMessage( $_[HEAP], $msg );

	# All done!
	return 1;
}

# Subroutine to authenticate whatever we can
sub Authenticate {
	my( $heap, $type, $ses, $arg, $rsvp, $fake_session ) = @_;

	# Check if there's a hook
	if ( exists $heap->{'AUTH'}->{ $type } ) {
		# Check again
		if ( exists $heap->{'AUTH'}->{ $type }->{ $ses } ) {
			# post/callreply messages do not have RSVP
			if ( $type eq 'post' or $type eq 'callreply' ) {
				if ( $heap->{'AUTH'}->{ $type }->{ $ses }->( $type, $ses, $arg, $fake_session ) ) {
					return 1;
				} else {
					return undef;
				}
			} else {
				if ( $heap->{'AUTH'}->{ $type }->{ $ses }->( $type, $ses, $arg, $rsvp, $fake_session ) ) {
					return 1;
				} else {
					return undef;
				}
			}
		} else {
			# Try the catch-all hook
			if ( exists $heap->{'AUTH'}->{ $type }->{'*'} ) {
				# post/callreply messages do not have RSVP
				if ( $type eq 'post' or $type eq 'callreply' ) {
					if ( $heap->{'AUTH'}->{ $type }->{'*'}->( $type, $ses, $arg, $fake_session ) ) {
						return 1;
					} else {
						return undef;
					}
				} else {
					if ( $heap->{'AUTH'}->{ $type }->{'*'}->( $type, $ses, $arg, $rsvp, $fake_session ) ) {
						return 1;
					} else {
						return undef;
					}
				}
			} else {
				# No hook available
				return 1;
			}
		}
	} else {
		# No hook available
		return 1;
	}
}

# Helper sub to get the list of sessions with aliases
sub GetSessions {
	# Big thanks to POE::API::Peek for this code

	my @sessions = ();
	my $kr_sessions = $poe_kernel->[ POE::Kernel::KR_SESSIONS ];
	foreach my $key ( keys %$kr_sessions ) {
		# Skip over the Kernel itself
		next if $key =~ /POE::Kernel/;

		# Get the alias
		my @list = $poe_kernel->alias_list( $kr_sessions->{ $key }->[ POE::Kernel::SS_SESSION ] );
		if ( defined $list[0] ) {
			push( @sessions, [ @list ] );
		}
	}

	# All done!
	return @sessions;
}

# Helper to find if we are the target of a destination
sub FindOurself {
	my( $our, $dest ) = @_;

	# If destination is unspecified, then obviously not us
	if ( ! defined $dest ) {
		if ( DEBUG ) {
			Carp::confess( "Undefined destination!" );
		}
		return 0;
	}

	# Is it an arrayref?
	if ( ref( $dest ) ) {
		# Find ourself in it...
		foreach my $t ( @$dest ) {
			if ( $our eq $t ) {
				return 1;
			}
		}

		# Got here, didn't find it
		return 0;
	} else {
		# Is it *
		if ( $dest eq '*' ) {
			return 1;
		} elsif ( $dest eq $our ) {
			return 1;
		} else {
			return 0;
		}
	}
}

# Helper subroutine to parse destination scalars
sub ValidateDestination {
	my $dest = shift;

	# Simple checks
	if ( ! defined $dest ) {
		return undef;
	}

	# Okay, if it is a simple scalar we pull the values out
	if ( ! ref( $dest ) ) {
		if( $dest =~ m|^poe://(.+)/(.+)/(.+)$|i ) {
			# Set the stuff
			$dest = [ $1, $2, $3 ];
		} elsif ( $dest =~ m|^poe://(.+)/(.+)/$|i ) {
			# Set the stuff
			$dest = [ $1, $2 ];
		} else {
			if ( DEBUG ) {
				warn "The string is malformed: $dest";
			}
			return undef;
		}
	} else {
		if ( ref( $dest ) eq 'HASH' ) {
			# Make sure we have all 3 parts
			unless ( exists $dest->{'KERNEL'} and exists $dest->{'SESSION'} and exists $dest->{'STATE'} ) {
				if ( DEBUG ) {
					warn "Destination does not have all 3 parts -" . Data::Dumper::Dumper( $dest );
				}
				return undef;
			} else {
				# Convert it into an array
				$dest = [
					$dest->{'KERNEL'},
					$dest->{'SESSION'},
					$dest->{'STATE'}
				];
			}
		} elsif ( ref( $dest ) eq 'ARRAY' ) {
			# Make sure we have all 3 parts
			if ( scalar( @$dest ) != 3 ) {
				if ( DEBUG ) {
					warn "Destination does not have all 3 parts -" . Data::Dumper::Dumper( $dest );
				}
				return undef;
			}
		} else {
			# Unknown reference here...
			if ( DEBUG ) {
				warn "Destination is a unknown reference -" . Data::Dumper::Dumper( $dest );
			}
			return undef;
		}
	}

	# Convert multiple kernel arguments
	if ( ! ref( $dest->[0] ) ) {
		# If there's a comma, then we have a multi-kernel message
		if ( $dest->[0] =~ tr/,/,/ ) {
			# Split on the comma
			$dest->[0] = [ split( ',', $dest->[0] ) ];
		}
	} else {
		# Make sure it's an arrayref full of scalars
		if ( ref( $dest->[0] ) eq 'ARRAY' ) {
			foreach my $d ( @{ $dest->[0] } ) {
				if ( ref( $d ) ) {
					if ( DEBUG ) {
						warn "Destination kernel has some non-scalars in it -" . Data::Dumper::Dumper( $dest );
					}
					return undef;
				}
			}
		} else {
			if ( DEBUG ) {
				warn "Destination kernel is not an arrayref -" . Data::Dumper::Dumper( $dest );
			}
			return undef;
		}
	}

	# TODO Remove duplicate kernels

	# Convert multiple session arguments
	if ( ! ref( $dest->[1] ) ) {
		# If there's a comma, then we have a multi-session message
		if ( $dest->[1] =~ tr/,/,/ ) {
			# Split on the comma
			$dest->[1] = [ split( ',', $dest->[1] ) ];
		}
	} else {
		# Make sure it's an arrayref full of scalars
		if ( ref( $dest->[1] ) eq 'ARRAY' ) {
			foreach my $d ( @{ $dest->[1] } ) {
				if ( ref( $d ) ) {
					if ( DEBUG ) {
						warn "Destination session has some non-scalars in it -" . Data::Dumper::Dumper( $dest );
					}
					return undef;
				}
			}
		} else {
			if ( DEBUG ) {
				warn "Destination session is not an arrayref -" . Data::Dumper::Dumper( $dest );
			}
			return undef;
		}
	}

	# TODO Remove duplicate sessions

	# All done!
	return $dest;
}

# Sends the message!
sub SendMessage {
	my( $heap, $msg ) = @_;

	# Add the To
	if ( ! defined $msg->[ MSG_TO ] ) {
		$msg->[ MSG_TO ] = [ $heap->{'GRAPH'}->vertices ];
	} elsif ( ! ref( $msg->[ MSG_TO ] ) ) {
		# Is it the broadcast kernel?
		if ( $msg->[ MSG_TO ] eq '*' ) {
			$msg->[ MSG_TO ] = [ $heap->{'GRAPH'}->vertices ];
		} else {
			# Convert it into an array
			$msg->[ MSG_TO ] = [ $msg->[ MSG_TO ] ];
		}
	}

	# For starters, strip out our kernel if it is there + remove any invalid kernels
	$msg->[ MSG_TO ] = [ grep { $_ ne $heap->{'MYKERNEL'} and $heap->{'GRAPH'}->has_vertex( $_ ) } @{ $msg->[ MSG_TO ] } ];

	# Nothing left?
	if ( scalar( @{ $msg->[ MSG_TO ] } ) == 0 ) {
		return 1;
	}

	# Add the From
	if ( ! defined $msg->[ MSG_FROM ] ) {
		$msg->[ MSG_FROM ] = $heap->{'MYKERNEL'};
	}

	# Add the realto field
	if ( ! defined $msg->[ MSG_REALTO ] ) {
		$msg->[ MSG_REALTO ] = [ @{ $msg->[ MSG_TO ] } ];
	}

	# Short-circuit it if only one kernel to send message to
	if ( scalar( @{ $msg->[ MSG_TO ] } ) == 1 ) {
		# Munge the MSG_TO field
		$msg->[ MSG_TO ] = $msg->[ MSG_TO ]->[0];

		# The MSG_REALTO field too
		$msg->[ MSG_REALTO ] = $msg->[ MSG_TO ];

		# Find the route
		my @route = $heap ->{'APSP'}->path_vertices( $heap->{'MYKERNEL'}, $msg->[ MSG_TO ] );

		# Send it off!
		$POE::Kernel::poe_kernel->post(
			$heap->{'WID_SID'}->{ $heap->{'KERNEL_WID'}->{ $route[1] } },
			'send',
			$heap->{'KERNEL_WID'}->{ $route[1] },
			$msg,
		);
	} else {
		# Find out all the paths we need
		my %route = ();

		foreach my $k ( @{ $msg->[ MSG_TO ] } ) {
			$route{ $k } = [ $heap ->{'APSP'}->path_vertices( $heap->{'MYKERNEL'}, $k ) ];
		}

		# Collect the routes that are on the same link
		my %link = ();

		foreach my $k ( keys %route ) {
			push( @{ $link{ $route{ $k }->[1] } }, $k );
		}

		# Now, send the message to all links
		foreach my $l ( keys %link ) {
			# Make a new message
			my $p = [
				undef,
				$msg->[ MSG_FROM ],
				$msg->[ MSG_ACTION ],
				$msg->[ MSG_DATA ],
				$msg->[ MSG_REALTO ],
				$msg->[ MSG_TIMESTAMP ],
			];

			# Munge the TO-field
			if ( scalar( @{ $link{ $l } } ) == 1 ) {
				$p->[ MSG_TO ] = $link{ $l }->[0];
			} else {
				$p->[ MSG_TO ] = $link{ $l };
			}

			# Send it!
			$POE::Kernel::poe_kernel->post(
				$heap->{'WID_SID'}->{ $heap->{'KERNEL_WID'}->{ $l } },
				'send',
				$heap->{'KERNEL_WID'}->{ $l },
				$p,
			);
		}
	}

	# All done!
	return 1;
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

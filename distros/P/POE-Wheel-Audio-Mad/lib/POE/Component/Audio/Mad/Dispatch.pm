package POE::Component::Audio::Mad::Dispatch;
require 5.6.0;

use warnings;
use strict;

use POE;
use POE::Wheel::Audio::Mad;

our $VERSION = '0.3';

## NOTE:  this isn't an elegant solution..  but it's what I've come
## up with.  There are POE::Session subclasses out there that allow
## multi-dispatch,  but I'm not sure they work the way I want..  so
## we have this..  let me know if you have a beter idea.  

sub create {
	my ($class, $args) = @_;

	## create our own session and return the newly
	## created session reference back to the caller..
	POE::Session->create(
		inline_states => {
			_start => \&_start,
			
			shutdown => \&shutdown,
			input    => \&input,
			
			add_listener    => \&add_listener,
			update_listener => \&update_listener,
			del_listener    => \&del_listener
		},
		args => [$args]
	);
}

sub _start {
	my ($heap, $kernel, $args) = @_[HEAP, KERNEL, ARG0];
	
	$args->{alias} = 'mad-decoder' unless (defined($args->{alias}));
	$heap->{alias} = delete($args->{alias});
	
	$heap->{wheel} = POE::Wheel::Audio::Mad->new( message_event => 'input', %{$args} );
	$kernel->alias_set($heap->{alias});
	
	## these are here to save information about our listeners..

	## listenpost:  key => listener_id,  value => [session, state],
	## each key is our listener id number,  and the value is an
	## arrayref which tracks that listeners postback session and
	## state..
	$heap->{listenpost} = {};

	## listeners:  key => listner_id,  value => [events...],
	## each key is our listener id number,  and the value is an
	## arraref which tracks which events we are currently listening
	## for..

	$heap->{listeners}  = {};
	
	## listenmap:  key => event_id,  value => { listener_id => 1 }
	## each key is an event id that is currently being listened for,
	## and the value is a hashref;  each key in that hashref is a
	## listener id and the value is simply one.  we use a nested
	## hash for easier insertion and deletion of listeners under
	## a particular event..
	
	$heap->{listenmap}  = {};
}

##############################################################################

## gets us to shut ourselvs down and disappear,  this probably
## shouldn't get called directly from anywhere..
sub shutdown {
	my ($kernel, $heap) = @_[KERNEL, HEAP];
	
	## generate a message about our shutdown..
	$kernel->yield('input', {
		id   => 'IPC_SHUTDOWN_SUCCESS',
		data => ''
	});
	
	## hmm.. race condition?  release the references to
	## all our sessions so they can die..

	foreach my $lid (keys(%{$heap->{listenpost}})) {
		$kernel->refcount_decrement( $heap->{listenpost}->{$lid}->[0]->ID, 'POE::Component::Audio::Mad::Dispatch' );
	}
	
	$kernel->alias_remove($heap->{alias});
	undef $heap->{wheel};
}
	
sub input {
	my ($kernel, $heap, $raw) = @_[KERNEL, HEAP, ARG0];
	return undef unless (defined($raw));
	
	foreach my $lid (keys(%{$heap->{listenmap}->{$raw->{id}}})) {
	
		## we post back to our listener,  and send them
		## a copy of the message

		$kernel->post(@{$heap->{listenpost}->{$lid}}, $raw);
	}
}
	

##############################################################################

## don't know where I picked this idiom up from,  but it sure
## looks cute,  dosen't it?

my $_NEXT_LISTENER_ID = 0;
sub NEXT_LISTENER_ID { ++$_NEXT_LISTENER_ID }

## this state adds a listener into our session.  

sub add_listener {
	my ($kernel, $heap, $l_session, $l_state, $l_list) = @_[KERNEL, HEAP, ARG0..ARG2];

	return undef unless (defined($l_session) && defined($l_state) && ref($l_list) eq 'ARRAY' && @{$l_list} > 0);
	$l_session = $kernel->alias_resolve( $l_session ) unless (ref($l_session));
	
	## assign a new listener ID..  which will probably wrap at 2**31,  but
	## I don't think we're that popular..
	my $LID = NEXT_LISTENER_ID;
	
	## track our postback session and state in our 'listenpost' hash..
	$heap->{listenpost}->{$LID} = [$l_session, $l_state];

	## track the events we are listening for in 'listeners'..
	$heap->{listeners}->{$LID}  = $l_list;
	
	## then we map ourselvs into each even we are listening
	## for in listenmap..
	foreach (@{$l_list}) { $heap->{listenmap}->{$_}->{$LID} = 1 }

	## bump the refcount for the calling session,  as long as we
	## have a hold of them,  we expect them to persist to get
	## our messages..

	$kernel->refcount_increment( $l_session->ID, 'POE::Component::Audio::Mad::Dispatch' );

	## send back our LID..  this state is definitely meant to 
	## be used via ->call(),  rather than ->post() so we can
	## get back our LID.  Although,  if you don't plan to 
	## ever update or delete yourself from the listener 
	## chain,  it isn't necessary..
	return $LID;
}

## this method might be cleaner,  but this seems to work
## prety well,  and it's generally not often called..

sub update_listener {
	my ($heap, $lid, $list) = @_[HEAP, ARG0..ARG1];
	return undef unless (defined($lid) && defined($heap->{listenpost}->{$lid}) && ref($list) eq 'ARRAY' && @{$list} > 0);
	
	## to update our information,  we just cycle through the list
	## of currently listened for events,  and remove ourselvs
	## from that event in the map..
	foreach (@{$heap->{listeners}->{$lid}}) { delete($heap->{listenmap}->{$_}->{$lid}) }
	
	## then we update our listened for events,  with the new list
	## passed in as an argument to this state..
	$heap->{listeners}->{$lid} = $list;
	
	## then we remap our new list of states back into
	## the event map..
	foreach (@{$list}) { $heap->{listenmap}->{$_}->{$lid} = 1 }

}

sub del_listener {
	my ($kernel, $heap, $lid) = @_[KERNEL, HEAP, ARG0];
	return undef unless (defined($lid) && defined($heap->{listenpost}->{$lid}));
	
	my $target_session = $heap->{listenpost}->{$lid}->[0];

	## cycle through the event map,  and be sure to remove
	## ourselvs..

	foreach (@{$heap->{listeners}->{$lid}}) { delete($heap->{listenmap}->{$_}->{$lid}) }
	
	## remove our entries in the listeners and listenpost maps..

	delete($heap->{listeners}->{$lid});
	delete($heap->{listenpost}->{$lid});
	
	## drop the reference count so we don't hold them unecessarily..
	$kernel->refcount_decrement( $target_session->ID, 'POE::Component::Audio::Mad::Dispatch' );
	
	## return something..
	
	return 1;
}

##############################################################################
1;
__END__

=pod

=head1 NAME

  POE::Component::Audio::Mad::Dispatch - A POE::Component::Audio::Mad frontend
  implementing listener based message dispatch.
  
=head1 SYNOPSIS

  use POE;
  use POE::Component::Audio::Mad::Dispatch;

  ## we print some stuff below,  and we don't want it
  ## to get buffered..  so turn on autoflush.
  $| = 1;

  ## create our frontend session,  which will create a decoder and
  ## forward it's messages to all interested listeners..
  create POE::Component::Audio::Mad::Dispatch({ 
  	decoder_play_on_open => 1,
  	alias                => 'mad-decoder'
  });

  POE::Session->create(inline_states => {
  	_start            => \&ex_start,
  	mad_decoder_input => \&ex_input
  });
  
  sub ex_start {
  	my ($kernel, $heap, $session) = @_[KERNEL, HEAP, SESSION];
  	
	## add ourself in as a listener,  and register for the DECODER_FRAME_DATA and
	## IPC_SHUTDOWN_SUCCESS events.  The decoder core will then call the
	## 'mad_decoder_input' state in the current session when these 
	## events arrive.. 
	
	## this also has the added benefit of keeping a reference to our
	## session alive in the event notification list.  Our session will
	## remain alive as long as we are a registered listener..
	
  	$heap->{lid} = $kernel->call('mad-decoder', 'add_listener', $session, 'mad_decoder_input', [
  		'DECODER_FRAME_DATA', 'INPUT_EOF_WARNING'
  	]);
  	
  	## tell our decoder to start playing a stream..
  	$kernel->post('mad-decoder', 'decoder_open', { filename => '/path/to/stream.mp3', play => 1 });
  }
  
  sub ex_input {
  	my ($kernel, $heap, $msg) = @_[KERNEL, HEAP, ARG0];
  	
  	## this is called when the decoder has generated an event
  	## that we have registered for.  the message packet is
  	## contained in ARG0,  and is a hashref with two
  	## fields ->{id} and ->{data}.  id specifies the name
  	## of the event,  and data contains a reference to 
  	## the data included in this event..
  	
  	if ($msg->{id} eq 'DECODER_FRAME_DATA') {

  		## we got a message updating us as to player
  		## progress,  the data part of the event will
  		## contain two values:  ->{played} and ->{progress},
  		## played is the number of seconds of stream
  		## played..

  		print "\rplayed: $msg->{data}->{played}" if (defined($msg->{data}->{played}));
  	} elsif ($msg->{id} eq 'INPUT_EOF_WARNING') {
  	
  		## we got a message telling us that the 
  		## decoder system has come to the end of
  		## the current stream,  use it as a queue
  		## to shutdown..
  		
  		print "\nshutting down..\n";
  		$kernel->post('mad-decoder', 'decoder_shutdown');

  	} else {
  	
  		## unknown messages should never happen,  but
  		## we could do something interesting with them
  		## here..  for simplicity,  we just ignore it.
  		
  		return;
  	}
  }

  ## start this thing..
  $poe_kernel->run();
  exit();
  
  
=head1 DESCRIPTION

  POE::Component::Audio::Mad::Dispatch implements a multiple dispatch 
  front end component for the POE::Wheel::Audio::Mad mpeg decoder. It 
  receieves status messages from the decoder and dispatches them to
  other registered "listener" sessions.  All of the states listed in
  POE::Wheel::Audio::Mad(3) under STATES will be defined within this
  components session.  To control the decoder,  simply post the
  appropriate POE::Wheel::Audio::Mad STATE to this session.

  If you intend to implement a decoder that will be controlled and/or 
  monitored by other POE::Session's,  then this is the module you want 
  to be using.  If you wish to implement a decoder through an IPC
  bridge,  you want POE::Component::Audio::Mad::Handle.

=head1 METHODS

=over

=item create({ ..options.. })

  This class method is used to create a new POE session for both the 
  decoder core and the front end module.  This constructor does
  not specify any options,  but options sent through this
  constructor will be sent on to the decoder core.  For more 
  information on options available to control the decoder core's
  behaviour see POE::Component::Audio::Mad(3)
  
=back
  
=head1 STATES

  These states are specific to this component's session,  and allow
  other sessions to register themselvs as a "listener" to specific
  decoder status messages.  The states listed in POE::Component::Audio::Mad(3)
  under STATES are also defined under this session and may be posted
  to.

=over

=item add_listener

  This state adds a new session to the decoders event notification list.  It
  accepts three arguments:  (session,  state,  events).  'session' is the name
  of (or a reference to) a session that wishes to receive events,  'state' is
  the name of a state within the 'session',  and 'events' is an arrayref listing
  the names events one wishes to receive.  
  
  This state will return your "listener id number" which is necessary if you wish 
  to update the events you are listening for,  or to delete yourself from the event 
  notification list.  If you wish to retrieve this number,  you must tell the POE
  kernel to ->call() to this state rather than ->post() to it.
  
  For a list of available event names,  see the documentation in 
  POE::Component::Audio::Mad(3) section EVENTS.
  
=item update_listener

  This state updates the list of events that a listener wishes to be notified
  of.  It takes two arguments:  (listener id, events).  'listener id' is the
  number that was returned to you when you called 'add_listener'.  events is
  an arrayref containing an updated list of events you wish to receive.

=item del_listener

  This state removes you from the event notification list.  It takes one
  argument,  your 'listener id' which was returned to you when you 
  called 'add_listener'.  This completely removes you from the event
  notification list.

=back

=head1 SEE ALSO

perl(1)

POE::Wheel::Audio::Mad(3)

=head1 AUTHOR

Mark McConnell, E<lt>mischke@cpan.orgE<gt>
  
=head1 COPYRIGHT AND LICENSE
  
Copyright 2003 by Mark McConnell
  
This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
  
package MooX::Role::POE::Emitter;
$MooX::Role::POE::Emitter::VERSION = '1.001002';
use strictures 2;

use feature 'state';
use Carp;
use Scalar::Util 'reftype';

use List::Objects::WithUtils;
use List::Objects::Types -all;
use Types::Standard      -types;

use MooX::Role::Pluggable::Constants;

use POE;

sub E_TAG () { 'Emitter Running' }

=pod

=for Pod::Coverage E_TAG

=cut


use Moo::Role;
with 'MooX::Role::Pluggable';


has alias => (
  lazy      => 1,
  is        => 'ro',
  isa       => Str,
  predicate => 'has_alias',
  writer    => 'set_alias',
  default   => sub { my $self = shift; "$self" },
);

around set_alias => sub {
  my ($orig, $self, $value) = @_;

  if ( $poe_kernel->alias_resolve( $self->session_id ) ) {
    $self->call( __emitter_reset_alias => $value );
    $self->emit( $self->event_prefix . 'alias_set' => $value );
  }

  $self->$orig($value)
};

has event_prefix => (
  lazy      => 1,
  is        => 'ro',
  isa       => Str,
  predicate => 'has_event_prefix',
  writer    => 'set_event_prefix',
  default   => sub { 'emitted_' },
);

has pluggable_type_prefixes => (
  ## Optionally remap PROCESS / NOTIFY types
  lazy      => 1,
  is        => 'ro',
  isa       => HashObj,
  coerce    => 1,
  predicate => 'has_pluggable_type_prefixes',
  writer    => 'set_pluggable_type_prefixes',
  default   => sub {
    hash( PROCESS => 'P', NOTIFY  => 'N' )
  },
);


has object_states => (
  lazy      => 1,
  is        => 'ro',
  isa       => ArrayObj,
  coerce    => 1,
  predicate => 'has_object_states',
  writer    => 'set_object_states',
  trigger   => 1,
  default   => sub { array },
);

sub _trigger_object_states {
  my ($self, $states) = @_;

  $states = array(%$states) if reftype $states eq 'HASH';

  confess "object_states() should be an ARRAY or HASH"
    unless ref $states and reftype $states eq 'ARRAY';

  $states = array(@$states) unless is_ArrayObj $states;

  state $disallowed = array( qw/
    _start
    _stop
    _default
    emit
    register
    unregister
    subscribe
    unsubscribe
  / )->map(sub { $_ => 1 })->inflate;

  my $itr = $states->natatime(2);
  while (my (undef, $events) = $itr->()) {
    my $evarr = reftype $events eq 'ARRAY' ? array(@$events) 
                : reftype $events eq 'HASH'  ? array(keys %$events)
                : confess "Expected ARRAY or HASH but got $events";
    $evarr->map(
      sub { confess "Disallowed handler: $_" if $disallowed->exists($_) }
    );
  }
}


has register_prefix => (
  lazy      => 1,
  is        => 'ro',
  isa       => Str,
  predicate => 'has_register_prefix',
  writer    => 'set_register_prefix',
  ## Emitter_register / Emitter_unregister
  default   => sub { 'Emitter_' },
);

has session_id => (
  init_arg  => undef,
  lazy      => 1,
  is        => 'ro',
  isa       => Defined,
  predicate => 'has_session_id',
  writer    => 'set_session_id',
  default   => sub { -1 },
);

has shutdown_signal => (
  lazy      => 1,
  is        => 'ro',
  isa       => Str,
  predicate => 'has_shutdown_signal',
  writer    => 'set_shutdown_signal',
  default   => sub { 'SHUTDOWN_EMITTER' },
);

has __emitter_reg_sessions => (
  lazy    => 1,
  is      => 'ro',
  isa     => TypedHash[Object],
  default => sub { hash_of Object },
);


has __emitter_reg_events => (
  ## ->{ $event }->{ $session_id } = 1
  lazy    => 1,
  is      => 'ro',
  isa     => TypedHash[ TypedHash[Int] ],
  coerce  => 1,
  default => sub { hash_of TypedHash[Int] },
);


sub _start_emitter {
  ## Call to spawn Session.
  ##   my $emitter = MyClass->new(
  ##     alias           => Emitter session alias
  ##     event_prefix    => Session event prefix (emitted_)
  ##     register_prefix => _register/_unregister prefix (Emitter_)
  ##     object_states   => Extra object_states for Session
  ##   )->_start_emitter();
  my ($self) = @_;

  my %types;
  if ( $self->has_pluggable_type_prefixes ) {
    $types{PROCESS} = $self->pluggable_type_prefixes->{PROCESS} ||= 'P';
    $types{NOTIFY}  = $self->pluggable_type_prefixes->{NOTIFY}  ||= 'N';
  } else {
    %types = ( PROCESS => 'P', NOTIFY => 'N' );
  }

  $self->_pluggable_init(
    event_prefix  => $self->event_prefix,
    reg_prefix    => $self->register_prefix,
    types         => \%types,
  );

  POE::Session->create(
    object_states => [

      $self => {
        '_start'           => '__emitter_start',
        '_stop'            => '__emitter_stop',
        'shutdown_emitter' => '__shutdown_emitter',

        'register'         => '__emitter_register',
        'subscribe'        => '__emitter_register',
        'unregister'       => '__emitter_unregister',
        'unsubscribe'      => '__emitter_unregister',
        'emit'             => '__emitter_notify',

        '_default'               => '__emitter_disp_default',
        '__emitter_real_default' => '_emitter_default',
      },

      $self => [ qw/
        __emitter_notify

        __emitter_timer_set
        __emitter_timer_del

        __emitter_sigdie

        __emitter_reset_alias

        __emitter_sig_shutdown
      / ],

      (
        $self->has_object_states ? $self->object_states->all : ()
      ),

    ],
  );

  $self
}

around '_pluggable_event' => sub {
  my ($orig, $self) = splice @_, 0, 2;

  ## Overriden from Role::Pluggable
  ## Receives plugin_error, plugin_add etc
  ## Redispatch via emit()

  $self->emit( @_ );
};


### Public:

sub timer {
  my ($self, $time, $event, @args) = @_;

  confess "timer() expected at least a time and event name"
    unless defined $time and defined $event;

  $self->call( __emitter_timer_set => $time, $event, @args )
}

sub __emitter_timer_set {
  my ($kernel, $self)       = @_[KERNEL, OBJECT];
  my ($time, $event, @args) = @_[ARG0 .. $#_];

  my $alarm_id = $poe_kernel->delay_set( $event, $time, @args );

  $self->emit( $self->event_prefix . 'timer_set',
    $alarm_id,
    $event,
    $time,
    @args
  ) if $alarm_id;

  $alarm_id
}

sub timer_del {
  my ($self, $alarm_id) = @_;

  confess "timer_del() expects an alarm ID"
    unless defined $alarm_id;

  $self->call( __emitter_timer_del => $alarm_id );
}

sub __emitter_timer_del {
  my ($kernel, $self, $alarm_id) = @_[KERNEL, OBJECT, ARG0];

  my @deleted = $poe_kernel->alarm_remove($alarm_id);
  return unless @deleted;

  my ($event, undef, $params) = @deleted;

  $self->emit( $self->event_prefix . 'timer_deleted',
    $alarm_id,
    $event,
    @{ $params || [] }
  );

  $params
}

## yield/call provide post()/call() frontends.
sub yield {
  my ($self, @args) = @_;

  $poe_kernel->post( $self->session_id, @args );

  $self
}

sub call {
  my ($self, @args) = @_;

  $poe_kernel->call( $self->session_id, @args );

  $self
}

sub emit {
  ## Async NOTIFY event dispatch.
  my ($self, $event, @args) = @_;

  $self->yield( __emitter_notify => $event, @args );

  $self
}

sub emit_now {
  ## Synchronous NOTIFY event dispatch.
  my ($self, $event, @args) = @_;

  $self->call( __emitter_notify => $event, @args );

  $self
}

sub process {
  my ($self, $event, @args) = @_;
  ## Dispatch PROCESS events.
  ## process() events should _pluggable_process immediately
  ##  and return the EAT value.

  ## Dispatched to P_$event :
  $self->_pluggable_process( PROCESS => $event, \@args )
}



## Session ref-counting bits.
{ package MooX::Role::POE::Emitter::RegisteredSession;
$MooX::Role::POE::Emitter::RegisteredSession::VERSION = '1.001002';
  use Moo;
  has [qw/id refcount/] => ( is => 'rw', required => 1 );
}

sub __get_ses_refc {
  my ($self, $sess_id) = @_;
  my $regsess_obj = $self->__emitter_reg_sessions->get($sess_id);
  return unless $regsess_obj;
  $regsess_obj->refcount
}

sub __reg_ses_id {
  my ($self, $sess_id) = @_;
  return if $self->__emitter_reg_sessions->exists($sess_id);
  $self->__emitter_reg_sessions->set($sess_id =>
    MooX::Role::POE::Emitter::RegisteredSession->new(
      id       => $sess_id,
      refcount => 0
    )
  );
}

sub __incr_ses_refc {
  my ($self, $sess_id) = @_;

  my $regsess_obj = $self->__emitter_reg_sessions->get($sess_id);
  unless (defined $regsess_obj) {
    confess "BUG; attempted to increase nonexistant refcount for '$sess_id'";
  }

  $self->__emitter_reg_sessions->set($sess_id =>
    MooX::Role::POE::Emitter::RegisteredSession->new(
      id       => $sess_id,
      refcount => $regsess_obj->refcount + 1,
    )
  );

  $self->__emitter_reg_sessions->get($sess_id)->refcount
}

sub __decr_ses_refc {
  my ($self, $sess_id) = @_;

  my $regsess_obj = $self->__emitter_reg_sessions->get($sess_id);
  unless (defined $regsess_obj) {
    confess "BUG; attempted to decrease nonexistant refcount for '$sess_id'"
  }

  $self->__emitter_reg_sessions->set($sess_id =>
    do { 
      my $refc = $regsess_obj->refcount - 1;
      $refc = 0 if $refc < 0;  # FIXME delete (and return above) instead?
      MooX::Role::POE::Emitter::RegisteredSession->new(
        id       => $sess_id,
        refcount => $refc,
      )
    },
  );
}

sub __emitter_drop_sessions {
  my ($self) = @_;

  for my $id ($self->__emitter_reg_sessions->keys->all) {
    my $count = $self->__get_ses_refc($id);
    while ( $count-- > 0 ) {
      $poe_kernel->refcount_decrement( $id, E_TAG )
    }

    $self->__emitter_reg_sessions->delete($id)
  }

  1
}


## Our Session's handlers:

sub __emitter_notify {
  ## Dispatch a NOTIFY event
  my ($kernel, $self) = @_[KERNEL, OBJECT];
  my ($event, @args)  = @_[ARG0 .. $#_];

  my $prefix = $self->event_prefix;

  ## May have event_prefix (such as $prefix.'plugin_error')
  substr($event, 0, length($prefix), '') if index($event, $prefix) == 0;

  my %sessions;

  for my $registered_ev ('all', $event) {
    if (my $sess_hash = $self->__emitter_reg_events->get($registered_ev)) {
      $sess_hash->keys->visit(sub { $sessions{$_} = 1 })
    }
  }

  my $meth = $prefix . $event;

  ## Our own session will get ->event_prefix . $event first
  $kernel->call( $_[SESSION], $meth, @args )
    if delete $sessions{ $_[SESSION]->ID };

  ## Dispatched to N_$event after our Session has been notified:
  unless ( $self->_pluggable_process('NOTIFY', $event, \@args) == EAT_ALL ) {
    ## Notify subscribed sessions.
    $kernel->call( $_ => $meth, @args ) for keys %sessions;
  }

  ## Received emitted 'shutdown', drop sessions.
  $self->__emitter_drop_sessions if $event eq 'shutdown';
}

sub __emitter_start {
  ## _start handler
  my ($kernel, $self)    = @_[KERNEL, OBJECT];
  my ($session, $sender) = @_[SESSION, SENDER];

  $self->set_session_id( $session->ID );

  $kernel->alias_set( $self->alias );

  $kernel->sig( DIE => '__emitter_sigdie' );
  $kernel->sig( $self->shutdown_signal => '__emitter_sig_shutdown' );

  unless ($sender == $kernel) {
    ## Have a parent session.
    my $s_id = $sender->ID;
    $kernel->refcount_increment( $s_id, E_TAG );
    $self->__reg_ses_id( $s_id );
    $self->__incr_ses_refc( $s_id );

    ## subscribe parent session to all notification events
    $self->__emitter_reg_events->{all}->{ $s_id } = 1;

    ## Detach child session.
    $kernel->detach_myself;
  }

  $self->call('emitter_started');

  $self
}

sub __emitter_reset_alias {
  my ($kernel, $self) = @_[KERNEL, OBJECT];
  $kernel->alias_set( $_[ARG0] );
}

sub __emitter_disp_default {
  my ($kernel, $self) = @_[KERNEL, OBJECT];
  my ($event, $args)  = @_[ARG0, ARG1];

  if (ref $event eq 'CODE') {
    ## Anonymous coderef callback.
    ## Cute trick from dngor:
    ##  - Shove arguments back into @_
    ##    (starting at ARG0 and replacing ARG0/ARG1)
    ##  - Set $_[STATE] to our coderef
    ##    (callback sub can retrieve itself via $_[STATE])
    ##  - Replace current subroutine
    splice @_, ARG0, 2, @$args;
    $_[STATE] = $event;
    goto $event
  } else {
    $self->call( __emitter_real_default => $event, $args );
  }
}

sub _emitter_default {
  my ($kernel, $self) = @_[KERNEL, OBJECT];
  my ($event, $args)  = @_[ARG0, ARG1];

  ## Session received an unknown event.
  ## Dispatch it to any appropriate P_$event handlers.

  $self->process( $event, @$args )
    unless index($event, '_') == 0
    or     index($event, 'emitter_') == 0
    and    $event =~ /(?:started|stopped)$/;
}

sub __emitter_sig_shutdown {
  my ($kernel, $self) = @_[KERNEL, OBJECT];
  $self->yield( shutdown_emitter => @_[ARG2 .. $#_] )
}

sub __emitter_sigdie {
  my ($kernel, $self) = @_[KERNEL, OBJECT];
  my $exh = $_[ARG1];

  my $event   = $exh->{event};
  my $dest_id = $exh->{dest_session}->ID;
  my $errstr  = $exh->{error_str};

  warn
    "SIG_DIE: Event '$event'  session '$dest_id'\n",
    "  exception: $errstr\n";

  $kernel->sig_handled;
}

sub __emitter_stop {
  ## _stop handler
  my ($kernel, $self) = @_[KERNEL, OBJECT];

  $self->call('emitter_stopped');
}

sub _shutdown_emitter {
  ## Opposite of _start_emitter
  my $self = shift;

  $self->call( shutdown_emitter => @_ );

  1
}

sub __shutdown_emitter {
  my ($kernel, $self) = @_[KERNEL, OBJECT];

  $kernel->alarm_remove_all;

  ## Destroy plugin pipeline.
  $self->_pluggable_destroy;

  ## Notify sessions.
  $self->emit( shutdown => @_[ARG0 .. $#_] );

  ## Drop sessions and we're spent.
  $self->call( unsubscribe => () );
  $self->__emitter_drop_sessions;
}


## Handlers for listener sessions.
sub __emitter_register {
  my ($kernel, $self, $sender) = @_[KERNEL, OBJECT, SENDER];
  my @events = @_[ARG0 .. $#_];

  @events = 'all' unless @events;

  my $s_id = $sender->ID;

  ## Add to our known sessions.
  $self->__reg_ses_id( $s_id );

  for my $event (@events) {
    ## Add session to registered event lists.
    $self->__emitter_reg_events->{$event}->{$s_id} = 1;

    ## Make sure registered session hangs around
    ##  (until _unregister or shutdown)
    $kernel->refcount_increment( $s_id, E_TAG )
      unless $s_id == $self->session_id
      or $self->__get_ses_refc($s_id);

    $self->__incr_ses_refc( $s_id );
  }

  $kernel->post( $s_id => $self->event_prefix . 'registered', $self )
}

sub __emitter_unregister {
  my ($kernel, $self, $sender) = @_[KERNEL, OBJECT, SENDER];
  my @events = @_[ARG0 .. $#_];

  ##  - An unsub without any arguments means "stop sending all events I
  ##    have subscribed to"
  ##  - An unsub for 'all' means "stop sending events I haven't asked for 
  ##    by name"

  @events = $self->__emitter_reg_events->keys->all unless @events;

  my $s_id = $sender->ID;

  EV: for my $event (@events) {
    # intentional no Lowu, leave me for autoviv:
    unless (delete $self->__emitter_reg_events->{$event}->{$s_id}) {
      next EV
    }

    # Sessions left for this event?
    $self->__emitter_reg_events->delete($event)
      if $self->__emitter_reg_events->get($event)->is_empty;

    $self->__decr_ses_refc($s_id);

    unless ($self->__get_ses_refc($s_id)) {
      ## No events left for this session.
      $self->__emitter_reg_sessions->delete($s_id);

      $kernel->refcount_decrement( $s_id, E_TAG )
        unless $_[SESSION] == $sender;
    }

  } ## EV
}

1;


=pod

=for Pod::Coverage has_\S+

=head1 NAME

MooX::Role::POE::Emitter - Pluggable POE event emitter role for cows

=head1 SYNOPSIS

  ## A POE::Session that can broadcast events to listeners:
  package My::EventEmitter;
  use POE;
  use Moo;
  with 'MooX::Role::POE::Emitter';

  sub spawn {
    my ($self, %args) = @_;

    $self->set_object_states(
      [
        $self => {
          ## Add some extra handlers to our Emitter:
          'emitter_started' => '_emitter_started',
          'emitter_stopped' => '_emitter_stopped',
        },

        ## Include any object_states we had previously
        ## (e.g. states added at construction time):
        (
          $self->has_object_states ?
            @{ $self->object_states } : ()
        ),

        ## Maybe include from named arguments, for example:
        (
          ref $args{object_states} eq 'ARRAY' ?
            @{ $args{object_states} } : ()
        ),
      ],
    );

    ## Start our Emitter's POE::Session:
    $self->_start_emitter;
  }

  sub shutdown {
    my ($self) = @_;
    ## .. do some cleanup, whatever ..
    $self->_shutdown_emitter;
  }

  sub _emitter_started {
    my ($kernel, $self) = @_[KERNEL, OBJECT];
    ## A POE state called when the emitter's session starts.
    ## (Analogous to a normal '_start' handler)
    ## Could load plugins, do initialization, etc.
  }

  sub _emitter_stopped {
    ## Opposite of 'emitter_started'
  }

  sub do_something {
    my ($self, @things) = @_;
    # ... do some work ...
    # ... emit an event:
    $self->emit( did_stuff => @things )
  }

  ## A listening POE::Session:
  package My::Listener;
  use POE;

  sub spawn {
    # This spawn() takes an alias/session to subscribe to:
    my ($self, $alias_or_sessionID) = @_;

    POE::Session->create(
      ## Set up a Session, etc
      object_states => [
        $self => [
            'emitted_did_stuff',
            # ...
        ],
      ],
    );

    ## Subscribe to all events from $alias_or_sessionID:
    $poe_kernel->call( 
      $alias_or_sessionID => subscribe => 'all'
    );
  }

  sub emitted_did_stuff {
    my ($kernel, $self) = @_[KERNEL, OBJECT];
    ## Received 'did_stuff' from Emitter
    my @things = @_[ARG0 .. $#_];
    # ...
  }

=head1 DESCRIPTION

Consuming this L<Moo::Role> gives your class a L<POE::Session> capable of 
processing events via loaded plugins and/or emitting them to registered 
"listener" sessions.

It is derived from L<POE::Component::Syndicator> by BINGOS, HINRIK, APOCAL 
et al, but with more cows ;-) and a few extra features (such as anonymous 
coderef callbacks; see L</yield>), as well as the 
faster plugin dispatch system that comes with L<MooX::Role::Pluggable>.

The Emitter role consumes L<MooX::Role::Pluggable>, 
making your emitter pluggable (see the 
L<MooX::Role::Pluggable> documentation for plugin-related details).

You do not need to create your own L<POE::Session>; calling 
L</_start_emitter> will spawn one for you.

You also get some useful sugar over POE event dispatch; see L</Methods>.

=head2 Creating an Emitter

L</SYNOPSIS> contains an emitter that uses B<set_$attrib> methods to
configure itself when C<spawn()> is called; attributes can, of course,
be set when your Emitter is constructed:

  my $emitter = MyEmitter->new(
    alias => 'my_emitter',
    pluggable_type_prefixes => {
      NOTIFY  => 'Notify',
      PROCESS => 'Proc',
    },
    # . . .
  );

=head3 Attributes

Most of these can be altered via B<set_$attrib> methods at any time before 
L</_start_emitter> is called. Changing an emitter's configuration after it has
been started may result in undesirable behavior ;-)

Public attributes provide B<has_> prefixed predicates; e.g.
B<has_event_prefix>.

=head4 alias

B<alias> specifies the POE::Kernel alias used for our L<POE::Session>; 
defaults to the stringified object.

Set via B<set_alias>. If the emitter is running, a prefixed B<alias_set> 
event is emitted to notify listeners that need to know where to reach the emitter.

=head4 event_prefix

B<event_prefix> is prepended to notification events before they are
dispatched to listening sessions. It is also used for the plugin 
pipeline's internal events; see L<MooX::Role::Pluggable/_pluggable_event> 
for details.

Defaults to C<emitted_>

Set via B<set_event_prefix>

=head4 pluggable_type_prefixes

B<pluggable_type_prefixes> is a hash reference that can optionally be set 
to change the default L<MooX::Role::Pluggable> plugin handler prefixes for 
C<PROCESS> and C<NOTIFY> (which default to C<P> and C<N>, respectively):

  my $emitter = $class->new(
    pluggable_type_prefixes => {
      PROCESS => 'P',
      NOTIFY  => 'N',
    },
  );

Set via B<set_pluggable_type_prefixes>

=head4 object_states

B<object_states> is an array reference suitable for passing to
L<POE::Session>; the subclasses own handlers should be added to
B<object_states> prior to calling L</_start_emitter>.

Set via B<set_object_states>

=head4 register_prefix

B<register_prefix> is prepended to 'register' and 'unregister' methods
called on plugins at load time (see L<MooX::Role::Pluggable>).

Defaults to I<Emitter_>

Set via B<set_register_prefix>

=head4 session_id

B<session_id> is our emitter's L<POE::Session> ID, set when our Session is 
started via L</"_start_emitter">.

=head4 shutdown_signal

B<shutdown_signal> is the name of the L<POE> signal that will trigger a 
shutdown (used to shut down multiple Emitters). See L</"Signals">

=head3 _start_emitter

B<_start_emitter()> should be called on our object to spawn the actual
L<POE::Session>. It takes no arguments and should be called after the 
object has been configured.

=head3 _shutdown_emitter

B<_shutdown_emitter()> must be called to terminate the Emitter's 
L<POE::Session>

A 'shutdown' event will be emitted before sessions are dropped.

=head2 Listening sessions

=head3 Session event subscription

An external L<POE::Session> can subscribe to receive events via 
normal POE event dispatch by sending a C<subscribe>:

  $poe_kernel->post( $emitter->session_id,
    'subscribe',
    @events
  );

Listening sessions are consumers; they cannot modify event arguments in 
any meaningful way, and will receive arguments as-normal (in @_[ARG0 .. 
$#_] like any other POE state). Plugins operate differently and receive 
references to arguments that can be modified -- see 
L<MooX::Role::Pluggable> for details.

=head3 Session event unregistration

An external Session can unregister subscribed events using the same syntax 
as above:

  $poe_kernel->post( $emitter->session_id,
    'unsubscribe',
    @events
  );

If no events are specified, then any previously subscribed events are 
unregistered.

Note that unsubscribing from 'all' does not carry the same behavior; that 
is to say, a subscriber can subscribe/unsubscribe for 'all' separately from 
some set of specifically named events.

=head2 Receiving events

=head3 Events delivered to listeners

Events are delivered to subscribed listener sessions as normal POE events, 
with the configured L</event_prefix> prepended and arguments available via 
C< @_[ARG0 .. $#_] > as normal.

  sub emitted_my_event {
    my ($kernel, $self) = @_[KERNEL, OBJECT];
    my @args = @_[ARG0 .. $#_];
    # . . .
  }

See L</"Session event subscription"> and L</"emit">

=head3 Events delivered to this session

The emitter's L<POE::Session> provides a '_default' handler that 
redispatches unknown POE-delivered events to L</process> 
(except for events prefixed with '_', which are reserved).

You can change this behavior by overriding '_emitter_default' -- here's a 
direct adaption of the example from L<POE::Component::Syndicator>:

  use Moo;
  use POE;
  with 'MooX::Role::POE::Emitter';
  around '_emitter_default' => sub {
    my $orig = shift;
    my ($kernel, $self) = @_[KERNEL, OBJECT];
    my ($event, $args)  = @_[ARG0, ARG1];

    ## process(), then do something else, for example
    return if $self->process( $event, @$args ) == EAT_ALL;

    . . .
  };

(Note that due to internal redispatch $_[SENDER] will be the Emitter's 
Session.)

=head2 EAT values

L<MooX::Role::Pluggable> uses C<EAT_*> constants to indicate event 
lifetime.

If a plugin in the pipeline returns EAT_CLIENT or EAT_ALL, events 
are not dispatched to subscribed listening sessions; a dispatched NOTIFY 
event goes to your emitter's Session if it is subscribed to receive it, 
then to the plugin pipeline, and finally to other subscribed listener 
Sessions B<unless> a plugin returned EAT_CLIENT or EAT_ALL.

See L</"emit"> for more on dispatch behavior and event lifetime. See 
L<MooX::Role::Pluggable> for details regarding plugins.

=head3 NOTIFY events

B<NOTIFY> events are intended to be dispatched asynchronously to our own
session, any loaded plugins in the pipeline, and subscribed listening 
sessions, respectively.

See L</emit>.

=head3 PROCESS events

B<PROCESS> events are intended to be processed by the plugin pipeline
immediately; these are intended for message processing and similar
synchronous action handled by plugins.

Handlers for B<PROCESS> events are prefixed with C<P_>

See L</process>.

=head2 Sending events

=head3 emit

  $self->emit( $event, @args );

B<emit()> dispatches L</"NOTIFY events"> -- these events are dispatched
first to our own session (with L</event_prefix> prepended), then any
loaded plugins in the pipeline (with C<N_> prepended), then registered
sessions (with L</event_prefix> prepended):

  ## With default event_prefix:
  $self->emit( 'my_event', @args )
  #  -> Dispatched to own session as 'emitted_my_event'
  #  -> Dispatched to plugin pipeline as 'N_my_event'
  #  -> Dispatched to registered sessions as 'emitted_my_event'
  #     *unless* a plugin returned EAT_CLIENT or EAT_ALL

See L</"Receiving events">, L</"EAT values">

=head3 emit_now

  $self->emit_now( $event, @args );

B<emit_now()> synchronously dispatches L</"NOTIFY events"> -- see
L</emit>.

=head3 process

  $self->process( $event, @args );

B<process()> calls registered plugin handlers for L</"PROCESS events">
immediately; these are B<not> dispatched to listening sessions.

Returns the same value as L<MooX::Role::Pluggable/"_pluggable_process">.

See L<MooX::Role::Pluggable> for details on pluggable 
event dispatch.

=head2 Methods

These methods provide easy proxy mechanisms for issuing POE events and 
managing timers within the context of the emitter's L<POE::Session>.

=head3 yield

  $self->yield( $poe_event, @args );

Provides an interface to L<POE::Kernel>'s yield/post() method, dispatching 
POE events within the context of the emitter's session.

The event can be either a named event/state dispatched to your Emitter's 
L<POE::Session>:

  $emitter->yield( 'some_event', @args );

... or an anonymous coderef, which is executed as if it were a named 
POE state belonging to your Emitter:

  $emitter->yield( sub {
    ## $_[OBJECT] is the Emitter's object:
    my ($kernel, $self) = @_[KERNEL, OBJECT];
    my @params          = @_[ARG0 .. $#_];

    ## $_[STATE] is the current coderef
    ## Yield ourselves again, for example:
    $self->yield( $_[STATE], @new_args )
      if $some_condition;
  }, $some, $args );

Inside an anonymous coderef callback such as shown above, C<$_[OBJECT]> is 
the Emitter's C<$self> object and C<$_[STATE]> contains the callback 
coderef itself.

=head3 call

  $self->call( $poe_event, @args );

The synchronous counterpart to L</yield>.

=head3 timer

  my $alarm_id = $self->timer(
    $delayed_seconds,
    $event,
    @args
  );

Set a timer in the context of the emitter's L<POE::Session>. Returns the 
POE alarm ID.

The event can be either a named event/state or an anonymous coderef (see 
L</yield>).

A prefixed (L</event_prefix>) 'timer_set' event is emitted when a timer is 
set. Arguments are the alarm ID, the event name or coderef, the delay time, 
and any event parameters, respectively.

=head3 timer_del

  $self->timer_del( $alarm_id );

Clears a pending L</timer>.

A prefixed (L</event_prefix>) 'timer_deleted' event is emitted when a timer 
is deleted. Arguments are the removed alarm ID, the event name or coderef, 
and any event parameters, respectively.

=head2 Signals

=head3 Shutdown Signal

The attribute L</shutdown_signal> defines a POE signal that will trigger a 
shutdown; it defaults to C<SHUTDOWN_EMITTER>:

  ## Shutdown *all* emitters (with a default shutdown_signal()):
  $poe_kernel->signal( $poe_kernel, 'SHUTDOWN_EMITTER' );

See L<POE::Kernel/"Signal Watcher Methods"> for details on L<POE> signals.

=head1 SEE ALSO

For details regarding POE, see L<POE>, L<POE::Kernel>, L<POE::Session>

For details regarding Moo classes and Roles, see L<Moo>, L<Moo::Role>, 
L<Role::Tiny>

=head1 AUTHOR

Jon Portnoy <avenj@cobaltirc.org>

Written from the ground up, but conceptually derived from
L<POE::Component::Syndicator>-0.06 copyright Hinrik Orn Sigurosson (HINRIK),
Chris Williams (BINGOS), APOCAL et al -- that will probably do you for
non-Moo(se) use cases; I needed something cow-like that worked with
L<MooX::Role::Pluggable>. 

Licensed under the same terms as Perl 5; see the license that came with your
Perl distribution for details.

=cut


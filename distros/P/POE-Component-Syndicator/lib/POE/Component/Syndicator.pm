package POE::Component::Syndicator;
BEGIN {
  $POE::Component::Syndicator::AUTHORITY = 'cpan:HINRIK';
}
BEGIN {
  $POE::Component::Syndicator::VERSION = '0.06';
}

use strict;
use warnings FATAL => 'all';
use Carp qw(carp croak);
use Object::Pluggable::Constants qw(:ALL);
use POE;
use base 'Object::Pluggable';

use constant REFCOUNT_TAG => 'POE::Component::Syndicator registered';

sub _pluggable_event {
    my ($self, $event, @args) = @_;
    $self->send_event($event, @args);
    return;
}

sub _syndicator_init {
    my ($self, %args) = @_;

    $args{prefix} = 'syndicator_' if !defined $args{prefix};
    $self->{_syndicator}{prefix} = $args{prefix};

    if (defined $args{types}) {
        croak("'types' argument must be an array") if ref $args{types} ne 'ARRAY';
        if (@{ $args{types} } == 4) {
            $self->{_syndicator}{server_event} = $args{types}[0];
            $self->{_syndicator}{user_event} = $args{types}[2];
            $args{types} = { @{ $args{types} } };
        }
        elsif (@{ $args{types} } == 2) {
            $self->{_syndicator}{server_event} = $args{types}[0];
            $self->{_syndicator}{user_event} = $args{types}[1];
        }
        else {
            croak('Only two event types are supported');
        }
    }
    else {
        $args{types} = { SERVER => 'S', USER => 'U' };
        $self->{_syndicator}{server_event} = 'SERVER';
        $self->{_syndicator}{user_event} = 'USER';
    }

    # set up the plugin system
    $self->_pluggable_init(
        prefix     => delete $args{prefix},
        reg_prefix => delete $args{reg_prefix},
        debug      => delete $args{debug},
        types      => delete $args{types},
    );

    if (ref $args{object_states} eq 'ARRAY') {
        my $start_stop = "Don't install handlers for _start or _stop. Use"
                    . "_syndicator_started or _syndicator_stopped instead";
        my $reg_unreg = "Don't install handlers for register or unregister."
                        . " Those are handled by POE::Component::Syndicator";

        for (my $i = 1; $i <= $#{ $args{object_states} }; $i += 2) {
            my $events = $args{object_states}[$i];
            if (ref $events eq 'HASH') {
                if (defined $events->{_start} || defined $events->{_stop}) {
                    croak($start_stop);
                }
                elsif (defined $events->{register} || defined $events->{unregister}) {
                    croak($reg_unreg);
                }
            }
            elsif (ref $events eq 'ARRAY') {
                for my $event (@$events) {
                    if ($event eq '_start' || $event eq '_stop') {
                        croak($start_stop);
                    }
                    elsif ($event eq 'register' || $event eq 'unregister') {
                        croak($reg_unreg);
                    }
                }
            }
        }
    }

    # set up our POE session
    POE::Session->create(
        object_states => [
            $self => {
                _start     => '_syndicator_start',
                _default   => '_syndicator_default',
                _stop      => '_syndicator_stop',
                register   => '_syndicator_register',
                unregister => '_syndicator_unregister',
            },
            $self => [qw(
                _syndicator_shutdown
                _syndicator_send_pending_events
                _syndicator_delay
                _syndicator_delay_remove
                _syndicator_sig_register
                _syndicator_sig_shutdown
                _syndicator_sig_die
            )],
            ($args{object_states} ? @{ $args{object_states} } : ()),
        ],
        ($args{options} ? (options => delete $args{options}) : ()),
        args => [%args],
        heap => $self,
    );

    return;
}

sub _syndicator_sig_die {
    my ($kernel, $self, $ex) = @_[KERNEL, OBJECT, ARG1];
    chomp $ex->{error_str};

    my $error = "Event $ex->{event} in session ".$ex->{dest_session}->ID
        ." raised exception:\n    $ex->{error_str}";

    warn $error, "\n";
    $kernel->sig_handled();
    return;
}

sub _syndicator_destroy {
    my ($self, @args) = @_;
    $self->call('_syndicator_shutdown', @args);
    return;
}

sub _syndicator_shutdown {
    my ($kernel, $self, @args) = @_[KERNEL, OBJECT, ARG0..$#_];
    return if $self->{_shutting_down};
    $kernel->alarm_remove_all();
    $self->_pluggable_destroy();
    $self->send_event($self->{_syndicator}{prefix} . 'shutdown', @args);
    $self->{_shutting_down} = 1;
    return;
}

sub _syndicator_start {
    my ($kernel, $sender, $session, $self, %args)
        = @_[KERNEL, SENDER, SESSION, OBJECT, ARG0..$#_];

    $kernel->sig('DIE', '_syndicator_sig_die');
    $self->{_syndicator}{session_id} = $session->ID();

    # set an alias to keep our session alive
    if (defined $args{alias}) {
        $kernel->alias_set($args{alias});
        $self->{_syndicator}{session_alias} = $args{alias};
    }
    else {
        $kernel->alias_set("$self");
        $self->{_syndicator}{session_alias} = "$self";
    }

    $args{register_signal} = 'SYNDICATOR_REGISTER' if !defined $args{register_signal};
    $kernel->sig($args{register_signal}, '_syndicator_sig_register');
    $args{shutdown_signal} = 'SYNDICATOR_SHUTDOWN' if !defined $args{shutdown_signal};
    $kernel->sig($args{shutdown_signal}, '_syndicator_sig_shutdown');

    # if called from a parent session, register the parent for all events
    # and detach our session from the parent
    if ($sender != $kernel) {
        my $sender_id = $sender->ID;
        my $prefix = $self->{_syndicator}{prefix};
        $self->{_syndicator}{events}{all}{$sender_id} = $sender_id;
        $self->{_syndicator}{sessions}{$sender_id}{ref} = $sender_id;
        $self->{_syndicator}{sessions}{$sender_id}{refcnt}++;
        $kernel->refcount_increment($sender_id, REFCOUNT_TAG);
        $kernel->post($sender, "${prefix}registered", $self);
        $kernel->detach_myself();
    }

    $kernel->call($session, 'syndicator_started');
    return;
}

sub _syndicator_default {
    my ($self, $event, $args) = @_[OBJECT, ARG0, ARG1];
    return if $event =~ /^_/;
    return if $event =~ /^syndicator_(?:started|stopped)$/;
    $self->send_user_event($event, [@$args]);
    return;
}

sub _syndicator_stop {
    my ($kernel, $self) = @_[KERNEL, OBJECT];
    $kernel->call($self->{_syndicator}{session_id}, 'syndicator_stopped');
    return;
}

sub _syndicator_unregister_sessions {
    my ($self) = @_;

    for my $session_id ( keys %{ $self->{_syndicator}{sessions} } ) {
        my $refcnt = $self->{_syndicator}{sessions}{$session_id}{refcnt};
        while ($refcnt-- > 0) {
            $poe_kernel->refcount_decrement($session_id, REFCOUNT_TAG);
        }
        delete $self->{_syndicator}{sessions}{$session_id};
    }

    return;
}

sub yield {
    my ($self, @args) = @_;
    $poe_kernel->post($self->{_syndicator}{session_id}, @args);
    return;
}

sub _syndicator_sig_register {
    my ($kernel, $self, $session, $signal, $sender, @events)
        = @_[KERNEL, OBJECT, SESSION, ARG0..$#_];

    if (!@events || !defined $sender) {
        warn "Signal $signal: not enough arguments\n";
        return;
    }

    my $sender_id;
    if (my $ref = $kernel->alias_resolve($sender)) {
        $sender_id = $ref->ID();
    }
    else {
        warn "Signal $signal: can't resolve sender $sender\n";
        return;
    }

    $self->_syndicator_reg($sender_id, @events);
    return;
}

sub _syndicator_sig_shutdown {
    my ($kernel, $self, @args) = @_[KERNEL, OBJECT, ARG2..$#_];
    $kernel->yield('shutdown', @args) if !$self->{_shutdown_event_sent};
    $self->{_shutdown_event_sent} = 1;
    return;
}

sub _syndicator_register {
    my ($kernel, $self, $session, $sender, @events)
        = @_[KERNEL, OBJECT, SESSION, SENDER, ARG0 .. $#_];

    @events = 'all' if !@events;
    my $sender_id = $sender->ID();
    $self->_syndicator_reg($sender_id, @events);
    return;
}

sub _syndicator_reg {
    my ($self, $sender_id, @events) = @_;
    my $prefix = $self->{_syndicator}{prefix};

    for my $event (@events) {
        $self->{_syndicator}{events}{$event}{$sender_id} = $sender_id;
        $self->{_syndicator}{sessions}{$sender_id}{ref} = $sender_id;

        if (!$self->{_syndicator}{sessions}{$sender_id}{refcnt}
            && $sender_id ne $self->{_syndicator}{session_id}) {
            $poe_kernel->refcount_increment($sender_id, REFCOUNT_TAG);
        }

        $self->{_syndicator}{sessions}{$sender_id}{refcnt}++;
    }

    # BINGOS:
    # Apocalypse is gonna hate me for this as 'registered' events will bypass
    # the plugin system, but I can't see how this event will be relevant
    # without some sort of reference, like what session has registered. I'm
    # not going to start hurling session references around at this point :)
    $poe_kernel->post($sender_id, "${prefix}registered", $self);
    return;
}

sub _syndicator_unregister {
    my ($kernel, $self, $session, $sender, @events)
        = @_[KERNEL, OBJECT, SESSION, SENDER, ARG0 .. $#_];

    @events = 'all' if !@events;
    my $sender_id = $sender->ID();
    my $prefix = $self->{_syndicator}{prefix};

    for my $event (@events) {
        my $blah = delete $self->{_syndicator}{events}{$event}{$sender_id};
        if (!defined $blah) {
            warn "Sender $sender_id hasn't registered for '$event' events";
            next;
        }
        if (!keys %{ $self->{_syndicator}{events}{$event} }) {
            delete $self->{_syndicator}{events}{$event};
        }

        if (--$self->{_syndicator}{sessions}{$sender_id}{refcnt} <= 0) {
            delete $self->{_syndicator}{sessions}{$sender_id};
            if ($session != $sender) {
                $kernel->refcount_decrement($sender_id, REFCOUNT_TAG);
            }
        }
    }

    return;
}

sub delay {
    my ($self, $arrayref, $time) = @_;

    if (!defined $arrayref || ref $arrayref ne 'ARRAY' || !@$arrayref) {
        croak('First argument to delay() must be a populated ARRAYREF');
    }

    croak('No time specified') if !defined $time;

    return $self->call('_syndicator_delay', [@$arrayref], $time);
}

sub _syndicator_delay {
    my ($kernel, $self, $arrayref, $time) = @_[KERNEL, OBJECT, ARG0, ARG1];

    my $event = shift @$arrayref;
    my $alarm_id = $kernel->delay_set($event, $time, @$arrayref);
    if ($alarm_id) {
        my $prefix = $self->{_syndicator}{prefix};
        $self->send_event("${prefix}delay_set", $alarm_id, $event, @$arrayref);
    }
    return $alarm_id;
}

sub delay_remove {
    my ($self, $alarm_id) = @_;
    croak('No alarm id specified') if !defined $alarm_id;
    return $self->call('_syndicator_delay_remove', $alarm_id);
}

sub _syndicator_delay_remove {
    my ($kernel, $self, $alarm_id) = @_[KERNEL, OBJECT, ARG0];

    my @old_alarm_list = $kernel->alarm_remove($alarm_id);
    if (@old_alarm_list) {
        my $args = $old_alarm_list[-1];
        my $prefix = $self->{_syndicator}{prefix};
        $self->send_event("${prefix}delay_removed", $alarm_id, $args);
        return $args;
    }

    return;
}

sub call {
    my ($self, @args) = @_;
    return $poe_kernel->call($self->{_syndicator}{session_id}, @args);
}

sub session_id {
    my ($self) = @_;
    return $self->{_syndicator}{session_id};
}

sub session_alias {
    my ($self) = @_;
    return $self->{_syndicator}{session_alias};
}

sub send_user_event {
    my ($self, $event, $args) = @_;

    push @{ $self->{_syndicator}{pending_events} }, [];
    my $user_type = $self->{_syndicator}{user_event};
    my $eat = $self->_pluggable_process($user_type, $event, $args);
    $self->call('_syndicator_send_pending_events');
    return $eat;
}

sub send_event {
    my ($self, $event, @args) = @_;
    $self->yield('_syndicator_send_pending_events', $event, @args);
    return;
}

sub send_event_now {
    my ($self, $event, @args) = @_;
    $self->call('_syndicator_send_pending_events', $event, @args);
    return;
}

sub send_event_next {
    my ($self, $event, @args) = @_;

    if (!$self->{_syndicator}{pending_events}
        || !@{ $self->{_syndicator}{pending_events} }) {
        croak('send_event_next() can only be called from an event handler');
    }
    else {
        $event =~ s/^\Q$self->{_syndicator}{prefix}//;
        push @{ $self->{_syndicator}{pending_events}[-1] }, [$event, \@args];
    }
    return;
}

sub _syndicator_send_pending_events {
    my ($kernel, $session, $self, $new_event, @args)
        = @_[KERNEL, SESSION, OBJECT, ARG0, ARG1..$#_];
    my $session_id = $session->ID();
    my %sessions;
    my $prefix = $self->{_syndicator}{prefix};

    # create new context if we were passed an event directly
    if (defined $new_event) {
        $new_event =~ s/^\Q$prefix//;
        my @our_events = [$new_event, \@args];
        push @{ $self->{_syndicator}{pending_events} }, \@our_events;
    }

    while (my ($ev) = shift @{ $self->{_syndicator}{pending_events}[-1] }) {
        last if !defined $ev;
        my ($event, $args) = @$ev;

        my @ids = (
            (exists $self->{_syndicator}{events}{all}
                ? values %{ $self->{_syndicator}{events}{all} }
                : ()),
            (exists $self->{_syndicator}{events}{$event}
                ? values %{ $self->{_syndicator}{events}{$event} }
                : ()),
        );

        $sessions{$_} = $_ for @ids;

        # Make sure our session gets notified of any requested events before
        # any other bugger
        if (delete $sessions{$session_id}) {
            $kernel->call($session_id, "$prefix$event", @$args);
        }

        # then let the plugin system process this
        my $server_type = $self->{_syndicator}{server_event};
        if ($self->_pluggable_process($server_type, $event, $args) != PLUGIN_EAT_ALL) {
            # and finally, let registered sessions process it
            for my $session (values %sessions) {
                # We have to use call() here to maintain consistency, for
                # example if a subclass maintains state which needs to make
                # sense at the time this event is delivered (e.g.
                # POE::Component::IRC::State). But this is not good if the
                # user decides to use $poe_kernel->run_while() (which
                # POE::Quickie and LWP::UserAgent::POE do). But then again
                # that's a risk for everyone using call(), and the user
                # should know not to use such modules in event handlers
                # which might get call()ed by foreign sessions.
                $kernel->call($session, "$prefix$event", @$args);
            }
        }

        # unregister all sessions if we're shutting down
        if ($event eq 'shutdown') {
            $self->_syndicator_unregister_sessions();
        }
    }

    pop @{ $self->{_syndicator}{pending_events} };
    return;
}

1;

=encoding utf8

=head1 NAME

POE::Component::Syndicator - A POE component base class which implements the Observer pattern

=head1 SYNOPSIS

 package POE::Component::IRC;

 use strict;
 use warnings;
 use POE;
 use base 'POE::Component::Syndicator';

 # our constructor
 sub spawn {
     my ($package, %args) = @_;

     # process arguments...

     my $self = bless \%args, $package;

     # set up our plugin system and POE session
     $self->_syndicator_init(
         prefix        => 'irc_',
         reg_prefix    => 'PCI_',
         types         => [SERVER => 'S', USER => 'U'],
         object_states => [qw(
             syndicator_started
             shutdown
         )],
     );

     return $self;
 }

 sub syndicator_started {
     my ($kernel, $self) = @_[KERNEL, OBJECT];

     # connect to a server, etc...
 }

 # plugin handler for SERVER event 'hlagh'
 sub S_hlagh {
     # ...
 }

 sub shutdown {
     my ($kernel, $self) = @_[KERNEL, OBJECT];

     # disconnect from a server, etc...

     # shut down the syndicator
     $self->_syndicator_destroy();
 }

=head1 DESCRIPTION

POE::Component::Syndicator is a base class for POE components which need
to handle a persistent resource (e.g. a connection to an IRC server) for
one or more sessions in an extendable way.

This module (as well as L<Object::Pluggable|Object::Pluggable>, which this
module inherits from) was born out of
L<POE::Component::IRC|POE::Component::IRC>, the guts of which quickly
spread to other POE components. Now they can all inherit from this module
instead.

The component provides an event queue, which can be managed with the methods
documented below. It handles delivery of events to the object itself, all
interested plugins, and all interested sessions.

=head2 Component lifetime

You start by calling L<C<_syndicator_init>|/_syndicator_init>, which will
create a POE session with your object as its heap, and a few event handlers
installed. The events described in L</Local events> delimit the start and
end of the session's lifetime. In between those, interested plugins and
sessions will receive various events, usually starting with
L<C<syndicator_registered>|/_syndicator_registered>. In this phase, your
subclass and plugins can call the L<methods|/METHODS> and send the
L<events|/Input events> documented below. When the component has been shut
down, sessions (but not plugins) will receive a
L<C<syndicator_shutdown>|/_syndicator_shutdown> event. After this, the
component will become unusable.

=head2 A note on events

In this document, an I<event> (unless explicitly referred to as a I<POE event>)
is defined as a message originating from POE::Component::Syndicator, delivered
to plugins (and the subclass) via plugin methods and to registered sessions as
POE events.

Interested sessions are considered consumers only, so they always receive
copies of event arguments, whereas interested plugins and subclasses receive
scalar references to them. This allows them to alter, add, or remove event
arguments before sessions (or even other plugins) receive them. For more
information about plugins, see L<Object::Pluggable|Object::Pluggable>'s
documentation. A subclass does not have to register for plugin events.

Two event types are supported: SERVER and USER, though their names can be
overriden (see L<C<_syndicator_init>|/_syndicator_init>).

=head3 SERVER events

These represent data received from the network or some other outside resource
(usually a server, hence the default name).

SERVER events are generated by the L<C<send_event*>|/send_event> methods.
These events are delivered to the subclass and plugins (method C<S_foo>) and
interested sessions (event C<syndicator_foo>).

=head3 USER events

These represent commands about to be sent to a server or some other resource.

USER events are generated by L<C<send_user_event>|/send_user_event>. In
addition, all POE events sent to this component's session (e.g. with
L<C<yield>|/yield>) which do not have a handler will generate corresponding
USER events. USER events are considered more private, so they are only
delivered to the subclass and plugins, not to sessions.

=head1 PRIVATE METHODS

The following methods should only be called by a subclass.

=head2 C<_syndicator_init>

You should call this in your constructor. It initializes
L<Object::Pluggable|Object::Pluggable>, creates the Syndicator's POE session,
and calls the L<C<syndicator_started>|/syndicator_started> POE events. It
takes the following arguments:

B<'prefix'>, a prefix for all your event names, when sent to interested
sessions. If you don't supply this, L<Object::Pluggable|Object::Pluggable>'s
default (B<'pluggable'>) will be used.

B<'reg_prefix'>, the prefix for the C<register()>/C<unregister()>
plugin methods  If you don't supply this, L<Object::Pluggable|Object::Pluggable>'s
default (B<'plugin_'>) will be used.

B<'debug'>, a boolean, if true, will cause a warning to be printed
every time a plugin event handler raises an exception.

B<'types'>, a 2-element arrayref of the types of events that your
component will support, or a 4-element (2 pairs) arrayref where the event
types are keys and their abbrevations (used as plugin event method prefixes)
are values (see L</A note on events> and L<Object::Pluggable|Object::Pluggable>
for more information). The two event types are fundamentally different, so
make sure you supply them in the right order. If you don't provide this
argument, C<< [ SERVER => 'S', USER => 'U' ] >> will be used.

B<'register_signal'>, the name of the register signal (see L</SIGNALS>).
Defaults to B<'SYNDICATOR_REGISTER'>.

B<'shutdown_signal'>, the name of the shutdown signal (see L</SIGNALS>).
Defaults to B<'SYNDICATOR_SHUTDOWN'>.

B<'object_states'> an arrayref of additional object states to add to
the POE session. Same as the 'object_states' argument to
L<POE::Session|POE::Session>'s C<create> method. You'll want to add a handler
for at least the L<C<syndicator_started>|/syndicator_started> event.

B<'options'>, a hash of options for L<POE::Session|POE::Session>'s
constructor.

If you call C<_syndicator_init> from inside another POE session, the
component will automatically register that session as wanting all events.
That session will first receive a
L<C<syndicator_registered>|/syndicator_registered> event.

=head2 C<_syndicator_destroy>

Call this method when you want Syndicator to clean up (delete all plugins,
etc) and make sure it won't keep the POE session alive after all remaining
events have been processed. A L<C<syndicator_shutdown>|/syndicator_shutdown>
event (or similar, depending on the prefix you chose) will be generated.
Any argument passed to C<_syndicator_destroy> will be passed along with that
event.

B<Note:> this method will clear all alarms for the POE session.

=head1 PUBLIC METHODS

=head2 C<session_id>

Returns the component's POE session id.

=head2 C<session_alias>

Returns the component's POE session alias.

=head2 C<yield>

This method provides an alternative, object-based means of posting events to the
component. First argument is the event to post, following arguments are sent as
arguments to the resultant post.

=head2 C<call>

This method provides an alternative, object-based means of calling events to the
component. First argument is the event to call, following arguments are sent as
arguments to the resultant call.

=head2 C<send_event>

Adds a new SERVER event onto the end of the queue. The event will be
processed after other pending events, if any. First argument is an event name,
the rest are the event arguments.

 $component->send_event('irc_public, 'foo!bar@baz.com', ['#mychan'], 'message');

=head2 C<send_event_next>

Adds a new SERVER event to the start of the queue. The event will be the next
one to be processed. First argument is an event name, the rest are the event
arguments.

=head2 C<send_event_now>

Sends a new SERVER event immediately. Execution of the current POE event will
be suspended (i.e. this call will block) until the new event has been
processed by the component class and all plugins. First argument is an event
name, the rest are the event arguments.

=head2 C<send_user_event>

Sends a new USER event immediately. You should call this before every command
you send to your remote server/resource. Only the subclass and plugins will
see this event. Takes two arguments, an event name and an arrayref of
arguments. Returns one of the C<EAT> constants listed in
L<Object::Pluggable::Constants|Object::Pluggable::Constants>. After this
method returns, the arrayref's contents may have been modified by the
subclass or plugins.

 $component->send_user_event('PRIVMSG', '#mychan', 'message');

=head2 C<delay>

This method provides a way of posting delayed events to the component. The
first argument is an arrayref consisting of the delayed command to post and
any command arguments. The second argument is the time in seconds that one
wishes to delay the command being posted.

 my $alarm_id = $component->delay(['mode', $channel, '+o', $dude], 60);

=head2 C<delay_remove>

This method removes a previously scheduled delayed event from the component.
Takes one argument, the C<alarm_id> that was returned by a
L<C<delay>|/delay> method call. Returns an arrayref of arguments to the
event that was originally requested to be delayed.

 my $arrayref = $component->delay_remove($alarm_id);

=head1 EVENTS

=head2 Local events

The component will send the following POE events to its session.

=head3 C<syndicator_started>

Called after the session has been started (like C<_start> in
L<POE::Kernel|POE::Kernel/Session Management>. This is where you should do
your POE-related setup work such as adding new event handlers to the session.

=head3 C<syndicator_stopped>

Called right before the session is about to die (like C<_stop> in
L<POE::Kernel|POE::Kernel/Session Management>).

=head2 Input events

Other POE sessions can send the following POE events to the Syndicator's
session.

=head3 C<register>

Takes any amount of arguments: a list of event names that your session wants
to listen for, minus the prefix (specified in
L<C<syndicator_init>/_syndicator_init>).

 $kernel->post('my syndicator', 'register', qw(join part quit kick));

Registering for the special event B<'all'> will cause it to send all
events to your session. Calling it with no event names is equivalent to
calling it with B<'all'> as an argumente.

Registering will generate a L<C<syndicator_registered>|/syndicator_registered>
event that your session can trap.

Registering with multiple component sessions can be tricky, especially if
one wants to marry up sessions/objects, etc. Check the L<SIGNALS|/SIGNALS>
section for an alternative method of registering with multiple components.

=head3 C<unregister>

Takes any amount of arguments: a list of event names which you I<don't> want
to receive. If you've previously done a L<C<register>|/register>
for a particular event which you no longer care about, this event will
tell the component to stop sending them to you. (If you haven't, it just
ignores you. No big deal.) Calling it with no event names is equivalent to
calling it with B<'all'> as an argument.

If you have registered for the special event B<'all'>, attempting to
unregister individual events will not work. This is a 'feature'.

=head3 C<shutdown>

By default, POE::Component::Syndicator sessions never go away. You can send
its session a C<shutdown> event manually to make it delete itself.
Terminating multiple Syndicators can be tricky. Check the L</SIGNALS> section
for a method of doing that.

=head3 C<_default>

Any POE events sent to the Syndicator's session which do not have a handler
will go to the Syndicator's C<_default> handler, will generate
L</USER events> of the same name. If you install your own C<_default>
handler, make sure you do the same thing before you handle an event:

 use Object::Pluggable::Constants 'PLUGIN_EAT_ALL';

 $poe_kernel->state('_default', $self, '__default');

 sub __default {
     my ($self, $event, $args) = @_[OBJECT, ARG0, ARG1];

     # do nothing if a plugin eats the event
     return if $self->send_user_event($event, [@$args]) == PLUGIN_EAT_ALL;

     # handle the event
     # ...
 }

Note that the handler for the C<_default> event must be named something other
than '_default', because that name is reserved for the plugin-type default
handler (see the L<Object::Pluggable|Object::Pluggable/PLUGINS> docs).

=head2 Output events

The Syndicator will send the following events at various times. The
B<'syndicator_'> prefix in these event names can be customized with a
B<'prefix'> argument to L<C<_syndicator_init>/_syndicator_init>.

=head3 C<syndicator_registered>

Sent once to the requesting session on registration (see
L<C<register>|/register>). C<ARG0> is a reference to the component's object.

=head3 C<syndicator_shutdown>

Sent to all interested sessions when the component has been shut down. See
L<C<_syndicator_destroy>|/_syndicator_destroy>.

=head3 C<syndicator_delay_set>

Sent to the subclass, plugins, and all interested sessions on a successful
addition of a delayed event using the L<C<delay>|/delay> method. C<ARG0> will
be the alarm_id which can be used later with L<C<delay_remove>|/delay_remove>.
Subsequent parameters are the arguments that were passed to L<C<delay>|/delay>.

=head3 C<syndicator_delay_removed>

Sent to the subclass, plugins, and all interested sessions when a delayed
event is successfully removed. C<ARG0> will be the alarm_id that was removed.
Subsequent parameters are the arguments that were passed to L<C<delay>|/delay>.

=head3 All other events

All other events sent by the Syndicator are USER events (generated with
L<C<send_user_event>|/send_user_event>) and SERVER events (generated with
L<C<send_event*>|/send_event>) which will be delivered normally. Your
subclass and plugins are responsible for generating them.

=head1 SIGNALS

The component will handle a number of custom signals that you may send using
L<POE::Kernel|POE::Kernel>'s C<signal> method. They allow any session to
communicate with every instance of the component in certain ways without
having references to their objects or knowing about their sessions. The names
of these signals can be customized with
L<C<_syndicator_init>|/_syndicator_init>.

=head2 C<SYNDICATOR_REGISTER>

Registers for an event with the component. See L<C<register>|/register>.

=head2 C<SYNDICATOR_SHUTDOWN>

Causes a 'shutdown' event to be sent to your session. Any arguments to the
signal will be passed along to the event. That's where you should clean up
and call L<C<_syndicator_destroy>|/_syndicator_destroy>.

=head1 AUTHOR

Hinrik E<Ouml>rn SigurE<eth>sson, L<hinrik.sig@gmail.com>,
Chris C<BinGOs> Williams L<chris@bingosnet.co.uk>,
Apocalypse L<apocal@cpan.org>, and probably others.

=head1 LICENSE AND COPYRIGHT

Copyright 2011 Hinrik E<Ouml>rn SigurE<eth>sson

This program is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

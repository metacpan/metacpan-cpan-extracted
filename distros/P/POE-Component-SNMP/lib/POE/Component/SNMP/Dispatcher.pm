package POE::Component::SNMP::Dispatcher;

use strict;

use base qw/Net::SNMP::Dispatcher/;

use POE::Kernel; # imports $poe_kernel
use POE::Session;

use Time::HiRes qw/time/;
use Scalar::Util qw/weaken/;

our $VERSION = '1.32';

our $INSTANCE;            # reference to our Singleton object

our $MESSAGE_PROCESSING;  # reference to single MP object

BEGIN {
    if ( ! defined &VERBOSE ) {
        eval { sub VERBOSE () { 0 } };
    }
}

# *DEBUG_INFO = sub {};
*DEBUG_INFO = \&Net::SNMP::Dispatcher::DEBUG_INFO;

use constant _ACTIVE   => 0;     # State of the event ( not used )
use constant _TIME     => 1;     # Execution time
use constant _CALLBACK => 2;     # Callback reference
use constant _DELAY    => 3;     # Delay, in seconds

use constant _PAUSE_FD => 0;

# {{{ SUBCLASSED METHODS

# all subclassed methods return the same values as their base
# versions.

# {{{ instance methods and constructor

sub instance { $INSTANCE ||= POE::Component::SNMP::Dispatcher->_new }

# In Net::SNMP::Dispatcher, this function invokes the event
# dispatch loop.  Here, we let POE handle things for us instead,
# and overload with a no-op.
sub activate { }

sub _new     { shift->SUPER::_new(@_)->_new_session() }

sub _new_session {
    my $this = shift;

    # $this->{_active} = Net::SNMP::Message::TRUE;
    $this->{_active} = 1;

    $MESSAGE_PROCESSING = $Net::SNMP::Dispatcher::MESSAGE_PROCESSING;
    POE::Session->create( object_states =>
                          [ $this => [
                                      qw/
                                         _start
                                         _stop
                                         __schedule_event
                                         __invoke_callback
                                         __socket_callback
                                         __listen
                                         __dispatch_pdu
                                         __clear_pending
                                         /
                                     ],
                          ]);

    $this;
}

# }}} instance methods and constructor
# {{{ send_pdu and _send_pdu

# Net::SNMP::Dispatcher::send_pdu() takes a reference to &_send_pdu in
# its own package, which bypasses inheritance.  Here we temporarily
# replace that reference to point to our own local copy before
# continuing.
#
# This is the first method in the chain of calls to
# Net::SNMP::Dispatcher that gets the action going.
sub send_pdu {
    my ($this, $pdu, $delay) = @_;

    DEBUG_INFO('%s', dump_args( [ $pdu, $delay ] ));

    no warnings; # the line below warns "redefined"
    local *Net::SNMP::Dispatcher::_send_pdu = \&_send_pdu;

    weaken($pdu);

    VERBOSE and DEBUG_INFO('{--------  SUPER::send_pdu()');
    my $retval = $this->SUPER::send_pdu($pdu, $delay);
    VERBOSE and DEBUG_INFO(' --------} SUPER::send_pdu()');

    $retval;
}

# _send_pdu() tosses requests into POE space at the __dispatch_pdu
# state, which invokes SUPER::_send_pdu() or queues requests for
# later, as appropriate.
sub _send_pdu {
    my ($this, $pdu, $timeout, $retries) = @_;

     DEBUG_INFO('dispatching request [%d] %s', $pdu->transport->fileno,
                VERBOSE ? dump_args( [ $pdu, $timeout, $retries ] ) : '');

    # using yield() or call() instead of post() here breaks things.  So don't do that.
    $poe_kernel->post(_alias() => __dispatch_pdu =>
                      $pdu, $timeout, $retries);

    1;
}

# }}} send_pdu and _send_pdu
# {{{ schedule and cancel

# Net::SNMP v5.x

# In Net::SNMP::Dispatcher, the critical methods to intercept are:
# - register()  : listen for data on a socket
# - schedule()  : schedule a timeout action if no response is received
# - deregister(): stop listening on a socket
# - cancel()    : cancel a pending event
# Our versions hand the appropriate actions to POE.
#

sub schedule {
    my ($this, $when, $callback) = @_;
    my $time = time;

    # cook the args like Net::SNMP::schedule() does for _event_insert()
    my $event  = [ $this->{_active}, $time + $when, $this->_callback_create($callback), $when ];

    my $fileno = $this->_get_fileno($event);
    if ($event->[_TIME] <= $time) {
        # run the callback NOW, instead of invoking __invoke_callback.  saves a POE call().

        DEBUG_INFO('{--------  invoking callback [%d] %s', $fileno,
                   VERBOSE ? dump_args( $event->[_CALLBACK] ) : '');

        $this->_callback_execute($event->[_CALLBACK]); # no parameter cooking needed!

        DEBUG_INFO(' --------} callback complete [%d]', $fileno);
     } else {
         DEBUG_INFO("%0.1f seconds [%d] %s", $event->[_DELAY], $fileno,
		    VERBOSE ? dump_args( $event->[_CALLBACK] ) : '');

         # This call breaks down to $kernel->alarm_set($event)
         $poe_kernel->call(_alias() => __schedule_event => $event);

	 # $poe_kernel->post(_alias() => __schedule_event => $event);
         # breaks
	 # $poe_kernel->yield(__schedule_event => $event);
     }

     $event;
}

sub cancel {
    my ($this, $event) = @_;

    # this catches a stray shutdown case where __schedule has been
    # queued but not yet dispatched.  In this case, $event->[_TIME]
    # will be an epoch time in the future, meaning that we never
    # replaced it with a POE delay id, which means there is no POE
    # event to cancel.
    return if $event->[_TIME] > time;

    # $event->[_TIME] is the POE alarm id, which was stashed in __schedule_event
    DEBUG_INFO('remove alarm id %d', $event->[_TIME]);
    $poe_kernel->alarm_remove($event->[_TIME]);

    return ! ! $this->_pending_pdu_count($this->_get_fileno($event)); # boolean: are there entries are left?
}

# }}} schedule and cancel
# {{{ register and deregister

## version support
# see the notes on Net::SNMP v4.x support

our $SUPER_register = 'SUPER::register';
our $SUPER_deregister = 'SUPER::deregister';

## coding notes
#
# Here we say $poe_kernel->call(dispatcher => '__listen' ), which does
# select_read() *within a POE::Session* and returns, instead of simply
# invoking select_read() here, so that select_read() is guaranteed to
# occur from within the 'dispatcher' session (instead of possibly the
# parent 'snmp' session).  Otherwise, when we reach _unlisten(), we
# could get a (silent) failure because the "session doesn't own
# handle".

# <rant> This was a *GIGANTIC* hassle to debug, and I don't care who
# knows about it.  During the course of tracing this down, Rocco even
# added a diagnostic message to indicate this problem (see the Changes
# file for POE 0.29 ), so at least I can have the satisfaction of
# having been responsible for somebody else down the line not having
# to spend the hours debugging this same problem that I did.</rant>

sub register {
    my ($this, $transport, $callback) = @_;

    DEBUG_INFO('register on [%d] %s', $transport->fileno, VERBOSE ? dump_args([ $callback ]) : '');

    if (ref ($transport = $this->SUPER::register($transport, $callback))) {

        # $poe_kernel->post(_alias() => __listen => $transport);
        $poe_kernel->call(_alias() => __listen => $transport);

        # we would use this version if we were sending the callback to
        # return with the "got data" event, but in fact we retrieve it
        # directly from the SNMP object.  I can't make up my mind
        # which is cleaner in terms of encapsulation:

        # $poe_kernel->post(_alias() => __listen => $transport,
        #                 [ $this->_callback_create($callback), $transport ]);
    }

    $transport;
}

# there is an optimization here in not having a __unlisten state
# corresponding to __listen (avoiding call() overhead), and just
# telling the kernel directly to stop watching the handle.  __listen
# only needs to exist because when we watch a socket, we have to be in
# the right session... deregister() is always called in the same
# session as __listen.

sub deregister {
    my ($this, $transport) = @_;
    my $fileno = $transport->fileno;

    DEBUG_INFO('deregister on [%d] %s', $transport->fileno,
               VERBOSE ? dump_args([ $transport ]) : '');

    if (ref ($transport = $this->SUPER::deregister($transport))) {
        $this->_unwatch_socket($transport->socket);
    }

    # no more current.
    $this->_clear_current_pdu($fileno);

    if ($this->_pending_pdu_count($fileno)) {
        # run next pending
        DEBUG_INFO('dispatching (queued) request on [%d] %d remaining',
                   $fileno, $this->_pending_pdu_count($fileno) - 1);

        # $poe_kernel->yield(__dispatch_pending_pdu => $fileno);
        $poe_kernel->yield(__dispatch_pdu => $this->_get_next_pending_pdu_args($fileno));
    }

    $transport;
}

# }}} register and deregister

# }}} SUBCLASSED METHODS
# {{{ PRIVATE METHODS

##### socket methods
#
## These two methods are the only place in this module where the
## socket refcounting is done, so it's all self-contained.
#
# {{{ _watch_socket

# socket listen with refcount.  If socket refcount, increment it. Else
# set refcount and listen on the socket.
#
# accesses global kernel.
sub _watch_socket {
    my ($this, $socket) = @_;
    my $fileno = $socket->fileno;

    if (not $this->{_refcount}{$fileno}) {
        # reference counting starts at 1 for the controlling
        # *session*, and 1 for this *request*.
        #
        # refcount will fluctuate between 1 and 2 until the owning
        # snmp session is stopped, then it will drop to 0 and we'll
        # stop watching that handle.
        $this->{_refcount}{$fileno} = 1 + 1;

        DEBUG_INFO('[%d] refcount %d, select', $fileno, $this->{_refcount}{$fileno});

        $poe_kernel->select_read($socket, '__socket_callback');
    } else {
        $this->{_refcount}{$fileno}++;
        DEBUG_INFO('[%d] refcount %d, resume', $fileno, $this->{_refcount}{$fileno});

        _PAUSE_FD and $poe_kernel->select_resume_read($socket);
    }
    $this->{_refcount}{$fileno};
}

# }}} _watch_socket
# {{{ _unwatch_socket

# decrement the socket refcount. unlisten if refcount == 0.
# accesses global kernel.
sub _unwatch_socket {
    my ($this, $socket) = @_;
    my $fileno = $socket->fileno;

    if (--$this->{_refcount}{$fileno} <= 0) {
        DEBUG_INFO('[%d] refcount %d, unselect', $fileno, $this->{_refcount}{$fileno});

        # stop listening on this socket
        $poe_kernel->select_read($socket, undef);
    } else {
        DEBUG_INFO('[%d] refcount %d, pause %s',
                   $fileno, $this->{_refcount}{$fileno}, ('(deferred)') x defined $this->_current_pdu($fileno) );

        _PAUSE_FD and $poe_kernel->select_pause_read($socket) unless $this->_current_pdu($fileno);

    }
    $this->{_refcount}{$fileno}
}

# }}} _unwatch_socket
#####

##### current and pending PDU pethods
# {{{ _current_pdu

# if called with one argument, a fileno, returns the current pdu.
#
# if called with two arguments, a fileno and a pdu, makes that pdu the
# current pdu.
sub _current_pdu {
    my ($this, $fileno, $pdu) = @_;

    if (@_ == 3) {
        $this->{_current_pdu}{$fileno} = $pdu;
    }

    $this->{_current_pdu}{$fileno};
}

# remove the current pdu. return it.
sub _clear_current_pdu {
    my ($this, $fileno) = @_;

    delete $this->{_current_pdu}{$fileno};
}

# }}} _current_pdu
# {{{ (_enqueue_pending|_get_next_pending|_clear_pending)_pdu

# enqueues an array reference
sub _enqueue_pending_pdu {
    my ($this, $fileno, $arg) = @_;

    push @{$this->{_pending_pdu}{$fileno}}, $arg;
}

# dequeues an array reference and dereferences it, returning an array
sub _get_next_pending_pdu_args {
    my ($this, $fileno) = @_;

    @{ shift @{$this->{_pending_pdu}{$fileno}} }
}

# deletes the pending queue
sub _clear_pending_pdu {
    my ($this, $fileno) = @_;

    delete $this->{_pending_pdu}{$fileno};
}

# }}} (_enqueue_pending|_get_next_pending|_clear_pending)_pdu
# {{{ _pending_pdu_count

sub _pending_pdu_count {
    my ($this, $fileno) = @_;

    ref $this->{_pending_pdu}{$fileno} eq 'ARRAY' ?
      scalar @{$this->{_pending_pdu}{$fileno}} :
        0
}

# }}} _pending_pdu_count
#####

# {{{ _current_callback

# fetch the "current" callback for the fileno corresponding to the
# socket we just saw a response on out of Net::SNMP::Dispatcher.
sub _current_callback {
    my ($this, $fileno) = @_;

    $this->{_descriptors}{$fileno}
}

# }}} _current_callback
# {{{ _get_fileno

# the calls to schedule($when, $callback) looks like this:
#    $this->schedule($delay,   [\&_send_pdu,          $pdu, $pdu->timeout, $pdu->retries]);
#    $this->schedule($timeout, [\&_transport_timeout, $pdu, $timeout,      $retries])

# so _CALLBACK is: [ CODE, PDU, TIMEOUT, RETRIES ];

sub _get_fileno {
    my ($this, $event) = @_;

    return $this->_fileno_from_callback($event->[_CALLBACK]);
}

sub _fileno_from_callback {
    my ($self, $callback) = @_;
    # $callback->[1] is a $pdu object
    return $callback->[1]->transport->fileno;
}

# }}} _get_fileno

# {{{ _alias

# this session runs as a singleton, here is its session alias:
sub _alias { '_poe_component_snmp_dispatcher' }

# }}} _alias

# }}} PRIVATE METHODS
# {{{ POE EVENTS

# By convention, all POE states, except _start and _stop, have
# two leading underscores.

# {{{ _start and _stop

sub _start {
    $_[KERNEL]->alias_set(_alias())
}

sub _stop  {
    $_[KERNEL]->alias_remove(_alias());
    undef $INSTANCE;
}

# }}} _start and _stop
# {{{ __dispatch_pdu

# We want to prevent conflicts between listening sockets and pending
# requests, because POE can't listen to two at a time on the same
# handle.  If that socket is currently listening for a reply to a
# different request (eg $this->_current_pdu() is TRUE), the request is
# queued, otherwise it is dispatched immediately.
#
# (which again additionally POE-izes Net::SNMP)
#
# this event is invoked by _send_pdu()
sub __dispatch_pdu {
    my ($this, @pdu_args) = @_[OBJECT, ARG0..$#_];

    # these are the args this state was invoked with:
    # @pdu_args = ( $pdu, $timeout, $retries );

    my $pdu = $pdu_args[0];
    my $fileno = $pdu->transport->fileno;

    # enqueue or execute
    if ($this->_current_pdu($fileno)) {
        # this socket is busy. enqueue.

        $this->_enqueue_pending_pdu($fileno => \@pdu_args);
        DEBUG_INFO('queued request for [%d] %d requests pending',
                   $fileno, $this->_pending_pdu_count($fileno));

    } else {
        # this socket is free. execute.

        DEBUG_INFO('sending request for [%d]', $fileno);

        $this->_current_pdu($fileno => $pdu);

        VERBOSE and DEBUG_INFO('{--------  SUPER::_send_pdu() for [%d]', $fileno);
        $this->SUPER::_send_pdu(@pdu_args);
        VERBOSE and DEBUG_INFO(' --------} SUPER::_send_pdu() for [%d]', $fileno );
    }
}

# }}} __dispatch_pdu
# {{{ __schedule_event

# this event is invoked by schedule() / _event_insert()
sub __schedule_event {
    my ($this, $event) = @_[ OBJECT, ARG0 ];

    # $event->[_ACTIVE] is always true for us, and we ignore it.
    #
    # $event->[_TIME] is the epoch time this event should fire.  We
    # use that value for scheduling the POE event, then replace it
    # with POE's alarm id.
    #
    # $event->[_CALLBACK] is an opaque callback reference.
    #
    # $event->[_DELAY] is how long from the time of scheduling to
    # fire the event, in seconds
    #
    # We get this same $event back in cancel(), where we reference
    # $event->[_TIME] as alarm id to deactivate.

    if ($event->[_TIME] <= time) {
        $this->_callback_execute($event->[_CALLBACK]); # no parameter cooking needed!
        return;
    }

    my $timeout_id = $poe_kernel->alarm_set(__invoke_callback => $event->[_TIME], $event->[_CALLBACK]);

    # stash the alarm id.  since $event is a reference, this
    # assignment is "global".
    $event->[_TIME] = $timeout_id;

    # I only use $event->[_DELAY] for debugging.
    DEBUG_INFO("alarm id %d, %0.1f seconds [%d] %s",
               $timeout_id, $event->[_DELAY],
               $this->_get_fileno($event),
               VERBOSE ? dump_args([ $event->[_CALLBACK] ]) : ''
              );
}

# }}} __schedule_event
# {{{ __invoke_callback

# Invokes a callback immediately.
#
# this event is invoked when an delay has fired.
sub __invoke_callback {
    my ($this, $callback) = @_[OBJECT, ARG0];

    my $fileno = $this->_fileno_from_callback($callback);
    DEBUG_INFO('{--------  invoking scheduled callback for [%d] %s',
               $fileno, VERBOSE ? dump_args([ $callback ]) : '');

    $this->_callback_execute($callback);

    DEBUG_INFO(' --------} callback complete for [%d]', $fileno );
}

# }}} __invoke_callback
# {{{ __listen

# stash the supplied $callback based on the fileno of the $transport
# object.  tell POE to watch the $transport's socket.
#
# this event is invoked by register()
sub __listen {
    my ($this, $transport, $callback) = @_[OBJECT, ARG0, ARG1];
    # we'll fetch the callback directly from $this in
    # __socket_callback.  later versions of POE allow for sending the
    # callback with the request, but we only strive for a "relatively
    # recent" version.  Actually, we've tested all the way back to
    # 0.22, released 03-Jul-2002.

    DEBUG_INFO('listening on [%d]', $transport->fileno);
    $this->_watch_socket($transport->socket);
}

# }}} __listen
# {{{ __socket_callback

# fetch the stashed callback and execute it.
#
# this event is invoked when a watched socket becomes ready to read
# data.
sub __socket_callback {
    my ($this, $socket) = @_[OBJECT, ARG0];
    my $fileno = $socket->fileno;

    return unless $this->_current_callback($fileno);

    DEBUG_INFO('{--------  invoking callback for [%d] %s',
	       $fileno, dump_args($this->_current_callback($fileno)));

    $this->_callback_execute( @{ $this->_current_callback($fileno) } );
    # the extra argument contained in the callback is harmless

    DEBUG_INFO(' --------} callback complete for [%d]', $fileno);
}

# }}} __socket_callback
# {{{ __clear_pending

# account for a 'finish' request to a parent snmp session.  Cancels
# any *pending* requests for the specified session. However, if
# 'finish' is called on a session while the Dispatcher is currently
# listening for a reply to that session, that reply *will* be
# delivered when it arrives.
#
# this event is invoked from P::C::S::close_snmp_session(), to help us
# keep in sync.
sub __clear_pending {
    my ($this, $session) = @_[OBJECT, ARG0];

    DEBUG_INFO('start');

    my $socket =
      $session->transport ?
        $session->transport->socket :
          $session->{_pdu}{_transport} ?
            $session->{_pdu}{_transport}->socket :
              undef;

    my $fileno = $socket ? $socket->fileno : undef;

    DEBUG_INFO('clearing %d pending requests', $this->_pending_pdu_count($fileno));
    $this->_clear_pending_pdu($fileno);

    # we purposely do NOT delete $this->_current_pdu($fileno) until
    # *AFTER* the select() stuff, so that it doesn't bother doing
    # socket ops, because next we will stop listening all the way.

    # drop reference count
    # $this->_unwatch_socket($session->transport->socket);
    $this->_unwatch_socket($socket);

    if (defined (my $pdu = $this->_clear_current_pdu($fileno))) {

        DEBUG_INFO('cancelling current request');

        # stop listening
        $this->deregister($pdu->transport);

        # cancel pending timeout:

        # Fetch the last cached reference held to our request (and its
        # postback) held outside our own codespace...
        if (defined (my $request = $MESSAGE_PROCESSING->msg_handle_delete($pdu->request_id))) {
            # ... which returns enough information to cancel anything
            # we had pending:
            $this->cancel($request->timeout_id);
        }

    }

    DEBUG_INFO('done');
}

# }}} __clear_pending

# }}} POE EVENTS

# {{{ method call tracing

# this code generates overload stubs for EVERY method in class
# SUPER, that warn their name and args before calling SUPER:: whatever.
if (0) {
my $code_for_method_tracing = q!

    no strict; # 'refs';
    my $package = __PACKAGE__ . "::";
    my $super = "$ISA[0]::";

    for (grep defined *{"$super$_"}{CODE}, keys %{$super}) {
        next if /_*[A-Z]+$/; # ignore constants
        next if defined *{ "$package$_" }{CODE};
        print "assigning trace for $_\n";

        *{ "$package::$_" } =
          eval qq[ sub {
                       my (\$package, \$filename, \$line, \$subroutine, \$sub) = caller (1);
                       print "$super$_ from \$subroutine:\$line ", (dump_args(\\\@_)), "\n";
                       goto &{"$super$_"};
                   }
                 ];

        warn "$@" if $@;        # in case we screwed something up
    }
!

}

# {{{ dump_args

# get sub_fullname from Sub::Identify if it's present and we're being
# VERBOSE.  Otherwise, generate our own, simple version.
eval { require Sub::Identify };

if ($@ or not VERBOSE) {

 no warnings 'redefine';
 eval { sub sub_fullname($) { ref shift } };

} else {
    Sub::Identify->import('sub_fullname') unless *sub_fullname;
}

sub dump_args {
    return '' unless VERBOSE;
    my @out;
    my $first = 0;
    for (@{$_[0]}) {
        next if ref eq __PACKAGE__;
        # next if $first++;
        my $out;
        if (ref eq 'ARRAY') {
            $out .= '[';
            $out .= join ' ', map {ref $_ ? (ref $_ eq 'CODE' ? sub_fullname($_) : ref $_ ) : $_ || 'undef'} @$_;
            $out .= ']';
        } elsif (defined $_) {
            $out .= ref $_ ? ref $_ : $_;
        } else {
            $out .= 'undef';
        }
        push @out, $out;
    }

    return '{' . join (" ", @out) . '}';
}

# }}} dump_args

# }}} method call tracing

1;

__END__
# vi:foldmethod=marker:

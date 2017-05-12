package POE::Component::SNMP::Session::Dispatcher;

use strict;
use warnings;

use SNMP;

use Carp;
# use base qw/SNMP::Session/;

# use Smart::Comments qw/####/;

use POE::Kernel;
use POE::Session;

use Time::HiRes qw/time/;

our $INSTANCE;            # reference to our Singleton object

use constant VERBOSE => 0; # debugging, that is

use constant SNMP_DEBUG        => 0; # set to 2 for output, 3 includes packet dumps
# use constant SNMP_SELECT_DEBUG => 0; # set to 2 or 3 to see anything.

# sub DEBUG_INFO() {   }
# sub DEBUG_INFO { my $pat = shift; printf "$pat\n", @_ }
our $DEBUG = 0;

# $SNMP::verbose = $DEBUG;
# $SNMP::debugging = 3;
# $SNMP::debug_internals = $DEBUG;

# {{{ instance methods and constructor

sub instance { $INSTANCE ||= POE::Component::SNMP::Session::Dispatcher->_new }

sub new { _new(@_) };

# sub _new     { shift->SUPER::_new(@_)->_new_session() }
sub _new     {
    my $class = shift;
    my $self = {};
    bless $self, $class;

    $self->_new_session();
}

sub _new_session {
    my $this = shift;

    POE::Session->create( object_states =>
                          [ $this => [ qw/ _start
                                           _stop
                                           __timeout_callback
                                           __socket_callback
                                           __clear_pending

                                           __create_pdu
                                           __listen

                                           _send_pdu
                                         /
                                     ],
                          ]);

    $this;
}

sub _alias {'_poe_component_snmp_session_dispatcher'}

# }}} instance methods and constructor

# {{{ POE EVENTS

# By convention, all POE states, except _start and _stop, have
# two leading underscores.

# {{{ _start and _stop

sub _start {
    $_[KERNEL]->alias_set($_[OBJECT]->_alias);
}

sub _stop  {
    $_[KERNEL]->alias_remove($_[OBJECT]->_alias);
    undef $INSTANCE;
}

# }}} _start and _stop

# {{{ __listen

sub __listen {
    my ($this, $session, $fd) = @_[OBJECT, ARG0..$#_];

    $this->_fd_from_session($session => $fd);
    $this->_session_from_fd($fd => $session);

    $this->_watch_socket($this->_sock_from_fd($fd));
}

# }}} __listen
# {{{ __create_pdu

sub __create_pdu {
    my ($this, $kernel,
        $session, $method, $snmp_args, $postback, $callback_args,
        @args) = @_[OBJECT, KERNEL, ARG0..$#_];

    # $callback_args is defined as:
    # $callback_args = [ $session => $method => \@snmp_args, $callback ]

    my $callback =
      sub {
          # Perl Hacks #57
          local *__ANON__ = __PACKAGE__ . "::   session callback";
          DEBUG_INFO("{{{{ callback start");

          # deliver response
          DEBUG_INFO("     dispatching POE postback");
          # print STDOUT Dump($DISPATCHER);
          $postback->(@_,
                      @$callback_args,
                     );

          # handle cleanups

          my $pending = $this->_dec_pending($session);
          my $fd = $this->_fd_from_session($session);

          if ($pending == 0 and exists $this->{_unwatch}{$fd}) {
              delete $this->{_unwatch}{$fd};
              $this->_unwatch_socket($this->_sock_from_fd($fd));
          }

          DEBUG_INFO("}}}} callback done");
      };

    my $ok;

    ## send an SNMP request.  If error free, check with the API about
    ## timeouts. otherwise return the error.
    DEBUG_INFO("sending request");

    {
        local $SNMP::debugging = SNMP_DEBUG if SNMP_DEBUG;
        $ok = $session->$method( @$snmp_args,
                                 $callback
                               );
        # $SNMP::debugging = 0;
    }

    unless ($ok) {
        DEBUG_INFO("request returns: (%d) %s", $session->{ErrorNum}, $session->{ErrorStr});

        # invoke the callback with nothing.  the session object is
        # available via the calling args, to retrieve the actual
        # error.
        $callback->();

        # calling return here makes the assumption that since
        # the request failed, nothing will have changed as far
        # as what needs to be managed by us.
        return;
    }

    # flag that we have a pending request in the queue.
    $this->_inc_pending($session);

    DEBUG_INFO("sent    request");

    # check timeouts, set delays.  delays WILL have changed after
    # making the request.
    $this->_timeout_check();

    return $ok;
}

# }}} __create_pdu

### ... time passes.  then either a socket comes live, or a timeout occurs.

# {{{ __socket_callback

sub __socket_callback {
    my ($this, $kernel, $socket) = @_[OBJECT, KERNEL, ARG0];
    my $fd = $socket->fileno;

    ### ah-HAH, we got a response!

    DEBUG_INFO('{--------  invoking callback for [%d]', $fd);

    {
        local $SNMP::debugging = SNMP_DEBUG if SNMP_DEBUG;
        SNMP::reply_cb($fd);
    }

    DEBUG_INFO(' --------} callback complete for [%d]', $fd);

    $this->_timeout_check();
}

# }}} __socket_callback
# {{{ __timeout_callback

sub __timeout_callback {
    my ($this) = @_; # $_[OBJECT];

    ### oh NO!! We timed out!

    DEBUG_INFO('{--------  invoking scheduled callback id %d',
               $this->_timeout_id());

    # clear the timeout that just fired
    $this->_timeout_id(undef);

    # check for timeout callbacks or retrigger
    $this->_timeout_check();

    DEBUG_INFO(' --------} callback complete' );
}

# }}} __timeout_callback
# {{{ __clear_pending

# account for a 'finish' request to a parent snmp session.  Cancels
# any *pending* requests for the specified session. However, if
# 'finish' is called on a session while the Dispatcher is currently
# listening for a reply to that session, that reply *will* be
# delivered when it arrives.
#
# this event is invoked from PoCo:S::close_snmp_session(), to help us
# keep in sync.
#
# This event exists as an event so that _unwatch_socket() will live in
# the right POE session.
sub __clear_pending {
    my ($this, $session) = @_[OBJECT, ARG0];
    my $fd = $this->_fd_from_session($session);

    # if a response is still pending, defer unwatch and make it a part
    # of the socket callback.

    # if ($this->_current_pdu($session)) {
    if ($this->_get_pending($session)) {
        DEBUG_INFO('%d response still pending for [%d], deferring _unwatch_socket()', $this->{_pending}{$fd}, $fd);
        $this->{_unwatch}{$fd}++;
    } else {
        $this->_unwatch_socket($this->_sock_from_fd($fd));
    }
}

# }}} __clear_pending

# }}} POE EVENTS

# {{{ PRIVATE METHODS

# {{{ _timeout_check

sub _timeout_check {
    my $this = shift;
    my $delay_id = $this->_timeout_id();
    my $delay;

    DEBUG_INFO(' start');

    # iro e n nes a voki select_info() ir, t e kud & l tav i miutz
    # e urd.
    #
    # there is no need to call select_info() here, it is included
    # in the api call and the delay in seconds is returned.

    # local $SNMP::debugging = 3;
    # $delay = SNMP::check_timeout(); # deferred so that kernel calls happen closer to check_timeout().

    if (defined $delay_id) {
        # $delay_id is defined. adjust it.

        if ($delay = SNMP::check_timeout()) {
            # $delay is non-0, which means we've just gotten a
            # different value from previous.  Adjust our global
            # timeout $delay seconds out.
            POE::Kernel->delay_adjust($delay_id => $delay);

            DEBUG_INFO(' adjusted delay id %d %f seconds', $delay_id, $delay);

        } else {
            # $delay is 0, which means there is nothing pending.
            # Remove our timeout.
            POE::Kernel->alarm_remove($delay_id);
            $this->_timeout_id(undef);

            DEBUG_INFO('  removed delay id %d', $delay_id);
        }

    } elsif ($delay = SNMP::check_timeout()) {
        # $delay_id is NOT defined. define it.

        # we try to set this alarm as soon after $delay is
        # returned as possible. we end up slow by a few usecs.
        $delay_id = POE::Kernel->alarm_set(__timeout_callback => $delay + time,
                                           # $callback, $session
                                          );
        $this->_timeout_id($delay_id);

        DEBUG_INFO(' set delay id %d %f seconds', $delay_id, $delay);

    }

    # return $delay;
}

# }}}  _timeout_check
# {{{ _timeout_id

sub _timeout_id {
    my ($this) = @_;

    # using a global timeout!
    if (@_ > 1) {
        # DEBUG_INFO("Setting timeout_id to [%d]", $_[1]);
        $this->{_timeout_id} = $_[1];
    }
    # DEBUG_INFO("returning timeout_id [%d]", $this->{_timeout_id});
    return $this->{_timeout_id};
}

# }}} _timeout_id

# {{{ _send_pdu

# this method exists to create sugar, so that we can say:
#
# $DISPATCHER->_send_pdu(@args)
#
# instead of
#
# $kernel->call( $DISPATCHER->_alias => __create_pdu => @args)

sub _send_pdu {
    my $this = shift;
    POE::Kernel->call($this->_alias() => __create_pdu => @_);
}

# }}} _send_pdu

# {{{ _listen

# this method exists to create sugar, so that we can say:
#
# $DISPATCHER->_listen(@args)
#
# instead of
#
# $kernel->call( $DISPATCHER->_alias => __listen => @args)

sub _listen {
    my $this = shift;
    POE::Kernel->call(_alias() => __listen => @_);
}

# }}} _listen


# {{{ _clear_session

sub _clear_session {
    my ($this, $session) = @_;

    # warn "XXX have to finish clear_current";
    # WWW { c => $this, sede => $session };

    my $fd = delete $this->{_s_to_fd}{$session};
    my $sock = delete $this->{_fd_to_sock}{$fd};
    delete $this->{_fd_to_s}{$fd};
}

# }}} _clear_session
# {{{ _session_from_fd

sub _session_from_fd {
    my ($this, $fd) = @_;

    if (@_ > 2) {
        $this->{_fd_to_s}{$fd} = $_[2];
    }
    return $this->{_fd_to_s}{$fd};
}

# }}} _session_from_fd
# {{{ _fd_from_session

sub _fd_from_session {
    my ($this, $session) = @_;

    if (@_ > 2) {
        $this->{_s_to_fd}{$session} = $_[2];
    }
    return $this->{_s_to_fd}{$session};
}

# }}} _fd_from_session

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
    my ($this, $socket, @args) = @_;
    my $fd = $socket->fileno;

    if (not $this->{_refcount}{$fd}) {
        # don't need the per-request reference.
        $this->{_refcount}{$fd} = 1;

        DEBUG_INFO('[%d] refcount %d, select', $fd, $this->{_refcount}{$fd});

        POE::Kernel->select_read($socket, '__socket_callback', @args);
    } else {
#         $this->{_refcount}{$fd}++;
#         DEBUG_INFO('[%d] refcount %d, resume', $fd, $this->{_refcount}{$fd});

#         POE::Kernel->select_resume_read($socket);
        die __PACKAGE__, "::_watch_socket(): SHOULD NOT HAVE GOTTEN HERE!";
    }
    return $this->{_refcount}{$fd};
}

# }}} _watch_socket
# {{{ _unwatch_socket

# decrement the socket refcount. unlisten if refcount == 0.
# accesses global kernel.
sub _unwatch_socket {
    my ($this, $socket) = @_;

    DEBUG_INFO("{{{ enter");

    # WWW ([ caller(0), [ caller(1),  [ caller(2), [ caller(3) ]]]]);

    my $fd = $socket->fileno;

    if (--$this->{_refcount}{$fd} <= 0) {
        DEBUG_INFO('[%d] refcount %d, unselect', $fd, $this->{_refcount}{$fd});

        # stop listening on this socket
        POE::Kernel->select_read($socket, undef);

        delete $this->{_refcount}{$fd};

        # _unwatch_socket used to be a per-request operation.  Now it
        # is a destructor, so:
            $this->_clear_session($this->_session_from_fd($fd));

    } else {
#         DEBUG_INFO('[%d] refcount %d, pause %s',
#                    $fd, $this->{_refcount}{$fd}, ''
#                    # ('(deferred)') x defined $this->_current_pdu($fd)
#                   );

#         POE::Kernel->select_pause_read($socket) # unless $this->_current_pdu($fd);

        die __PACKAGE__, "::_unwatch_socket(): SHOULD NOT HAVE GOTTEN HERE!";

    }

    DEBUG_INFO("}}} leave");

    return $this->{_refcount}{$fd}
}

# }}} _unwatch_socket
#####

# {{{ pending requests

sub _inc_pending {
    my ($this, $session) = @_;

    ++$this->{_pending}{$this->_fd_from_session($session)};
}

sub _dec_pending {
    my ($this, $session) = @_;

    --$this->{_pending}{$this->_fd_from_session($session)};
}

sub _get_pending {
    my ($this, $session) = @_;

    $this->{_pending}{$this->_fd_from_session($session)};
}

# }}} pending requests
#####

# {{{ _fileno

sub _fileno {
    if (@_ == 2) {
        $_[0]->{_fileno} = $_[1];
    }
    $_[0]->{_fileno};
}

# }}} _fileno
# {{{ _sock_from_fd

# return a socket attached to a supplied fd

use Symbol qw/gensym/;

sub _sock_from_fd {
    my $this = shift;
    my $fd = shift;
    carp "_sock_from_fd: undefined $fd!", return unless $fd;

    return $this->{_fd_to_sock}{$fd} if exists $this->{_fd_to_sock}{$fd};

    my $socket = gensym;
    open $socket, "<&=", $fd;
    # -- perl critic complains I don't check the return value of
    #    open()

    return $this->{_fd_to_sock}{$fd} ||= $socket;
}

# NOTE: this version killed POE+Tk, even though it supposedly does the
# same as the above.
#
# specifically, the code calls:
#   my $fd =  _fd_from_session($session);
#   my $socket = $this->_sock_from_fd($fd);
sub _sock_from_session {
    my $this = shift;
    my $session = shift;
    carp "_sock_from_session: undefined $session!", return unless $session;

    # return $this->{_fd_to_sock}{$fd} if exists $this->{_fd_to_sock}{$fd};
    return $this->{_session_to_sock}{$session} if exists $this->{_session_to_sock}{$session};

    my $socket = gensym;
    open $socket, "<&=", $this->_fd_from_session($session);

    return $this->{_session_to_sock}{$session} ||= $socket;
}

# }}} _sock_from_fd

# }}} PRIVATE METHODS

# {{{ DEBUG_INFO

sub DEBUG_INFO
{
   return unless $DEBUG;

   printf(
      sprintf('debug: [%d] %s(): ', (caller(0))[2], (caller(1))[3]) .
      ((@_ > 1) ? shift(@_) : '%s') .
      "\n",
      @_
   );

   $DEBUG;
}

# }}} DEBUG_INFO

1;

__END__

# {{{ END Data

package SNMP::Session;

use Inline C => DATA =>
  # Config => ENABLE => AUTOWRAP =>
  LIBS => '-lnetsnmp' =>
  AUTO_INCLUDE => [ '#include <net-snmp/net-snmp-config.h>',
                    '#include <net-snmp/net-snmp-includes.h>'
                  ];

1;

__DATA__
__C__

int _fileno(SV *sess_ref) {
  SV **sess_ptr_sv = hv_fetch((HV*)SvRV(sess_ref), "SessPtr", 7, 1);
  netsnmp_session *ss = (netsnmp_session *)SvIV((SV*)SvRV(*sess_ptr_sv));
  int fileno = 0;

  netsnmp_transport *transport;

  if ((transport = snmp_sess_transport(snmp_sess_pointer(ss))) != NULL)
    fileno = transport->sock;

  /* printf("#### fileno: %d\\n", fileno); */
  return fileno;

}

# }}} END Data

# vi:foldmethod=marker:

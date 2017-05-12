=head1 NAME

Net::SNMP::EV - adaptor to integrate Net::SNMP into the EV event loop.

=head1 SYNOPSIS

 use EV;
 use Net::SNMP;
 use Net::SNMP::EV;

 # just use Net::SNMP and EV as you like:

 ... start non-blocking snmp request(s)...

 EV::loop;

=head1 DESCRIPTION

This module coerces the Net::SNMP scheduler to use the EV high performance
event loop as underlying event loop, i.e. EV will be used by Net::SNMP for
all events.

This integrates Net::SNMP into EV: You can make non-blocking Net::SNMP
calls and as long as your main program uses the EV event loop, they will
run in parallel to anything else that uses EV or AnyEvent.

This module does not export anything and does not require you to do
anything special apart from loading it.

The module is quite short, you can use it as example to implement a
similar integration into e.g. Event or other event loops.

=cut

package Net::SNMP::EV;

no warnings;
use strict;

use Net::SNMP ();
use EV ();

our $VERSION = '0.12';

our @W;
our $DISPATCHER = $Net::SNMP::DISPATCHER;

# handle as many snmp events as possible
sub drain {
   while () {
      $DISPATCHER->one_event;

      my $next = $DISPATCHER->{_event_queue_h}
         or return;

      return $next
         if !$next->[Net::SNMP::Dispatcher::_ACTIVE]
            || $next->[Net::SNMP::Dispatcher::_TIME] > EV::now;
   }
}

our $PREPARE = EV::prepare sub {
   # has any events?
   if ($DISPATCHER->{_event_queue_h}) {
      # do some work
      my $next = drain
         or return;

      # register io watchers for all fds and a single timout
      @W = (
         (map { EV::io $_, EV::READ, sub { } }
             keys %{ $DISPATCHER->{_descriptors} }),

         (EV::timer +($next->[Net::SNMP::Dispatcher::_ACTIVE]
                      ? $next->[Net::SNMP::Dispatcher::_TIME] - EV::now
                      : 0),
                    0, sub { }),
      );
   }
};

our $CHECK = EV::check sub {
   # nuke the watchers again (usually their callbacks will not even be called)
   @W = ();

   drain
      if $DISPATCHER->{_event_queue_h};
};

=head1 BUGS

Net::SNMP has no (documented or otherwise) API to do what this module
does. As such, this module rummages around in the internals of Net::SNMP
in a rather inacceptable way, and as thus might be very sensitive to the
version of Net::SNMP used (it has been tested with some 5.x versions
only, YMMV).

=head1 SEE ALSO

L<EV>, L<Net::SNMP>, L<AnyEvent>, L<Glib::EV>.

=head1 AUTHOR

 Marc Lehmann <schmorp@schmorp.de>
 http://home.schmorp.de/

=cut

1


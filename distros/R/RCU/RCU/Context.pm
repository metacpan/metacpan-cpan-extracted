=head1 NAME

RCU::Context - Remote Control Unit Interface

=head1 SYNOPSIS

   use RCU::Context;

=head1 DESCRIPTION

=over 4

=cut

package RCU::Context;

$VERSION = 0.01;

use Carp;

# the maximum context length required by any context
$histsize = 0;

=item $ctx = new RCU::Context;

Create a new key context.

=cut

sub new {
   my $class = shift;
   my $self = bless {}, $class;
   $self;
}

=item $ctx->bind(event, action)

Bind the given action to an event (see EVENT SYNTAX, below, for an
explanation of this string).

C<action> must be one of the following:

 A code-reference
   This code reference will be called with the event name, generating rcu,
   timestamp and any additional arguments (usually none) fiven to the
   inject method.

 "enter", $context
 "enter*", $context
   Enter the given context object. The forms with an appended star "re-exec"
   the event in the new context.
 
 "leave"
 "leave*"
   leave the current context (restoring the context active before it was
   "enter"'ed)

 "switch", $context
 "switch*", $context
   switch to the given context object

For every keypress, I<only the first> (in order of their definition)
matching event handler is being executed.

=cut

sub bind {
   my $self = shift;
   while (@_) {
      my $event = shift;
      my $action = shift;

      $event = ":$event";
      $event =~ s/:(?=[^=~.<:][^:]*$)/:=/;

      my $len = $event =~ y/://;
      $histsize = $len if $histsize < $len;
      
      unless (ref $action) {
         my $context = shift;

         if    ($action eq "enter"  ) { $action = sub { $_[2]->push_context($context)                       } }
         elsif ($action eq "enter*" ) { $action = sub { $_[2]->push_context($context); $context->inject(@_) } }
         elsif ($action eq "leave"  ) { $action = sub { $_[2]->pop_context                                  } }
         elsif ($action eq "leave*" ) { $action = sub { $_[2]->pop_context;            $context->inject(@_) } }
         elsif ($action eq "switch" ) { $action = sub { $_[2]->set_context($context)                        } }
         elsif ($action eq "switch*") { $action = sub { $_[2]->set_context($context);  $context->inject(@_) } }
      }

      $event =~ y/:/\n/;
      $event = qr<$event\Z>m;
      push @{$self->{events}}, $event;
      $self->{event}{$event} = $action;
   }
}

=item $ctx->inject(event, time, rcu, args...)

Simulate the given event (see "EVENT SYNTAX", below).

=cut

sub inject {
   my $self = shift;
   # remaining args are passed through
   my $event = ":$_[0]"; $event =~ y/:/\n/;
   for (@{$self->{events}}) {
      if ($event =~ $_) {
         #print "calling $_ $self->{event}{$_}\n";#d#
         goto &{$self->{event}{$_}};
         die;
      }
   }
}

=item $ctx->enter($rcu)

=item $ctx->leave($rcu)

"Enter" ("Leave") the context (and create an <enter> (<leave>")
event). Not usually called by application code.

=cut

sub enter {
   my ($self, $rcu) = @_;
   $self->inject("<enter>", $rcu);
}

sub leave {
   my ($self, $rcu) = @_;
   $self->inject("<leave>", $rcu);
}

1;

=back

=head1 EVENT SYNTAX

The simplest way to specify events is using the (cooked) keyname, e.g. the
event C<cd-shuffle> occurs when the key named "cd-shuffle" was pressed
down.

Since events are regular expressions, you have to quote any special
characters (like C<.> or C<*>, where C<^>, C<$> and C<.> stop at keys
boundaries) if you want to use them. On the other hand, regexes give you
great freedom, if you specify the event:

 rcu-key-(\d+)

... you can then use "$1" in your callback to find out which digit was
pressed.

You can prefix a keyname with a "~" which means the key was released
(deactivates, switched off) instead of being pressed. If you want to force
interpretation as a key-down event you can prefix the keyname with an "="
character.

Every key will always generate two events: one key-down (activate) event
when it is pressed and one "~" (key-up) event when it is released again.
It is not possible that two keys are active at the same time.

To make matters slightly more complicated, you can also prepend a
"history" of key names (all seperated by ":") before the current
event. This means that the event depends on previous key-presses (no
prefix characters are there).

Examples (all key names are, of course, hypothetical):

  <enter>          enter the current context
  key-ff           the fast forward key was pressed down
  =key-ff          same as above
  ~key-rev         the "rev"-key was released
  key-tuner:key-4  first the tuner key was pressed (and released), then "4"
  key-tuner:~key-4 first the tuner key was pressed, then "4" was released
  k1:k2:k3         the keys "1", "2" were pressed and released, then
                   "3" was pressed.

EBNF-Grammar

For those of you who need it...

  event     := history prefix eventname
  history   := <empty> | keyname ":" history
  prefix    := <empty> | "=" | "~"
  eventname := keyname | "<enter>" | "<leave>"
  keyname   := any string consisting of printable, non-whitespace
               characters without ":"

=head1 SEE ALSO

L<RCU>.

=head1 AUTHOR

This perl extension was written by Marc Lehmann <schmorp@schmorp.de>.

=cut






=head1 NAME

RCU::Event - Event-based RCU operation

=head1 SYNOPSIS

   use RCU::Event;

   $rcu = connect RCU::Event "interfac-spec", [initial-context]

=head1 DESCRIPTION

This module provides a superset of the standard C<RCU> interface by adding
an event-based interface. Basically, you create one or more I<contexts>
(See C<RCU::Context>) and bind it to a RCU::Event object. All key events
will then be directed to the current context.

=over 4

=cut

package RCU::Event;

$VERSION = 0.01;

use Carp;
use Event;

use RCU;
use RCU::Context;
use base RCU;

=item $ctx = connect RCU::Event "interface-desc";

Create a new RCU interface. The functionality is the same as L<RCU|RCU>,
with the functions added below.

=cut

sub new {
   my $class = shift;
   my $if = shift;
   my $self = $class->SUPER::new($if);

   my $last_key;

   $self->{w} = Event->io(
      fd   => $self->{if}->fd,
      desc => "$if key event",
      poll => 'r',
      hard => 1,
      nice => -1,
      cb   => sub {
         while (my ($time, $raw, $cooked) = $self->{if}->poll) {
            my $key = $RCU::Key::db{$raw}
                      || ($RCU::Key::db{$cooked} ||= new RCU::Key
                            $RCU::some_key->[0] || $RCU::Key::db{""}{"<default>"}[0] || {},
                            $cooked);

            my $repeat_freq = $key->[0]{repeat_freq} || 0.1;
            if ($RCU::last_key != $key || $time > $RCU::next_time) {
               if ($RCU::last_key) {
                  $self->inject("~" . ($RCU::last_key->[2] || $RCU::last_key->[1]), $time);
                  undef $RCU::last_key;
               }
               $self->inject("=" . ($key->[2] || $key->[1]), $time);
            }
            $RCU::some_key = $RCU::last_key = $key;
            $RCU::next_time = $time + $repeat_freq;
            $self->{tow}->stop;
            $self->{tow}->at($RCU::next_time);
            $self->{tow}->start;
         }
      },
   );
   $self->{tow} = Event->timer(
         parked => 1,
         cb     => sub {
            if ($RCU::last_key) {
               $self->inject("~" . ($RCU::last_key->[2] || $RCU::last_key->[1]), $self->{tow}->at);
               undef $RCU::last_key;
            }
         },
   );

   $self;
}

=item $rcu->inject(key)

Act as if key C<key> was pressed (C<key> starts with "=") or released
(when C<key> starts with C<~>).  This is rarely used but is useful to
"simulate" key presses.

=cut

sub inject {
   my $self = shift;
   my ($event, $time) = @_;
   $self->{ctx}->inject((join ":", @{$self->{history}}, $event), $time, $self) if $self->{ctx};
   if ("~" eq substr $event, 0, 1) {
      push  @{$self->{history}}, substr $event, 1;
      shift @{$self->{history}} if @{$self->{history}} > $RCU::Context::histsize;
   }
}

=item $rcu->set_context(new_context)

Leave the current context (if any) and enter the C<new_context>, to which
all new events are directed to.

=cut

sub set_context {
   my $self = shift;
   my $ctx = shift;
   if ($self->{ctx} != $ctx) {
      $self->{ctx}->leave($self) if $self->{ctx};
      $self->{ctx} = $ctx;
      $ctx->enter($self);
   }
}

=item $rcu->push_context(new_context)

Enter the given C<new_context> without leaving the current one.

=cut

sub push_context {
   my $self = shift;
   my $ctx = shift;
   push @{$self->{ctx_stack}}, $self->{ctx};
   $self->{ctx} = $ctx;
   $ctx->enter($self);
}

=item $rcu->pop_context

Leave the current context and restore the previous context that was saved
in C<push_context>.

=cut

sub pop_context {
   my $self = shift;
   $self->{ctx}->leave($self);
   $self->{ctx} = pop @{$self->{ctx_stack}};
}

1;

=back

=head1 SEE ALSO

L<RCU>.

=head1 AUTHOR

This perl extension was written by Marc Lehmann <schmorp@schmorp.de>.

=cut






=head1 NAME

POE::Session::MultiDispatch - Callback dispatch for session events.

=head1 SYNOPSIS

  use POE qw[Session::MultiDispatch];
  
  my $session = POE::Session::MultiDispatch->create(
    inline_states  => { _start => \&_start },
    package_states => [ ... ],
    object_states  => [ ... ],
  );

  sub _start {
    # Execute Foo::Bar's _start state first.
    $_[SESSION]->first( _start => 'Foo::Bar' );
    $_[SESSION]->stop;
  }

  # run Foo::Bar's done state last.
  $session->last( done => 'Foo::Bar' );

  $poe_kernel->run;
  exit 0;

=head1 DESCRIPTION

POE::Session::MultiDispatch is a drop in replacement for
L<POE::Session|POE::Session> that adds callback dispatch functionality
to POE sessions.  Each event may have multiple handlers associated with
it.  Fine control over the order of execution is available using helper
methods that extend the interface of a POE::Session.

POE::Session::MultiDispatch uses POE::Session as a base class.  When
multiple callbacks are registered for an event, only the last callback
survives, all the others are clobbered.  POE::Session::MultiDispatch is
much nicer to your registered callbacks, it keeps them all in the order
they were defined.  When an event is triggered, all the callbacks are
then executed in that same order (unless you muck around with said order).

Just what is the order?  Last I checked it is C<inline_states>,
C<package_states>, and C<object_states>.  As you can probably tell, that
order is by no means documented (here or anywhere else) as something that
is stead fast and solid.  You should be careful and know what you're doing
if you intend to care too much about the order.  Having said that, my
guess is that it won't change.  But don't take my word for it.

All the real heavy lifting is still done in POE::Session.  The interface
is exactly the same with the exception of the following additions.
Please read the POE::Session documentation for details on working with
POE sessions.

=cut

package POE::Session::MultiDispatch;
#
# $Revision: 1.3 $
# $Id: MultiDispatch.pm,v 1.3 2003/02/01 21:53:45 cwest Exp $
#
use strict;
$^W = 1; # At least for development.

use vars qw($VERSION);
$VERSION = (qw$Revision: 1.3 $)[1];

use Carp qw(carp croak);
use base qw[POE::Session];


=head2 Methods

These methods have been added to POE::Sessions's interface.  They
can be accessed from an event by using the session object stored
in C<$_[SESSION]>.  Alternativley, you can use the object returned
when calling C<create()> to call these methods.

=over 4

=item stop

C<stop()> tells the session dispatcher to stop processing callbacks
for this event, after the current one is finished processing.

=cut

sub stop {
  my ($self) = @_;
  
  $self->[POE::Session::SE_OPTIONS]->{stop} = 1;
}

=pod

=item go

C<go()> tells the session dispatcher to continue processing callbacks
for this event.

=cut

sub go {
  my ($self) = @_;

  $self->[POE::Session::SE_OPTIONS]->{stop} = 0;
}

=pod

=item status

C<status()> returns the current status of the event.  It returns true
if the callback stack is set to be stopped, false if we're still going
through.

=cut

sub status {
  my ($self) = @_;

  $self->[POE::Session::SE_OPTIONS]->{stop} || 0;
}

=pod

=item up EVENT, STATE, DIFFERENCE

C<up()> moves a state up in the calling order for an event.  The
difference is how far up to move it, the default is 1.  A state is
given by name.

Inline states don't usually have a name, so one is assigned.  Names
follow the convention 'inline_state_N' where 'N' is a number, zero
indexed.  Package states are named using the package name.  Object
states are named using the object name.

=cut

sub up {
  my ($self, $event, $state, $difference) = @_;
  croak "No event name passed to up()" unless $event;
  croak "No state name passed to up()" unless $state;
  $difference ||= 1;
  $state = 'inline_state_0' if $state eq 'inline_state';
  my $location = $self->_get_event_location( $event );

  my $handlers = $location->{$event};

  my $pos = $self->state_location( $state, $handlers );
  my $newpos = $pos - $difference;
  $newpos = 0 if $newpos < 0;
  
  @{$handlers}[$pos, $newpos] = @{$handlers}[$newpos,$pos];
  
  $location->{$event} = $handlers;
  
  return 1;
}

=pod

=item down EVENT, STATE, DIFFERENCE

C<down()> moves a state down in the calling order for an event.  The
difference is how far down to move it, the default is 1.  A state is
given by name.

=cut

sub down {
  my ($self, $event, $state, $difference) = @_;
  croak "No event name passed to down()" unless $event;
  croak "No state name passed to down()" unless $state;
  $difference ||= 1;
  $state = 'inline_state_0' if $state eq 'inline_state';
  my $location = $self->_get_event_location( $event );

  my $handlers = $location->{$event};

  my $pos = $self->state_location( $state, $handlers );
  my $newpos = $pos + $difference;
  $newpos = $#{$handlers} if $newpos > $#{$handlers};
  
  @{$handlers}[$pos, $newpos] = @{$handlers}[$newpos,$pos];
  
  $location->{$event} = $handlers;
  
  return 1;
}

=pod

=item first EVENT, STATE

C<first()> moves a state to the beginning of the callback stack.

=cut

sub first {
  my ($self, $event, $state) = @_;
  croak "No event name passed to up()" unless $event;
  croak "No state name passed to up()" unless $state;

  $state = 'inline_state_0' if $state eq 'inline_state';
  my $location = $self->_get_event_location( $event );

  my $handlers = $location->{$event};

  my $pos = $self->state_location( $state, $handlers );
  
  @{$handlers}[$pos, 0] = @{$handlers}[0,$pos];
  
  $location->{$event} = $handlers;
  
  return 1;
}

=item last EVENT, STATE

C<last()> moves a state to the end of the callback stack.

=cut

sub last {
  my ($self, $event, $state) = @_;
  croak "No event name passed to up()" unless $event;
  croak "No state name passed to up()" unless $state;

  $state = 'inline_state_0' if $state eq 'inline_state';
  my $location = $self->_get_event_location( $event );

  my $handlers = $location->{$event};

  my $pos = $self->state_location( $state, $handlers );
  
  @{$handlers}[$pos, $#{$handlers}] = @{$handlers}[$#{$handlers}, $pos];
  
  $location->{$event} = $handlers;
  
  return 1;
}

=item swap EVENT, STATE1, STATE2

C<swap()> well... swaps the position of two states.

=cut

sub swap {
  my ($self, $event, $state1, $state2) = @_;
  croak "No event name passed to down()" unless $event;
  croak "Not enough states passed to down()" unless $state1 && $state2;

  my $location = $self->_get_event_location( $event );

  my $handlers = $location->{$event};

  my $pos1 = $self->state_location( $state1, $handlers );
  my $pos2 = $self->state_location( $state2, $handlers );

  @{$handlers}[$pos1, $pos2] = @{$handlers}[$pos2,$pos1];
  
  $location->{$event} = $handlers;
  
  return 1;
}

=pod

=back

=cut

# internal stuff
sub _get_event_location {
  my ($self, $event) = @_;

  return
      exists $self->[POE::Session::SE_OPTIONS]->{+__PACKAGE__}->{$event} ?
      $self->[POE::Session::SE_OPTIONS]->{+__PACKAGE__} :
      $self->[POE::Session::SE_STATES];
}

sub state_location {
  my ($self, $state, $handlers) = @_;
  my $pos    = undef;
  my $inline = 0;
  my $count  = 0;
  foreach (@$handlers) {
    if ( ref($_) eq 'CODE' ) {
  	  my $name = "inline_state_$inline";
  	  if ( $name eq $state ) {
        $pos = $count;
        last;
      } else {
        $inline++;
      }
    } else {
      my ($name, $code) = @$_;
      if ( $name eq $state || $name->isa( $state ) ) {
        $pos = $count;
        last;
      }
    }
    $count++;
  }
  return $pos;  
}

sub _invoke_state {
  my ($self, $source_session, $state, $etc, $file, $line) = @_;

  my $handlers = $self->[POE::Session::SE_STATES]->{$state}
    || $self->[POE::Session::SE_STATES]->{POE::Session::EN_DEFAULT};
  $self->[POE::Session::SE_OPTIONS]->{+__PACKAGE__}->{$state} = $handlers;

  if ( $handlers ) {
    foreach (@$handlers) {
      if ( $self->status == 1 ) {
        $self->go;
        last;
      }
      $self->[POE::Session::SE_STATES]->{$state} = $_;
      $self->SUPER::_invoke_state(@_[1..$#_]);
    }
  } else {
    $self->SUPER::_invoke_state(@_[1..$#_]);
  }

  $self->[POE::Session::SE_STATES]->{$state}
    = delete $self->[POE::Session::SE_OPTIONS]->{+__PACKAGE__}->{$state};
  
  return undef;
}

sub register_state {
  my ($self, $name, $handler, $method) = @_;
  $method = $name unless defined $method;

  if ($name eq POE::Session::EN_SIGNAL) {

    # Report the problem outside POE.
    my $caller_level = 0;
    local $Carp::CarpLevel = 1;
    while ( (caller $caller_level)[0] =~ /^POE::/ ) {
      $caller_level++;
      $Carp::CarpLevel++;
    }

    carp( "The _signal event is deprecated.  ",
          "Please use sig() to register a signal handler"
        );
  }

  # There is a handler, so add the state to the event.

  if ($handler) {

    # Coderef handlers are inline states.

    if (ref($handler) eq 'CODE') {
      carp( "adding state($name) for session(",
            $POE::Kernel::poe_kernel->ID_session_to_id($self), ")"
          )
        if ( $self->[POE::Session::SE_OPTIONS]->{+POE::Session::OPT_DEBUG} );
      if ( ref($self->[POE::Session::SE_STATES]->{$name}) eq 'ARRAY' || ! $self->[POE::Session::SE_STATES]->{$name} ) {
        push @{ $self->[POE::Session::SE_STATES]->{$name} }, $handler;
      } else {
        # ReadWrite wheel seems to be determined to do this, plus,
        # it does make sense.
        $self->[POE::Session::SE_STATES]->{$name} = $handler;
      }
    }

    # Non-coderef handlers may be package or object states.  See if
    # the method belongs to the handler.

    elsif ($handler->can($method)) {
      carp( "adding state($name) for session(",
            $POE::Kernel::poe_kernel->ID_session_to_id($self), ")"
          )
        if ( $self->[POE::Session::SE_OPTIONS]->{+POE::Session::OPT_DEBUG} );
      push @{ $self->[POE::Session::SE_STATES]->{$name} }, [ $handler, $method ];
    }

    # Something's wrong.  This code also seems wrong, since
    # ref($handler) can't be 'CODE'.

    else {
      if ( (ref($handler) eq 'CODE') and
           $self->[POE::Session::SE_OPTIONS]->{+POE::Session::OPT_TRACE}
         ) {
        carp( $POE::Kernel::poe_kernel->ID_session_to_id($self),
              " : state($name) is not a proper ref - not registered"
            )
      }
      else {
        unless ($handler->can($method)) {
          if (length ref($handler)) {
            croak "object $handler does not have a '$method' method"
          }
          else {
            croak "package $handler does not have a '$method' method";
          }
        }
      }
    }
  }

  # No handler.  Delete the state!

  else {
    delete $self->[POE::Session::SE_STATES]->{$name};
  }
}

1;

__END__

=pod

=head1 BUGS

No doubt.

See http://rt.cpan.org to report bugs.

=head2 Known Issues

The following is what I would consider known issues.

=over 4

=item

Updates to the call stack take place right away.  When moving a state
for an event down in the stack, during that event, it will be called twice.
I think that isn't a good idea.

=item

You can call C<stop()> and C<go()> from outside an event callback.  This
is not useful and will almost guarantee a suprise when it's time to start
POE.

=item

I'm sure I can guess reasonable defaults for C<up()>, C<down()>, C<first()>,
C<last()>, and event C<swap> if I wanted to, but I haven't even tried.  This
would be most useful.

=item

Obviously the testing suite is more than lacking, but it does check some
basics, and it gives an example of usage.  Please help me write more.

=back

=head1 AUTHOR

Casey West <casey@geeknest.com>

=head1 THANKS

Matt Cashner -- Many features inspired by his earlier modle,
POE::Session::Cascading.

=head1 COPYRIGHT

Copyright (c) 2003 Casey West.  All rights reserved.  This program 
is free software; you can redistribute it and/or modify it under the same 
terms as Perl itself.

=head1 SEE ALSO

L<perl>, L<POE::Session>, L<POE>.

=cut

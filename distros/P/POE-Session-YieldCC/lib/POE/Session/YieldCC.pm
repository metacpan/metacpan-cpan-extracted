package POE::Session::YieldCC;

use strict;
use warnings;
use POE;
use Coro::State;

our $VERSION = '0.202';

BEGIN { *TRACE = sub () { 0 } unless defined *TRACE{CODE} }
BEGIN { *LEAK  = sub () { 1 } unless defined *LEAK{CODE} }

our @ISA = qw/POE::Session/;

our $_uniq = 1;
sub _get_uniq { $_uniq++ }

our $main;
our $last_state;
sub _invoke_state {
  my $self = shift;
  my $args = \@_; # so I can close on the args below

  # delimit the continuation stack
  local $main = Coro::State->new;

  my $next;
  $next = Coro::State->new(sub {
    print "  invoking the state $args->[1]\n" if TRACE;
    $self->SUPER::_invoke_state(@$args);
    print "  invoked ok $args->[1]\n" if TRACE;

    # jump out to main, there's no need to save state
    # $next is just discarded when _invoke_state is left

    # FACT: at this point there are no continuations into this state
    # hence we're all done, and everything should be destroyed!

    $last_state = Coro::State->new;
    register_object($last_state, "last_state") if LEAK;
    $last_state->transfer($main);

    die "oops shouldn't get here"; # ie you should have discarded $next
  });

  register_object($main, "main") if LEAK;
  register_object($next, "next") if LEAK;

  print "  pre-invoking $args->[1]\n" if TRACE;
  $main->transfer($next);
  print "  post-invoking $args->[1]\n" if TRACE;

  $main = $next = $last_state = undef;
}

sub yieldCC {
  my ($self, $state, @args) = @_;
  print "yieldCC! to $state\n" if TRACE;

  # this makes a continuation
  my @retval;
  my $save = Coro::State->new;
  $POE::Kernel::poe_kernel->yield(
    $state,
    POE::Session::YieldCC::Continuation->new($save, \@retval, $self),
    \@args,
  );

  register_object($save, "yieldCC-save") if LEAK;

  # save the current state, and jump back out to main
  print "jumping back out\n" if TRACE;
  $save->transfer($main);

  return wantarray ? @retval : $retval[0];
}

sub sleep {
  my ($self, $delay) = @_;
  # $self == the session

  my $uniq = _get_uniq;

  $poe_kernel->state(__PACKAGE__."::sleep_${uniq}" => \&_before_sleep);
  $self->yieldCC(__PACKAGE__."::sleep_${uniq}", $delay);
}

sub _before_sleep {
  my ($cont, $args) = @_[ARG0, ARG1];
  $_[KERNEL]->delay($cont->make_state, $$args[0]);
  $_[KERNEL]->state($_[STATE]);
}

sub wait {
  my $self = shift;
  my $uniq = _get_uniq;

  $poe_kernel->state(__PACKAGE__."::wait_event_${uniq}" => \&_before_wait);
  $self->yieldCC(__PACKAGE__."::wait_event_${uniq}", @_);
}

sub _before_wait {
  my ($cont, $args) = @_[ARG0, ARG1];
  my $state = shift @$args;
  my $timeout = shift @$args;
  my @post_timeout = @$args;

  my $tid;
  my $cleanup = sub {
    $poe_kernel->state($state);
    $poe_kernel->alarm_remove($tid) if defined $tid;
    $tid = undef;
  };

  my $handle = sub {
    return unless defined $cont;

    my $res = shift;
    if (!$res && @post_timeout) {
      $poe_kernel->state($state => @post_timeout);
    } else {
      $cleanup->();
    }
    
    $cont->invoke($res, @_);
    $cont = undef;
  };

  $_[KERNEL]->state($state => sub { $handle->(1, @_[ARG0..$#_]) });

  if ($timeout) {
    $_[KERNEL]->state($_[STATE]."_timeout" => sub { $handle->(0) });
    $tid = $_[KERNEL]->delay_set($_[STATE]."_timeout", $timeout);
  }

  $_[KERNEL]->state($_[STATE]);
}

{
  package POE::Session::YieldCC::Continuation;
  use POE;
  use overload
    '&{}' => 'as_code',
    fallback => 1;
  use constant SELF_SAVE    => 0;
  use constant SELF_RETVAL  => 1;
  use constant SELF_SESSION => 2;
  sub new { my $c = shift; return bless [@_], $c }
  sub as_code { my $s = shift; return sub { $s->invoke(@_) } }
  sub invoke {
    my $self = shift;
    my ($save, $retval) = @$self;
    @$retval = @_;
    @_ = ();

    print "continuation invoked\n" if POE::Session::YieldCC::TRACE;
    local $main = Coro::State->new;
    POE::Session::YieldCC::register_object($main, "continuation-main")
      if POE::Session::YieldCC::LEAK;
    $main->transfer($save);
    $save = $last_state = undef;
    print "continuation finished\n" if POE::Session::YieldCC::TRACE;
  }
  sub make_state {
    my $self = shift;
    $self->[SELF_SESSION]->_register_state(
      "\0$self" => sub {
	$self->invoke(@_[ARG0..$#_]);
	$self->[SELF_SESSION]->_register_state("\0$self");
	$self = undef;
      }
    );
    return "\0$self";
  }
}

use Scalar::Util qw/weaken/;
our @objects;
our %descriptions;
sub register_object {
  my $obj = shift;
  @objects = grep defined($_), @objects;
  push @objects, $obj;
  weaken $_ for @objects;
  my $description = shift;
  $descriptions{$obj} = $description;
  print "REGISTER $obj $description\n" if TRACE;
}
END {
  @objects = grep defined($_), @objects;
  if (@objects) {
    print STDERR scalar(@objects), " objects still exist :-/\n";
    print STDERR "$_ $descriptions{$_}\n" for sort @objects;
  }
}

1;

__END__

=head1 NAME

POE::Session::YieldCC - POE::Session extension for using continuations

=head1 SYNOPSIS

  use POE::Session::YieldCC;

  POE::Session::YieldCC->create(
    inline_states => {
      handler => sub {
	print "before\n";
	my $val = $_[SESSION]->yieldCC('do_async', 123);
	print "after: $val\n";
      },
      do_async => sub {
        my ($cont, $args) = @_[ARG0, ARG1];
        # do something synchronously, passing $cont about
        # when we're ready:
	$cont->("value");
      },
      demo_sleep => sub {
	print "I feel rather tired now\n";
	$_[SESSION]->sleep(60);
	print "That was a short nap!\n";
      },
      demo_wait = sub {
        print "I want to wait right now\n";
        $_[SESSION]->wait('demo_wait_event');
        print "Great!\n";
      },
      demo_wait_trigger = sub {
        $_[KERNEL]->yield('demo_wait_event');
      },
    },
  );
  $poe_kernel->run();

=head1 DESCRIPTION

POE::Session::YieldCC extends POE::Session to allow "continuations".  A new
method on the session object, C<yieldCC> is introduced.

C<yieldCC> takes as arguments a state name (in the current session) and
a list of arguments.  Control is yield to that state (via POE::Session->yield)
passing a "continuation" as ARG0 and the arguments as an array reference in
ARG1.  C<yieldCC> does B<not> return immediately.

The "continuation" is a anonymous subroutine that when invoked passes control
back to where C<yieldCC> was called returning any arguments to the continuation
from the C<yieldCC>.  Once the original state that called yieldCC finishes
control returns to where the continuation was invoked.

In fact the "continuation" is also an object with several useful methods that
are listed below.

Examples can be found in the examples/ directory of the distribution.

THIS MODULE IS EXPERIMENTAL.  And while I'm pretty sure I've squashed all the
memory leaks there may still be some.

=head1 METHODS

=over 2

=item sleep SECONDS

Takes a number of seconds to sleep for (possibly fraction in the same way
that POE::Kernel::delay can take fractional seconds) suspending the current
event and only returning after the time has expired.   POE events continue to
be processed while you're sleeping.

=item wait EVENT_NAME [, TIMEOUT [, POST_TIMEOUT_HANDLER... ]]

Takes an event to wait for, suspending the current event. When the wake-up
event is dispatched, control passes back and C<wait> returns true, followed by
any arguments passed in with the event. As with C<sleep>, POE events continue to
be processed while you're waiting.

If a timeout is provided, will optionally return after that number of seconds.
In the case of a timeout, false is returned.

When a timeout is involved, it is possible that some code may try to dispatch
the wakeup-event after C<wait> has already returned. By default the event will
no longer be registered any more, so _default will be delivered. However, if
you so wish you can keep the event registered by providing your own event
handler to take over after a timeout occurs. Anything that C<< $kernel->state
>> understands is acceptable here.

=back

=head1 CONTINUATION METHODS

=over 2

=item invoke ARGS

The same as treating the continuation as a subroutine reference: it invokes
the continuation passing the arguments as the return value of the yieldCC
that created it.  It returns when the original handler next gives up control
either at its end or at another yieldCC call.  It has no meaningful return
value at the current time.

=item make_state

Returns the name of a state of the session which when posted to invokes
the continuation with the event's arguments.

=back

=head1 SEE ALSO

L<POE>, L<POE::Session>, L<Coro::State>

=head1 AUTHOR

Benjamin Smith E<lt>bsmith@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Benjamin Smith

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.5 or,
at your option, any later version of Perl 5 you may have available.


=cut

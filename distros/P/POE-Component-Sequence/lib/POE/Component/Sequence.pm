package POE::Component::Sequence;

=head1 NAME

POE::Component::Sequence - Asynchronous sequences with multiple callbacks

=head1 SYNOPSIS

    use POE qw(Component::Sequence);

    POE::Component::Sequence
        ->new(
            sub {
                my $sequence = shift;
                $sequence->heap_set(
                    a => 5,
                    b => 9,
                    op => '*'
                );
            },
            sub {
                my $sequence = shift;
                my $math = join ' ', map { $sequence->heap_index($_) } qw(a op b);
                $sequence->heap_set(result => eval $math);
            }
        )
        ->add_callback(sub {
            my ($sequence, $result) = @_;
            print "Answer was " . $sequence->heap_index('result') . "\n";
        })
        ->run();

    $poe_kernel->run();

=head1 DESCRIPTION

A Sequence is a series of code blocks (actions) that are executed (handled) within the same context, in series.  Each action has access to the sequence object, can pause it, finish the sequence, add additional actions to be performed later, or store variables in the context (the heap).

If we had the following action in the above example sequence:

    sub {
        my $sequence = shift;
        $sequence->pause;
        ...
    }

...the sequence would pause, waiting for something to call either $sequence->failed, $sequence->finished or $sequence->resume.

=head2 Reasoning

=over 4

Normally, in Perl when I would create a series of asynchronous steps I needed to complete, I would chain them together using a bunch of hardcoded callbacks.  So, say I needed to login to a remote server using a custom protocol, I would perhaps do this:

=over 4

=item 1.

Using POE, yield to a state named 'login' with my params

=item 2.

'login' would send a packet along a TCP socket, assigning the state 'login_callback' as the recipient of the response to this packet.

=item 3.

'login_callback' would run with the response

=back

If I wanted to do something after I was done logging in, I have a number of ways to do this:

=over 4

=item 1.

Pass an arbitrary callback to 'login' (which would somehow have to carry to 'login_callback')

=item 2.

Hard code the next step in 'login_callback'

=item 3.

Have 'login_callback' publish to some sort of event watcher (PubSub) that it had logged in

=back

The first two mechanisms are cludgy, and don't allow for the potential for more than one thing being done upon completion of the task.  While the third idea, the PubSub announce, is a good one, it wouldn't (without cludgly coding) contain contextual information that we wanted carried through the process at the outset.  Additionally, if the login process failed at some point in the process, keeping track of who wants to be notified about this failure becomes very difficult to manage.

The elegant solution, in my opinion, was to encapsulate all the actions necessary for a process into a discrete sequence that can be paused/resumed, can have multiple callbacks, and carry with it a shared heap where I could store and retrieve data from, passing around as a reference to whomever wanted to access it.

=back

=cut

use strict;
use warnings;
use POE;
use Class::MethodMaker [
    array  => [qw(
        actions
        callbacks
        handlers
        on_run
        active_action_path
    )],
    hash   => [qw(
        heap
        options
        delays
    )],
    scalar => [qw(
        alias
        pause_state
        running
        result
        is_error
        is_finished
    )],
];

our $VERSION = '0.02';

my $_session_count = 0;

# Provide a globla attach point for plugins
our @_plugin_handlers;

our $RUN_AGAIN = '__poco_sequence_run_again__';

=head1 USAGE

=head2 Class Methods

=head3 new( ... )

=over 4

Creates a new Sequence object.  Provide a list of actions to be handled in sequence by the handlers.

If the first argument to new() is a HASHREF, it will be treated as arguments that modify the behavior as follows:

=over 4

=item *

Any method that can be chained on the sequence (add_callback, add_error_callback, and add_finally_callback, for example) can be specified in this arguments hash, but obviously only once, as it's a hash and has unique keys.

=item *

Aside from this, the arguments hash is thrown into the $sequence->options and modifies the way the actions are handled (see L<OPTIONS>).

=back

=back

=cut

sub new {
    my $class = shift;
    my $self = bless {}, $class;

    $self->alias(__PACKAGE__ . '_' . $_session_count++);

    POE::Session->create(
        object_states => [
            $self => [qw(
                next
                fail
                finish
                finally
                delay_add
                delay_complete
                delay_adjust
                delay_remove
            )],
        ],
        inline_states => {
            _start => sub {
                my ($kernel) = $_[KERNEL];
                $kernel->alias_set($self->alias);
            },
        },
    );

    if (my @actions = @_) {
        foreach my $action (@actions) {
            $self->add_action($action);
        }
    }

    $self->add_handler(\&default_handler);
    $self->add_handler($_) foreach @_plugin_handlers;

    return $self;
}

=head2 Object Methods, Chained

All these methods return $self, so you can chain them together.

=head3 add_callback( $subref )

=over 4

Callbacks are FIFO.  Adds the subref onto the list of normal callbacks.  See C<finished()> for how and when the normal callbacks are called.  Subref signature is ($sequence, @args || ()) where @args is what was passed to the C<finished()> call (if the sequence completes without C<finished()> called, this will be an empty array).

Dying inside a normal callback will be caught, and will move execution to the error callbacks, passing the error message to the error callbacks.

=back

=cut

sub add_callback {
    my ($self, $callback) = @_;
    $self->callbacks_push({
        code => $callback,
        type => 'normal',
    });
    return $self;
}

=head3 add_error_callback( $subref )

=over 4

Error callbacks are FIFO.  Adds the subref onto the list of error callbacks.  See C<failed()> for how and when the error callbacks are called.  Subref signature is ($sequence, @args || ()) where @args is what was passed to the C<failed()> call (usually a caught 'die' error message).

Return value is not used.

Dying inside an error callback won't be caught by the sequence.

=back

=cut

sub add_error_callback {
    my ($self, $callback) = @_;
    $self->callbacks_push({
        code => $callback,
        type => 'error',
    });
    return $self;
}

=head3 add_finally_callback( $subref )

=over 4

Adds the subref onto the list of 'finally' callbacks.  See C<finally()> for how and when the 'finally' callbacks are called.  This is effectively the same as a normal callback (C<add_callback()>) but is called even if the sequence ended in failure.

Dying inside a 'finally' callback will not be caught.

=back

=cut

sub add_finally_callback {
    my ($self, $callback) = @_;
    $self->callbacks_push({
        code => $callback,
        type => 'finally',
    });
    return $self;
}

=head3 add_action( $subref || <some other scalar value> )

=over 4

Actions are FIFO.  Enqueues the given action.

=back

=cut

sub add_action {
    my ($self, $action) = @_;

    my $stack;
    if ($self->active_action_path_isset) {
        for (my $i = 0; $i < $self->active_action_path_count; $i++) {
            my $idx = $self->active_action_path_index($i);
            $stack = $stack ? $stack->[$idx] : $self->actions_index($idx - 1);
        }
    }

    if (! $stack) {
        $self->actions_push([ $action ]);
    }
    else {
        push @$stack, [ $action ];
    }

    return $self;
}

=head3 add_handler( $subref )

=over 4

Handlers are LIFO.  Enqueues the given handler.  See L<HANDLERS> for more information on this.

=back

=cut

sub add_handler {
    my ($self, $handler) = @_;
    # Unshift as it's LIFO
    $self->handlers_unshift($handler);
    return $self;
}

=head3 add_delay

  $sequence->add_delay(
      5,
      sub {
          my $seq = shift;
          $seq->failed("Took longer than 5 seconds to process");
          # or you can just die and it'll do the same thing
          die "Took longer than 5 seconds to process\n";
      },
      'timeout',
  );

Takes $delay, $action and optionally $name.  If $name is given and another delay was set with the same name, that delay will be removed and replaced with this new delay.  The $action is a subref which will take receive the sequence as it's only argument.  The subref will be executed in an eval { }, with errors causing the failure of the sequence.

The return value of the $action subref is usually ignored, but as a special case, if the subref returns [ $POE::Component::Sequence::RUN_AGAIN, $delay ], the same action will be run again after the indicated delay with the same name.  This allows you to setup a regular delay without having to do a complex recursive algorithm.

=cut

sub add_delay {
    my ($self, @args) = @_;
    $self->do_on_run(sub {
        $poe_kernel->post($self->alias, 'delay_add', @args);
    });
    return $self;
}

=head3 adjust_delay

  $sequence->adjust_delay('timeout', 10);

=cut

sub adjust_delay {
    my ($self, @args) = @_;
    $self->do_on_run(sub {
        $poe_kernel->post($self->alias, 'delay_adjust', @args);
    });
    return $self;
}

=head3 remove_delay

  $sequence->remove_delay('timeout');

=cut

sub remove_delay {
    my ($self, @args) = @_;
    $self->do_on_run(sub {
        $poe_kernel->post($self->alias, 'delay_remove', @args);
    });
    return $self;
}

sub delay_add {
    my ($self, $kernel, $delay, $action, $name) = @_[OBJECT, KERNEL, ARG0 .. $#_];
    my $delay_id = $kernel->delay_set('delay_complete', $delay, $action, $name);
    if (defined $name) {
        #print STDERR "added delay $name\n";
        if (my $existing_delay_id = $self->delays_index($name)) {
            $kernel->alarm_remove($existing_delay_id);
        }
        $self->delays_set($name => $delay_id);
    }
}

sub delay_complete {
    my ($self, $kernel, $action, $name) = @_[OBJECT, KERNEL, ARG0, ARG1];
    my $return = eval { $action->($self) };
    if ($@) {
        $kernel->yield('fail', $@);
    }
    if ($name) {
        $self->delays_reset($name);
    }
    if ($return && ref $return eq 'ARRAY' && $return->[0] eq $RUN_AGAIN) {
        $kernel->call($_[SESSION], 'delay_add', $return->[1], $action, $name);
    }
}

sub delay_adjust {
    my ($self, $kernel, $name, $seconds) = @_[OBJECT, KERNEL, ARG0, ARG1];
    return unless $name && $self->delays_isset($name);
    my $delay_id = $self->delays_index($name);
    $kernel->delay_adjust($delay_id, $seconds);
}

sub delay_remove {
    my ($self, $kernel, $name) = @_[OBJECT, KERNEL, ARG0];
    return unless $name && $self->delays_isset($name);
    my $delay_id = $self->delays_index($name);
    $kernel->alarm_remove($delay_id);
    $self->delays_reset($name);
    #print STDERR "removed delay $name\n";
}

sub do_on_run {
    my ($self, $subref) = @_;

    if ($self->running) {
        $subref->();
    }
    else {
        $self->on_run_push($subref);
    }
}

=head3 run()

=over 4

Starts the sequence.  This is mandatory - if you never call C<run()>, the sequence will never start.

=back

=cut

sub run {
    my $self = shift;

    $self->running(1);
    $self->pause_state(0);
    $poe_kernel->post($self->alias, 'next');

    if ($self->on_run_count) {
        while (my $subref = $self->on_run_shift) {
            $subref->();
        }
    }

    return $self
}

=head2 Object Accessors, public

=head3 heap(), heap_index(), heap_set(), etc.

=over 4

Think of C<heap()> like the POE::Session heap - it is simply a hashref where you may store and retrieve data from while inside an action.  See L<Class::MethodMaker::hash> for all the various heap_* calls that are available to you.  The most important are:

=over 4

=item * heap_index( $key )

Returns the value at index $key

=item * heap_set( $key1 => $value1, $key2 => $value2, ... )

Sets the given key/value pairs, overriding previous values

=item * heap( )

Returns all the key/value pairs of the heap in no particular order

=back

=back

=head3 options_*()

=over 4

In usage identical to C<heap()> above, this is another object hashref.  Its values are intended to modify how the handlers perform their actions.  See L<OPTIONS> for more info.

=back

=head3 alias()

=over 4

Returns the L<POE::Session> alias for this sequence.

=back

=head3 result()

=over 4

Stores the return value of the last action that was executed.  See L<HANDLERS>.

=back

=head2 Object Methods, public

=head3 pause()

=over 4

Pauses the sequence

=back

=cut

sub pause {
    my $self = shift;

    $self->pause_state( $self->pause_state + 1 );
}

=head3 resume()

=over 4

Resumes the sequence.  You must call resume() as many times as pause() was called, as they are cumulative.

=back

=cut

sub resume {
    my $self = shift;

    if ($self->pause_state > 0) {
        $self->pause_state( $self->pause_state - 1 );
    }
    if ($self->pause_state == 0) {
        $poe_kernel->post($self->alias, 'next');
    }
}

=head3 finished( @args )

=over 4

Marks the sequence as finished, preventing further actions to be handled.  The normal callbacks are called one by one, receiving ($sequence, @args) as arguments.  If the normal callbacks die, execution is handed to C<failed()>, and then to C<finally()>.

=back

=cut

sub finished {
    my $self = shift;
    $poe_kernel->post($self->alias, 'finish', @_);
    #$self->is_finished(1);
}

sub finish {
    my ($self, @args) = @_[OBJECT, ARG0 .. $#_];
    return if $self->is_finished();
    $self->is_finished(1);

    foreach my $callback ($self->callbacks) {
        next unless $callback->{type} eq 'normal';
        eval {
            $callback->{code}($self, @args);
        };
        if ($@) {
            $self->failed($@);
            return;
        }

        # Callback can redirect to 'fail'; if so, stop execution
        if ($self->is_error) {
            return;
        }
    }

    $poe_kernel->post($self->alias, 'finally', @_);
}

=head3 failed( @args )

=over 4

Marks the sequence as failed, finishing the sequence.  This will happen if an action dies, if C<failed()> is explicitly called by the user, or if a normal callback dies.  The error callbacks are called one by one, receiving ($sequence, @args) as arguments.  Afterwards, execution moves to C<finally()>.

=back

=cut

sub failed {
    my $self = shift;
    $poe_kernel->post($self->alias, 'fail', @_);
    #$self->is_error(1);
    #$self->is_finished(1);
}

sub fail {
    my ($self, @args) = @_[OBJECT, ARG0 .. $#_];
    $self->is_error(1);
    $self->is_finished(1);

    foreach my $callback ($self->callbacks) {
        next unless $callback->{type} eq 'error';
        # Don't catch exceptions here
        $callback->{code}($self, @args);
    }

    $poe_kernel->post($self->alias, 'finally', @_);
}

=head2 Object Methods, private, POE states

These methods can't be called directly, but instead can be 'yield'ed or 'post'ed to via POE:

  $poe_kernel->post( $sequence->alias, 'finally', @args );

=head3 finish( @args )

=over 4

See C<finished()>.

=back

=head3 fail( @args )

=over 4

See C<failed()>.

=back

=head3 finally( @args )

=over 4

Walks through each 'finally' callback, passing ($sequence, @args) to each.

=back

=cut

sub finally {
    my ($self, $kernel, @args) = @_[OBJECT, KERNEL, ARG0 .. $#_];

    foreach my $callback ($self->callbacks) {
        next unless $callback->{type} eq 'finally';
        # Don't catch exceptions here
        $callback->{code}($self, @args);
    }

    # Remove any alarms that were set; these can't live past the life of the session
    $kernel->alarm_remove_all();
}

=head3 next()

=over 4

The main loop of the code, C<next()> steps through each action on the stack, handling each in turn.  See L<HANDLERS> for more info on this.

=back

=cut

sub _next_recurse {
    my ($stack, $path, $path_index) = @_;
    $path_index = 0 unless defined $path_index;

    my $stack_index = $path->[$path_index];

    # We're guessing here; if there's a value, return it, otherwise undef
    if (! defined $stack_index) {
        my $new_stack = $stack->[1];
        if (defined $new_stack) {
            $path->[$path_index] = 1;
            return $new_stack->[0];
        }     
        return undef;
    }

    # Depth search first
    my $value = _next_recurse($stack->[$stack_index], $path, $path_index + 1);
    if (defined $value) {
        return $value;
    }

    # Breadth search next; return the next value in my stack
    if ($stack_index + 1 >= int @$stack) {
        return undef;
    }

    # Adjust the path and return the next value
    $path->[$path_index]++;
    splice @$path, $path_index + 1;
    return $stack->[$stack_index + 1][0];
}

sub get_next_action {
	my $self = shift;

    ## Find the next action to execute

    # Start with the last action path we know
    my @active_action_path;
    if ($self->active_action_path_isset) {
        @active_action_path = $self->active_action_path;
    }

    # Find the next action, and modify the @active_action_path in place
    my $action = _next_recurse([ undef, $self->actions ], \@active_action_path);

    # Store the newly changed action path
    $self->active_action_path(@active_action_path);

	return $action;
}

sub next {
    my $self = $_[OBJECT];

    return if $self->pause_state || $self->is_finished;

	my $action = $self->get_next_action();

    if (defined $action) {
        # Create request to pass to handlers
        my $request = {
            action => $action,
            options => { $self->options },
        };

        # Perform auto_pause
        if ($request->{options}{auto_pause}) {
            $self->pause();
        }

        # Iterate over handlers
        my $handled;
        foreach my $handler ($self->handlers) {

            my $handler_result;
            eval {
                $handler_result = &$handler($self, $request);
            };
            if ($@) {
                $self->failed($@);
                return;
            }
            
            if ($handler_result->{deferred}) {
                next;
            }
            elsif ($handler_result->{skip}) {
                # Handler wants to skip to the next action
                # Make sure we're unpaused
                $self->pause_state(0);
                $handled = 1;
                last;
            }
            else {
                $self->result($handler_result->{value});
                $handled = 1;
                last;
            }
        }
        if (! $handled) {
            die "No handler handled action '$action'";
        }

        # Perform auto_resume; this refers to the request's copy of the options
        # as the handler may have performed the auto_resume, negating my need to
        # do so.
        if ($request->{options}{auto_resume} && $self->pause_state) {
            $self->pause_state( $self->pause_state - 1 );
        }
    }

    if ($self->pause_state) {
        return;
    }

    # Pull the next action, but don't modify my path (a look ahead, so to speak)
    if (! defined _next_recurse([ undef, $self->actions ], [ $self->active_action_path ])) {
        $poe_kernel->post($self->alias, 'finish');
    }
    else {
        $poe_kernel->post($self->alias, 'next');
    }
}

=head1 OPTIONS

Some options affect the default handler.  Other options may be intended for plugin handlers.

=head2 auto_pause

=over 4

Before each action is performed, the sequence is paused.

=back

=head2 auto_resume

=over 4

After each action is performed, the sequence is resumed. 

=back

=cut

=head1 HANDLERS

To make the sequence a flexible object, it's not actually mandatory that you use CODEREFs as your actions.  If you wanted to provide the name of a POE session and state to be posted to, you could write a handler that does what you need given the action passed.  For example:

    POE::Component::Sequence
        ->new(
            [ 'my_session', 'my_state', @args ],
        )
        ->add_handler(sub {
            my ($sequence, $request) = @_;

            my $action = $request->{action};
            if (! ref $action || ref $action ne 'ARRAY') {
                return { deferred => 1 };
            }

            my $session = shift @$action;
            my $state   = shift @$action;
            my @args    = @$action;

            $sequence->pause;
            $poe_kernel->post($session, $state, $sequence, \@args);

            # Let's just hope $state will unpause the sequence when it's done...
        })
        ->run;

When an action is being handled, a shared request object is created:

  my $request = {
    action => $action,
    options => \%sequence_options,
  }

This request is handed to each handler in turn (LIFO), with the signature ($sequence, $request).  The handler is expected to return either a HASHREF in response or throw an exception.

If a handler returns the key 'deferred', the next handler is tried.  If the handler returns the key 'skip', the action is skipped.  Otherwise, the handler is expected to return the key 'value', which is the optional return value of the $action.  This return value is stored in $sequence->result.  This value will be overwritten upon each action.

The default handler handles actions only of type CODEREFs, passing to the action the arg $self.

If you'd like to add default handlers globally rather than calling C<add_handler()> for each sequence, push the handler onto @POE::Component::Sequence::_plugin_handlers.  See <POE::Component::Sequence::Nested> for an example of this.

=cut

sub default_handler {
    my ($self, $request) = @_;

    my $action = $request->{action};

    if (! defined $action || ! ref $action) {
        return { deferred => 1 };
    }
    elsif (ref $action eq 'HASH') {
        ## Options

        # Allow to bypass normal chaining calls
        foreach my $method (qw(
            add_callback add_error_callback add_finally_callback
            add_action add_handler run
        )) {
            next unless $action->{$method};
            $self->$method(delete $action->{$method});
        }

        # Store the remainder in options
        $self->options_set( %$action );

        return { skip => 1 };
    }
    elsif (ref $action eq 'CODE') {
        ## Normal code ref

        my $value = &$action($self);
        return { value => $value };
    }
    else {
        return { deferred => 1 };
    }
}

1;

__END__

=head1 KNOWN BUGS

No known bugs, but I'm sure you can find some.

=head1 SEE ALSO

L<POE>

=head1 DEVELOPMENT

This module is being developed via a git repository publicly available at L<http://github.com/ewaters/poe-component-sequence>.  I encourage anyone who is interested to fork my code and contribute bug fixes or new features, or just have fun and be creative.

=head1 COPYRIGHT

Copyright (c) 2008 Eric Waters and XMission LLC (http://www.xmission.com/).
All rights reserved.  This program is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the LICENSE file included with
this module.

=head1 AUTHOR

Eric Waters <ewaters@gmail.com>

=cut

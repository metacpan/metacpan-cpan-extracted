package Test::CallFlow::Plan;
use strict;
use Carp;

=head1 Test::CallFlow::Plan

Contains planned calls to mocked functions.

=head1 METHODS

=head2 new

  my $mock_call_plan = Test::CallFlow::Plan->new( %properties );

=cut

sub new {
    my $class = shift;
    my $self = bless {@_}, $class;
    $self->reset;
    $self;
}

=head2 add_call

  $mock_call_plan->add_call( Test::CallFlow::Call->new( 'subname', @args ) );

Adds a call into this plan.

=cut

sub add_call {
    my ( $self, $call ) = @_;
    push @{ $self->{calls} ||= [] }, $call;
}

=head2 call

  $mock_call_plan->call( 'subname', @args );

Heart of plan execution. Searches for a matching call and returns the result.

This should be shortened for ease of further development. Then again, it seems to work.

=cut

sub call {
    my ( $self, $sub, @args ) = @_;
    warn "Plan got call $sub(@args) for planned call #$self->{at}\n"
        if $self->{debug};
    my $got_args = [ $sub, @args ];

    my ( @error, @errors );
    my $at = 0;
    my $call;
    my @try_calls;
    my $trying_in_order = 1;
    my @try_call_at = ( $self->{at} || 0 );
    my @unordered;
    my $num_calls = @{ $self->{calls} || [] };
    my $first_in_order_at;

    while (@try_call_at) {
        warn "Calls to try: @try_call_at",
            $trying_in_order ? "; delayed: @unordered" : ''
            if $self->{debug};
        $at   = shift @try_call_at;
        $call = $self->{calls}[$at]
            or last;

        if ( $trying_in_order and not $call->in_order ) {

            # try again later if match not found in order
            push @unordered, $at
                unless $at <= ( $self->{latest_unordered_at} || -1 );
            if ( ++$at < $num_calls ) {

                # try next in order
                unshift @try_call_at, $at;
            } else {

                # start going through unordered ones
                $trying_in_order = 0;
                @try_call_at = ( @{ $self->{anytime} || [] }, @unordered );
            }
            next;
        } elsif (     not defined $first_in_order_at
                  and not $call->over )
        {
            $first_in_order_at = $at;
        }

        last    # matched!
            unless @error = $call->check($got_args);

        push @errors, [ $at, @error ];

        if ($trying_in_order) {
            if ( $call->satisfied and ++$at < $num_calls ) {

                # this plan may be passed;
                # keep looking ahead in order
                unshift @try_call_at, $at;
                next;
            } else {

                # this plan must be matched in order before any later ones;
                # fallback to looking at unordered ones
                $trying_in_order = 0;
                @try_call_at = ( @{ $self->{anytime} || [] }, @unordered );
            }
        }
    }

    $self->failed_call( [ $sub, @args ], $self->{calls}, \@errors )
        if @error;

    croak "Unplanned call to mock at $self->{at}: $sub(@args)"
        unless $call;

    if (@unordered) {
        push @{ $self->{anytime} ||= [] }, @unordered;
        $self->{latest_unordered_at} = $unordered[-1];
    }

    if ( my $end_calls = $call->{end} ) {
        warn "end calls: @$end_calls" if $self->{debug};
        my %end_calls = map {
            croak(
"Expected call $_->{sub}(@{$_->{args}}) not made until end of scope\n"
            ) unless $_->satisfied;
            $_ => 1
        } @$end_calls;
        $self->{anytime} =
            [ grep { !$end_calls{$_} } @{ $self->{anytime} || [] } ];
    }

    my $result = $call->call;
    $result = wantarray ? ( $result->(@_) ) : ( scalar $result->(@_) )
        if ref $result eq 'CODE';
    $result = [] unless defined $result;
    $result = [$result] unless ref $result eq 'ARRAY';

    # point to where to start looking at next time
    warn "Going from ", ( $self->{at} || 0 ), " to $first_in_order_at"
        if $self->{debug};
    $self->{at} = $first_in_order_at;

    # skip those we can't use anymore
    while ( $self->{at} < $num_calls ) {
        my $call = $self->{calls}[ $self->{at} ];
        confess("Bad item in call plan at $self->{at} ($call)")
            unless ref $call;
        last unless $call->over;
        warn "Passing completed call #$self->{at} ($call->{called}/",
            $call->min, "-", $call->max, "): ", $call->name
            if $self->{debug};
        ++$self->{at};
    }

    warn "mock #$at $sub(@args) -> (@$result)" if $self->{debug};
    return wantarray ? @$result : $result->[0];
}

=head2 failed_call

  $mock_call_plan->failed_call( $called, $calls, \@errors );

Used by C<call()> to report errors. Croaks with a list of tried and failed call proposals.

=cut

sub failed_call {
    my ( $self, $called, $calls, $errors ) = @_;
    my $msg = '';
    my $at  = -1;
    while ( ++$at < @$errors ) {
        my ( $call_at, $arg_at, $test_at ) = @{ $errors->[$at] };
        my $call = $self->{calls}[$call_at];
        $msg .=
              $arg_at
            ? $test_at < @{ $call->{args} }
                ? "Call '$called->[0]' argument #$arg_at ($called->[$arg_at]) did not match "
                : "Too many arguments (" . ( @$called - 1 ) . ") after last "
            : "Called sub name '$called->[0]' did not match ";
        $msg .=
            $test_at
            ? "argument test #$test_at"
            : "sub name";
        $msg .= " of "
            . (   $call->in_order
                ? $call->min 
                        ? 'required' 
                        : 'optional'
                : 'unordered' );
        $msg .= " planned call " . $call->name . "\n";
    }

    croak($msg);
}

=head2 unsatisfied

Returns an array of remaining unsatisfied calls.

Whole plan can be seen as successfully executed once this returns an empty array.

=cut

sub unsatisfied {
    my $self      = shift;
    my $last_call = @{ $self->{calls} } - 1;

    grep { !$_->satisfied }
        $self->{calls}[ ( $self->{at} || 0 ), $last_call ],
        map { $self->{calls}[$_] } @{ $self->{anytime} || [] };
}

=head2 reset

  $plan->reset;

Return to planning state, preserving all previously made plans and discarding any results of running.

=cut

sub reset {
    my $self = shift;
    warn "Reset Mock Plan at ", ( $self->{at} || 0 )
        if $self->{debug};
    $_->reset for @{ $self->{calls} };
    $self->_clean;
}

sub _clean {
    my $self = shift;
    delete $self->{at};
    delete $self->{anytime};
    delete $self->{latest_unordered_at};
}

=head2 list_calls

Returns the list of calls in this plan.

=cut

sub list_calls {
    my $self = shift;
    @{ $self->{calls} };
}

1;

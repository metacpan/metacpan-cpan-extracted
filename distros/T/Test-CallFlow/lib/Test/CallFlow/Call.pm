package Test::CallFlow::Call;
use strict;
use UNIVERSAL qw(isa);
use Carp;

=head1 Test::CallFlow::Call

=head1 SYNOPSIS

  my $call = Test::CallFlow::Call->new( args => [ 'My::Pkg::Method', 'an argument' ] )->result(12765);

  my @mismatch = $call->check( 'My::Pkg::Method', 'an argument' )
    and die "Argument #$mismatch[0] did not match check #$mismatch[1]\n";

  my $result = $call->call; # returns 12765

  print "Enough calls made\n" if $call->satisfied;
  print "No more calls could be made\n" if $call->over;

=head1 PROPERTIES

=over 4

=item args

  [ 'Package::Method', "static argument", ... ]

Reference to an array containing full method name and argument checkers:
static values to compare against or Test::CallFlow:ArgCheck subclasses to use for comparison.

=item results

  [ [ 'first result' ],  [ 'second result' ], [ 'result for any subsequent calls' ] ]

Reference to an array of arrays, each containing the result returned from a call to this mock.

=item min

Minimum number of calls required for this call to be satisfied.

=item max

Maximum number of calls to allow.

=item called

Number of times this call has been made.

=item anytime

When true, this call may be made any time rather than at a specific step.

=item debug

When true, some helpful messages are printed.

=back

=head1 METHODS

=head2 new

  my $call = Test::CallFlow::Call->new(
    args => [
      'full::sub_name',
      qw(arguments to match),
      Test::CallFlow::ArgCheck::Regexp->new( qr/arg regex/ )
    ]
  );

Returns a new C<Test::CallFlow::Call object> with given properties.

=cut

sub new {
    my ( $class, %self ) = @_;
    bless \%self, $class;
}

=head2 result

  $call = $call->result( 'foo', 'bar', 'baz', 'quu' );

Adds a result for a call.
Multiple values will be returned as an array in array context.
Multiple result sets can be defined for a repeated call.

Returns self.

=cut

sub result {
    my ( $self, @values ) = @_;
    push @{ $self->{results} ||= [] }, \@values;
    warn "Add result to ", $self->name() if $self->{debug};
    $self;
}

=head2 result_from

  $call = $call->result_from( \&result_provider_sub );

Adds a result provider for a call.

A result provider will be called whenever a result is required.
It will get as parameters the original call.

Returns self.

=cut

sub result_from {
    my ( $self, $coderef ) = @_;
    push @{ $self->{results} ||= [] }, $coderef;
    warn "Add result provider to ", $self->name() if $self->{debug};
    $self;
}

=head2 anytime

Causes this call to be callable at any time after its declaration, rather than at that exact point in call order.

Returns self.

=cut

sub anytime {
    $_[0]->{anytime} = 1;
    $_[0];
}

=head2 min

  $call->min(0)->max(2);
  die "must be called" if $call->min;

When called with a value, set minimum number of calls required to given value and return self.
When called without a value, returns the current minimum number of calls; default is number of specified results.

=cut

sub min {
    my $self = shift;
    if (@_) {
        $self->{min} = shift;
        return $self;
    }

    defined( $self->{min} )
        ? $self->{min}
        : ( @{ $self->{results} || [] } || 1 );    # default to single void call
}

=head2 max

  $call->max(2)->min(0);
  die "no results available" unless $call->max;

When called with a value, set maximum number of calls possible and return self.
When called without a value, returns the current maximum number of calls.
Default is 1 or bigger of minimum and number of results.

=cut

sub max {
    my $self = shift;
    if (@_) {
        $self->{max} = shift;
        return $self;
    }
    return $self->{max} if defined $self->{max};

    my $results = @{ $self->{results} || [] };
    my $min = $self->min;
    ( $results > $min ? $results : $min ) || 1;
}

=head2 end

  mock_package( 'Foo' );
  my @optionals = (
    Foo->get->anytime->min(0),
    Foo->set->anytime
  );
  Foo->may_be_called->min(0); # ordered, skipped unless called
  Foo->shall_be_called->end( @optionals ); # will croak about uncalled Foo->set 

Given calls that could be made at any time are no more callable.
If any of them are uncalled when this call is matched, optional ones are discarded silently, required ones cause dying with stack trace in L<Test::CallFlow::Plan::call>.

Returns self.

=cut

sub end {
    my ( $self, @end ) = @_;
    push @{ $self->{end} ||= [] }, @end;
    warn $self->name, " planned to end @{$self->{end}}" if $self->{debug};
    $self;
}

=head2 satisfied

  die "Not enough calls made" unless $call->satisfied;

Returns true when enough calls have been made.

=cut

sub satisfied {
    my $self = shift;
    warn $self->name, " satisfied = ", ( $self->{called} || 0 ), " >= ",
        $self->min
        if $self->{debug};
    ( $self->{called} || 0 ) >= $self->min;
}

=head2 over

  die "No more calls can be made" if $call->over;

Returns true when no more calls can be made.

=cut

sub over {
    my $self = shift;
    ( $self->{called} || 0 ) >= $self->max;
}

=head2 in_order

Returns true if this call must be made in order, false if it can be made at any time.

=cut

sub in_order {
    !$_[0]->{anytime};
}

=head2 check

  die "Arg #$arg failed to match arg check #$check"
    if my ($arg, $check) =
      $call->check( [ $sub, @args ] );

Returns nothing on success.
On failure, returns position of failed argument and position of the test it failed against.

=cut

sub check {
    my ( $self, $args ) = @_;
    my $arg_tests = $self->{args} || [];
    my $test_at   = 0;
    my $args_at   = 0;

    do {
        my $check = $arg_tests->[$test_at];
        my $arg   = $args->[$args_at];

        warn
"Check argument #$args_at '$arg' of (@$args) against test #$test_at '$check'"
            if $self->{debug};

        $args_at = !defined $check
            ? (
            !defined $arg
            ? $args_at + 1     # undef matches undef
            : -1 - $args_at    # should have been undef
            )
            : isa( $check, 'Test::CallFlow::ArgCheck' )
            ? $check->skip_matching( $args_at, $args )    # returns new position
            : ( defined $args->[$args_at] and $check eq $args->[$args_at] )
            ? $args_at + 1     # scalars match
            : -1 - $args_at    # undef or mismatching scalar

    } while ( $args_at > 0 and ++$test_at < @$arg_tests );

    my @result =
        $args_at < @$args
        ? ( ( $args_at < 0 ? -$args_at - 1 : $args_at ), $test_at )
        : ();

    warn "Check ", $self->name(), " at $args_at ",
        ( @result ? " mismatch: @result" : " ok" ), "\n"
        if $self->{debug};

    @result;
}

=head2 call

  my $result = $call->call;

Returns next result of this call, nothing if result not set.

Dies if call has been executed more than maximum times.

=cut

sub call {
    my $self = shift;
    $self->{called_from} = shift;
    die $self->name, " called too many times ($self->{called} > ", $self->max,
        ")\n"
        if ++$self->{called} > $self->max;
    warn $self->name, " called $self->{called} times" if $self->{debug};
    return
        unless my $results = @{ $self->{results} || [] };
    my $at = $self->{called} < $results ? $self->{called} : $results;
    return $self->{results}[ $at - 1 ];
}

=head2 called_from

  $call->called_from( "subname" );

Sets calling context reported by C<name()>.

Returns self.

=cut

sub called_from {
    my $self = shift;
    $self->{called_from} = shift;
    $self;
}

=head2 name

  print "Calling ", $call->name, "\n";

Returns a user-readable representation of this call.

=cut

sub name {
    my $self = shift;
    my ( $name, @args ) = @{ $self->{args} || [] };
    $name .= _list_to_string(@args) if @args;
    $name .= "->result"
        . join "->result",
        map { ref $_ eq 'CODE' ? "_from( \\\&{'$_'} )" : _list_to_string(@$_) }
        @{ $self->{results} }
        if $self->{results};
    $name .= "->called_from('$self->{called_from}')"
        if defined $self->{called_from};
    $name;
}

sub _list_to_string {
    "(" . join( ", ", map { "'$_'" } @_ ) . ")";
}

=head2 reset

  $call->reset;

Resets the call object to pre-run state.

=cut

sub reset {
    my $self = shift;
    warn "Reset ", $self->name if $self->{debug};
    delete $self->{called};
}

1;

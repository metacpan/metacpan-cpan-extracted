package PDF::FromHTML::Template::Iterator;

use strict;

BEGIN {
    use vars qw(@ISA);
    @ISA = qw(PDF::FromHTML::Template::Base);

    use PDF::FromHTML::Template::Base;
}

sub new
{
    my $class = shift;
    my $self = $class->SUPER::new(@_);

    unless (PDF::FromHTML::Template::Factory::isa($self->{CONTEXT}, 'CONTEXT'))
    {
        die "Internal Error: No context object passed to ", __PACKAGE__, $/;
    }

    $self->{MAXITERS} ||= 0;

    # This is the index we will work on NEXT, in whatever direction the
    # iterator is going.
    $self->{INDEX} = -1;

    # This will always increment because it's tracking how many iterations
    # have happened on this page, regardless of the direction the iterator
    # is traveling.
    $self->{ITERS_THIS_PAGE} = 0;

    # This is a short-circuit parameter to let the iterator function in a
    # null state.
    $self->{NO_PARAMS} = 0;
    unless ($self->{NAME} =~ /\w/)
    {
        $self->{NO_PARAMS} = 1;

        warn "INTERNAL ERROR: 'NAME' was blank was blank when passed to ", __PACKAGE__, $/;

        return $self;
    }

    # Cache the reference to the appropriate data.
    $self->{DATA} = $self->{CONTEXT}->param($self->{NAME});

    unless (UNIVERSAL::isa($self->{DATA}, 'ARRAY'))
    {
        $self->{NO_PARAMS} = 1;
        warn "'$self->{NAME}' does not have a list of parameters", $/;

        return $self;
    }

    unless (@{$self->{DATA}})
    {
        $self->{NO_PARAMS} = 1;
    }

    $self->{MAX_INDEX} = $#{$self->{DATA}};

    return $self;
}

sub enter_scope
{
    my $self = shift;

    return 0 if $self->{NO_PARAMS};

    for my $x ($self->{DATA}[$self->{INDEX}])
    {
        $x->{uc $_} = delete $x->{$_} for keys %$x;
    }
    push @{$self->{CONTEXT}{PARAM_MAP}}, $self->{DATA}[$self->{INDEX}];

    return 1;
}

sub exit_scope
{
    my $self = shift;

    return 0 if $self->{NO_PARAMS};

    # There has to be the base parameter map and at least the one that
    # Iterator::enter_scope() added on top.
    @{$self->{CONTEXT}{PARAM_MAP}} > 1 ||
        die "Internal Error: ", __PACKAGE__, "'s internal param_map off!", $/;

    pop @{$self->{CONTEXT}{PARAM_MAP}};

    return 1;
}

sub can_continue
{
    my $self = shift;

    return 0 if $self->{NO_PARAMS};

    return 1 if $self->more_params &&
                $self->more_space &&
                $self->more_iters;

    return 0;
}

sub more_iters
{
    my $self = shift;

    return 0 if $self->{NO_PARAMS};

    return 1 unless $self->{MAXITERS};

    return 1 if $self->{MAXITERS} > $self->{ITERS_THIS_PAGE};

    return 0;
}

sub more_params
{
    my $self = shift;

    return 0 if $self->{NO_PARAMS};

    return 1 if $self->{MAX_INDEX} > $self->{INDEX};

    return 0;
}

sub more_space
{
    my $self = shift;

    return 0 if $self->{NO_PARAMS};

    return 1 if $self->{CONTEXT}->get($self, 'Y') >= ($self->{CONTEXT}->get($self, 'END_Y'));

    return 0;
}

# Call this method BEFORE incrementing the index to the next value.
sub _do_globals
{
    my $self = shift;

    my $data = $self->{DATA}[$self->{INDEX}];

    # Perl's arrays are 0-indexed. Thus, the first element is at index "0".
    # This means that odd-numbered elements are at even indices, and vice-versa.
    # This also means that MAX (the number of elements in the array) can never
    # be the value of an index. It is NOT the last index in the array.

    $data->{'__FIRST__'} ||= ($self->{INDEX} == 0);
    $data->{'__INNER__'} ||= (0 < $self->{INDEX} && $self->{INDEX} < $self->{MAX_INDEX});
    $data->{'__LAST__'}  ||= ($self->{INDEX} == $self->{MAX_INDEX});
    $data->{'__ODD__'}   ||= !($self->{INDEX} % 2);

    return 1;
}

sub next
{
    my $self = shift;

    return 0 if $self->{NO_PARAMS};

    return 0 unless $self->more_params;

    $self->exit_scope;

    $self->{INDEX}++;
    $self->{ITERS_THIS_PAGE}++;

    $self->_do_globals;

    $self->enter_scope;

    return 1;
}

sub back_up
{
    my $self = shift;

    return 0 if $self->{NO_PARAMS};

    $self->exit_scope;

    $self->{INDEX}--;
    $self->{ITERS_THIS_PAGE}++;

    $self->_do_globals;

    $self->enter_scope;

    return 1;
}

sub reset
{
    my $self = shift;

    return 0 if $self->{NO_PARAMS};

    $self->{INDEX} = -1;
    $self->{ITERS_THIS_PAGE} = 0;

    return 1;
}

1;
__END__

package PDF::FromHTML::Template::Container::Loop;

use strict;

BEGIN {
    use vars qw(@ISA);
    @ISA = qw(PDF::FromHTML::Template::Container);

    use PDF::FromHTML::Template::Container;
}

sub new
{
    my $class = shift;
    my $self = $class->SUPER::new(@_);

    if (exists $self->{MAXITERS} && $self->{MAXITERS} < 1)
    {
        die "<loop> MAXITERS must be greater than or equal to 1", $/;
    }
    else
    {
        $self->{MAXITERS} = 0;
    }

    return $self;
}

sub _do_page
{
    my $self=shift;
    my ($context) = @_;
    return 0 unless $self->should_render($context);
    unless ($self->{ITERATOR} && $self->{ITERATOR}->more_params)
    {
        $self->{ITERATOR} = $self->make_iterator($context);
    }
    my $iterator = $self->{ITERATOR};
    $iterator->enter_scope;
    while ($iterator->can_continue)
    {
        $iterator->next;
        $self->SUPER::begin_page($context);
    }
    $iterator->exit_scope;
    return 1;
}

sub begin_page
{
    _do_page(@_,'begin_page');
}

sub end_page
{
    _do_page(@_,'end_page');
}

sub make_iterator
{
    my $self = shift;
    my ($context) = @_;

    return PDF::FromHTML::Template::Factory->create('ITERATOR',
        NAME     => $context->get($self, 'NAME'),
        MAXITERS => $context->get($self, 'MAXITERS'),
        CONTEXT  => $context,
    );
}

sub render
{
    my $self = shift;
    my ($context) = @_;

    return 0 unless $self->should_render($context);

    unless ($self->{ITERATOR} && $self->{ITERATOR}->more_params)
    {
        $self->{ITERATOR} = $self->make_iterator($context);
    }
    my $iterator = $self->{ITERATOR};

    $iterator->enter_scope;

    while ($iterator->can_continue)
    {
        $iterator->next;

        unless ($self->iterate_over_children($context))
        {
            $iterator->back_up;
            last;
        }

        $self->reset;
    }

    $iterator->exit_scope;

    if ($iterator->more_params) {
        splice(@{$iterator->{DATA}}, 0, $iterator->{INDEX}+1);
        $iterator->{MAX_INDEX} = $#{$iterator->{DATA}};
        return 0;
    }

    return 1;
}

sub total_of
{
    my $self = shift;
    my ($context, $attr) = @_;

    my $iterator = $self->make_iterator($context);

    my $total = 0;

    $iterator->enter_scope;
    while ($iterator->can_continue)
    {
        $iterator->next;
        $total += $self->SUPER::total_of($context, $attr);
    }
    $iterator->exit_scope;

    return $total;
}

sub max_of
{
    my $self = shift;
    my ($context, $attr) = @_;

    my $iterator = $self->make_iterator($context);

    my $max = $context->get($self, $attr);

    $iterator->enter_scope;
    while ($iterator->can_continue)
    {
        $iterator->next;
        my $v = $self->SUPER::max_of($context, $attr);

        $max = $v if $max < $v;
    }
    $iterator->exit_scope;

    return $max;
}

1;
__END__

=head1 NAME

PDF::FromHTML::Template::Container::Loop

=head1 PURPOSE

To provide a looping construct

=head1 NODE NAME

LOOP

=head1 INHERITANCE

PDF::FromHTML::Template::Container

=head1 ATTRIBUTES

=over 4

=item * NAME - the name of a parameter that points to an array of hashes.

=back

=head1 CHILDREN

None

=head1 AFFECTS

Nothing

=head1 DEPENDENCIES

FOOTER - indicates where to pagebreak

=head1 USAGE

  <loop name="LOOPY">
    ... Children here ...
  </loop>

The children tags will have access to the values specified in LOOPY, as well as
the parameters specifed outside.

=head1 AUTHOR

Rob Kinyon (rkinyon@columbus.rr.com)

=head1 SEE ALSO

HTML::Template, FOOTER

=cut

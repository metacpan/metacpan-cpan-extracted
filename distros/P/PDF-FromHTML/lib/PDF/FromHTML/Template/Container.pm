package PDF::FromHTML::Template::Container;

use strict;

BEGIN {
    use vars qw(@ISA);
    @ISA = qw(PDF::FromHTML::Template::Base);

    use PDF::FromHTML::Template::Base;
}

# Containers are objects that can contain arbitrary elements, such as
# PageDefs or Loops.

sub new
{
    my $class = shift;
    my $self = $class->SUPER::new(@_);

    $self->{ELEMENTS} = [] unless UNIVERSAL::isa($self->{ELEMENTS}, 'ARRAY');

    return $self;
}

sub _do_page
{
    my $self = shift;
    my ($context, $method) = @_;

    for my $e (@{$self->{ELEMENTS}})
    {
        $e->enter_scope($context);
        $e->$method($context);
        $e->exit_scope($context, 1);
    }

    return 1;
}

sub begin_page { _do_page @_, 'begin_page' }
#{
#    my $self = shift;
#    my ($context) = @_;
#
#    for my $e (@{$self->{ELEMENTS}})
#    {
#        $e->enter_scope($context);
#        $e->begin_page($context);
#        $e->exit_scope($context, 1);
#    }
#
#    return 1;
#}

sub end_page { _do_page @_, 'end_page' }
#{
#    my $self = shift;
#    my ($context) = @_;
#
#    for my $e (@{$self->{ELEMENTS}})
#    {
#        $e->enter_scope($context);
#        $e->end_page($context);
#        $e->exit_scope($context, 1);
#    }
#
#    return 1;
#}

sub reset
{
    my $self = shift;

    $self->SUPER::reset;
    $_->reset for @{$self->{ELEMENTS}};
}

sub iterate_over_children
{
    my $self = shift;
    my ($context) = @_;

    my $continue = 1;

    for my $e (grep !$_->has_rendered, @{$self->{ELEMENTS}})
    {
        $e->enter_scope($context);

        my $rc;
        if ($rc = $e->render($context))
        {
            $e->mark_as_rendered;
        }
        $continue = $rc if $continue;

        $e->exit_scope($context);
    }

    return $continue;
}

sub render
{
    my $self = shift;
    my ($context) = @_;

    return 0 unless $self->should_render($context);

    return $self->iterate_over_children($context);
}

sub max_of
{
    my $self = shift;
    my ($context, $attr) = @_;

    my $max = $context->get($self, $attr);

    ELEMENT:
    foreach my $e (@{$self->{ELEMENTS}})
    {
        $e->enter_scope($context);

        my $v = $e->isa('CONTAINER')
            ? $e->max_of($context, $attr)
            : $e->calculate($context, $attr);

        $max = $v if $max < $v;

        $e->exit_scope($context, 1);
    }

    return $max;
}

sub total_of
{
    my $self = shift;
    my ($context, $attr) = @_;

    my $total = 0;

    ELEMENT:
    foreach my $e (@{$self->{ELEMENTS}})
    {
        $e->enter_scope($context);

        $total += $e->isa('CONTAINER')
            ? $e->total_of($context, $attr)
            : $e->calculate($context, $attr);

        $e->exit_scope($context, 1);
    }

    return $total;
}

1;
__END__

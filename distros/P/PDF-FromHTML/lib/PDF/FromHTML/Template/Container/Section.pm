package PDF::FromHTML::Template::Container::Section;

use strict;

BEGIN {
    use vars qw(@ISA);
    @ISA = qw(PDF::FromHTML::Template::Container);

    use PDF::FromHTML::Template::Container;
}

# Sections are used to keep text together and not allow page-breaking
# within this branch of the tree, if possible.

sub new
{
    my $class = shift;
    my $self = $class->SUPER::new(@_);

    $self->{__CHECK_FOR_SPACE__} = 1;

    return $self;
}

sub reset
{
    my $self = shift;

    $self->{__CHECK_FOR_SPACE__} = 1;

    return $self->SUPER::reset;
}

sub render
{
    my $self = shift;
    my ($context) = @_;

    return 0 unless $self->should_render($context);

    my $child_success = $self->iterate_over_children($context);

    $self->{__CHECK_FOR_SPACE__} = $child_success;

    return $child_success;
}

sub should_render
{
    my $self = shift;
    my ($context) = @_;

    return 0 if $context->pagebreak_tripped;

    unless ($self->{__CHECK_FOR_SPACE__})
    {
        $self->{__CHECK_FOR_SPACE__} = 1;
        return 1;
    }

    my $y_shift = $self->total_of($context, 'H');
    my $end_y = $context->get($self, 'END_Y');

    if ($context->{Y} - $y_shift < $end_y)
    {
        my $start_y = $context->get($self, 'START_Y');

        $self->{__CHECK_FOR_SPACE__} = 0 if $y_shift > ($start_y - $end_y);

        return 1 if $context->{Y} == $start_y;

        $context->trip_pagebreak;
        return 0;
    }

    return 1;
}

1;
__END__

=head1 NAME

PDF::FromHTML::Template::Container::Section

=head1 PURPOSE

To provide a keep-together for children. If a pagebreak would occur within the
section tag, then the entire branch is rendered on the next page. If the branch
would take more than a page anyways, the section tag is ignored.

=head1 NODE NAME

SECTION

=head1 INHERITANCE

PDF::FromHTML::Template::Container

=head1 ATTRIBUTES

None

=head1 CHILDREN

None

=head1 AFFECTS

Nothing

=head1 DEPENDENCIES

None

=head1 USAGE

  <section>
    .. Children here ...
  </section>

The children will be rendered on the same page, if at all possible.

=head1 AUTHOR

Rob Kinyon (rkinyon@columbus.rr.com)

=head1 SEE ALSO

=cut

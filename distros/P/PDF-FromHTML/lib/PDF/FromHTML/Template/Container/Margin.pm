package PDF::FromHTML::Template::Container::Margin;

use strict;

BEGIN {
    use vars qw(@ISA);
    @ISA = qw(PDF::FromHTML::Template::Container::Always);

    use PDF::FromHTML::Template::Container::Always;
}

# This is the common parent for <header> and <footer>. It exists so that
# common code can be factored out. The code here is used for redefining
# Context::should_render(). Normally, it restricts display only to
# between the top and bottom margins. However, footers and headers are
# supposed to write in those margins, so the children of this type of
# node need to be allowed anywhere on the page.

sub enter_scope
{
    my $self = shift;
    my ($context) = @_;

    $self->SUPER::enter_scope($context);

    {
        no strict 'refs';

        my $class = ref $context;
        $self->{OLD_CHECK_EOP} = \&{"${class}::check_end_of_page"};
        *{"${class}::check_end_of_page"} = sub { return 1 };
    }

    return 1;
}

sub exit_scope
{
    my $self = shift;
    my ($context) = @_;

    {
        no strict 'refs';

        my $class = ref $context;
        *{"${class}::check_end_of_page"} = delete $self->{OLD_CHECK_EOP};
    }

    @{$context}{qw/X Y/} = @{$self}{qw/OLD_X OLD_Y/};

    return $self->SUPER::exit_scope($context);
}

1;
__END__

=head1 NAME

PDF::FromHTML::Template::Container::Margin

=head1 PURPOSE

A base class for HEADER and FOOTER

=head1 NODE NAME

None (This is not a rendering class)

=head1 INHERITANCE

PDF::FromHTML::Template::Container::Always

=head1 ATTRIBUTES

None

=head1 CHILDREN

PDF::FromHTML::Template::Container::Footer
PDF::FromHTML::Template::Container::Header

=head1 AFFECTS

Nothing

=head1 DEPENDENCIES

None

=head1 USAGE

None

=head1 AUTHOR

Rob Kinyon (rkinyon@columbus.rr.com)

=head1 SEE ALSO

ALWAYS, HEADER, FOOTER

=cut

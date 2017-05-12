package Moonshine::Bootstrap::Component::LinkedLiSpan;

use Moonshine::Magic;

extends 'Moonshine::Bootstrap::Component';

has(
    linked_li_span_spec => sub {
        {
            tag  => { default  => 'li' },
            link => { default  => HASHREF },
            span => { default  => HASHREF, build => 1 },
            data => { optional => 1, build => 1 },
        };
    }
);

sub linked_li_span {
    my ($self) = shift;

    my ( $base_args, $build_args ) = $self->validate_build(
        {
            params => $_[0] // {},
            spec => $self->linked_li_span_spec,
        }
    );

    my $base_element = Moonshine::Element->new($base_args);

    my $a = $base_element->add_child(
        {
            tag => 'a',
            ( %{ $build_args->{link} } ),
        }
    );

    $a->add_child(
        {
            tag => 'span',
            ( %{ $build_args->{span} } ),
        }
    );

    return $base_element;
}

1;

__END__

=head1 NAME

Moonshine::Bootstrap::Component::LinkedLiSpan

=head1 SYNOPSIS

    $self->linked_li_span({ link => { href => 'http://some.url' }, span => { data => 'Action'} )

=head3 Options

=over

=item Disabled

    $self->linked_li( disabled => 1, ... )
    <li class="disabled"><a href="#"><span aria-hidden="true">Disabled link</span></a></li>

=item link

    $self->linked_li({ link => { href => "#" , ... } })
    <a href="#">

=item span

    $self->linked_li({ span => { data => [1, 2, 3] }, ... })
    123

=back

=head3 Sample Output

    <li><a href="http://some.url"><span aria-hidden="true">Action</span></a></li>


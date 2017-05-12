package Moonshine::Bootstrap::Component::Pagination;

use Moonshine::Magic;
use Params::Validate qw/ARRAYREF HASHREF/;

lazy_components qw/li/;

extends(
    'Moonshine::Bootstrap::Component',
    'Moonshine::Bootstrap::Component::LinkedLi',
    'Moonshine::Bootstrap::Component::LinkedLiSpan',
);

has(
    pagination_spec => sub {
        {
            tag         => { default => 'ul' },
            class_base  => { default => 'pagination' },
            items       => { type    => ARRAYREF, optional => 1 },
            sizing_base => { default => 'pagination-' },
            count    => 0,
            previous => {
                default => {
                    span => { data => '&laquo;', aria_hidden => 'true' },
                    link => { href => "#",       aria_label  => 'Previous' },
                },
                type => HASHREF
            },
            next => {
                default => {
                    span => { data => '&raquo;', aria_hidden => 'true' },
                    link => { href => "#",       aria_label  => "Next" }
                },
                type  => HASHREF,
                build => 1,
            },
            nav      => 0,
            nav_args => { default => { tag => 'nav' } },
        };
    }
);

sub pagination {
    my ($self) = shift;

    my ( $base_args, $build_args ) = $self->validate_build(
        {
            params => $_[0] // {},
            spec => $self->pagination_spec,
        }
    );

    my $base_element = Moonshine::Element->new($base_args);

    $base_element->add_child(
        $self->linked_li_span( $build_args->{previous} ) );

    if ( defined $build_args->{items} ) {
        for ( @{ $build_args->{items} } ) {
            if ( $_->{active} ) {
                $base_element->add_child( $self->li($_) );
            }
            else {
                $base_element->add_child( $self->linked_li($_) );
            }
        }
    }
    elsif ( defined $build_args->{count} ) {
        for ( 1 .. $build_args->{count} ) {
            $base_element->add_child(
                $self->linked_li( { data => $_, link => '#' } ) );
        }
    }

    $base_element->add_child( $self->linked_li_span( $build_args->{next} ) );

    if ( defined $build_args->{nav} ) {
        my $nav = Moonshine::Element->new( $build_args->{nav_args} );
        $nav->add_child($base_element);
        return $nav;
    }

    return $base_element;
}

1;

__END__

=head1 NAME

Moonshine::Bootstrap::Component::Pagination

=head1 SYNOPSIS

    $self->pagination({ class => 'search' });

returns a Moonshine::Element that renders too..


	<ul class="pagination">
        <li>
            <a href="#" arilabel="Previous">
                <span aria-hidden="true">&laquo;</span>
            </a>
        </li>
        <li><a href="#">1</a></li>
        <li><a href="#">2</a></li>
        <li><a href="#">3</a></li>
        <li>
            <a href="#" aria-label="Next">
                <span aria-hidden="true">&raquo;</span>
            </a>
        </li>
    </ul>

=cut


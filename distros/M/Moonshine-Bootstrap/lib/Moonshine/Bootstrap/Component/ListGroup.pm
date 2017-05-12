package Moonshine::Bootstrap::Component::ListGroup;

use Moonshine::Magic;
use Params::Validate qw/ARRAYREF/;

extends (
    'Moonshine::Bootstrap::Component',
    'Moonshine::Bootstrap::Component::ListGroupItem',
);

has(
    list_group_spec => sub {
        {
            tag        => { default => 'ul' },
            class_base => { default => 'list-group' },
            list_items => { type => ARRAYREF, default => [ ] },
        };
    }
);

sub list_group {
    my ($self) = shift;

    my ( $base_args, $build_args ) = $self->validate_build(
        {
            params => $_[0] // {},
            spec => $self->list_group_spec,
        }
    );

    my $base_element = Moonshine::Element->new($base_args);

    for ( @{ $build_args->{list_items} } ) {
        $base_element->add_child($self->list_group_item($_));
    }

    return $base_element;
}

1;

__END__

=head1 NAME

Moonshine::Bootstrap::Component::ListGroup

=head1 SYNOPSIS

    $self->list_group({  });

returns a Moonshine::Element that renders too..

    <ul class="list-group">
        <li class="list-group-item">Some text</li>
        ....
    </ul>

=cut


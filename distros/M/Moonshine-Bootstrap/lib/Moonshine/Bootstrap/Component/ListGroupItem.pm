package Moonshine::Bootstrap::Component::ListGroupItem;

use Moonshine::Magic;
use Params::Validate qw/HASHREF/;

extends (
    'Moonshine::Bootstrap::Component',
    'Moonshine::Bootstrap::Component::Badge',
);

has(
    list_group_item_spec => sub {
        {
            tag         => { default => 'li' },
            class_base  => { default => 'list-group-item' },
            switch_base => { default => 'list-group-item-' },
            badge       => { type => HASHREF, optional => 1 },
        };
    }
);

sub list_group_item {
    my ($self) = shift;

    my ( $base_args, $build_args ) = $self->validate_build(
        {
            params => $_[0] // {},
            spec => $self->list_group_item_spec,
        }
    );

    my $base_element = Moonshine::Element->new($base_args);

    if ( my $badge = $build_args->{badge} ) {
        $base_element->add_child( $self->badge($badge) );
    }

    return $base_element;
}

1;

__END__

=head1 NAME

Moonshine::Bootstrap::Component::ListGroupItem

=head1 SYNOPSIS

    $self->list_group_item({ class => 'search' });

returns a Moonshine::Element that renders too..

    <li class="list-group-item">Some text</li>

=cut


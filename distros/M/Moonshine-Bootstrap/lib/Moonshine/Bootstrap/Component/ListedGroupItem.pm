package Moonshine::Bootstrap::Component::ListedGroupItem;

use Moonshine::Magic;
use Params::Validate qw/HASHREF/;

extends (
    'Moonshine::Bootstrap::Component',
    'Moonshine::Bootstrap::Component::Badge',
    'Moonshine::Bootstrap::Component::ListedGroupItemText',
    'Moonshine::Bootstrap::Component::ListedGroupItemHeading',
);

has(
    listed_group_item_spec => sub {
        {
            tag         => { default => 'a' },
            class_base  => { default => 'list-group-item' },
            switch_base => { default => 'list-group-item-' },
            button      => 0,
            badge       => { type => HASHREF, optional => 1 },
        };
    }
);

sub listed_group_item {
    my ($self) = shift;

    my ( $base_args, $build_args ) = $self->validate_build(
        {
            params => $_[0] // {},
            spec => $self->listed_group_item_spec,
        }
    );

    if ( $build_args->{button} ) {
        $base_args->{tag}   = 'button';
        $base_args->{type}  = 'button';
    }

    my $base_element = Moonshine::Element->new($base_args);

    if ( my $badge = $build_args->{badge} ) {
        $base_element->add_child( $self->badge($badge) );
    }

    return $base_element;
}

1;

__END__

=head1 NAME

Moonshine::Bootstrap::Component::ListedGroupItem

=head1 SYNOPSIS

    $self->listed_group_item({ class => 'search' });

returns a Moonshine::Element that renders too..

    <li class="list-group-item">Some text</li>

=cut


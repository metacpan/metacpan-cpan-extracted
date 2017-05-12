package Moonshine::Bootstrap::Component::ListedGroupItemHeading;

use Moonshine::Magic;

extends 'Moonshine::Bootstrap::Component';

has(
    listed_group_item_heading_spec => sub {
        {
            tag        => { default => 'h4' },
            class_base => { default => 'list-group-item-heading' },
        };
    }
);

sub listed_group_item_heading {
    my ($self) = shift;

    my ( $base_args, $build_args ) = $self->validate_build(
        {
            params => $_[0] // {},
            spec => $self->listed_group_item_heading_spec,
        }
    );

    return Moonshine::Element->new($base_args);
}

1;

__END__

=head1 NAME

Moonshine::Bootstrap::Component::ListedGroupItemHeading

=head1 SYNOPSIS

    $self->listed_group_item_heading({ ... });

returns a Moonshine::Element that renders too..

    <h4 class="listed-group-item-heading"></h4>

=cut


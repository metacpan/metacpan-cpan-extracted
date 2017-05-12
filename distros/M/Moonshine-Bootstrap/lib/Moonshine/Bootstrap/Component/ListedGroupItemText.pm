package Moonshine::Bootstrap::Component::ListedGroupItemText;

use Moonshine::Magic;

extends 'Moonshine::Bootstrap::Component';

has(
    listed_group_item_text_spec => sub {
        {
            tag        => { default => 'p' },
            class_base => { default => 'list-group-item-text' },
        };
    }
);

sub listed_group_item_text {
    my ($self) = shift;

    my ( $base_args, $build_args ) = $self->validate_build(
        {
            params => $_[0] // {},
            spec => $self->listed_group_item_text_spec,
        }
    );

    return Moonshine::Element->new($base_args);
}

1;

__END__

=head1 NAME

Moonshine::Bootstrap::Component::ListedGroupItemText

=head1 SYNOPSIS

    $self->listed_group_item_text({ ... });

returns a Moonshine::Element that renders too..

    <p class="listed-group-item-text"></p>

=cut


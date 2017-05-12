package Moonshine::Bootstrap::Component::ListedGroup;

use Moonshine::Magic;
use Params::Validate qw/ARRAYREF/;

extends (
    'Moonshine::Bootstrap::Component',
    'Moonshine::Bootstrap::Component::ListedGroupItem',
);

has(
    listed_group_spec => sub {
        {
            tag        => { default => 'div' },
            class_base => { default => 'list-group' },
            list_items => { type => ARRAYREF, default => [ ] },
        };
    }
);

sub listed_group {
    my ($self) = shift;

    my ( $base_args, $build_args ) = $self->validate_build(
        {
            params => $_[0] // {},
            spec => $self->listed_group_spec,
        }
    );

    my $base_element = Moonshine::Element->new($base_args);

    for ( @{ $build_args->{list_items} } ) {
        $base_element->add_child($self->listed_group_item($_));
    }

    return $base_element;
}

1;

__END__

=head1 NAME

Moonshine::Bootstrap::Component::ListedGroup

=head1 SYNOPSIS

    $self->listed_group({  });

returns a Moonshine::Element that renders too..

    <div class="list-group">
        <a class="list-group-item">Some text</a>
        ....
    </ul>

=cut


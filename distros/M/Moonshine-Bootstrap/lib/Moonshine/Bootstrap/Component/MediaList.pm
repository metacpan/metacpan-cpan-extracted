package Moonshine::Bootstrap::Component::MediaList;

use Moonshine::Magic;

use Params::Validate qw/ARRAYREF/;

extends (
    'Moonshine::Bootstrap::Component',
    'Moonshine::Bootstrap::Component::Media',
);

has(
    media_list_spec => sub {
        {
            tag         => { default => 'ul' },
            class_base  => { default => 'media-list' },
            media_items => { type => ARRAYREF, optional => 1 }, 
        };
    }
);

sub media_list {
    my ($self) = shift;

    my ( $base_args, $build_args ) = $self->validate_build(
        {
            params => $_[0] // {},
            spec => $self->media_list_spec,
        }
    );

    my $base_element = Moonshine::Element->new($base_args);

    for ( @{ $build_args->{media_items} } ) {
        $base_element->add_child( 
            $self->media( { tag => 'li', %{$_} } )
        );
    }

    return $base_element;
}

1;

__END__

=head1 NAME

Moonshine::Bootstrap::Component::MediaList

=head1 SYNOPSIS

    $self->media_list({ class => 'search' });

returns a Moonshine::Element that renders too..

    <ul class="media-list">
        <li class="media">
            ...
        </li>
    </ul>

=cut


package Moonshine::Bootstrap::Component::Thumbnail;

use Moonshine::Magic;

extends 'Moonshine::Bootstrap::Component';

has(
    thumbnail_spec => sub {
        {
            tag        => { default => 'div' },
            class_base => { default => 'thumbnail' },
        };
    }
);

sub thumbnail {
    my ($self) = shift;

    my ( $base_args, $build_args ) = $self->validate_build(
        {
            params => $_[0] // {},
            spec => $self->thumbnail_spec,
        }
    );

    return Moonshine::Element->new($base_args);
}

1;

__END__

=head1 NAME

Moonshine::Bootstrap::Component::Thumbnail

=head1 SYNOPSIS

    $self->thumbnail({ class => 'search' });

returns a Moonshine::Element that renders too..

    <span class="thumbnail"></span>

=cut


package Moonshine::Bootstrap::Component::Media;

use Moonshine::Magic;

extends (
    'Moonshine::Bootstrap::Component',
    'Moonshine::Bootstrap::Component::MediaObject',   
);

has(
    media_spec => sub {
        {
            tag        => { default => 'div' },
            class_base => { default => 'media' },
        };
    }
);

sub media {
    my ($self) = shift;

    my ( $base_args, $build_args ) = $self->validate_build(
        {
            params => $_[0] // {},
            spec => $self->media_spec,
        }
    );

    return Moonshine::Element->new($base_args);
}

1;

__END__

=head1 NAME

Moonshine::Bootstrap::Component::Media

=head1 SYNOPSIS

    $self->media({ class => 'search' });

returns a Moonshine::Element that renders too..

    <div class="media">....</div>

=cut


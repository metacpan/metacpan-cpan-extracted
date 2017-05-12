package Moonshine::Bootstrap::Component::Caption;

use Moonshine::Magic;

extends 'Moonshine::Bootstrap::Component';

has(
    caption_spec => sub {
        {
            tag        => { default => 'div' },
            class_base => { default => 'caption' },
        };
    }
);

sub caption {
    my ($self) = shift;

    my ( $base_args, $build_args ) = $self->validate_build(
        {
            params => $_[0] // {},
            spec => $self->caption_spec,
        }
    );

    return Moonshine::Element->new($base_args);
}

1;

__END__

=head1 NAME

Moonshine::Bootstrap::Component::Caption

=head1 SYNOPSIS

    $self->caption({ class => 'search' });

returns a Moonshine::Element that renders too..

    <div class="caption"></div>

=cut


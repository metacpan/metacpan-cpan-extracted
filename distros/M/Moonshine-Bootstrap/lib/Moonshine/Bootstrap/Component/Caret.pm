package Moonshine::Bootstrap::Component::Caret;

use Moonshine::Magic;

extends 'Moonshine::Bootstrap::Component';

has(
    caret_spec => sub {
        {
            tag        => { default => 'span' },
            class_base => { default => 'caret' },
        };
    }
);

sub caret {
    my ($self) = shift;

    my ( $base_args, $build_args ) = $self->validate_build(
        {
            params => $_[0] // {},
            spec => $self->caret_spec,
        }
    );

    return Moonshine::Element->new($base_args);
}

1;

__END__

=head1 NAME

Moonshine::Bootstrap::Component::Caret

=head1 SYNOPSIS

    $self->caret({ class => 'search' });

returns a Moonshine::Element that renders too..

    <span class="caret"></span>

=cut


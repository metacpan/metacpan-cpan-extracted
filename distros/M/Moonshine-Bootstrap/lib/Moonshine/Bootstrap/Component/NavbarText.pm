package Moonshine::Bootstrap::Component::NavbarText;

use Moonshine::Magic;

extends 'Moonshine::Bootstrap::Component';

has(
    navbar_text_spec => sub {
        {
            tag            => { default => 'p' },
            data           => 1,
            alignment_base => { default => 'navbar-' },
            class_base     => { default => 'navbar-text' },
        };
    }
);

sub navbar_text {
    my ($self) = shift;

    my ( $base_args, $build_args ) = $self->validate_build(
        {
            params => $_[0] // {},
            spec => $self->navbar_text_spec,
        }
    );

    return Moonshine::Element->new($base_args);
}

1;

__END__

=head1 NAME

Moonshine::Bootstrap::Component::NavbarText

=head1 SYNOPSIS

    $self->navbar_text({ data => 'Hey' });

returns a Moonshine::Element that renders too..

    <p class="navbar-text">Hey</p>

=cut


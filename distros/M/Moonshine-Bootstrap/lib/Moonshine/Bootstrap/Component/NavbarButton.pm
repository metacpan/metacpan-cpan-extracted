package Moonshine::Bootstrap::Component::NavbarButton;

use Moonshine::Magic;

extends(
    'Moonshine::Bootstrap::Component',
    'Moonshine::Bootstrap::Component::Button',
);

has(
    navbar_button_spec => sub {
        {
            type           => { default  => 'button' },
            switch         => { default  => 'default', base => 1 },
            class_base     => { default  => 'navbar-btn' },
            data           => { default  => 'Submit' },
            alignment      => { optional => 1, base => 1 },
            alignment_base => { default  => 'navbar-', base => 1, },
        };
    }
);

sub navbar_button {
    my ($self) = shift;

    my ( $base_args, $build_args ) = $self->validate_build(
        {
            params => $_[0] // {},
            spec => $self->navbar_button_spec,
        }
    );

    return $self->button($base_args);
}

1;

__END__

=head1 NAME

Moonshine::Bootstrap::Component::NavbarText

=head1 SYNOPSIS

    $self->navbar_button({ data => 'Hey' });

returns a Moonshine::Element that renders too..

    <button type="button" class="btn btn-default">Submit</button>

=cut


package Moonshine::Bootstrap::Component::NavbarNav;

use Moonshine::Magic;
use Params::Validate qw/SCALAR ARRAYREF/;

extends(
    'Moonshine::Bootstrap::Component',
    'Moonshine::Bootstrap::Component::Nav',
);

has(
    navbar_nav_spec => sub {
        {

            class_base     => { default => 'navbar-nav' },
            alignment_base => { default => 'navbar-' },
            switch         => {
                base     => 1,
                type     => SCALAR,
                optional => 1,
            },
            nav_items => {
                type => ARRAYREF,
                base => 1,
            },
            stacked   => { base => 1, optional => 1 },
            justified => { base => 1, optional => 1 },
        };
    },
);

sub navbar_nav {
    my ($self) = shift;

    my ( $base_args, $build_args ) = $self->validate_build(
        {
            params => $_[0] // {},
            spec => $self->navbar_nav_spec,
        }
    );

    return $self->nav($base_args);
}

1;

__END__

=head1 NAME

Moonshine::Bootstrap::Component::NavbarNav

=head1 SYNOPSIS

    $self->navbar_nav({ data => 'Hey' });

returns a Moonshine::Element that renders too..

    <p class="navbar-text">Hey</p>

=cut


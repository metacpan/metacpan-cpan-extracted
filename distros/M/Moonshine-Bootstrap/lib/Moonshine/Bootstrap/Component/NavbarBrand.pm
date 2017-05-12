package Moonshine::Bootstrap::Component::NavbarBrand;

use Moonshine::Magic;

extends 'Moonshine::Bootstrap::Component';

has(
    navbar_brand_spec => sub {
        {
            tag        => { default => 'a' },
            href       => { default => '#' },
            class_base => { default => 'navbar-brand' },
        };
    }
);

sub navbar_brand {
    my ($self) = shift;

    my ( $base_args, $build_args ) = $self->validate_build(
        {
            params => $_[0] // {},
            spec => $self->navbar_brand_spec,
        }
    );

    return Moonshine::Element->new($base_args);
}

1;

__END__

=head1 NAME

Moonshine::Bootstrap::Component::NavbarBrand

=head1 SYNOPSIS

    $self->navbar_brand({ data => 'Hey' });

returns a Moonshine::Element that renders too..

    <a class="navbar-brand" href="#">Hey</a>

=cut


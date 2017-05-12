package Moonshine::Bootstrap::Component::NavbarTextLink;

use Moonshine::Magic;
use Params::Validate qw/HASHREF/;
lazy_components('a');

extends (
    'Moonshine::Bootstrap::Component',
    'Moonshine::Bootstrap::Component::NavbarText',
);

has(
    navbar_text_link_spec => sub {
        {
            tag            => { default => 'p' },
            link           => { type => HASHREF },
            alignment      => { base => 1, optional => 1 },
            data           => 1,
        };
    }
);

sub navbar_text_link {
    my ($self) = shift;

    my ( $base_args, $build_args ) = $self->validate_build(
        {
            params => $_[0] // {},
            spec => $self->navbar_text_link_spec,
        }
    );

    my $base_element = $self->navbar_text($base_args);

    $base_element->add_child(
        $self->a( { %{ $build_args->{link} }, class => 'navbar-link' } )
    );

    return $base_element;
}

1;

__END__

=head1 NAME

Moonshine::Bootstrap::Component::NavbarTextLink

=head1 SYNOPSIS

    $self->navbar_text_link({ data => 'Hey' });

returns a Moonshine::Element that renders too..

    <p class="navbar-text">Hey</p>

=cut


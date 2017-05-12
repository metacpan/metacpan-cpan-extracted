package Moonshine::Bootstrap::Component::Container;

use strict;
use warnings;

use Moonshine::Magic;
use Moonshine::Bootstrap::Component;

extends 'Moonshine::Bootstrap::Component';

has(
    container_spec => sub {
        {
            tag       => { default => 'div' },
            container => { default => 1 },
        };
    }
);

sub container {
    my ($self) = shift;

    my ( $base_args, $build_args ) = $self->validate_build(
        {
            params => $_[0] // {},
            spec => $self->container_spec,
        }
    );
    return Moonshine::Element->new($base_args);
}

1;

__END__

=head1 NAME

Moonshine::Bootstrap::Component::Container

=head1 SYNOPSIS

    container();

returns a Moonshine::Element that renders too..

    <div class="container"></div>

=cut



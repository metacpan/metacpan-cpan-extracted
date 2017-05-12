package Moonshine::Bootstrap::Component::Well;

use strict;
use warnings;

use Moonshine::Magic;
use Moonshine::Bootstrap::Component;

extends 'Moonshine::Bootstrap::Component';

has(
    well_spec => sub {
        {
            tag         => { default => 'div' },
            class_base  => { default => 'well' },
            switch_base => { default => 'well-' },
        };
    }
);

sub well {
    my ($self) = shift;

    my ( $base_args, $build_args ) = $self->validate_build(
        {
            params => $_[0] // {},
            spec => $self->well_spec,
        }
    );
    return Moonshine::Element->new($base_args);
}

1;

__END__

=head1 NAME

Moonshine::Bootstrap::Component::Well

=head1 SYNOPSIS

    well({ ... });

returns a Moonshine::Element that renders too..

    <div class="well"></div>

=cut



package Moonshine::Bootstrap::Component::Row;

use strict;
use warnings;

use Moonshine::Magic;
use Moonshine::Bootstrap::Component;

extends 'Moonshine::Bootstrap::Component';

has(
    row_spec => sub {
        {
            tag => { default => 'div' },
            row => { default => 1 },
        };
    }
);

sub row {
    my ($self) = shift;

    my ( $base_args, $build_args ) = $self->validate_build(
        {
            params => $_[0] // {},
            spec => $self->row_spec,
        }
    );
    return Moonshine::Element->new($base_args);
}

1;

__END__

=head1 NAME

Moonshine::Bootstrap::Component::Row

=head1 SYNOPSIS

    row({ ... });

returns a Moonshine::Element that renders too..

    <div class="row"></div>

=cut



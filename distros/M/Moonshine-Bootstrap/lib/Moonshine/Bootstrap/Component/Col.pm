package Moonshine::Bootstrap::Component::Col;

use strict;
use warnings;

use Moonshine::Magic;
use Moonshine::Bootstrap::Component;

extends 'Moonshine::Bootstrap::Component';

has(
    col_spec => sub {
        { tag => { default => 'div' }, };
    }
);

sub col {
    my ($self) = shift;

    my ( $base_args, $build_args ) = $self->validate_build(
        {
            params => $_[0] // {},
            spec => $self->col_spec,
        }
    );
    return Moonshine::Element->new($base_args);
}

1;

__END__

=head1 NAME

Moonshine::Bootstrap::Component::Col

=head1 SYNOPSIS

    col({ ... });

returns a Moonshine::Element that renders too..

    <div class="col-md-1"></div>

=cut



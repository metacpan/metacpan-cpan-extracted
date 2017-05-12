package Moonshine::Bootstrap::Component::Button;

use strict;
use warnings;

use Moonshine::Magic;
use Moonshine::Bootstrap::Component;

extends 'Moonshine::Bootstrap::Component';

has(
    button_spec => sub {
        {
            tag         => { default => 'button' },
            switch      => { default => 'default' },
            switch_base => { default => 'btn btn-' },
            type        => { default => 'button' },
            sizing_base => { default => 'btn-' },
        };
    }
);

sub button {
    my ($self) = shift;

    my ( $base_args, $build_args ) = $self->validate_build(
        {
            params => $_[0] // {},
            spec => $self->button_spec,
        }
    );
    return Moonshine::Element->new($base_args);
}

1;

__END__

=head1 NAME

Moonshine::Bootstrap::Component::Button

=head1 SYNOPSIS

    button({ switch => 'success', data => 'Left' });

returns a Moonshine::Element that renders too..

	<button type="button" class="btn btn-success">Left</button>

=cut



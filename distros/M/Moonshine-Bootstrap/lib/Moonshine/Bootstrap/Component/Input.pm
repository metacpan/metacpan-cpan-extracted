package Moonshine::Bootstrap::Component::Input;

use strict;
use warnings;

use Moonshine::Magic;
use Moonshine::Bootstrap::Component;

extends 'Moonshine::Bootstrap::Component';

has(
    input_spec => sub {
        {
            tag        => { default => 'input' },
            class_base => { default => 'form-control' },
            type       => { default => 'text' },
        };
    }
);

sub input {
    my ($self) = shift;

    my ( $base_args, $build_args ) = $self->validate_build(
        {
            params => $_[0] // {},
            spec => $self->input_spec,
        }
    );
    return Moonshine::Element->new($base_args);
}

1;

__END__

=head1 NAME

Moonshine::Bootstrap::Component::Input

=head1 SYNOPSIS

  $self->input();

=head3

=over

=item class

default form-control

=item type

default text

=back

=head3 Renders

    <input type="text" class="form-control">

=cut



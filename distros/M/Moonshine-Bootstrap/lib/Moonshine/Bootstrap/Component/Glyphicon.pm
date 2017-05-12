package Moonshine::Bootstrap::Component::Glyphicon;

use strict;
use warnings;

use Moonshine::Magic;
use Moonshine::Bootstrap::Component;

extends 'Moonshine::Bootstrap::Component';

lazy_components(qw/span/);

has(
    glyphicon_spec => sub {
        {
            switch      => 1,
            switch_base => { default => 'glyphicon glyphicon-' },
            aria_hidden => { default => 'true' },
        };
    }
);

sub glyphicon {
    my ($self) = shift;

    my ( $base_args, $build_args ) = $self->validate_build(
        {
            params => $_[0] // {},
            spec => $self->glyphicon_spec,
        }
    );
    return $self->span($base_args);
}

1;

__END__

=head1 NAME

Moonshine::Bootstrap::Component::Glyphicon

=head1 SYNOPSIS

    glyphicon({ class => 'search' });

returns a Moonshine::Element that renders too..

    <span class="glyphicon glyphicon-search" aria-hidden="true"></span>

=cut



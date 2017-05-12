package Moonshine::Bootstrap::Component::Clearfix;

use strict;
use warnings;

use Moonshine::Magic;
use Moonshine::Bootstrap::Component;

extends 'Moonshine::Bootstrap::Component';

has(
    clearfix_spec => sub {
        {
            tag        => { default => 'div' },
            class_base => { default => 'clearfix visible-xs-block' },
        };
    }
);

sub clearfix {
    my ($self) = shift;

    my ( $base_args, $build_args ) = $self->validate_build(
        {
            params => $_[0] // {},
            spec => $self->clearfix_spec,
        }
    );
    return Moonshine::Element->new($base_args);
}

1;

__END__

=head1 NAME

Moonshine::Bootstrap::Component::Clearfix

=head1 SYNOPSIS

    clearfix({ switch => 'success', data => 'Left' });

returns a Moonshine::Element that renders too..

    <div class="clearfix visible-xs-block"></div>

=cut



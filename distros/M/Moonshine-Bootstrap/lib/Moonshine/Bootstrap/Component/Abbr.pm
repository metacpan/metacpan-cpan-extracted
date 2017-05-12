package Moonshine::Bootstrap::Component::Abbr;

use strict;
use warnings;

use Moonshine::Magic;
use Moonshine::Util;

extends 'Moonshine::Bootstrap::Component';

has(
    abbr_spec => sub {
        {
            tag        => { default => 'abbr' },
            title      => 1,
            data       => 1,
            initialism => 0,
        };
    }
);

sub abbr {
    my ($self) = shift;

    my ( $base_args, $build_args ) = $self->validate_build(
        {
            params => $_[0] // {},
            spec => $self->abbr_spec,
        }
    );

    if ( defined $build_args->{initialism} ) {
        $base_args->{class} = append_str( 'initialism', $base_args->{class} );
    }

    return Moonshine::Element->new($base_args);
}

1;

__END__

=head1 NAME

Moonshine::Bootstrap::Component::Abbr

=head1 SYNOPSIS

    abbr({ title => 'Hello World', initialism => 1 });

returns a Moonshine::Element that renders too..

	<abbr type="abbr" class="btn btn-success">Left</abbr>

=cut



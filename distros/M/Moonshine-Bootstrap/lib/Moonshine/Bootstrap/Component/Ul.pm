package Moonshine::Bootstrap::Component::Ul;

use strict;
use warnings;

use Moonshine::Magic;
use Moonshine::Bootstrap::Component;
use Moonshine::Util;

extends 'Moonshine::Bootstrap::Component';

has(
    ul_spec => sub {
        {
            tag     => { default => 'ul' },
            inline  => 0,
            unstyle => 0,
        };
    }
);

sub ul {
    my $self = shift;
    my ( $base_args, $build_args ) = $self->validate_build(
        {
            params => $_[0] // {},
            spec => $self->ul_spec,
        }
    );

    if ( defined $build_args->{unstyle} ) {
        $base_args->{class} =
          append_str( 'list-unstyled', $base_args->{class} );
    }

    if ( defined $build_args->{inline} ) {
        $base_args->{class} = append_str( 'list-inline', $base_args->{class} );
    }

    return Moonshine::Element->new($base_args);
}

1;

__END__

=head1 NAME

Moonshine::Bootstrap::Component::Ul

=head1 SYNOPSIS

    ul({ inline => 1 });

returns a Moonshine::Element that renders too..

	<ul class="list-inline"></ul>

=cut



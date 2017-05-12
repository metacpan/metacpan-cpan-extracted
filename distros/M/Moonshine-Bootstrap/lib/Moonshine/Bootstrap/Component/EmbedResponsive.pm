package Moonshine::Bootstrap::Component::EmbedResponsive;

use strict;
use warnings;

use Moonshine::Magic;
use Moonshine::Bootstrap::Component;
use Moonshine::Util;

extends 'Moonshine::Bootstrap::Component';

has(
    embed_responsive_spec => sub {
        {
            tag        => { default  => 'div' },
            class_base => { default  => 'embed-responsive' },
            ratio      => { optional => 1 },
            ratio_base => { default  => 'embed-responsive-' },
        };
    }
);

sub embed_responsive {
    my ($self) = shift;

    my ( $base_args, $build_args ) = $self->validate_build(
        {
            params => $_[0] // {},
            spec => $self->embed_responsive_spec,
        }
    );

    if ( my $ratio =
        join_class( $build_args->{ratio_base}, $build_args->{ratio} ) )
    {
        $base_args->{class} = prepend_str( $ratio, $base_args->{class} );
    }

    return Moonshine::Element->new($base_args);
}

1;

__END__

=head1 NAME

Moonshine::Bootstrap::Component::EmbedResponsive

=head1 SYNOPSIS

    responsive_embed({  });

returns a Moonshine::Element that renders too..
    
    <div class="embed-responsive embed-responsive-16by9">
        ...
    </div>

=cut


package Moonshine::Bootstrap::Component::EmbedRes;

use strict;
use warnings;

use Moonshine::Magic;
use Moonshine::Util;
use Method::Traits qw[ Moonshine::Bootstrap::Trait::Export ];

extends(
    'Moonshine::Bootstrap::Component',
    'Moonshine::Bootstrap::Component::EmbedResponsive',
    'Moonshine::Bootstrap::Component::EmbedResponsiveIframe',
);

has(
    embed_res_spec => sub {
        return { iframe => 1, };
    }
);

sub embed_res : Export {
    my ($self) = shift;

    my ( $base_args, $build_args ) = $self->validate_build(
        {
            params => $_[0] // {},
            spec => $self->embed_res_spec,
        }
    );

    my $base = $self->embed_responsive($base_args);
    $base->add_child( $self->embed_responsive_iframe( $build_args->{iframe} ) );
    return $base;
}

1;

__END__

=head1 NAME

Moonshine::Bootstrap::Component::EmbedRes

=head1 SYNOPSIS

    embed_res({ iframe => { src => "..." } });

returns a Moonshine::Element that renders too..
    
    <div class="embed-responsive embed-responsive-16by9">
        <iframe class="embed-responsive-item" src="..."></iframe>
    </div>

=cut


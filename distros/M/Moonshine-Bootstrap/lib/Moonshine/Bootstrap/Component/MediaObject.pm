package Moonshine::Bootstrap::Component::MediaObject;

use Moonshine::Magic;
use Moonshine::Util;

lazy_components(qw/h4/);

extends (
    'Moonshine::Bootstrap::Component',
    'Moonshine::Bootstrap::Component::MediaLinkImage',
);

has(
    media_object_spec => sub {
        {
            tag        => { default => 'div' },
            x          => 0,
            y          => 0,
            base_class => { default => 'media-' },
            body       => 0,
        };
    }
);

sub media_object {
    my ($self) = shift;

    my ( $base_args, $build_args ) = $self->validate_build(
        {
            params => $_[0] // {},
            spec => $self->media_object_spec,
        }
    );

    my $base = $build_args->{base_class};
    if ( $build_args->{body} ) {
        $base_args->{class} = append_str(
            join_class( $base, 'body'), $base_args->{class}
        );
    }
    
    for (qw/y x/) {
        if ( my $class = join_class($base, $build_args->{$_}) ) {
            $base_args->{class} = append_str($class, $base_args->{class});
        }
    }

    return Moonshine::Element->new($base_args);
}

1;

__END__

=head1 NAME

Moonshine::Bootstrap::Component::MediaObject

=head1 SYNOPSIS

    $self->media_object({  });

returns a Moonshine::Element that renders too..

    <div class="media-left media-top"><a href="#"><img class="media-object" src="url" alt="alt text"></img></a></div>'

=cut


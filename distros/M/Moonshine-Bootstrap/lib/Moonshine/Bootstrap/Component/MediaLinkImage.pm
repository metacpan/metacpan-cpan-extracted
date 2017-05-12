package Moonshine::Bootstrap::Component::MediaLinkImage;

use Moonshine::Magic;
use Params::Validate qw/HASHREF/;
use Moonshine::Util;

extends (
    'Moonshine::Bootstrap::Component',
    'Moonshine::Bootstrap::Component::LinkImage',
);

has(
    media_link_image_spec => sub {
        {
            img         => { base => 1, type => HASHREF },
            href        => 1,
        };
    }
);

sub media_link_image {
    my ($self) = shift;

    my ( $base_args, $build_args ) = $self->validate_build(
        {
            params => $_[0] // {},
            spec => $self->media_link_image_spec,
        }
    );

    $base_args->{img}->{class} = append_str('media-object', $base_args->{img}->{class});    
    return $self->link_image($base_args);
}

1;

__END__

=head1 NAME

Moonshine::Bootstrap::Component::MediaLinkImage

=head1 SYNOPSIS

    $self->media_link_image({ class => 'search' });

returns a Moonshine::Element that renders too..

    <a href="#"><img class="media-object" src="url" alt="alt text"></img></a>

=cut


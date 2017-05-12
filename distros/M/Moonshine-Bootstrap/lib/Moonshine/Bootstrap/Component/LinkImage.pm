package Moonshine::Bootstrap::Component::LinkImage;

use Moonshine::Magic;
use Params::Validate qw/HASHREF/;

lazy_components qw/a img/;

extends 'Moonshine::Bootstrap::Component';

has(
    link_image_spec => sub {
        {
            img => { build => 1, type => HASHREF },
            href => 1,
        };
    }
);

sub link_image {
    my ($self) = shift;

    my ( $base_args, $build_args ) = $self->validate_build(
        {
            params => $_[0] // {},
            spec => $self->link_image_spec,
        }
    );

    my $a = $self->a($base_args);
    $a->add_child( $self->img( $build_args->{img} ) );
    return $a;
}

1;

__END__

=head1 NAME

Moonshine::Bootstrap::Component::LinkImage

=head1 SYNOPSIS

    $self->link_image({  });

returns a Moonshine::Element that renders too..

    <a class="navbar-brand" href="..."><img alt="some-text" src="..."></img></a>

=cut


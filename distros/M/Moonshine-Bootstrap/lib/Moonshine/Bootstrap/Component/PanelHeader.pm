package Moonshine::Bootstrap::Component::PanelHeader;

use Moonshine::Magic;
use Params::Validate qw/HASHREF/;

extends (
    'Moonshine::Bootstrap::Component',
    'Moonshine::Bootstrap::Component::PanelTitle',
);

has(
    panel_header_spec => sub {
        {
            tag        => { default => 'div' },
            class_base => { default => 'panel-heading' },
            title      => { build => 1, optional => 1, type => HASHREF },
        };
    }
);

sub panel_header {
    my ($self) = shift;

    my ( $base_args, $build_args ) = $self->validate_build(
        {
            params => $_[0] // {},
            spec => $self->panel_header_spec,
        }
    );

    my $base_element = Moonshine::Element->new($base_args);

    if ( $build_args->{title} ) {
        $base_element->add_child(
            $self->panel_title($build_args->{title})
        );
    }   

    return $base_element;
}

1;

__END__

=head1 NAME

Moonshine::Bootstrap::Component::PanelHeader

=head1 SYNOPSIS

    $self->panel_header({  });

returns a Moonshine::Element that renders too..

    <div class="panel-body"></div>

=cut


package Moonshine::Bootstrap::Component::PanelBody;

use Moonshine::Magic;

extends 'Moonshine::Bootstrap::Component';

has(
    panel_body_spec => sub {
        {
            tag        => { default => 'div' },
            class_base => { default => 'panel-body' },
        };
    }
);

sub panel_body {
    my ($self) = shift;

    my ( $base_args, $build_args ) = $self->validate_build(
        {
            params => $_[0] // {},
            spec => $self->panel_body_spec,
        }
    );

    return Moonshine::Element->new($base_args);
}

1;

__END__

=head1 NAME

Moonshine::Bootstrap::Component::PanelBody

=head1 SYNOPSIS

    $self->panel_body({  });

returns a Moonshine::Element that renders too..

    <div class="panel-body"></div>

=cut


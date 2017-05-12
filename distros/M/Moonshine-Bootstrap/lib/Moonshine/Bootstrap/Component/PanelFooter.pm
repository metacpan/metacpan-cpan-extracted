package Moonshine::Bootstrap::Component::PanelFooter;

use Moonshine::Magic;

extends 'Moonshine::Bootstrap::Component';

has(
    panel_footer_spec => sub {
        {
            tag        => { default => 'div' },
            class_base => { default => 'panel-footer' },
        };
    }
);

sub panel_footer {
    my ($self) = shift;

    my ( $base_args, $build_args ) = $self->validate_build(
        {
            params => $_[0] // {},
            spec => $self->panel_footer_spec,
        }
    );

    return Moonshine::Element->new($base_args);
}

1;

__END__

=head1 NAME

Moonshine::Bootstrap::Component::PanelFooter

=head1 SYNOPSIS

    $self->panel_footer({  });

returns a Moonshine::Element that renders too..

    <div class="panel-footer"></div>

=cut


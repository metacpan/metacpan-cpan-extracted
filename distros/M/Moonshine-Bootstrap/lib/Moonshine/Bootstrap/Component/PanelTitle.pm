package Moonshine::Bootstrap::Component::PanelTitle;

use Moonshine::Magic;

extends 'Moonshine::Bootstrap::Component';

has(
    panel_title_spec => sub {
        {
            tag        => { default => 'h3' },
            class_base => { default => 'panel-title' },
        };
    }
);

sub panel_title {
    my ($self) = shift;

    my ( $base_args, $build_args ) = $self->validate_build(
        {
            params => $_[0] // {},
            spec => $self->panel_title_spec,
        }
    );

    return Moonshine::Element->new($base_args);
}

1;

__END__

=head1 NAME

Moonshine::Bootstrap::Component::PanelTitle

=head1 SYNOPSIS

    $self->panel_title({ class => 'search' });

returns a Moonshine::Element that renders too..

    <h3 class="panel-title"></h3>

=cut


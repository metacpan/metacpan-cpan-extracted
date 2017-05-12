package Moonshine::Bootstrap::Component::Panel;

use Moonshine::Magic;
use Params::Validate qw/HASHREF/;

extends (
    'Moonshine::Bootstrap::Component',
    'Moonshine::Bootstrap::Component::PanelHeader',
    'Moonshine::Bootstrap::Component::PanelBody',
    'Moonshine::Bootstrap::Component::PanelFooter',
);

has(
    panel_spec => sub {
        {
            tag         => { default  => 'div' },
            class_base  => { default  => 'panel' },
            switch      => { default  => 'default' },
            switch_base => { default  => 'panel-' },
            header      => { optional => 1, type => HASHREF },
            body        => { optional => 1, type => HASHREF },
            footer      => { optional => 1, type => HASHREF },
        };
    }
);

sub panel {
    my ($self) = shift;

    my ( $base_args, $build_args ) = $self->validate_build(
        {
            params => $_[0] // {},
            spec => $self->panel_spec,
        }
    );

    my $base_element = Moonshine::Element->new($base_args);

    for (qw/header body footer/) {
        if ( $build_args->{$_} ) {
            my $action = sprintf 'panel_%s', $_;
            $base_element->add_child($self->$action($build_args->{$_}));
        }
    }

    return $base_element;
}

1;

__END__

=head1 NAME

Moonshine::Bootstrap::Component::Panel

=head1 SYNOPSIS

    $self->panel({ class => 'search' });

returns a Moonshine::Element that renders too..

    <div class="panel panel-default">
        ...
    </div>

=cut


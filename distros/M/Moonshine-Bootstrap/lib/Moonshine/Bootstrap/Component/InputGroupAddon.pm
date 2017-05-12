package Moonshine::Bootstrap::Component::InputGroupAddon;

use Moonshine::Magic;
use Params::Validate qw/HASHREF/;

extends (
    'Moonshine::Bootstrap::Component',
    'Moonshine::Bootstrap::Component::Input',
    'Moonshine::Bootstrap::Component::DropdownButton',
    'Moonshine::Bootstrap::Component::DropdownUl',
);

has(
    input_group_addon_spec => sub {
        {
            tag        => { default => 'span' },
            class_base => { default => 'input-group-addon' },
            checkbox   => 0,
            radio      => 0,
            button     => { type   => HASHREF, optional => 1 },
            dropdown   => { type   => HASHREF, optional => 1 },
        };
    }
);

sub input_group_addon {
    my ($self) = shift;

    my ( $base_args, $build_args ) = $self->validate_build(
        {
            params => $_[0] // {},
            spec => $self->input_group_addon_spec,
        }
    );

    my $base_element = Moonshine::Element->new($base_args);
    
    if ( my $button = $build_args->{button} ) {
        $base_element->class("input-group-btn");
        $base_element->add_child( $self->button($button) );
    }

    if ( my $dropdown = $build_args->{dropdown} ) {
        $base_element->class("input-group-btn");
        $base_element->tag('div');
        $base_element->add_child(
            $self->dropdown_button(
                { %{ $dropdown->{button} }, id => $dropdown->{mid} }
            )
        );
        $base_element->add_child(
            $self->dropdown_ul(
                { %{ $dropdown->{ul} }, aria_labelledby => $dropdown->{mid} }
            )
        );
    }

    if ( $build_args->{checkbox} ) {
        $base_element->add_child($self->input( { type => 'checkbox' } ));
    }

    if ( $build_args->{radio} ) {
        $base_element->add_child($self->input( { type => 'radio' } ));
    }

    return $base_element;
}

1;

__END__

=head1 NAME

Moonshine::Bootstrap::Component::InputAddon

=head1 SYNOPSIS

    $self->input_addon({ class => 'search' });

returns a Moonshine::Element that renders too..

    <span class="input-group-addon"></span>

=cut


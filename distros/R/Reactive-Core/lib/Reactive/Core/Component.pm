package Reactive::Core::Component;

use warnings;
use strict;

use Scalar::Util 'blessed';
use Types::TypeTiny qw( is_ArrayLike );

use Reactive::Core::TemplateRenderer;


=head2 allow_method_call

=cut
sub allow_method_call {
    my $self = shift;
    my $method = shift;

    return 0 unless $self->can($method);
    return 0 if $method =~ /^_/;
    return 0 if $method =~ /^[A-Z]*$/;

    if ($self->can('allowed_methods')) {
        for my $m ($self->allowed_methods) {
            return 1 if $method eq $m;
        }
        return 0;
    }

    return 1;
}

=head2 allow_property_update

=cut
sub allow_property_update {
    my $self = shift;
    my $property = shift;
    my $value = shift;

    return 0 if $property =~ /^_/;
    return 0 if $property =~ /^[A-Z]*$/;

    my ($root, $index, $sub) = $self->_split_property_and_index($property);

    if ($self->can('allowed_properties')) {
        my $check = $root;

        if (defined $index) {
            $check .= '[]';
        }

        if (defined $sub) {
            $check .= ".$sub";
        }

        for my $p ($self->allowed_properties) {
            return 1 if $check eq $p;
        }

        return 0;
    }

    for my $p ($self->r_get_property_names) {
        if ($root eq $p) {
            if (defined $index) {
                return is_ArrayLike($self->$root);
            }
            return 1;
        }

    }

    return 0;
}

=head2 r_process_method_call

=cut
sub r_process_method_call {
    my $self = shift;
    my $method = shift;

    return unless $self->allow_method_call($method);

    $self->$method();
}

=head2 r_process_update_property

=cut
sub r_process_update_property {
    my $self = shift;
    my $arg = shift;
    my $value = shift;

    my ($property, $index, $sub) = $self->_split_property_and_index($arg);

    if (defined $sub) {
        if (defined $index) {
            $self->$property->[ $index ]->{ $sub } = $value;
        } else {
            $self->$property->{ $sub } = $value;
        }
    } else {
        if (defined $index) {
            $self->$property->[$index] = $value;
        } else {
            $self->$property($value);
        }
    }


    if ($self->can('updated')) {
        $self->updated($property);
    }
}

=head2 r_get_property_names

=cut
sub r_get_property_names {
    my $self = shift;

    my $component_class = $self;
    if (ref $self) {
        $component_class = blessed $self;
    }

    my @keys = keys(%{
        'Moo'->_constructor_maker_for($component_class)->all_attribute_specs
    });

    return @keys;
}

=head2 r_get_properties

=cut
sub r_get_properties {
    my $self = shift;

    my @keys = $self->r_get_property_names();

    my %properties = map { $_ => $self->$_ } @keys;

    return %properties;
}

=head2 r_get_component_name

=cut
sub r_get_component_name {
    my $self = shift;

    my $name = blessed $self;
    $name =~ s/.*:://gi;

    return $name;
}

=head2 r_snapshot_data

=cut
sub r_snapshot_data {
    my $self = shift;

    my %properties = $self->r_get_properties();

    return {
        component => $self->r_get_component_name(),
        data => \%properties,
    };
}

=head2 render_template_file

=cut
sub render_template_file {
    my $self = shift;
    my $template = shift;

    return (
        Reactive::Core::TemplateRenderer::RENDER_TEMPLATE_FILE(),
        $template,
    );
}

=head2 render_template_inline

=cut
sub render_template_inline {
    my $self = shift;
    my $template = shift;

    return (
        Reactive::Core::TemplateRenderer::RENDER_TEMPLATE_INLINE(),
        $template,
    );
}

sub _split_property_and_index {
    my $self = shift;
    my $arg = shift;

    my ($property, $index, $subproperty) = $arg =~ /^([A-Z]*)(?:\[(\d+)\])?(?:\.([A-Z]+))?$/i;

    return ($property, $index, $subproperty);
}

1;

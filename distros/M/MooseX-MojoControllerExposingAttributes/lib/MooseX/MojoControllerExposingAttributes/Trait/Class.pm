package MooseX::MojoControllerExposingAttributes::Trait::Class;
use Moose::Role;

use MooseX::Types::Moose qw( HashRef );

our $VERSION = '1.000001';

has _mojo_method_name_to_attribute_reader_name_map => (
    is      => 'ro',
    isa     => HashRef,
    lazy    => 1,
    handles => { _get_mojo_attribute_name_for_method => 'get' },
    builder => '_make_mojo_method_name_to_attribute_reader_name_map',
);

# this isn't called _build_XXX because we're also calling it directly too
sub _make_mojo_method_name_to_attribute_reader_name_map {
    my $self = shift;

    my %output;
    foreach
        my $attr ( sort { $a->name cmp $b->name } $self->get_all_attributes )
    {
        next
            unless $attr->can('does')
            && $attr->does(
            'MooseX::MojoControllerExposingAttributes::Trait::Attribute');
        $output{ $attr->expose_to_mojo_as || $attr->name }
            = $attr->get_read_method;
    }
    return \%output;
}

sub get_read_method_name_for_mojo_helper {
    my $self        = shift;
    my $wanted_name = shift;

    return $self->_get_mojo_attribute_name_for_method($wanted_name)
        if $self->is_immutable;
    return
        $self->_make_mojo_method_name_to_attribute_reader_name_map
        ->{$wanted_name};
}

no Moose::Role;
1;

=head1 NAME

MooseX::MojoControllerExposingAttributes::Trait::Class - metaclass helper for MooseX::MojoControllerExposingAttributes

=head1 SYNOPSIS

    # No user serviceable parts contained within

=head1 DESCRIPTION

This is a class trait that is applied to your class's metaclass by
L<MooseX::MojoControllerExposingAttributes>.

You probably don't want to be worried about the internal details of this.

=head1 METHODS

=head2 get_read_method_name_for_mojo_helper( $wanted_name )

Returns the name of the reader method for the attribute exposed to Mojolicious
as the passed argument, or, if no such attribute is exposed, the undefined
value.

This method works by examining each attribute to see if the attribute
has the correct trait and what name the attribute is exposed to Mojolicious as.
If the metaclass has been made immutable this examination only has to happen
once and the results are cached.

=head1 SEE ALSO

L<MooseX::MojoControllerExposingAttributes>

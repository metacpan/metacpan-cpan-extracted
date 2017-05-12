package MooseX::Iterator::Meta::Iterable;
use Moose;
use MooseX::Iterator::Array;

use Carp 'confess';

our $VERSION   = '0.11';
our $AUTHORITY = 'cpan:RLB';

extends 'Moose::Meta::Attribute';

has iterate_over => ( is => 'ro', isa => 'Str', default => '' );

before '_process_options' => sub {
    my ( $class, $name, $options ) = @_;

    #if ( defined $options->{is} ) {
    #    confess "Can not use 'is' with the Iterable metaclass";
    #}
    $options->{is} = 'bare';
    $class->meta->add_attribute( iterate_name => ( is => 'ro', isa => 'Str', default => $name ) );
};

after 'install_accessors' => sub {
    my ($self) = @_;
    my $class = $self->associated_class;

    my $iterate_name    = $self->iterate_name;
    my $collection_name = $self->iterate_over;

    my $type       = $class->get_attribute($collection_name)->type_constraint->name;
    my $collection = $class->get_attribute($collection_name)->get_read_method;

    my $iterator_class_name = $self->_calculate_iterator_class_for_type($type);

    confess "Invalid iterator class given" if !$iterator_class_name;
    confess "$iterator_class_name does not implement MooseX::Iterator::Role" if !$iterator_class_name->does('MooseX::Iterator::Role');

    $class->add_method(
        $iterate_name => sub {
            my ($self) = @_;
            $iterator_class_name->new( collection => $self->$collection );
        }
    );
};

sub _calculate_iterator_class_for_type {
    my ( $self, $type ) = @_;

    if ( $type eq 'ArrayRef' ) {
        return 'MooseX::Iterator::Array';
    }
    elsif ( $type eq 'HashRef' ) {
        return 'MooseX::Iterator::Hash';
    }
}

no Moose;

package Moose::Meta::Attribute::Custom::Iterable;
sub register_implementation { 'MooseX::Iterator::Meta::Iterable' }

1;

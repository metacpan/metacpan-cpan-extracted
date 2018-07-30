package Model::Envoy::Storage::Memory;

our $VERSION = '0.1.1';
use Moose;
use Scalar::Util 'blessed';
use MooseX::ClassAttribute;

extends 'Model::Envoy::Storage';

=head1 Model::Envoy::Storage::Memory

A trivial example in-memory storage plugin. It should not be used in production.

=cut

class_has 'store' => (
    is       => 'rw',
    isa      => 'DBIx::Class::Schema',
    default  => sub { {} },
);


sub fetch {
    my $self        = shift;
    my $model_class = shift;
    my %params;

    return undef unless @_;

    if ( @_ == 1 ) {

        my ( $id ) = @_;

        $params{id} = $id;
    }
    else {
        %params = @_;
    }

    my $id = $params{id};

    return undef unless $id;

    return exists $self->store->{$id} ? $model_class->build( $self->store->{$id} ) : undef;
}

sub list {

    return ();
}

sub save {
    my ( $self ) = @_;

    $self->store->{ $self->model->id } = $self->model->dump;

    return $self;
}

sub delete {
    my ( $self ) = @_;

    delete $self->store->{ $self->model->id };

    return;
}

sub in_storage {
    my ( $self ) = @_;

    return exists $self->store->{ $self->model->id };
}

1;
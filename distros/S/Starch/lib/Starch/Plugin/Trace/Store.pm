package Starch::Plugin::Trace::Store;
our $VERSION = '0.14';

use Moo::Role;
use strictures 2;
use namespace::clean;

with 'Starch::Plugin::ForStore';

after BUILD => sub{
    my ($self) = @_;

    $self->log->tracef(
        'starch.store.%s.new',
        $self->short_store_class_name(),
    );

    return;
};

around set => sub{
    my $orig = shift;
    my $self = shift;
    my ($id, $namespace) = @_;

    my $key = $self->stringify_key( $id, $namespace );

    $self->log->tracef(
        'starch.store.%s.set.%s',
        $self->short_store_class_name(), $key,
    );

    return $self->$orig( @_ );
};

around get => sub{
    my $orig = shift;
    my $self = shift;
    my ($id, $namespace) = @_;

    my $key = $self->stringify_key( $id, $namespace );

    $self->log->tracef(
        'starch.store.%s.get.%s',
        $self->short_store_class_name(), $key,
    );

    my $data = $self->$orig( @_ );

    $self->log->tracef(
        'starch.store.%s.get.%s.missing',
        $self->short_store_class_name(), $key,
    ) if !$data;

    return $data;
};

around remove => sub{
    my $orig = shift;
    my $self = shift;
    my ($id, $namespace) = @_;

    my $key = $self->stringify_key( $id, $namespace );

    $self->log->tracef(
        'starch.store.%s.remove.%s',
        $self->short_store_class_name(), $key,
    );

    return $self->$orig( @_ );
};

1;

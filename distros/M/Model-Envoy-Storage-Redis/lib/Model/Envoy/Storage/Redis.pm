package Model::Envoy::Storage::Redis;

our $VERSION = '0.1.0';

use Moose;
use MooseX::ClassAttribute;

extends 'Model::Envoy::Storage';

=head1 Model::Envoy::Storage::Redis

A storage plugin for C<Model::Envoy> that conforms to C<Model::Envoy::Storage>.
It does not implement C<list> at the moment, but will fetch, store and delete
objects out of the key-value store.

=cut

class_has 'redis' => (
    is  => 'rw',
    isa => 'Redis::Fast',
);

sub configure {
    my ( $class, $conf ) = @_;

    $class->redis(
        ref $conf->{redis} eq 'CODE' ? $conf->{redis}->() : $conf->{redis}
    );

    $conf->{_configured} = 1;
}

sub fetch {
    my $self = shift;
    my $model_class = shift;

    my $id = do {

        if ( @_ == 1 ) {
            $_[0];
        }
        else {
            my %params = @_;

            $params{id};
        }
    };

    if ( my $result = $self->redis->get( 'id:' . $id ) ) {

        return $model_class->build($result);
    }

    return undef;
}

sub save {
    my ( $self ) = @_;

    $self->redis->set( 'id:' . $self->model->id => $self->model->dump );

    return $self;
}

sub delete {
    my ( $self ) = @_;

    $self->redis->del( 'id:' . $self->model->id );

    return;
}

sub in_storage {
    my ( $self ) = @_;

    return $self->redis->exists( 'id:' . $self->model->id ) ? 1 : 0;
}

1;

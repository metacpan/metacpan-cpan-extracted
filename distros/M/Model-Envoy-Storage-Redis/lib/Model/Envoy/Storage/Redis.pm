package Model::Envoy::Storage::Redis;

our $VERSION = '0.1.3';

use Moose;
use MooseX::ClassAttribute;
use JSON::XS;

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
    my ( $plugin_class, $envoy_class, $conf ) = @_;

    $plugin_class->redis(
        ref $conf->{redis} eq 'CODE' ? $conf->{redis}->($envoy_class) : $conf->{redis}
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

        return $model_class->build( decode_json( $result ) );
    }

    return undef;
}

sub save {
    my ( $self ) = @_;

    $self->redis->set( 'id:' . $self->model->id => encode_json( $self->model->dump ) );

    return $self;
}

sub list {

    return undef;
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

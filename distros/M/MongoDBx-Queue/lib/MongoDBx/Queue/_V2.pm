use 5.010;
use strict;
use warnings;

package MongoDBx::Queue::_V2;

# V2 implementation

our $VERSION = '2.001';

use Moose 2;

use Tie::IxHash;
use boolean;
use namespace::autoclean;

my $ID       = '_id';
my $RESERVED = '_x';
my $RES_TIME = '_r';
my $PRIORITY = '_p';

with(
    'MooseX::Role::Logger',
    'MooseX::Role::MongoDB' => { -version => 1.000 },
    'MongoDBx::Queue::Role::_CommonOptions',
);

sub _build__mongo_default_database { $_[0]->database_name }

sub _build__mongo_client_options {
    return {
        write_concern => { w     => "majority" },
        read_concern  => { level => "majority" },
        %{ $_[0]->client_options },
    };
}

sub create_indexes {
    my ($self) = @_;
    # ensure index on PRIORITY in the same order we use for reserving
    $self->_mongo_collection( $self->collection_name )
      ->indexes->create_one( [ $RESERVED => 1, $PRIORITY => 1 ] );
    $self->_mongo_collection( $self->collection_name )
      ->indexes->create_one( [ $RESERVED => 1, $RES_TIME => 1 ] );
}

sub add_task {
    my ( $self, $data, $opts ) = @_;

    delete $data->{$RES_TIME};
    $self->_mongo_collection( $self->collection_name )->insert_one(
        {
            %$data,
            $RESERVED => boolean::false,
            $PRIORITY => $opts->{priority} // time(),
        }
    );
}

sub reserve_task {
    my ( $self, $opts ) = @_;

    my $now = time();
    return $self->_mongo_collection( $self->collection_name )->find_one_and_update(
        {
            $RESERVED => boolean::false,
            $PRIORITY => { '$lte' => $opts->{max_priority} // $now },
        },
        {
            '$set' => {
                $RESERVED => boolean::true,
                $RES_TIME => $now,
            }
        },
        { sort => [ $PRIORITY => 1 ] },
    );
}

sub reschedule_task {
    my ( $self, $task, $opts ) = @_;
    $self->_mongo_collection( $self->collection_name )->update_one(
        { $ID => $task->{$ID} },
        {
            '$unset' => { $RES_TIME => 1 },
            '$set'   => {
                $RESERVED => boolean::false,
                $PRIORITY => $opts->{priority} // $task->{$PRIORITY}
            },
        },
    );
}

sub remove_task {
    my ( $self, $task ) = @_;
    $self->_mongo_collection( $self->collection_name )
      ->delete_one( { $ID => $task->{$ID} } );
}

sub apply_timeout {
    my ( $self, $timeout ) = @_;
    $timeout //= 120;
    my $cutoff = time() - $timeout;
    $self->_mongo_collection( $self->collection_name )->update_many(
        { $RESERVED => boolean::true, $RES_TIME => { '$lt' => $cutoff } },
        {
            '$unset' => { $RES_TIME => 1 },
            '$set'   => { $RESERVED => boolean::false },
        },
    );
}

sub search {
    my ( $self, $query, $opts ) = @_;
    $query = {} unless ref $query eq 'HASH';
    $opts  = {} unless ref $opts eq 'HASH';
    if ( exists $opts->{reserved} ) {
        $query->{$RESERVED} = ( $opts->{reserved} ? boolean::true : boolean::false );
        delete $opts->{reserved};
    }
    my $cursor =
      $self->_mongo_collection( $self->collection_name )->find( $query, $opts );
    return $cursor->all;
}

sub peek {
    my ( $self, $task ) = @_;
    my @result = $self->search( { $ID => $task->{$ID} } );
    return wantarray ? @result : $result[0];
}

sub size {
    my ($self) = @_;
    return $self->_mongo_collection( $self->collection_name )->count_documents( {} );
}

sub waiting {
    my ($self) = @_;
    return $self->_mongo_collection( $self->collection_name )
      ->count_documents( { $RESERVED => boolean::false } );
}

__PACKAGE__->meta->make_immutable;

1;

# vim: ts=4 sts=4 sw=4 et:

use 5.010;
use strict;
use warnings;

package MongoDBx::Queue::_V1;

# V1 implementation

our $VERSION = '2.002';

use Moose 2;

use Tie::IxHash;
use boolean;
use namespace::autoclean;

my $ID       = '_id';
my $RESERVED = '_r';
my $PRIORITY = '_p';

with (
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
      ->indexes->create_one( [ $PRIORITY => 1 ] );
}

sub add_task {
    my ( $self, $data, $opts ) = @_;

    $self->_mongo_collection( $self->collection_name )
      ->insert_one( { %$data, $PRIORITY => $opts->{priority} // time() } );
}

sub reserve_task {
    my ( $self, $opts ) = @_;

    my $now = time();
    return $self->_mongo_collection( $self->collection_name )->find_one_and_update(
        {
            $PRIORITY => { '$lte'    => $opts->{max_priority} // $now },
            $RESERVED => { '$exists' => boolean::false },
        },
        { '$set' => { $RESERVED => $now } },
        { sort   => [ $PRIORITY => 1 ] },
    );
}

sub reschedule_task {
    my ( $self, $task, $opts ) = @_;
    $self->_mongo_collection( $self->collection_name )->update_one(
        { $ID => $task->{$ID} },
        {
            '$unset' => { $RESERVED => 0 },
            '$set'   => { $PRIORITY => $opts->{priority} // $task->{$PRIORITY} },
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
        { $RESERVED => { '$lt'     => $cutoff } },
        { '$unset'  => { $RESERVED => 0 } },
    );
}

sub search {
    my ( $self, $query, $opts ) = @_;
    $query = {} unless ref $query eq 'HASH';
    $opts  = {} unless ref $opts eq 'HASH';
    if ( exists $opts->{reserved} ) {
        $query->{$RESERVED} =
          { '$exists' => $opts->{reserved} ? boolean::true : boolean::false };
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
    return $self->_mongo_collection( $self->collection_name )->estimated_document_count();
}

sub waiting {
    my ($self) = @_;
    return $self->_mongo_collection( $self->collection_name )
      ->count_documents( { $RESERVED => { '$exists' => boolean::false } } );
}

__PACKAGE__->meta->make_immutable;

1;

# vim: ts=4 sts=4 sw=4 et:

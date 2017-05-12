use strictures 1;
package Mojito::Model::Transform;
{
  $Mojito::Model::Transform::VERSION = '0.24';
}
use Moo;
use MooX::Types::MooseLike::Base qw/Object ArrayRef/;
use Mojito::Page::CRUD::Mongo;
use Mojito::Model::Config;
use DBM::Deep;
use Data::Dumper::Concise;

# Move records from Mongodb to DBM::Deep
has db_file => (
    is => 'rw',
    lazy => 1,
    default => sub { Mojito::Model::Config->new->config->{dbm_deep_filepath} },
);
has editer => (
    is => 'ro',
    isa => Object,
    lazy => 1,
    default => sub { Mojito::Page::CRUD::Mongo->new },
);
has frigo => (
    is => 'ro',
    isa => Object,
    lazy => 1,
    default => sub { DBM::Deep->new($_[0]->db_file) },
);
has collections => (
    is => 'ro',
    isa => ArrayRef,
    lazy => 1,
    default => sub { [qw/notes collection users/] }, 
); 

sub transfer_records {
    my ($self, $collection, @ids) = @_;
    foreach my $doc_id (@ids) {
        $self->transfer_record($collection, $doc_id);
    }
}

# Use mongo id as the key, but remove it's object from the doc
sub transfer_record {
    my ($self, $collection, $doc_id) = @_;
    my $doc = $self->get_mongo_record($collection, $doc_id); 
    # Remove the MongoDB::OID object, and replace it with just the oid string for the id key's value
    delete $doc->{_id};
    $doc->{id} = $doc_id;
    $self->set_deep_record($collection, $doc_id, $doc);
}
sub get_mongo_record {
    my ($self, $collection, $id) = @_;
    $self->set_collection_name($collection);
    my $doc = $self->editer->read($id); 
}
sub set_deep_record { 
   my ($self, $collection, $id, $record) = @_;
    print "SETTING DEEP Doc entitled: ", $record->{title}, "\n" if $record->{title};
    print "SETTING DEEP Collection named: ", $record->{collection_name}, "\n" if $record->{collection_name};
    print "SETTING DEEP User named: ", $record->{username}, "\n" if $record->{username};
    $self->frigo->{$collection}->{$id} = $record;
}

sub list_mongo_ids {
    my ($self, $collection) = @_;
    
    # Clear collection since it's lazy and we want it rebuilt
    # to ensure we're using the collection passed instead of any default
    $self->set_collection_name($collection);
    my $cursor = $self->editer->get_all;

    my @ids;
    while (my $doc = $cursor->next) {
        my $id = $doc->{_id}->value;
        push @ids, $id;
    }
    return @ids;
}

sub set_collection_name {
    my ($self, $collection) = @_; 
    $self->editer->clear_collection_name;
    $self->editer->clear_collection;
    $self->editer->collection_name($collection);
}


=head2 BUILD

Set a test DB when RELEASE_TESTING

=cut

sub BUILD {
    my ($self) = (shift);
    if ($ENV{RELEASE_TESTING}) {
        my $test_deep_db_file = '/home/hunter/mojito_test.db';
        my $test_mongo_db_name = 'mojito_test';
        $self->editer->db_name($test_mongo_db_name);
        $self->db_file($test_deep_db_file);
    }
}

1;

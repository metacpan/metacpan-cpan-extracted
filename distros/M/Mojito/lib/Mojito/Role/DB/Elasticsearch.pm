use strictures 1;
package Mojito::Role::DB::Elasticsearch;
$Mojito::Role::DB::Elasticsearch::VERSION = '0.25';
use Moo::Role;
use Mojito::Model::Config;
use Search::Elasticsearch;
use Data::Dumper::Concise;

with('Mojito::Role::DB::OID');

has 'db_name' => (
    is => 'rw',
    lazy => 1,
    # Set a test DB when RELEASE_TESTING
    default => sub { 
        $ENV{RELEASE_TESTING} 
          ?  'mojito_test' 
          : Mojito::Model::Config->new->config->{es_index}; 
    },
    clearer => 'clear_db_name',
);
has 'db' => (
    is => 'lazy',
    builder => sub { Search::Elasticsearch->new(nodes => [$_[0]->db_host]) },
    clearer => 'clear_db',
);
has 'collection' => (
    is => 'ro',
    lazy => 1,
    builder => '_build_collection',
    clearer => 'clear_collection',
);
has 'collection_name' => (
    is => 'rw',
    lazy => 1,
    default => sub { 'notes' },
    clearer => 'clear_collection_name',
);
has 'collection_size' => (
    is => 'lazy',
    builder => sub { 100 },
);
has 'db_host' => (
    is => 'lazy',
    builder => sub { 'localhost:9200' },
);

sub _build_collection  {
    my $self = shift;
    if (not defined $self->db) {
        $self->clear_db;
    }
    my $body = {
        query => {match_all => {}},
    };
    my $collection_name =$self->collection_name;
    # If we're the notes collection then sort by last_modified
    if ($collection_name eq 'notes') {
       $body->{sort} = [{last_modified => {order => 'desc'}}];
    } 
    my $results = $self->db->search(
        index => $self->db_name, 
        type => $collection_name,
        body => $body,
        size => $self->collection_size, 
    );
    return $results;
}


1;

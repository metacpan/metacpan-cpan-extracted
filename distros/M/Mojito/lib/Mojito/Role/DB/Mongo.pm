use strictures 1;
package Mojito::Role::DB::Mongo;
{
  $Mojito::Role::DB::Mongo::VERSION = '0.24';
}
use Moo::Role;
use MongoDB;

# Create a database and get a handle on a users collection.
has 'conn' => (
    is => 'ro',
    lazy => 1,
    builder => '_build_conn',
);
has 'db_name' => (
    is => 'rw',
    lazy => 1,
    default => sub { $ENV{RELEASE_TESTING} ? 'mojito_test' : 'mojito' },
    clearer => 'clear_db_name',
);
has 'db' => (
    is => 'rw',
    lazy => 1,
    builder => '_build_db',
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
has 'db_host' => (
    is => 'ro',
    lazy => 1,
    default => sub { 'localhost:27017' },
);

sub _build_conn {
    MongoDB::Connection->new(host => $_[0]->db_host);
}

sub _build_db  {
    warn "BUILD MONGO DB CONNECTION" if $ENV{MOJITO_DEBUG};
#    use Devel::StackTrace;
#    my $trace = Devel::StackTrace->new;
#    warn $trace->as_string;
    my $self = shift;
    my $db_name = $self->db_name;
    return $self->conn->get_database($db_name);
}
sub _build_collection  {
    my $self = shift;
    my $collection_name = $self->collection_name;
    # Ran into trouble with $self->db not being defined when it seemed 
    # that it should be.  Clearing the db attribute resolved it.
    if (not defined $self->db) {
        $self->clear_db;
    }
    $self->db->get_collection($collection_name);
}

1;

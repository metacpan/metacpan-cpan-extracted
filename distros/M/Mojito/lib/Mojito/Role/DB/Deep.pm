use strictures 1;
package Mojito::Role::DB::Deep;
{
  $Mojito::Role::DB::Deep::VERSION = '0.24';
}
use Moo::Role;
use Mojito::Model::Config;
use DBM::Deep;
use Data::Dumper::Concise;

with('Mojito::Role::DB::OID');

has 'db_name' => (
    is => 'rw',
    lazy => 1,
    # Set a test DB when RELEASE_TESTING
    default => sub { 
        $ENV{RELEASE_TESTING} 
          ?  '/home/hunter/mojito_test.db' 
          : Mojito::Model::Config->new->config->{dbm_deep_filepath}; 
    },
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

sub _build_db  {
    warn "BUILD DEEP DB CONNECTION for ", $_[0]->db_name if $ENV{MOJITO_DEBUG};
#    use Devel::StackTrace;
#    my $trace = Devel::StackTrace->new;
#    warn $trace->as_string;
    return DBM::Deep->new($_[0]->db_name);
}
sub _build_collection  {
    my $self = shift;
    my $collection_name = $self->collection_name;
    $self->db->{$collection_name};
}


1;

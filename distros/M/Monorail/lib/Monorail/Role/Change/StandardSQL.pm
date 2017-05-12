package Monorail::Role::Change::StandardSQL;
$Monorail::Role::Change::StandardSQL::VERSION = '0.4';
use Moose::Role;
use SQL::Translator;

with 'Monorail::Role::Change';

requires qw/as_sql/;

has producer => (
    is       => 'ro',
    isa      => 'Monorail::SQLTrans::ProducerProxy',
    lazy     => 1,
    builder  => '_build_producer',
);

# might break this into its own role that requires 'table'
has schema_table_object => (
    is      => 'ro',
    isa     => 'SQL::Translator::Schema::Table',
    lazy    => 1,
    builder => '_build_schema_table_object',
);

sub _build_schema_table_object {
    my ($self) = @_;

    require SQL::Translator::Schema::Table;
    return SQL::Translator::Schema::Table->new(name => $self->table);
}

sub _build_producer {
    my ($self) = @_;

    require Monorail::SQLTrans::ProducerProxy;
    return  Monorail::SQLTrans::ProducerProxy->new(db_type => $self->db_type);
}

sub transform_database {
    my ($self, $dbix) = @_;

    foreach my $statement ($self->as_sql) {
        $dbix->storage->dbh->do($statement);
    }
}


1;

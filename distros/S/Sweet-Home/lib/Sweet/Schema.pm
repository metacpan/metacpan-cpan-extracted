package Sweet::Schema;
use Moose::Role;

use Carp;
use UNIVERSAL::require;

has _database_connection_class => (
    builder => '_build_database_connection_class',
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
);

sub _build_database_connection_class {
    shift->meta->name . '::DatabaseConnection'
}

has schema => (
    builder => '_build_schema',
    isa     => 'DBIx::Class::Schema',
    is      => 'ro',
    lazy    => 1,
);

sub _build_schema {
    my $self = shift;

    my $database_connection_class = $self->_database_connection_class;
    my $schema_class = $self->_schema_class;

    $database_connection_class->require
      or croak "Could not require class: $database_connection_class\n";

    $schema_class->require
      or croak "Could not require class: $schema_class\n";

    my $database_connection = $database_connection_class->new;

    my $datasource            = $database_connection->datasource;
    my $username              = $database_connection->username;
    my $password              = $database_connection->password;
    my $connection_attributes = $database_connection->connection_attributes;

    my $schema = $schema_class->connect(
        $datasource,
        $username,
        $password,
        $connection_attributes
    );

    return $schema;
}

has _schema_class => (
    builder => '_build_schema_class',
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
);

sub _build_schema_class {
    shift->meta->name . '::Schema'
}

1;
__END__

=head1 NAME

Sweet::Schema

=head1 SYNOPSIS

In C<lib/My/Project.pm>.

    package My::Project;
    use Moose;

    with 'Sweet::Schema';

    __PACKAGE__->meta->make_immutable;

Generate C<lib/My/Project/Schema.pm> and its C<Result> subclasses with 

    $ dbicdump -o  dump_directory=./lib My::Project::Schema dbi:Oracle:XE scott tiger
    Dumping manual schema for My::Project::Schema to directory ./lib ...
    Schema dump completed.

In C<lib/My/Project/DatabaseConnection.pm>

    package My::Project::DatabaseConnection;
    use Moose;

    with 'My::Project::Config';

    __PACKAGE__->meta->make_immutable;

In C<lib/My/Project/Config.pm>

    package My::Project::DatabaseConnection;
    use Moose;

    extends 'Sweet::DatabaseConnection';

    with 'My::Project::Config';

    __PACKAGE__->meta->make_immutable;

In C<$HOME/.myproject.yml>

    My:
      Project:
        DatabaseConnection:
          datasource: dbi:Oracle:XE
          username: scott
          password: tiger

=head1 ATTRIBUTES

=head2 _database_connection_class

Defaults to C<__PACKAGE__::DatabaseConnection>.

=head2 _schema_class

Defaults to C<__PACKAGE__::Schema>.

=head2 schema

=cut


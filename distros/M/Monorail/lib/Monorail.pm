package Monorail;
$Monorail::VERSION = '0.4';
use Moose;

use Monorail::MigrationScript::Writer;
use Monorail::Diff;
use Monorail::Recorder;

use SQL::Translator;
use SQL::Translator::Schema;
use SQL::Translator::Parser::DBIx::Class;

=head1 NAME

Monorail - Database Migrations

=head1 VERSION

version 0.4

=head1 SYNOPSIS


    startup-monorail
   ./monorail.pl make_migration
   ./monorail.pl migrate

=head1 DESCRIPTION

This module attempts to provide a simplier and more robust way to manage
database migrations with L<DBIx::Class>.  This library borrows (steals!) ideas
heavily from L<django's migrations|https://docs.djangoproject.com/en/1.9/topics/migrations/>.

The main goals of this library are to free the programmer from keeping track
of schema versions and to work well with projects that have many branches in play.

=head1 DESIGN

=head2 DBIx::Class is the source truth.

Tables, their fields, views, triggers and procedures are all defined via the
result classes in L<DBIx::Class>.  Whenever possible, Monorail does not add
any functionality to DBIx::Class, but instead depends on existing deployment
hooks.

=head2 Migrations In Perl

Any tool like Monorail ends up building a set of database updates called
migrations.  In other tools like L<DBIx::Class::DeploymentHandler> these changes
are SQL files, with monorail these migrations are objects.

See L<Monorail::Role::Migration> for an example of what these migration files
look like.

=head2 No database needed

You do not need an active database connection to build a migration.  Monorail
compares the DBIx::Class schema on disk to a sql translator schema that contains
all the changes defined in the migrations.  This is where having the changes
defined in perl becomes powerful - the objects in each migration know how to
express themselves as SQL or as a change to a SQL::Translator schema).

=head2 Dependency Tree

Each migration has a list of other migrations that it depends on.  This is used
to build a tree (a directed acyclic graph if you want to be fancy) that
describes the relationships between the migrations.  Any new migration will be
created with the I<sink vertices> as its dependencies.  This means that new
migrations depend on all the previous migrations.

It's also worth noting that all migrations in the monorail directory are
included in the dependency tree.  When a database is updated the tree is walked
in topological order.

=head2 Non-versioned migration state

Pretty much every migration system I've looked at keeps track of what version
a database is at.  Usually this is a table with a integer column and a single
row.  There's migrations 1 thru 9 and the database is at 7?  Apply 8 and 9.

Monorail inserts a row with the migration name when it is applied, then as we
are walking the tree we can just skip migrations that have the row.

=head1 ATTRIBUTES

=head2 dbix

The DBIx::Class::Schema object for the schema we're managing.  This will be used
to inspect the current state of the result classes and for the DBI handle to the
database we're updating.

Required.

=cut

has dbix => (
    is       => 'ro',
    isa      => 'DBIx::Class::Schema',
    required => 1,
);

=head2 db_type

A string representing the type of database we're connecting to.  By default this
is dirived from the connection within C<dbix>.

=cut

has db_type => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    builder => '_build_db_type',
);

=head2 basedir

The directory where our migration files live.  Required.

=cut

has basedir => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);


=head2 recorder

The recorder object is responsible for the table that stores migration states
as discussed above.

=cut

has recorder => (
    is       => 'ro',
    isa      => 'Monorail::Recorder',
    lazy     => 1,
    builder  => '_build_recorder'
);

=head2 all_migrations

A L<Monorail::MigrationScript::Set> object representing all the migrations
that currently exist in the basedir.

=cut

has all_migrations => (
    is       => 'ro',
    isa      => 'Monorail::MigrationScript::Set',
    lazy     => 1,
    builder  => '_build_set_of_all_migrations',
);


=head2 current_diff

A L<Monorail::Diff> object representing the current difference
between the DBIx::Class schema on disk and the sum of the current migrations.

=cut

has current_diff => (
    is      => 'ro',
    isa     => 'Monorail::Diff',
    lazy    => 1,
    builder => '_build_current_diff',
);

=head2 quiet

A boolean flag.  When true this module will print no informative messages to
C<STDOUT>.  Defaults to false.

=cut

has quiet => (
    is      => 'ro',
    isa     => 'Bool',
    default => 0,
);

# ABSTRACT: Database migrations for DBIx::Class

__PACKAGE__->meta->make_immutable;

=head1 METHODS

=head2 make_migration

    $monorail->make_migration();
    # or
    $monorail->make_migration('add_visitor_table');

Compares the current DBIx::Class definitions on disk to a ProtoDBIX built from
all the migrations.  If there are differences, a new migration script will be
created that contains those differences.  If no name is passed an autogenerated
unique name will be used - otherwise the given name is used.

=cut

sub make_migration {
    my ($self, $name) = @_;

    my $diff = $self->current_diff;

    unless ($diff->has_changes) {
        $self->_out("No changes detected.\n");
        return;
    }

    $name ||= $self->all_migrations->next_auto_name;

    my $script = Monorail::MigrationScript::Writer->new(
        name         => $name,
        basedir      => $self->basedir,
        diff         => $diff,
        dependencies => [ map { $_->name } $self->all_migrations->current_dependencies ],
    );

    $script->write_file;

    $self->_out("Created $name.\n");

    return 1;
}


sub _build_current_diff {
    my ($self) = @_;

    return Monorail::Diff->new(
        source_schema => $self->_schema_from_current_migrations,
        target_schema => $self->_schema_from_dbix,
    );
}

sub _schema_from_current_migrations {
    my ($self) = @_;

    my $schema = SQL::Translator::Schema->new();

    foreach my $migration ($self->all_migrations->in_topological_order) {
        #warn sprintf("Applying %s to the schema...\n", $migration->name);
        my $changes = $migration->upgrade_steps;

        foreach my $change (@$changes) {
            $change->transform_schema($schema);
        }
    }

    # use Data::Dumper;
    # die Dumper($schema);

    return $schema;
}

# Get a SQL::Translator::Schema for our dbix.
sub _schema_from_dbix {
    my ($self) = @_;

    my $trans = SQL::Translator->new(
        parser      => 'SQL::Translator::Parser::DBIx::Class',
        parser_args => {
            dbic_schema => $self->dbix,
            # exclude our table, as it gets handled seperately.
            sources => [
               sort { $a cmp $b }
               grep { $_ ne $self->recorder->version_resultset_name }
               $self->dbix->sources
            ],
        },
    );

    $trans->translate;

    return $trans->schema;
}

=head2 migrate

    $monorail->migrate

Updates the database that we're connected to the current state of the
migrations.  Walks the dependency tree in topological order, applying all
migrations that are not yet applied.

=cut

sub migrate {
    my ($self) = @_;

    my $txn_guard = $self->dbix->txn_scope_guard;

    local $| = 1;

    foreach my $migration ($self->all_migrations->in_topological_order) {
        next if $self->recorder->is_applied($migration->name);

        $self->_out("Applying %s...", $migration->name);

        $migration->upgrade($self->db_type);

        $self->_out("done.\n");

        $self->recorder->mark_as_applied($migration->name);
    }

    $txn_guard->commit;
}

=head2 showmigrations

Prints all the migrations by name in order.  If the migration has been applied
to the database, it will be marked with C<[X]> in the output.

=cut

sub showmigrations {
    my ($self) = @_;

    foreach my $migration ($self->all_migrations->in_topological_order) {
        if ($self->recorder->is_applied($migration->name)) {
            $self->_out("%s [X]\n", $migration->name);
        }
        else {
            $self->_out("%s\n", $migration->name);
        }
    }
}

=head2 showmigrationplan

Prints all the migration that would be applied by C<migrate()>.

=cut

sub showmigrationplan {
    my ($self) = @_;

    foreach my $migration ($self->all_migrations->in_topological_order) {
        unless ($self->recorder->is_applied($migration->name)) {
            $self->_out("%s\n", $migration->name);
        }
    }
}


=head2 sqlmigrate

Prints a SQL representation of the given migration names.

=cut

sub sqlmigrate {
    my ($self, @names) = @_;

    foreach my $name (@names) {
        my $migration = $self->all_migrations->get($name);

        $self->_out("%s\n", $migration->name);
        foreach my $change (@{$migration->upgrade_steps}) {
            $change->db_type($self->db_type);

            foreach my $query ($change->as_sql) {
                $query =~ s/^/\t/mg;
                $self->_out("$query\n");
            }
        }
    }
}

sub _build_recorder {
    my ($self) = @_;

    return Monorail::Recorder->new(dbix => $self->dbix);
}


sub _build_set_of_all_migrations {
    my ($self) = @_;

    require Monorail::MigrationScript::Set;

    return Monorail::MigrationScript::Set->new(basedir => $self->basedir, dbix => $self->dbix);
}

{
    my %sqlt_name_for = (
        Pg     => 'PostgreSQL',
        mysql  => 'MySQL',
        SQLite => 'SQLite',
        Oracle => 'Oracle',
        Sybase => 'Sybase',
    );

    sub _build_db_type {
        my ($self) = @_;

        my $dbh      = $self->dbix->storage->dbh;
        my $dbi_name = $dbh->{Driver}->{Name};

        return $sqlt_name_for{$dbi_name} || die "Unsupported Database Type: $dbi_name\n";
    }
}

sub _out {
    my ($self, $fmt, @args) = @_;

    return if $self->quiet;

    printf $fmt, @args;
}

=head1 THANKS

This word is basically a perl port of django migrations.  Many many thanks in
that direction.

Anyone that worked on SQL::Translator, that module is a nuclear powered sonic
swiss army knife of handy.  This module is mostly just sugar on top of it.

The DBIx::Class authors and contributers deserve a lot of free drinks for
building a great ORM.

=head1 AUTHOR

Chris Reinhardt crein@cpan.org

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Liquid Web Inc.

This is free software; you can redistribute it and/or modify it under the same
terms as the Perl 5 programming language system itself.

=cut

1;
__END__

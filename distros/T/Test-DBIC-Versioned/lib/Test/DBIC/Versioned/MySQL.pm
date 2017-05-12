package Test::DBIC::Versioned::MySQL;

use strict;
use warnings;
use 5.016;

our $VERSION = '0.02'; # VERSION

=head1 NAME

Test::DBIC::Versioned:MySQL - Subclass with specific methods for MySQL

=head1 VERSION

version 0.02

=cut

use Capture::Tiny 'capture_stderr';
use File::Slurp 'read_file';
use File::Temp 'tempfile';
use Test::mysqld;
use Try::Tiny qw( try catch );

use Moose;
use MooseX::StrictConstructor;
extends 'Test::DBIC::Versioned';

=head1 FIELDS

=head2 mysqld_config

The configuration hash to pass into L<< Test::mysqld >> when creating a
new empty database. By default it contains {'skip-networking' => 1} to
disable network access to the test database.

=cut

has 'mysqld_config' => (
    is      => 'ro',
    isa     => 'HashRef',
    default => sub {
        {   'skip-networking' => 1,    # no TCP socket
        };
    },
);

=head2 my_cnf

The current my_cnf in the running database as it was when the database was
created.

=cut

has 'my_cnf' => (
    is         => 'ro',
    isa        => 'HashRef',
    lazy_build => 1,
);

sub _build_my_cnf {
    my $self = shift @_;
    return $self->test_db->my_cnf;
}

# Documented in the superclass.
has '+dsn' => (
    is         => 'rw',
    isa        => 'Str',
    lazy_build => 1,
);

sub _build_dsn {
    my $self = shift @_;
    return $self->test_db->dsn;
}

# Documented in the superclass.
has '+test_db' => (
    is         => 'ro',
    isa        => 'Test::mysqld',
    lazy_build => 1,
);

sub _build_test_db {
    my $self = shift;

    my $mysqld = Test::mysqld->new( my_cnf => $self->mysqld_config );
    $mysqld->start();
    $self->dsn( $mysqld->dsn );

    return $mysqld;
}

=head1 METHODS

=head2 DEMOLISH

The L<< Moose >> destructor. This is defined so that the test_db is cleanly stopped
when it goes out of scope, and to avoid filling RAM and disc with unused
databases.

Moose will call this automaticaly. It should not be called by users of this
class.

=cut

sub DEMOLISH {    ## no critic (RequireFinalReturn)
    my $self = shift;
    $self->test_db->stop();
}

=head2 run_sql

As Documented in the superclass, Runs some SQL commands on the database.

NB: This method splits the SQL script into statements by splitting on
semicolons. If there are semicolons in string literals (escaped or not) it
will break.

=cut

# Documented in the superclass.
# Run a deploy or upgrade script and see what errors come back;
sub run_sql {
    my $self = shift @_;
    my $sql  = shift @_;
    my $dbh  = $self->dbh;

    my @errors = ();
    my @sql_script;

    if ( 'SCALAR' eq ref $sql ) {
        @sql_script = split /\n/, $$sql;
    }
    elsif ( -f $sql || 'GLOB' eq ref $sql ) {
        @sql_script = read_file($sql);
    }
    else {
        die "SQL arg $sql is not a filepath, filehandle or scalar ref";
    }

    # Code to remove blank lines, transactions, & comment lines from the
    # raw sql_script. Then split into statements on semicolons.
    # This has been copped verbatim from DBIx::Class::Schema::Versioned
    my @statements = split /;/,
        join '',
        grep { $_ && !/^--/ && !/^(BEGIN|BEGIN TRANSACTION|COMMIT)/mi }
        @sql_script;

    # @statements is now a series of statements. Run each in turn.
    foreach my $statement (@statements) {
        next if $statement =~ m/^\s*$/;
        try {
            # This often results in two duplicate copies of each error
            # message, but better than than to loose some.
            local $SIG{__WARN__} = sub { push @errors, @_ };

            $dbh->do($statement) or push @errors, $dbh->errstr;
        }
        catch {
            my $error = $_;
            push @errors, $error;
        }
    }

    return join "\n", @errors;
}

# Documented in the superclass.
# Returns the table schema as a perl data structure.
sub describe_tables {
    my $self = shift;

    my $return_hash = {};
    my $dbh         = $self->dbh;
    my $json        = $self->_json_engine;

    # TODO: Use "show create table $table" here instead
    #       as people will understand the output more easily.

    my $table_names = $dbh->selectcol_arrayref("SHOW TABLES");

    foreach my $table (@$table_names) {
        $return_hash->{$table}{'index'}
            = $dbh->selectall_hashref( "SHOW INDEX IN $table",
            'Column_name' );

        # The Cardinality and Sub_part fields are statistics about the index
        # They do not represent schema differences, so leave them out.
        foreach my $col ( keys %{ $return_hash->{$table}{'index'} } ) {
            delete $return_hash->{$table}{'index'}{$col}{'Cardinality'};
            delete $return_hash->{$table}{'index'}{$col}{'Sub_part'};
        }

        # Get the list of columns in order
        my $table_cols = $dbh->selectall_arrayref("DESCRIBE $table");
        my @colum_names = map { $_->[0] } @$table_cols;

        # Get the schema for each column in the table (not ordered)
        my $table_schema
            = $dbh->selectall_hashref( "DESCRIBE $table", 'Field' );

        # Then store the column definitions in order
        # Store as a json string so that differences are easy to
        # understand when they occur.
        my @colums = ();
        foreach my $name (@colum_names) {
            push @colums, $json->encode( $table_schema->{$name} );
        }

        $return_hash->{$table}{'colums'} = \@colums;
    }

    return $return_hash;
}

1;

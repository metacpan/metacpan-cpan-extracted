package Pinwheel::Database;

use strict;
use warnings;

use Exporter;
use Carp;

our @ISA = qw(Exporter);
our @EXPORT_OK = qw(
    set_backend set_connection connect finish_all
    prepare do describe tables
    without_foreign_keys dbhostname
    fetchone_tables fetchall_tables
);

our $backend;



sub set_backend
{
    $backend = $_[0];
}

sub set_connection
{
    my ($class);

    croak "Missing database connection details." unless (defined $_[0]);

    $class = $_[0];
    $class =~ s/dbi:(.)(.+?):.*/Pinwheel::Database::\u$1\L$2/;
    
    eval "require $class" or croak "Failed to load database backend: $class";
    set_backend( $class->new( @_ ) );
}

sub connect
{
    croak "No database configured" unless ($backend);
    return $backend->connect(@_);
}

sub disconnect
{
    return $backend->disconnect(@_) if ($backend);
}

sub finish_all
{
    return $backend->finish_all(@_) if ($backend);
}

sub do
{
    croak "No database configured" unless ($backend);
    return $backend->do(@_);
}

sub without_foreign_keys(&)
{
    croak "No database configured" unless ($backend);
    return $backend->without_foreign_keys(@_);
}

sub prepare
{
    croak "No database configured" unless ($backend);
    return $backend->prepare(@_);
}

sub describe
{
    croak "No database configured" unless ($backend);
    return $backend->describe(@_);
}

sub tables
{
    croak "No database configured" unless ($backend);
    return $backend->tables(@_);
}

sub dbhostname
{
    croak "No database configured" unless ($backend);
    return $backend->dbhostname(@_);
}

sub fetchone_tables
{
    croak "No database configured" unless ($backend);
    return $backend->fetchone_tables(@_);
}

sub fetchall_tables
{
    croak "No database configured" unless ($backend);
    return $backend->fetchall_tables(@_);
}


1;

__DATA__ 

=head1 NAME

Pinwheel::Database

=head1 SYNOPSIS

    use Pinwheel::Database;

    my $sth = prepare('SELECT * FROM episodes');
    my $results = fetchall_tables($sth);

=head1 DESCRIPTION

C<set_connection> and C<connection> manage a single, persistent DBI connection
to a MySQL database.

TODO, an overview of the other routines.

=head1 ROUTINES

=over 4

=item set_connection(ARGS)

Sets the DBI connection arguments used by C<connect>.

=item connect()

Ensures the database connection is up, initialised, and ready for use.

If there was no previous connection, or the previous connection is dead, or
the previous connection was originally established >= 5 minutes ago, then a
new connection is made (first closing down any existing connection).

New connections are made using the arguments previously specified by
C<set_connection>.

After the connection is established, the following settings are applied:

        $dbh->do("SET time_zone='+00:00'");
        $dbh->do("SET names 'utf8'");
        $dbh->{unicode} = 1;

Finally, <connect> discovers the 'hostname' mysql variable and stores it in
C<$Pinwheel::Database::dbhostname>.

=item disconnect()

Ensures the database connection is down.

C<$Pinwheel::Database::dbhostname> is set to C<undef>.

=item finish_all()

Closes all the query handles for the database connections.

=item $sth = prepare($query[, $transient])

Prepares a query and returns the statement handle, connecting to the database
if required.

If the prepared statement cache already contains a statement handle for this
query, and that handle is idle, then it is returned.

Otherwise, C<connect> is called to ensure the database connection is up,
and the query is prepared.  The statement handle is stored in the cache,
unless C<$transient> is true.  Then the statement handle is returned.

=item $fields = describe($table_name)

Retrieves a list of the fields for the given table.

Returns a reference to a hash which might look like this:

  $fields = {
    'id' => { type => 'int(11)', null => 0 },
    'title' => { type => 'varchar(64)', null => 0 },
    'expires' => { type => 'datetime', null => 1 },
  }

The keys are the column names, 'type' is the MySQL column type, and 'null' is
boolean.

=item tables()

Returns an array of the names of the tables in the database.

=item dbhostname()

Return the hostname of the database server.

=item without_foreign_keys(BLOCK)

Runs BLOCK in a separate database transaction.  Foreign key constraints are
disabled at the start of the transaction, and re-enabled at the end.

=item fetchone_tables($sth[, $tables])

TODO, document me.

=item fetchall_tables($sth[, $tables])

TODO, document me.

=back

=head1 EXPORTS

Nothing is exported by default.  The following can be exported:

    set_connection
    connect
    dbhostname
    describe
    disconnect
    do
    fetchall_tables
    fetchone_tables
    finish_all
    prepare
    tables
    without_foreign_keys

=head1 BUGS

C<set_connection> doesn't take a deep copy of its arguments.

The 300 second threshold in C<connect> is hard-wired.

=head1 AUTHOR

A&M Network Publishing <DLAMNetPub@bbc.co.uk>

=cut

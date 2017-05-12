package Pg::DatabaseManager;
$Pg::DatabaseManager::VERSION = '0.06';
use Moose;

use autodie;
use namespace::autoclean;

use DBI;
use File::Slurp qw( read_file );
use File::Spec;
use List::AllUtils qw( first );
use MooseX::Types::Moose qw( ArrayRef Bool Int Maybe Str );
use MooseX::Types::Path::Class qw( Dir File );
use Path::Class qw( dir file );
use Pg::CLI::pg_config;
use Pg::CLI::pg_dump;
use Pg::CLI::psql;

use MooseX::StrictConstructor;

with 'MooseX::Getopt::Dashes';

has db_name => (
    is            => 'rw',
    writer        => '_set_db_name',
    isa           => Str,
    required      => 1,
    documentation => 'The name of the database to drop, create, or update. Required.',
);

has app_name => (
    traits  => ['NoGetopt'],
    is      => 'rw',
    isa     => Str,
    lazy    => 1,
    default => sub { $_[0]->db_name() },
);

has db_owner => (
    is  => 'rw',
    isa => Str,
    documentation =>
        'The name of the database owner. Defaults to the connection username.',
);

has db_encoding => (
    is        => 'rw',
    isa       => Str,
    predicate => '_has_db_encoding',
    documentation =>
        'The name of the database owner. Defaults to the connection username.',
);

for my $attr (qw( username password host port )) {
    has $attr => (
        is            => 'rw',
        writer        => '_set_' . $attr,
        isa           => Str,
        predicate     => '_has_' . $attr,
        documentation => "The $attr used when connecting to the database. Optional.",
    );
}

has ssl => (
    is      => 'ro',
    isa     => Bool,
    default => 0,
    documentation =>
        'If this is true then SSL will be required when connecting to the database.',
);

has _db_exists => (
    is      => 'ro',
    isa     => Bool,
    lazy    => 1,
    builder => '_build_db_exists',
);

has sql_file => (
    is            => 'ro',
    isa           => File,
    coerce        => 1,
    lazy          => 1,
    builder       => '_build_sql_file',
    documentation => 'The file containing DDL to create the database. Required unless provided by a subclass.',
);

has contrib_files => (
    is      => 'ro',
    isa     => ArrayRef [Str],
    default => sub { [] },
    documentation =>
        'The name of contrib files (citext.sql, pgxml.sql) to load when creating the database. Optional.',
);

has version_table => (
    is      => 'ro',
    isa     => Str,
    default => 'Version',
    documentation =>
        'The name of the table which contains the database version. Defaults to Version.',
);

has migrations_dir => (
    is      => 'ro',
    isa     => Dir,
    lazy    => 1,
    builder => '_build_migrations_dir',
    documentation =>
        'The directory which contains migrations. Required unless provided by a subclass.',
);

has drop => (
    is      => 'ro',
    isa     => Bool,
    default => 0,
    documentation =>
        'If set, this will cause an existing database to be dropped.',
);

has quiet => (
    is      => 'ro',
    isa     => Bool,
    default => 0,
    documentation =>
        'If set, this suppresses any output from this code.',
);

has _installed_version => (
    is      => 'ro',
    isa     => Maybe[Int],
    init_arg => undef,
    lazy     => 1,
    builder  => '_build_installed_version',
);

has _psql => (
    is       => 'ro',
    isa      => 'Pg::CLI::psql',
    init_arg => undef,
    lazy     => 1,
    builder  => '_build_psql',
);

has _pg_dump => (
    is       => 'ro',
    isa      => 'Pg::CLI::pg_dump',
    init_arg => undef,
    lazy     => 1,
    builder  => '_build_pg_dump',
);

has _pg_config => (
    is       => 'ro',
    isa      => 'Pg::CLI::pg_config',
    init_arg => undef,
    lazy     => 1,
    default  => sub { Pg::CLI::pg_config->new() },
);

sub update_or_install_db {
    my $self = shift;

    die $self->_connect_failure_message()
        unless $self->_can_connect();

    print "\n" unless $self->quiet();

    $self->_drop_db() if $self->drop();

    if ( !defined $self->_installed_version() ) {
        $self->_create_db();
        $self->_run_sql_file();
    }
    else {
        $self->_maybe_migrate_db();
    }
}

sub _maybe_migrate_db {
    my $self = shift;

    my $version      = $self->_installed_version();
    my $next_version = $self->_get_next_version();

    if ( $version == $next_version ) {
        $self->_msg(
            'Your %{app_name} database is up-to-date (database name = %{db_name}).'
        );
        return;
    }

    $self->_msg(
        'Migrating your %{app_name} database from version $version to $next_version.'
    );

    $self->_migrate_db( $version, $next_version );
}

sub _can_connect {
    my $self = shift;

    my $dsn = $self->_make_dsn('template1');

    DBI->connect(
        $dsn, $self->username(), $self->password(),
        { PrintError => 0, PrintWarn => 0 },
    );
}

sub _connect_failure_message {
    my $self = shift;

    my $msg
        = "\n  Cannot connect to Postgres with the connection info provided:\n\n";
    $msg .= sprintf( "    %13s = %s\n", 'database name', $self->db_name() );

    for my $key (qw( username password host port )) {
        my $val = $self->$key();
        next unless defined $val;

        $msg .= sprintf( "  %13s = %s\n", $key, $val );
    }

    $msg .= sprintf(
        "  %13s = %s\n", 'ssl',
        $self->ssl() ? 'required' : 'not required'
    );

    return $msg;
}

sub _build_db_exists {
    my $self = shift;

    eval { $self->_make_dbh() } && return 1;

    die $@ if $@ and $@ !~ /database "\w+" does not exist/;

    return 0;
}

sub _build_sql_file {
    die 'Cannot determine your sql file'
        . '- either pass this to the constructor'
        . 'or subclass this module and override _build_sql_file';
}

sub _build_migrations_dir {
    die 'Cannot determine your migrations directory'
        . '- either pass this to the constructor'
        . 'or subclass this module and override _build_migrations_dir';
}

sub _build_psql {
    my $self = shift;

    return Pg::CLI::psql->new( $self->_pg_cli_params() );
}

sub _build_pg_dump {
    my $self = shift;

    return Pg::CLI::pg_dump->new( $self->_pg_cli_params() );
}

sub _pg_cli_params {
    my $self = shift;

    my %p = map {
        my $pred = '_has_' . $_;
        $self->$pred() ? ( $_ => $self->$_() ) : ()
    } qw( username password host port );

    return (
        %p,
        require_ssl => $self->ssl(),
        quiet       => 1,
    );
}

sub _build_installed_version {
    my $self = shift;

    my $dbh = eval { $self->_make_dbh() }
        or return;

    my $row = eval {
        $dbh->selectrow_arrayref( q{SELECT version FROM }
                . $dbh->quote_identifier( $self->version_table() ) );
    };

    return $row->[0] if $row;
}

sub _make_dbh {
    my $self = shift;

    my $dsn = $self->_make_dsn(@_);

    return DBI->connect(
        $dsn,
        $self->username(),
        $self->password(), {
            RaiseError         => 1,
            PrintError         => 0,
            PrintWarn          => 1,
            ShowErrorStatement => 1,
        }
    );
}

sub _make_dsn {
    my $self = shift;
    my $name = shift || $self->db_name();

    my $dsn = 'dbi:Pg:dbname=' . $name;

    $dsn .= ';host=' . $self->host()
        if defined $self->host();

    $dsn .= ';port=' . $self->port()
        if defined $self->port();

    $dsn .= ';sslmode=require'
        if $self->ssl();

    return $dsn;
}

sub _get_next_version {
    my $self = shift;

    my $file = $self->sql_file();

    my $dbh   = $self->_make_dbh('template1');
    my $table = $dbh->quote_identifier( $self->version_table() );

    my ($version_insert)
        = grep {/INSERT INTO \Q$table/} read_file( $file->stringify() );

    my ($next_version) = $version_insert =~ /VALUES \((\d+)\)/;

    die "Cannot find a version in the sql file!"
        unless $next_version;

    return $next_version;
}

sub _drop_db {
    my $self = shift;

    return unless $self->_db_exists();

    $self->_msg(
        'Dropping the %{app_name} database (database name = %{db_name})');

    my $db_name  = $self->db_name();

    $self->_psql->run(
        database => 'template1',
        options  => [ '-c', qq{DROP DATABASE "$db_name"} ],
    );
}

sub _create_db {
    my $self = shift;

    my $db_name = $self->db_name();

    $self->_msg(
        'Creating the %{app_name} database (database name = %{db_name})');

    my $command = qq{CREATE DATABASE "$db_name"};
    $command .= q{ ENCODING '} . $self->db_encoding() . q{'}
        if $self->_has_db_encoding();

    my $owner = first {defined} $self->db_owner(), $self->username();
    $command .= ' OWNER ' . $owner if defined $owner;

    $self->_psql->run(
        database => 'template1',
        options  => [ '-c', $command ],
    );
}

sub _run_sql_file {
    my $self = shift;

    my $file = $self->sql_file();

    $self->import_contrib_file($_) for @{ $self->contrib_files() };

    $self->_msg("Running SQL in $file");

    $self->_psql->execute_file(
        database => $self->db_name(),
        file     => $file,
    );
}

sub import_contrib_file {
    my $self     = shift;
    my $filename = shift;

    my $config = Pg::CLI::pg_config->new();

    my $file = file( $config->sharedir(), 'contrib', $filename );

    unless ( -f $file ) {
        die "Cannot find $filename in your share dir - looked for $file";
    }

    $self->_msg("Importing contrib file: $filename");

    $self->_psql()->execute_file(
        database => $self->db_name(),
        file     => $file,
    );
}

sub _migrate_db {
    my $self         = shift;
    my $from_version = shift;
    my $to_version   = shift;
    my $skip_dump    = shift;

    $self->_dump_db() unless $skip_dump;

    $self->_run_migrations_for_version($_)
        for ( $from_version + 1 ) .. $to_version;
}

sub _dump_db {
    my $self = shift;

    my $tmp_file = dir(
        File::Spec->tmpdir(),
        $self->db_name() . "-db-dump-$$.sql"
    );

    $self->_msg(
        "Dumping %{app_name} database to $tmp_file before running migrations");

    $self->_pg_dump()->run(
        database => $self->db_name(),
        options  => [
            '-C',
            '-f', $tmp_file->stringify()
        ],
    );
}

sub _run_migrations_for_version {
    my $self    = shift;
    my $version = shift;

    $self->_msg("Running database migration scripts to version $version");

    my $dir = $self->migrations_dir()->subdir($version);
    unless ( -d $dir ) {
        warn "No migration direction for version $version (looked for $dir)!";
        return;
    }

    my @files = sort grep { !$_->is_dir() } $dir->children();
    unless (@files) {
        warn "Migration directory exists but is empty ($dir)";
        return;
    }

    for my $file (@files) {
        $self->_msg("  running $file");

        if ( $file =~ /\.sql/ ) {
            $self->_psql()->execute_file(
                database => $self->db_name(),
                file     => $file,
            );
        }
        else {
            my $perl = read_file( $file->stringify() );

            my $sub = eval $perl;
            die $@ if $@;

            $sub->($self);
        }
    }
}

sub _msg {
    my $self = shift;

    return if $self->quiet();

    my $msg = shift;

    $msg =~ s/\%\{app_name\}/$self->app_name()/eg;
    $msg =~ s/\%\{db_name\}/$self->db_name()/eg;

    print "  $msg\n\n";
}

__PACKAGE__->meta()->make_immutable();

1;

# ABSTRACT: Manage installation and migration of an application's (Postgres) database

__END__

=pod

=encoding UTF-8

=head1 NAME

Pg::DatabaseManager - Manage installation and migration of an application's (Postgres) database

=head1 VERSION

version 0.06

=head1 SYNOPSIS

  use Pg::DatabaseManager;

  Pg::DatabaseManager->new_with_options()->update_or_install_db();

or subclass it ...

  package MyApp::DatabaseManager;

  use Moose;

  extends 'Pg::DatabaseManager';

  has '+app_name' => ( default => 'MyApp' );

  has '+contrib_files' => ( default => [ 'citext.sql' ] );

=head1 DESCRIPTION

This class provides an object which can be used to drop, create, and migrate
an application's Postgres database.

It uses L<MooseX::Getopt> so that it can be invoked easily from a command-line
script, but it is also designed to be usable from another module.

=head1 THE VERSION TABLE

In order to perform migrations, your application database must define a table
to store the database version. By default, this class expects this table to be
named "Version", but you can override this by setting the appropriate
attribute.

However, the structure of the table is fixed, and must look like this:

  CREATE TABLE "Version" (
      version  INTEGER  PRIMARY KEY
  );

This table should never contain more than one row (for obvious reasons).

You must include the version table in your database SQL DDL file.

You must I<also> include a single line which inserts the current database
version into this table:

  INSERT INTO "Version" (version) VALUES (6);

This class will parse the database SQL file to find this line in order to
determine the current database version.

=head1 MIGRATIONS

Migrations are defined in their own directory. That directory in turn contains
one directory per database version (except version 1). The per-version
directories should each contain one or more files. The files will be executed
in the order that Perl's C<sort> returns them. You can number them
(F<01-do-x.sql>, F<02-do-y.sql>) to ensure a clear ordering.

The files can either contain SQL or Perl code. Any file ending in ".sql" is
assumed to contain SQL (duh) and is executed using the F<psql> utility.

Otherwise, the file should contain Perl code which defines an anonymous
subroutine. That subroutine will be called with the C<Pg::DatabaseManager>
object as its only argument.

Allowing Perl migration files lets you do things like import contrib SQL files
as part of a migration, for example:

  {
      use strict;
      use warnings;

      return sub {
          my $manager = shift;
          $manager->import_contrib_file('citext.sql');
      };
  }

This is the entire migration file.

This module always dumps the existing database (with data) to a file in the
temp directory before running migrations.

=head2 Testing Migrations

See the L<Pg::DatabaseManager::TestMigrations> module for a tool which you can
use to test your migrations as part of your test suite.

=head1 METHODS

This class provides the following methods:

=head2 Pg::DatabaseManager->new( ... )

This method accepts the following parameters:

=over 4

=item * db_name

The name of the database that this object will work with. Required.

=item * app_name

The name of the application that this database is for. This is only used in
informational messages. It defaults to the same value as C<db_name>.

It cannot be set from the command line.

=item * db_owner

The name of the database owner, which will be used when the database is
created. Optional.

=item * db_encoding

The encoding to use when the database is created. Optional.

=item * username

=item * password

=item * host

=item * port

These are connection parameters to be used when dropping, creating, or
modifying the database. All parameters are optional.

Note that the username will be used as the database owner if it is provided
but C<db_owner> is not.

=item * ssl

If this is true, then connecting to the database server will require an SSL
connection.

=item * sql_file

The SQL file that contains the DDL to create the database.

This file I<must not> contain C<DROP DATABASE> or C<CREATE DATABASE>
statements. Those actions will be taken care of by this code. Required.

=item * contrib_files

This is an array reference of contrib file I<names> like F<citext.sql> or
F<pgxml.sql>. These files will be loaded after creating the database, but
before running the DDL in the C<sql_file>. Optional.

=item * version_table

The name of the table which contains the database version. See L</THE VERSION
TABLE> for details. Defaults to "Version">

=item * migrations_dir

The directory which contains migrations for the database. This is required,
but the directory can be empty. However, if the database needs to be migrated
from one version to another, it expects to find migrations for every
appropriate version in this directory.

=item * drop

If this is true, then the database will be dropped and then recreated.

=item * quiet

Setting this to true suppresses any output from this module.

=back

=head2 $manager->update_or_install_db()

This is the one public "do it" method. It will update or install the database
as needed. If the drop parameter was true, then it will drop any existing
database first, meaning it will always install a new database from scratch.

This method tests whether it can connect to the database server's template1
database, and dies if it cannot connect.

=head2 $manager->import_contrib_file( $file )

Given a contrib file name such as "citext.sql" or "pgxml.sql", this method
finds the file and imports it into the database. If it cannot find the named
file, it dies.

=head1 SUBCLASSING

This module is designed to be subclassed. In particular, it may make sense for
a subclass to provide defaults for various attributes. Please see
C<Silki::DatabaseManager> in the L<Silki> distribution's F<inc> dir for an
example.

In future versions of this module, I plan to document more of the internals as
a stable subclassing interface. For now, if you subclass this module, please
let me know what parts of the interface you overrode.

=head1 BUGS

Please report any bugs or feature requests to
C<bug-pg-databasemanager@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.  I will be notified, and then you'll automatically be
notified of progress on your bug as I make changes.

=head1 DONATIONS

If you'd like to thank me for the work I've done on this module, please
consider making a "donation" to me via PayPal. I spend a lot of free time
creating free software, and would appreciate any support you'd care to offer.

Please note that B<I am not suggesting that you must do this> in order for me
to continue working on this particular software. I will continue to do so,
inasmuch as I have in the past, for as long as it interests me.

Similarly, a donation made in this way will probably not make me work on this
software much more, unless I get so many donations that I can consider working
on free software full time, which seems unlikely at best.

To donate, log into PayPal and send money to autarch@urth.org or use the
button on this page: L<http://www.urth.org/~autarch/fs-donation.html>

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by Dave Rolsky.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

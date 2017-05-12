package Test::Database::Driver;
$Test::Database::Driver::VERSION = '1.113';
use strict;
use warnings;
use Carp;
use File::Spec;
use File::Path;
use version;
use YAML::Tiny qw( LoadFile DumpFile );
use Cwd;

use Test::Database::Handle;

#
# GLOBAL CONFIGURATION
#

# the location where all drivers-related files will be stored
my $KEY   = '';
my $login = getlogin() || getpwuid($<);
$login =~ s/\W+//g;
my $root  = File::Spec->rel2abs(
    File::Spec->catdir( File::Spec->tmpdir(), "Test-Database-$login" ) );

# generic driver class initialisation
sub __init {
    my ($class) = @_;

    # create directory if needed
    my $dir = $class->base_dir();
    if ( !-e $dir ) {
        mkpath( [$dir] );
    }
    elsif ( !-d $dir ) {
        croak "$dir is not a directory. Initializing $class failed";
    }

    # load the DBI driver (may die)
    DBI->install_driver( $class->name() );
}

#
# METHODS
#
sub new {
    my ( $class, %args ) = @_;

    if ( $class eq __PACKAGE__ ) {
        if ( exists $args{driver_dsn} ) {
            my ( $scheme, $driver, $attr_string, $attr_hash, $driver_dsn )
                = DBI->parse_dsn( $args{driver_dsn} );
            $args{dbd} = $driver;
        }
        croak "dbd or driver_dsn parameter required" if !exists $args{dbd};
        eval "require Test::Database::Driver::$args{dbd}"
            or do { $@ =~ s/ at .*?\z//s; croak $@; };
        $class = "Test::Database::Driver::$args{dbd}";
        $class->__init();
    }

    my $self = bless {
        %args,
        dbd => $class->name() || $args{dbd},
        },
        $class;

    $self->_load_mapping();

    # try to connect before returning the object
    if ( !$class->is_filebased() ) {
        eval {
            DBI->connect_cached( $self->connection_info(),
                { PrintError => 0 } );
        } or return;
    }

    return $self;
}

sub _mapping_file {
    return File::Spec->catfile( $_[0]->base_dir(), 'mapping.yml' );
}

sub available_dbname {
    my ($self) = @_;
    my $name = $self->_basename();
    my %taken = map { $_ => 1 } $self->databases();
    my $n = 0;
    $n++ while $taken{"$name$n"};
    return "$name$n";
}

sub _load_mapping {
    my ($self, $file)= @_;
    $file = $self->_mapping_file() if ! defined $file;

    # basic mapping info
    $self->{mapping} = {};
    return if !-e $file;

    # load mapping from file
    my $mapping = LoadFile( $file );
    $self->{mapping} = $mapping->{$self->driver_dsn()} || {};

    # remove stale entries
    $self->_save_mapping( $file ) if $self->_check_mapping();
}

sub _save_mapping {
    my ($self, $file )= @_;
    $file = $self->_mapping_file() if ! defined $file;

    # update mapping information
    my $mapping = {};
    $mapping = LoadFile( $file ) if -e $file;
    $mapping->{ $self->driver_dsn() } = $self->{mapping};

    # save mapping information
    DumpFile( "$file.tmp", $mapping );
    rename "$file.tmp", $file
        or croak "Can't rename $file.tmp to $file: $!";
}

sub _check_mapping {
    my ($self) = @_;
    my $mapping = $self->{mapping};
    my %database = map { $_ => undef } $self->databases();
    my $updated;

    # check that all databases in the mapping exist
    for my $cwd ( keys %$mapping ) {
        if ( !exists $database{ $mapping->{$cwd} } ) {
            delete $mapping->{$cwd};
            $updated++;
        }
    }
    return $updated;
}

sub make_dsn {
    my ($self, @args, @pairs) = @_;

    push @pairs, join '=', splice @args, 0, 2 while @args;

    my $dsn = $self->driver_dsn();
    return $dsn
        . ( $dsn =~ /^dbi:[^:]+:$/ ? '' : ';' )
        . join( ';', @pairs  );
}

sub make_handle {
    my ($self) = @_;
    my $handle;

    # get the database name from the mapping
    my $dbname = $self->{mapping}{ cwd() };

    # if the database still exists, return it
    if ( $dbname && grep { $_ eq $dbname } $self->databases() ) {
        $handle = Test::Database::Handle->new(
            dsn      => $self->dsn($dbname),
            username => $self->username(),
            password => $self->password(),
            name     => $dbname,
            driver   => $self,
        );
    }

    # otherwise create the database and update the mapper
    else {
        $handle = $self->create_database();
        $self->{mapping}{ cwd() } = $handle->{name};
        $self->_save_mapping();
    }

    return $handle;
}

sub version_matches {
    my ( $self, $request ) = @_;

    # string tests
    my $version_string = $self->version_string();
    return
        if exists $request->{version}
            && $version_string ne $request->{version};
    return
        if exists $request->{regex_version}
            && $version_string !~ $request->{regex_version};

    # numeric tests
    my $version = $self->version();
    return
        if exists $request->{min_version}
            && $version < $request->{min_version};
    return
        if exists $request->{max_version}
            && $version >= $request->{max_version};

    return 1;
}

#
# ACCESSORS
#
sub name { return ( $_[0] =~ /^Test::Database::Driver::([:\w]*)/g )[0]; }
*dbd = \&name;

sub base_dir {
    my ($self) = @_;
    my $class = ref $self || $self;
    return $root if $class eq __PACKAGE__;
    my $dir = File::Spec->catdir( $root, $class->name() );
    return $dir if !ref $self;    # class method
    return $self->{base_dir} ||= $dir;    # may be overriden in new()
}

sub version {
    no warnings;
    return $_[0]{version}
        ||= version->new( $_[0]->_version() =~ /^([0-9._]*[0-9])/ );
}

sub version_string {
    return $_[0]{version_string} ||= $_[0]->_version();
}

sub dbd_version { return "DBD::$_[0]{dbd}"->VERSION; }

sub driver_dsn { return $_[0]{driver_dsn} ||= $_[0]->_driver_dsn() }
sub username { return $_[0]{username} }
sub password { return $_[0]{password} }

sub connection_info {
    return ( $_[0]->driver_dsn(), $_[0]->username(), $_[0]->password() );
}

# THESE MUST BE IMPLEMENTED IN THE DERIVED CLASSES
sub drop_database { die "$_[0] doesn't have a drop_database() method\n" }
sub _version      { die "$_[0] doesn't have a _version() method\n" }

# create_database creates the database and returns a handle
sub create_database {
    my $class = ref $_[0] || $_[0];
    goto &_filebased_create_database if $class->is_filebased();
    die "$class doesn't have a create_database() method\n";
}

sub databases {
    goto &_filebased_databases if $_[0]->is_filebased();
    die "$_[0] doesn't have a databases() method\n";
}

# THESE MAY BE OVERRIDDEN IN THE DERIVED CLASSES
sub is_filebased {0}
sub _driver_dsn    { join ':', 'dbi', $_[0]->name(), ''; }

sub dsn {
    my ( $self, $dbname ) = @_;
    return $self->make_dsn( database => $dbname );
}

#
# PRIVATE METHODS
#
sub _set_key {
    $KEY = $_[1] || '';
    croak "Invalid format for key '$KEY'" if $KEY !~ /^\w*$/;
}

sub _basename {
    lc join '_', 'TDD', $_[0]->name(), $login, ( $KEY ? $KEY : (), '' );
}

# generic implementations for file-based drivers
sub _filebased_databases {
    my ($self)   = @_;
    my $dir      = $self->base_dir();
    my $basename = qr/^@{[$self->_basename()]}/;

    opendir my $dh, $dir or croak "Can't open directory $dir for reading: $!";
    my @databases = grep {/$basename/} File::Spec->no_upwards( readdir($dh) );
    closedir $dh;

    return @databases;
}

sub _filebased_create_database {
    my ( $self ) = @_;
    my $dbname = $self->available_dbname();

    return Test::Database::Handle->new(
        dsn    => $self->dsn($dbname),
        name   => $dbname,
        driver => $self,
    );
}

'CONNECTION';

__END__

=head1 NAME

Test::Database::Driver - Base class for Test::Database drivers

=head1 SYNOPSIS

    package Test::Database::Driver::MyDatabase;
    use strict;
    use warnings;

    use Test::Database::Driver;
    our @ISA = qw( Test::Database::Driver );

    sub _version {
        my ($class) = @_;
        ...;
        return $version;
    }

    sub create_database {
        my ( $self ) = @_;
        ...;
        return $handle;
    }

    sub drop_database {
        my ( $self, $name ) = @_;
        ...;
    }

    sub databases {
        my ($self) = @_;
        ...;
        return @databases;
    }

=head1 DESCRIPTION

Test::Database::Driver is a base class for creating L<Test::Database>
drivers.

=head1 METHODS

The class provides the following methods:

=head2 new

    my $driver = Test::Database::Driver->new( driver => 'SQLite' );

    my $driver = Test::Database::Driver::SQLite->new();

Create a new Test::Database::Driver object.

If called as C<< Test::Database::Driver->new() >>, requires a C<driver>
parameter to define the actual object class.

=head2 make_handle

    my $handle = $driver->make_handle();

Create a new L<Test::Database::Handle> object, attached to an existing database
or to a newly created one.

The decision whether to create a new database or not is made by
Test::Database::Driver based on the information in the mapper.
See L<TEMPORARY STORAGE ORGANIZATION> for details.

=head2 make_dsn

    my $dsn = $driver->make_dsn( %args )

Return a Data Source Name based on the driver's DSN, with the key/value
pairs contained in C<%args> as additional parameters.

This is typically used by C<dsn()> to make a DSN for a specific database,
based on the driver's DSN.

=head2 name

=head2 dbd

    my $name = $driver->dbd;

The driver's short name (everything after C<Test::Database::Driver::>).

=head2 base_dir

    my $dir = $driver->base_dir;

The directory where the driver should store all the files for its databases,
if needed. Typically used by file-based database drivers.

=head2 version

    my $db_version = $driver->version;

C<version> object representing the version of the underlying database enginge.
This object is build with the return value of C<_version()>.

=head2 version_string

    my $db_version = $driver->version_string;

Version string representing the version of the underlying database enginge.
This string is the actual return value of C<_version()>.

=head2 dbd_version

    my $dbd_version = $driver->dbd_version;

The version of the DBD used to connect to the database engine, as returned
by C<VERSION()>.

=head2 driver_dsn

    my $dsn = $driver->driver_dsn;

Return a driver Data Source Name, sufficient to connect to the database
engine without specifying an actual database.

=head2 username

    my $username = $driver->username;

Return the connection username. Defaults to C<undef>.

=head2 password

    my $password = $driver->password;

Return the connection password. Defaults to C<undef>.

=head2 connection_info()

    my @info = $driver->connection_info;

Return the connection information triplet (C<driver_dsn>, C<username>,
C<password>).

=head2 version_matches

    if ( $driver->version_matches($request) ) {
        ...;
    }

Return a boolean indicating if the driver's version matches the version
constraints in the given request (see L<Test::Database> documentation's
section about requests).

=head1 METHODS FOR DRIVER AUTHORS

The class also provides a few helpful commands that may be useful for driver
authors:

=head2 available_dbname

    my $dbname = $self->available_dbname();

Return an unused database name that can be used to create a new database
for the driver.

=head2 dsn

    my $dns = $self->dsn( $dbname )

Build a Data Source Name for the database with the given C<$dbname>,
based on the driver's DSN.

=head1 WRITING A DRIVER FOR YOUR DATABASE OF CHOICE

The L<SYNOPSIS> contains a good template for writing a
Test::Database::Driver class.

Creating a driver requires writing the following methods:

=head2 _version

    my $version = $driver->_version;

Return the version of the underlying database engine.

=head2 create_database

    $driver->create_database( $name );

Create the database for the corresponding DBD driver.

Return a L<Test::Database::Handle> in case of success, and nothing in
case of failure to create the database.

=head2 drop_database( $name )

    $driver->drop_database( $name );

Drop the database named C<$name>.

=head1 OVERRIDABLE METHODS WHEN WRITING A DRIVER

Some methods have defaults implementations in Test::Database::Driver,
but those can be overridden in the derived class:

=head2 is_filebased

Return a boolean value indicating if the database engine is file-based
or not, i.e. if all the database information is stored in a file or a
directory, and no external database server is needed.

=head2 databases

    my @db = $driver->databases();

Return the names of all existing databases for this driver as a list
(the default implementation is only valid for file-based drivers).

=head1 TEMPORARY STORAGE ORGANIZATION

Subclasses of Test::Database::Driver store useful information
in the system's temporary directory, under a directory named
F<Test-Database-$user> (C<$user> being the current user's name).

That directory contains the following files:

=over 4

=item database files

The database files and directories created by file-based drivers
controlled by L<Test::Database> are stored here, under names matching
F<tdd_B<DRIVER>_B<N>>, where B<DRIVER> is the lowercased name of the
driver and B<N> is a number.

=item the F<mapping.yml> file

A YAML file containing a C<cwd()> / database name mapping, to enable a
given test suite to receive the same database handles in all the test
scripts that call the C<< Test::Database->handles() >> method.

=back

=head1 AUTHOR

Philippe Bruhat (BooK), C<< <book@cpan.org> >>

=head1 COPYRIGHT

Copyright 2008-2010 Philippe Bruhat (BooK), all rights reserved.

=head1 LICENSE

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut


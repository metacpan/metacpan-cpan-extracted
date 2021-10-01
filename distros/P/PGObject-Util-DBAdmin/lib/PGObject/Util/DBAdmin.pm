package PGObject::Util::DBAdmin;

use 5.010; # Uses // defined-or operator
use strict;
use warnings FATAL => 'all';

use Capture::Tiny 'capture';
use Carp;
use DBI;
use File::Temp;
use Log::Any;
use Scope::Guard qw(guard);

use Moo;
use namespace::clean;

=head1 NAME

PGObject::Util::DBAdmin - PostgreSQL Database Management Facilities for
PGObject

=head1 VERSION

version 1.5.0

=cut

our $VERSION = '1.5.0';


=head1 SYNOPSIS

This module provides an interface to the basic Postgres db manipulation
utilities.

 my $db = PGObject::Util::DBAdmin->new(
    connect_data => {
       user     => 'postgres',
       password => 'mypassword',
       host     => 'localhost',
       port     => '5432',
       dbname   => 'mydb'
    }
 );

 my @dbnames = $db->list_dbs(); # like psql -l

 $db->create(); # createdb
 $db->run_file(file => 'sql/initial_schema.sql'); # psql -f

 my $filename = $db->backup(format => 'c'); # pg_dump -Fc

 my $db2 = PGObject::Util::DBAdmin->new($db->export, (dbname => 'otherdb'));

 my $db3 = PGObject::Util::DBAdmin->new(
    connect_data => {
       service     => 'zephyr',
       sslmode     => 'require',
       sslkey      => "$HOME/.postgresql/postgresql.key",
       sslcert     => "$HOME/.postgresql/postgresql.crt",
       sslpassword => 'your-sslpassword',
    }
 );


=head1 PROPERTIES

=head2 connect_data

Contains a hash with connection parameters; see L<the PostgreSQL
documentation|https://www.postgresql.org/docs/current/libpq-connect.html#LIBPQ-PARAMKEYWORDS>
for supported parameters.

The usual parameters are:

=over

=item * user

=item * password

=item * dbname

=item * host

=item * port

=back

Please note that the key C<requiressl> is deprecated in favor of
C<sslmode> and isn't supported.

=cut

# Not supported
#  PGSERVICEFILE: (because no connect string equiv)
#  PGREQUIRESSL: deprecated
my %connkey_env = qw(
    host                     PGHOST
    hostaddr                 PGHOSTADDR
    dbname                   PGDATABASE
    user                     PGUSER
    password                 PGPASSWORD
    passfile                 PGPASSFILE
    channel_binding          PGCHANNELBINDING
    service                  PGSERVICE
    options                  PGOPTIONS
    sslmode                  PGSSLMODE
    sslcompression           PGSSLCOMPRESSION
    sslcert                  PGSSLCERT
    sslkey                   PGSSLKEY
    sslrootcert              PGSSLROOTCERT
    sslcrl                   PGSSLCRL
    requirepeer              PGREQUIREPEER
    ssl_min_protocol_version PGSSLMINPROTOCOLVERSION
    ssl_max_protocol_version PGSSLMAXPROTOCOLVERSION
    gssencmode               PGGSSENCMODE
    krbsrvname               PGKRBSRVNAME
    gsslib                   PGGSSLIB
    connect_timeout          PGCONNECT_TIMEOUT
    client_encoding          PGCLIENTENCODING
    target_session_attrs     PGTARGETSESSIONATTRS
    );
my @connstr_keys = ((grep { not ($_ eq 'user' or $_ eq 'password') }
                     keys %connkey_env),
                    qw(application_name fallback_application_name
                    keepalives keepalives_idle keepalives_interval
                    keepalives_count tcp_user_timeout replication sslpassword),
    );

sub _connect_data_env {
    my ($connect_data) = @_;
    my @keys = grep { exists $connkey_env{$_}
                      and defined $connect_data->{$_} } keys %$connect_data;
    return map { $connkey_env{$_} => $connect_data->{$_} } @keys;
}

sub _connect_data_str {
    my ($connect_data) = @_;
    my @keys = grep { defined $connect_data->{$_} } @connstr_keys;
    return join(';', map {
        my $val = $connect_data->{$_};
        $val =~ s/\\/\\\\/g;
        $val =~ s/'/\\'/g;
        "$_='$val'"; } @keys );
}

has connect_data => (is => 'ro');

=head2 username (deprecated)

The username used to authenticate with the PostgreSQL server.

=cut

has username => (is => 'ro');

=head2 password (deprecated)

The password used to authenticate with the PostgreSQL server.

=cut

has password => (is => 'ro');

=head2 host (deprecated)

In PostgreSQL, this can refer to the hostname or the absolute path to the
directory where the UNIX sockets are set up.

=cut

has host => (is => 'ro');

=head2 port (deprecated)

Default '5432'

=cut

has port => (is => 'ro');

=head2 dbname (deprecated)

The database name to create or connect to.

=cut

has dbname => (is => 'ro');

=head2 stderr

When applicable, the stderr output captured from any external commands (for
example createdb or pg_restore) run during the previous method call. See
notes in L</"CAPTURING">.

=cut

has stderr => (is => 'ro');

=head2 stdout

When applicable, the stdout output captured from any external commands (for
example createdb or pg_restore) run during the previous method call. See
notes in L</"CAPTURING">.

=cut

has stdout => (is => 'ro');

=head2 logger

Provides a reference to the logger associated with the current instance. The
logger uses C<ref $self> as its category, eliminating the need to create
new loggers when deriving from this class.

If you want to override the logger-instantiation behaviour, please implement
the C<_build_logger> builder method in your derived class.

=cut

has logger => (is => 'ro', lazy => 1, builder => '_build_logger');

sub _build_logger {
    return Log::Any->get_logger(category => ref $_[0]);
}


our %helpers =
    (
     create => [ qw/createdb/ ],
     run_file => [ qw/psql/ ],
     backup => [ qw/pg_dump/ ],
     backup_globals => [ qw/pg_dumpall/ ],
     restore => [ qw/pg_restore psql/ ],
     drop => [ qw/dropdb/ ],
    );

=head1 GLOBAL VARIABLES


=head2 %helper_paths

This hash variable contains as its keys the names of the PostgreSQL helper
executables C<psql>, C<dropdb>, C<pg_dump>, etc. The values contain the
paths at which the executables to be run are located. The default values
are the names of the executables only, allowing them to be looked up in
C<$PATH>.

Modification of the values in this variable are the strict realm of
I<applications>. Libraries using this library should defer potential
required modifications to the applications based upon them.

=cut

our %helper_paths =
    (
     psql => 'psql',
     dropdb => 'dropdb',
     createdb => 'createdb',
     pg_dump => 'pg_dump',
     pg_dumpall => 'pg_dumpall',
     pg_restore => 'pg_restore',
    );

sub _run_with_env {
    my %args = @_;
    my $env = $args{env};

    local %ENV = (
        # Note that we're intentionally *not* passing
        # PERL5LIB & PERL5OPT into the environment here!
        # doing so prevents the system settings to be used, which
        # we *do* want. If we don't, hopefully, that's coded into
        # the executables themselves.
        # Before using this whitelisting, coverage tests in LedgerSMB
        # would break on the bleeding through this caused.
        HOME => $ENV{HOME},
        PATH => $ENV{PATH},
        %{$env // {}},
        );

    return system @{$args{command}};
}

sub _run_command {
    my ($self, %args) = @_;
    my $exit_code;
    my %env = (
        # lowest priority: existing environment variables
        (map { $ENV{$_} ? ($_ => $ENV{$_})  : () }
         qw(PGUSER PGPASSWORD PGHOST PGPORT PGDATABASE PGSERVICE)),
        # overruled by middle priority: object connection parameters
        _connect_data_env($self->connect_data),
        # overruled by highest priority: specified environment
        ($args{env}   ? %{$args{env}} : ()),
        );
    $self->logger->debugf(
        sub {
            return 'Running with environment: '
                . join(' ', map { qq|$_="$env{$_}"| } keys %env );
        });

    # Any files created should be accessible only by the current user
    my $original_umask = umask 0077;
    {
        my $guard = guard { umask $original_umask; };

        ($self->{stdout}, $self->{stderr}, $exit_code) = capture {
            _run_with_env(%args, env => \%env);
        };
        if(defined ($args{errlog} // $args{stdout_log})) {
            $self->_write_log_files(%args);
        }
    }

    if ($exit_code != 0) {
        for my $filename (@{$args{unlink}}) {
            unlink $filename or carp "error unlinking '$filename': $!";
        }
        my $command = join( ' ', map { "'$_'" } @{$args{command}} );
        my $err;
        if ($? == -1) {
            $err = "$!";
        }
        elsif ($? & 127) {
            $err = sprintf('died with signal %d', ($? & 127));
        }
        else {
            $err = sprintf('exited with code %d', ($? >> 8));
        }
        croak "$args{error}; (command: $command): $err";
    }
    return 1;
}


sub _generate_output_filename {
    my ($self, %args) = @_;

    # If caller has supplied a file path, use that
    # rather than generating our own temp file.
    defined $args{file} and return $args{file};

    my %file_options = (UNLINK => 0);

    if(defined $args{tempdir}) {
        -d $args{tempdir}
            or croak "directory $args{tempdir} does not exist or is not a directory";
        $file_options{DIR} = $args{tempdir};
    }

    # File::Temp creates files with permissions 0600
    my $fh = File::Temp->new(%file_options)
        or croak "could not create temp file: $@, $!";

    return $fh->filename;
}


sub _write_log_files {
    my ($self, %args) = @_;

    defined $args{stdout_log} and $self->_append_to_file(
        $args{stdout_log},
        $self->{stdout},
    );

    defined $args{errlog} and $self->_append_to_file(
        $args{errlog},
        $self->{stderr},
    );

    return;
}


sub _append_to_file {
    my ($self, $filename, $data) = @_;

    open(my $fh, '>>', $filename)
        or croak "couldn't open file $filename for appending $!";

    print $fh ($data // '')
        or croak "failed writing to file $!";

    close $fh
        or croak "failed closing file $filename $!";

    return;
}



=head1 SUBROUTINES/METHODS

=head2 new

Creates a new db admin object for manipulating databases.

=head2 BUILDARGS

Compensates for the legacy invocation with the C<username>, C<password>,
C<host>, C<port> and C<dbname> parameters.

=head2 verify_helpers( [ helpers => [...]], [operations => [...]])

Verifies ability to execute (external) helper applications by
method name (through the C<operations> argument) or by external helper
name (through the C<helpers> argument). Returns a hash ref with each
key being the name of a helper application (see C<helpers> below) with
the values being a boolean indicating whether or not the helper can be
successfully executed.

Valid values in the array referenced by the C<operations> parameter are
C<create>, C<run_file>, C<backup>, C<backup_globals>, C<restore> and
C<drop>; the methods this module implements with the help of external
helper programs. (Other values may be passed, but unsupported values
aren't included in the return value.)

Valid values in the array referenced by the C<helpers> parameter are the
names of the PostgreSQL helper programs C<createdb>, C<dropdb>, C<pg_dump>,
C<pg_dumpall>, C<pg_restore> and C<psql>. (Other values may be passed, but
unsupported values will not be included in the return value.)

When no arguments are passed, all helpers will be tested.

Note: C<verify_helpers> is a class method, meaning it wants to be called
as C<PGObject::Util::DBAdmin->verify_helpers()>.

=cut

around 'BUILDARGS' => sub {
    my ($orig, $class, @args) = @_;

    ## 1.1.0 compatibility code (allow a reference to be passed in)
    my %args = (@args == 1 and ref $args[0]) ? (%{$args[0]}) : (@args);

    # deprecated field support code block
    if (exists $args{connect_data}) {
        # Work-around for 'export' creating the expectation that
        # parameters may be overridable; I've observed the pattern
        #  ...->new($db->export, (dbname => 'newdb'))
        # which we "solve" by hacking the dbname arg into the connect_data
        # Don't overwrite connect_data, because it may be used elsewhere...
        $args{connect_data} = {
            %{$args{connect_data}},
            dbname => ($args{dbname} // $args{connect_data}->{dbname})
        };

        # Now for legacy purposes hack the connection parameters into
        # connect_data
        $args{username} = $args{connect_data}->{user};
        $args{$_}       = $args{connect_data}->{$_} for (qw(password dbname
                                                         host port));
    }
    else {
        $args{connect_data}             = {};
        $args{connect_data}->{user}     = $args{username};
        $args{connect_data}->{password} = $args{password};
        $args{connect_data}->{dbname}   = $args{dbname};
        $args{connect_data}->{host}     = $args{host};
        $args{connect_data}->{port}     = $args{port};
    }
    return $class->$orig(%args);
};




sub _run_capturing_output {
    my @args = @_;
    my ($stdout, $stderr, $exitcode) = capture { _run_with_env(@args); };

    return $exitcode;
}

sub verify_helpers {
    my ($class, %args) = @_;

    my @helpers = (
        @{$args{helpers} // []},
        map { @{$helpers{$_} // []} } @{$args{operations} // []}
        );
    if (not @helpers) {
        @helpers = keys %helper_paths;
    }
    return {
        map {
            $_ => not _run_capturing_output(command =>
                                            [ $helper_paths{$_} , '--help' ])
        } @helpers
    };
}


=head2 export

Exports the database parameters as a list so it can be used to create another
object.

=cut

sub export {
    my $self = shift;
    return ( connect_data => $self->connect_data );
}

=head2 connect($options)

Connects to the database using DBI and returns a database connection.

Connection options may be specified in the $options hashref.

=cut

sub connect {
    my ($self, $options) = @_;

    my $connect = _connect_data_str($self->connect_data);
    my $dbh     = DBI->connect(
        'dbi:Pg:' . $connect,
        $self->connect_data->{user} // '',    # suppress use of DBI_USER
        $self->connect_data->{password} // '',# suppress use of DBI_PASS
        $options
    ) or croak 'Could not connect to database: ' . $DBI::errstr;

    return $dbh;
}

=head2 server_version([$dbname])

Returns a version string (like 9.1.4) for PostgreSQL. Croaks on error.

When a database name is specified, uses that database to connect to,
using the credentials specified in the instance.

If no database name is specified, 'template1' is used.

=cut

sub server_version {
    my $self = shift @_;
    my $dbname = (shift @_) || 'template1';
    my $version =
        __PACKAGE__->new($self->export, (dbname => $dbname)
        )->connect->{pg_server_version};

    my $retval = '';
    while (1) {
        $retval = ($version % 100) . $retval;
        $version = int($version / 100);

        return $retval unless $version;
        $retval = ".$retval";
    }
}


=head2 list_dbs([$dbname])

Returns a list of db names.

When a database name is specified, uses that database to connect to,
using the credentials specified in the instance.

If no database name is specified, 'template1' is used.

=cut

sub list_dbs {
    my $self = shift;
    my $dbname = (shift @_) || 'template1';

    return map { $_->[0] }
           @{ __PACKAGE__->new($self->export, (dbname => $dbname)
           )->connect->selectall_arrayref(
                 'SELECT datname from pg_database order by datname'
           ) };
}

=head2 create

Creates a new database.

Croaks on error, returns true on success.

Supported arguments:

=over

=item copy_of

Creates the new database as a copy of the specified one (using it as
a template). Optional parameter. Default is to create a database
without a template.

=back

=cut

sub create {
    my $self = shift;
    my %args = @_;

    my @command = ($helper_paths{createdb});
    defined $args{copy_of}  and push(@command, '-T', $args{copy_of});
    # No need to pass the database name PGDATABASE will be set
    #  if a 'dbname' connection parameter was provided

    $self->_run_command(command => [@command],
                        error   => 'error creating database');

    return 1;
}


=head2 run_file

Run the specified file on the db.

After calling this method, STDOUT and STDERR output from the external
utility which runs the file on the database are available as properties
$db->stdout and $db->stderr respectively.

Croaks on error. Returns true on success.

Recognized arguments are:

=over

=item file

Path to file to be run. This is a mandatory argument.

=item stdout_log

Provided for legacy compatibility. Optional argument. The full path of
a file to which STDOUT from the external psql utility will be appended.

=item errlog

Provided for legacy compatibility. Optional argument. The full path of
a file to which STDERR from the external psql utility will be appended.

=back

=cut

sub run_file {
    my ($self, %args) = @_;
    $self->{stderr} = undef;
    $self->{stdout} = undef;

    croak 'Must specify file' unless defined $args{file};
    croak 'Specified file does not exist' unless -e $args{file};

    # Build command
    my @command =
        ($helper_paths{psql}, '--set=ON_ERROR_STOP=on', '-f', $args{file});

    my $result = $self->_run_command(
        command    => [@command],
        errlog     => $args{errlog},
        stdout_log => $args{stdout_log},
        error      => "error running file '$args{file}'");

    return $result;
}


=head2 backup

Creates a database backup file.

After calling this method, STDOUT and STDERR output from the external
utility which runs the file on the database are available as properties
$db->stdout and $db->stderr respectively.

Unlinks the output file and croaks on error.

Returns the full path of the file containining the backup.

Accepted parameters:

=over

=item format

The specified format, for example c for custom.  Defaults to plain text.

=item file

Full path of the file to which the backup will be written. If the file
does not exist, one will be created with umask 0600. If the file exists,
it will be overwritten, but its permissions will not be changed.

If undefined, a file will be created using File::Temp having umask 0600.

=item tempdir

The directory in which to write the backup file. Optional parameter.  Uses
File::Temp default if not defined.  Ignored if file parameter is given.

=item compress

Optional parameter. Specifies the compression level to use and is passed to
the underlying pg_dump command. Default is no compression.

=back

=cut

sub backup {
    my ($self, %args) = @_;
    $self->{stderr} = undef;
    $self->{stdout} = undef;

    my $output_filename = $self->_generate_output_filename(%args);

    my @command = ($helper_paths{pg_dump}, '-f', $output_filename);
    defined $args{compress} and push(@command, '-Z', $args{compress});
    defined $args{format}   and push(@command, "-F$args{format}");

    $self->_run_command(command => [@command],
                        unlink  => [$output_filename],
                        error   => 'error running pg_dump command');

    return $output_filename;
}


=head2 backup_globals

This creates a file containing a plain text dump of global (inter-db)
objects, such as users and tablespaces.  It uses pg_dumpall to do this.

Being a plain text file, it can be restored using the run_file method.

Unlinks the output file and croaks on error.

Returns the full path of the file containining the backup.

Accepted parameters:

=over

=item file

Full path of the file to which the backup will be written. If the file
does not exist, one will be created with umask 0600. If the file exists,
it will be overwritten, but its permissions will not be changed.

If undefined, a file will be created using File::Temp having umask 0600.

=item tempdir

The directory in which to write the backup file. Optional parameter.  Uses
File::Temp default if not defined.  Ignored if file parameter is given.

=back

=cut

sub backup_globals {
    my ($self, %args) = @_;
    $self->{stderr} = undef;
    $self->{stdout} = undef;

    local $ENV{PGPASSWORD} = $self->password if defined $self->password;
    my $output_filename = $self->_generate_output_filename(%args);

    my @command = ($helper_paths{pg_dumpall}, '-g', '-f', $output_filename);

    $self->_run_command(command => [@command],
                        unlink  => [$output_filename],
                        error   => 'error running pg_dumpall command');

    return $output_filename;
}


=head2 restore

Restores from a saved file.  Must pass in the file name as a named argument.

After calling this method, STDOUT and STDERR output from the external
restore utility are available as properties $db->stdout and $db->stderr
respectively.

Croaks on error. Returns true on success.

Recognized arguments are:

=over

=item file

Path to file which will be restored to the database. Required.

=item format

The file format, for example c for custom.  Defaults to plain text.

=back

=cut

sub restore {
    my ($self, %args) = @_;
    $self->{stderr} = undef;
    $self->{stdout} = undef;

    croak 'Must specify file' unless defined $args{file};
    croak 'Specified file does not exist' unless -e $args{file};

    return $self->run_file(%args)
           if not defined $args{format} or $args{format} eq 'p';

    # Build command options
    my @command = ($helper_paths{pg_restore}, '--verbose', '--exit-on-error');
    defined $args{format}   and push(@command, "-F$args{format}");
    defined $self->connect_data->{dbname}   and
        push(@command, '-d', $self->connect_data->{dbname});
    push(@command, $args{file});

    $self->_run_command(command => [@command],
                        error   => "error restoring from $args{file}");

    return 1;
}


=head2 drop

Drops the database.  This is not recoverable. Croaks on error, returns
true on success.

=cut

sub drop {
    my ($self) = @_;

    croak 'No db name of this object' unless $self->dbname;

    my @command = ($helper_paths{dropdb});
    push(@command, $self->connect_data->{dbname});

    $self->_run_command(command => [@command],
                        error   => 'error dropping database');

    return 1;
}


=head1 CAPTURING

This module uses C<Capture::Tiny> to run extenal commands and capture their
output, which is made available through the C<stderr> and C<stdout>
properties.

This capturing does not work if Perl's standard C<STDOUT> or
C<STDERR> filehandles have been localized. In this situation, the localized
filehandles are captured, but external system calls are not
affected by the localization, so their output is sent to the original
filehandles and is not captured.

See the C<Capture::Tiny> documentation for more details.

=head1 AUTHOR

Chris Travers, C<< <chris at efficito.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-pgobject-util-dbadmin at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=PGObject-Util-DBAdmin>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc PGObject::Util::DBAdmin


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=PGObject-Util-DBAdmin>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/PGObject-Util-DBAdmin>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/PGObject-Util-DBAdmin>

=item * Search CPAN

L<http://search.cpan.org/dist/PGObject-Util-DBAdmin/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2014-2020 Chris Travers.

This program is distributed under the (Revised) BSD License:
L<http://www.opensource.org/licenses/BSD-3-Clause>

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions
are met:

* Redistributions of source code must retain the above copyright
notice, this list of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright
notice, this list of conditions and the following disclaimer in the
documentation and/or other materials provided with the distribution.

* Neither the name of Chris Travers's Organization
nor the names of its contributors may be used to endorse or promote
products derived from this software without specific prior written
permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
"AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of PGObject::Util::DBAdmin

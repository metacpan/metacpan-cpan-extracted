package PGObject::Util::DBAdmin;

use 5.010; # Uses // defined-or operator
use strict;
use warnings FATAL => 'all';

use Carp;
use DBI;
use File::Temp;
use IO::File;
use Capture::Tiny 'capture';
use Moo;
use namespace::clean;

=head1 NAME

PGObject::Util::DBAdmin - PostgreSQL Database Management Facilities for
PGObject

=head1 VERSION

Version 0.120.0

=cut

our $VERSION = '0.120.0';


=head1 SYNOPSIS

This module provides an interface to the basic Postgres db manipulation
utilities.

 my $db = PGObject::Util::DBAdmin->new(
    username => 'postgres',
    password => 'mypassword',
    host     => 'localhost',
    port     => '5432',
    dbname   => 'mydb'
 );

 my @dbnames = $db->list_dbs(); # like psql -l

 $db->create(); # createdb
 $db->run_file(file => 'sql/initial_schema.sql'); # psql -f

 my $filename = $db->backup(format => 'c'); # pg_dump -Fc

 my $db2 = PGObject::Util::DBAdmin->new($db->export, (dbname => 'otherdb'));

=head1 PROPERTIES

=head2 username

=cut

has username => (is => 'ro');

=head2 password

=cut

has password => (is => 'ro');

=head2 host

In PostgreSQL, this can refer to the hostname or the absolute path to the
directory where the UNIX sockets are set up.

=cut

has host => (is => 'ro');

=head2 port

Default '5432'

=cut

has port => (is => 'ro');

=head2 dbname

=cut

has dbname => (is => 'ro');

=head2 stderr

When applicable, the stderr output captured from any external commands (for
example createdb or pg_restore) run during the previous method call.

=cut

has stderr => (is => 'ro');

=head2 stdout

When applicable, the stdout output captured from any external commands (for
example createdb or pg_restore) run during the previous method call.

=cut

has stdout => (is => 'ro');


sub _run_command {
    my ($self, %args) = @_;

    my $exit_code;
    ($self->{stdout}, $self->{stderr}, $exit_code) = capture {
        system @{$args{command}};
    };

    if(defined ($args{errlog} // $args{stdout_log})) {
        $self->_write_log_files(%args);
    }

    if($exit_code != 0) {
        croak 'error running command';
    }

    return 1;
}


sub _run_command_to_file {
    my ($self, $output_fh, $output_filename, @command) = @_;

    my $exit_code;
    (undef, $self->{stderr}, $exit_code) = capture {
        system @command;
    } stdout => $output_fh;

    close $output_fh or $self->_unlink_file_and_croak(
        $output_filename,
        "Failed to close output file after writing $!"
    );

    ($exit_code == 0) or $self->_unlink_file_and_croak(
        $output_filename,
        'error running command'
    );

    return 1;
}


sub _unlink_file_and_croak {
    my ($self, $filename, $message) = @_;

    unlink $filename or carp "error unlinking $filename $!";
    croak $message;
}


sub _open_output_filehandle {
    my ($self, %args) = @_;

    # If caller has supplied a file path, use that
    # rather than generating our own temp file.
    if(defined $args{file}) {
        # If file already exists, we don't alter its permissions,
        # but new files are created with a mask of 0600 so they are
        # only readable and writeable by the user that creates them.
        #
        # capture requires that the file be seekable.
        #
        # Use sysopen so we can set permissions at time of creation.
        sysopen(my $fh, $args{file}, O_RDWR|O_CREAT, 0600)
            or croak "couldn't open file $args{file} for writing $!";

        return ($fh, $args{file});
    }

    my %file_options = (UNLINK => 0);

    if(defined $args{tempdir}) {
        -d $args{tempdir}
            or croak "directory $args{tempdir} does not exist or is not a directory";
        $file_options{DIR} = $args{tempdir};
    }

    # File::Temp creates files with permissions 0600
    my $fh = File::Temp->new(%file_options)
        or croak "could not create temp file: $@, $!";

    return ($fh, $fh->filename);
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

=head2 export

Exports the database parameters in a hash so it can be used to create another
object.

=cut

sub export {
    my $self = shift;
    return map {$_ => $self->$_() } qw(username password host port dbname)
}

=head2 connect($options)

Connects to the database using DBI and returns a database connection.

Connection options may be specified in the $options hashref.

=cut

sub connect {
    my ($self, $options) = @_;

    my $connect = 'dbname="' . $self->dbname . '"';

    $connect .= ';host=' . $self->host
        if defined $self->host;

    $connect .= ';port=' . $self->port
        if defined $self->port;

    my $dbh = DBI->connect(
        'dbi:Pg:' . $connect,
        $self->username,
        $self->password,
        $options
    ) or croak 'Could not connect to database!';

    return $dbh;
}

=head2 server_version

Returns a version string (like 9.1.4) for PostgreSQL. Croaks on error.

=cut

sub server_version {
    my $self = shift @_;
    my $version =
           __PACKAGE__->new($self->export, (dbname => 'template1')
                           )->connect->selectrow_array('SELECT version()');
    my ($retval) = $version =~ /(\d+\.\d+\.\d+)/
        or croak 'failed to extract version string';
    return $retval;
}


=head2 list_dbs

Returns a list of db names.

=cut

sub list_dbs {
    my $self = shift;

    return map { $_->[0] }
           @{ __PACKAGE__->new($self->export, (dbname => 'template1')
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

    local $ENV{PGPASSWORD} = $self->password if $self->password;

    my @command = ('createdb');
    defined $self->username and push(@command, '-U', $self->username);
    defined $args{copy_of}  and push(@command, '-T', $args{copy_of});
    defined $self->host     and push(@command, '-h', $self->host);
    defined $self->port     and push(@command, '-p', $self->port);
    defined $self->dbname   and push(@command, $self->dbname);

    return $self->_run_command(command => [@command]);
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

    local $ENV{PGPASSWORD} = $self->password if defined $self->password;

    # Build command
    my @command = ('psql', '--set=ON_ERROR_STOP=on', '-f', $args{file});
    defined $self->username and push(@command, '-U', $self->username);
    defined $self->host     and push(@command, '-h', $self->host);
    defined $self->port     and push(@command, '-p', $self->port);
    defined $self->dbname   and push(@command, $self->dbname);

    my $result = $self->_run_command(
        command    => [@command],
        errlog     => $args{errlog},
        stdout_log => $args{stdout_log},
    );

    return $result;
}


=head2 backup

Creates a database backup file.

After calling this method, STDERR output from the external pg_dump
utility is available as property $db->stderr.

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
File::Temp default if not defined.  Ignored if file paramter is given.

=back

=cut

sub backup {
    my ($self, %args) = @_;
    $self->{stderr} = undef;
    $self->{stdout} = undef;

    local $ENV{PGPASSWORD} = $self->password if defined $self->password;
    my ($output_fh, $output_filename) = $self->_open_output_filehandle(%args);

    my @command = ('pg_dump');
    defined $self->username and push(@command, '-U', $self->username);
    defined $self->host     and push(@command, '-h', $self->host);
    defined $self->port     and push(@command, '-p', $self->port);
    defined $args{format}   and push(@command, "-F$args{format}");
    defined $self->dbname   and push(@command, $self->dbname);

    $self->_run_command_to_file(
        $output_fh,
        $output_filename,
        @command
    );

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
File::Temp default if not defined.  Ignored if file paramter is given.

=back

=cut

sub backup_globals {
    my ($self, %args) = @_;
    $self->{stderr} = undef;
    $self->{stdout} = undef;

    local $ENV{PGPASSWORD} = $self->password if defined $self->password;
    my ($output_fh, $output_filename) = $self->_open_output_filehandle(%args);

    my @command = ('pg_dumpall', '-g');
    defined $self->username and push(@command, '-U', $self->username);
    defined $self->host     and push(@command, '-h', $self->host);
    defined $self->port     and push(@command, '-p', $self->port);

    $self->_run_command_to_file(
        $output_fh,
        $output_filename,
        @command
    );

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

    local $ENV{PGPASSWORD} = $self->password if defined $self->password;

    # Build command options
    my @command = ('pg_restore', '--verbose', '--exit-on-error');
    defined $self->dbname   and push(@command, '-d', $self->dbname);
    defined $self->username and push(@command, '-U', $self->username);
    defined $self->host     and push(@command, '-h', $self->host);
    defined $self->port     and push(@command, '-p', $self->port);
    defined $args{format}   and push(@command, "-F$args{format}");
    push(@command, $args{file});

    return $self->_run_command(command => [@command]);
}


=head2 drop

Drops the database.  This is not recoverable. Croaks on error, returns
true on success.

=cut

sub drop {
    my ($self) = @_;

    croak 'No db name of this object' unless $self->dbname;

    local $ENV{PGPASSWORD} = $self->password if $self->password;

    my @command = ('dropdb');
    defined $self->username and push(@command, '-U', $self->username);
    defined $self->host     and push(@command, '-h', $self->host);
    defined $self->port     and push(@command, '-p', $self->port);
    push(@command, $self->dbname);

    return $self->_run_command(command => [@command]);
}


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

Copyright 2014-2018 Chris Travers.

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

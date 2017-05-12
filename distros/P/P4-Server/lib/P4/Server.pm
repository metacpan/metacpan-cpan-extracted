# Copyright (C) 2007-8 Stephen Vance
# 
# This library is free software; you can redistribute it and/or
# modify it under the terms of the Perl Artistic License.
# 
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the Perl
# Artistic License for more details.
# 
# You should have received a copy of the Perl Artistic License along
# with this library; if not, see:
#
#       http://www.perl.com/language/misc/Artistic.html
# 
# Designed and written by Stephen Vance (steve@vance.com) on behalf
# of The MathWorks, Inc.

package P4::Server;

use strict;
use warnings;

use Archive::Extract;
use Error qw( :warndie :try );
use Error::Exception;
use File::Path;
use File::Temp qw( tempdir );;
use IO::File;
use IO::Select;
use IO::Socket::INET;
use IPC::Open3;
use IPC::Cmd qw( can_run );
use P4;
use Symbol;

use Exception::Class (
    'P4::Server::Exception' => {
        isa         =>  'Error::Exception',
        description =>  'Base class for P4::Server-related exceptions',
    },

    'P4::Server::Exception::NoJournalFile' => {
        isa         => 'P4::Server::Exception',
        fields      => [ 'filename' ],
        description => 'Supplied journal file does not exist',
    },

    'P4::Server::Exception::FailedExec' => {
        isa         => 'P4::Server::Exception',
        fields      => [ 'command', 'reason' ],
        description => 'Process exec failed',
    },

    'P4::Server::Exception::FailedToStart' => {
        isa         => 'P4::Server::Exception',
        fields      => [ 'command', 'timeout' ],
        description => 'P4d did not respond to requests before the timeout',
    },

    'P4::Server::Exception::FailedSystem' => {
        isa         => 'P4::Server::Exception',
        fields      => [ 'command', 'retval' ],
        description => 'Process system call failed',
    },

    'P4::Server::Exception::P4DQuit' => {
        isa         => 'P4::Server::Exception',
        description => 'P4d process quit unexpectedly after starting',
    },

    'P4::Server::Exception::ServerRunning' => {
        isa         => 'P4::Server::Exception',
        description => 'Operation not allowed while server is running',
    },

    'P4::Server::Exception::ServerListening' => {
        isa         => 'P4::Server::Exception',
        fields      => [ 'port' ],
        description => 'Another server is listening on the port',
    },

    'P4::Server::Exception::NoArchiveFile' => {
        isa         => 'P4::Server::Exception',
        fields      => [ 'filename' ],
        description => 'Supplied archive file does not exist',
    },

    'P4::Server::Exception::ArchiveError' => {
        isa         => 'P4::Server::Exception',
        description => 'Error using Archive::Extract',
    },

    'P4::Server::Exception::UndefinedRoot' => {
        isa         => 'P4::Server::Exception',
        description => 'The server root is not defined when needed',
    },

    'P4::Server::Exception::BadRoot' => {
        isa         => 'P4::Server::Exception',
        fields      => [ 'dir' ],
        description => 'The server root directory does not exist',
    },

    'P4::Server::Exception::InvalidExe' => {
        isa         => 'P4::Server::Exception',
        fields      => [ 'role', 'exe' ],
        description => 'The executable for the role does not work as '
                        . 'expected',
    },
);

our $VERSION = '0.11';

use Class::Std;
{

    my %p4d_exe_of  : ATTR( get => 'p4d_exe' );
    my %p4d_timeout_of : ATTR( name => 'p4d_timeout' default => 2 );
    my %root_of     : ATTR( get => 'root' );
    my %port_of     : ATTR( get => 'port'       set => 'port' );
    my %log_of      : ATTR( get => 'log'        set => 'log' );
    my %journal_of  : ATTR( get => 'journal'    set => 'journal' );
    my %pid_of      : ATTR( get => 'pid' );
    my %cleanup_of  : ATTR( get => 'cleanup'    set => 'cleanup' );
    my $io_writer;
    my $io_reader;
    my $io_err = Symbol::gensym();

    my $dirtemplate = File::Spec->catfile(
        File::Spec->tmpdir(),
        'p4server-root-XXXXXX',
    );
    my $journaltemplate = File::Spec->catfile(
        File::Spec->tmpdir(),
        'p4server-journal-XXXXXX',
    );

sub BUILD {
    my ($self, $ident, $arg_ref) = @_;

    $pid_of{$ident} = 0;
    $self->set_p4d_exe( $arg_ref->{p4d_exe} );
    $port_of{$ident} = $arg_ref->{port} ? $arg_ref->{port} : '1666';
    $self->set_root( $arg_ref->{root} );
    $log_of{$ident} = $arg_ref->{log} ? $arg_ref->{log} : 'log';
    $journal_of{$ident} = $arg_ref->{journal} ? $arg_ref->{journal} : 'journal';

    $cleanup_of{$ident} = 1;

    return;
}

sub DEMOLISH {
    my ($self) = @_;
    my $ident = ident $self;

    # Shut down the server if necessary
    $self->stop_p4d();

    # Clean up the directory if necessary
    $self->clean_up_root();

    return;
}

sub set_root {
    my ($self, $root) = @_;
    my $ident = ident $self;

    if( $pid_of{$ident} != 0 ) {
        P4::Server::Exception::ServerRunning->throw();
    }

    $self->clean_up_root();
    $root_of{$ident} = $root;

    return;
}

sub start_p4d {
    my ($self) = @_;
    my $ident = ident $self;

    if( $pid_of{$ident} != 0 ) {
        P4::Server::Exception::ServerRunning->throw();
    }

    $self->create_temp_root();

    my $dynamic_port = defined( $port_of{$ident} ) ? 0 : 1;

    my $try_again = 1;
    while( $try_again ) {
        if( $dynamic_port ) {
            $self->_allocate_port();
        }

        try {
            $self->_launch_p4d();
            $try_again = 0;
        }
        catch P4::Server::Exception::ServerListening with {
            my $e = shift;
            # We want to retry for dynamic ports. Otherwise, rethrow.
            if( ! $dynamic_port ) {
                $e->throw();
            }
        };
        # TODO: Should we catch P4DQuit here?
        # otherwise let exceptions pass
    }

    return;
}

sub stop_p4d {
    my ($self) = @_;
    my $ident = ident $self;
    my $pid = $pid_of{$ident};

    if( $pid ) {
        kill( 15, $pid );
        waitpid( $pid, 0 );

        $self->_drain_output( $io_reader, $io_err );
    }

    $pid_of{$ident} = 0;

    return;
}

sub load_journal_file {
    my ($self, $journal) = @_;

    -f $journal
        or P4::Server::Exception::NoJournalFile->throw(
            filename => $journal
        );

    my $ident = ident $self;
    my @args = (
        $p4d_exe_of{$ident},
        '-r', $root_of{$ident},
        '-jr', $journal,
    );

    my $journal_writer;
    my $journal_reader;
    my $journal_err = Symbol::gensym();
    my $pid = open3( $journal_writer, $journal_reader, $journal_err, @args );
    waitpid( $pid, 0 );

    $self->_drain_output( $journal_reader, $journal_err );

    return;
}

sub load_journal_string {
    my ($self, $contents) = @_;

    my $fh = File::Temp->new( TEMPLATE => $journaltemplate );;
    my $journal = $fh->filename;

    print $fh $contents;
    close $fh;

    $self->load_journal_file( $journal );

    return;
}

sub create_temp_root {
    my ($self) = @_;
    my $ident = ident $self;

    return if( defined( $root_of{$ident} ) );

    my $name = tempdir( $dirtemplate, CLEANUP => $cleanup_of{$ident} );

    $root_of{ident $self} = $name;

    return;
}

sub clean_up_root {
    my ($self) = @_;
    my $ident = ident $self;
    my $root = $root_of{$ident};

    if( $pid_of{$ident} != 0 ) {
        P4::Server::Exception::ServerRunning->throw();
    }

    # Clean up the directory if necessary
    if( $cleanup_of{$ident}
            && defined( $root )
            && -d $root ) {
        rmtree( $root );
    }
}

sub set_p4d_exe {
    my ($self, $exe) = @_;

    if( ! defined( $exe ) ) {
        $exe = 'p4d';
    }

    if( ! $self->_is_exe_valid( $exe ) ) {
        P4::Server::Exception::InvalidExe->throw(
            role        => 'p4d',
            exe         => $exe,
        );
    }

    $p4d_exe_of{ident $self} = $exe;

    return;
}

sub unpack_archive_to_root_dir {
    my ($self, $archive) = @_;

    if( ! -f $archive || ! -r $archive ) {
        P4::Server::Exception::NoArchiveFile->throw( filename => $archive );
    }

    my $root = $self->get_root();
    if( ! defined( $root ) ) {
        P4::Server::Exception::UndefinedRoot->throw();
    }

    if( ! -d $root ) {
        P4::Server::Exception::BadRoot->throw( dir => $root );
    }

    my ($result, $error, $files) = $self->_extract_archive( $archive, $root );
    # TODO: This is untestable as I have not figured out how to make gunzip or
    # tar generate an error return.
    if( ! $result ) {
        P4::Server::Exception::ArchiveError->throw(
            error => $error,
        );
    }

    return $files;
}

# PRIVATE METHODS

# To be overridden for test failure injection

sub _system {
    my ($self, @args) = @_;

    return system( @args );
}

sub _is_exe_valid : RESTRICTED {
    my ($self, $exe) = @_;

    return defined( can_run( $exe ) ) ? 1 : 0;
}

sub _extract_archive : RESTRICTED {
    my ($self, $archive, $outdir) = @_;

    local $Archive::Extract::WARN = 0;
    my $extractor = Archive::Extract->new( archive => $archive );
    my $result = $extractor->extract( to => $outdir );

    return ($result, $extractor->error(), $extractor->files() );
}

sub _is_p4d_listening_on : PRIVATE {
    my ($self, $port) = @_;
    my $ident = ident $self;

    my $p4 = P4->new();
    $p4->ParseForms();
    $p4->Tagged();
    $p4->SetPort( $port );

    # Nothing's listening if we can't connect
    if( ! $p4->Connect() ) {
        return 0;
    }

    my @results = $p4->Info();
    return ! $p4->ErrorCount();
}

sub _spawn_p4d : PROTECTED {
    my ($self, @args ) = @_;

    return open3( $io_writer, $io_reader, $io_err, @args );
}

sub _drain_output : PRIVATE {
    my ($self, @handles) = @_;

    my $sel = IO::Select->new( @handles );
    my @ready;
    while( @ready = $sel->can_read( 30 ) ) {
        for my $fh ( @ready ) {
            my $buffer;

            # Read length is a magic number but is well more than any 'p4
            # info' returns.
            my $bytes_read = read( $fh, $buffer, 2048 );

            if( $bytes_read == 0 ) {
                $sel->remove( $fh );
                close( $fh );
            }
        }
    }

    close( $io_writer );
    close( $io_reader );
    close( $io_err );
}

sub _launch_p4d : PRIVATE {
    my ($self) = @_;
    my $ident = ident $self;

    my $port = $port_of{$ident};

    if( $self->_is_p4d_listening_on( $port ) ) {
        P4::Server::Exception::ServerListening->throw(
            port        => $port,
        );
    }

    # TODO: Do we check here for the validity of the args?
    # TODO: Do we check here for the existence of the root?
    my @args = (
        $p4d_exe_of{$ident},
        '-q',
        '-r', $root_of{$ident},
        '-p', $port,
        '-L', $log_of{$ident},
        '-J', $journal_of{$ident},
    );

    my $pid;
    my $process_quit = 0;
    local $SIG{CHLD} = sub { $process_quit = 1; return; };
    try {
        $pid = $self->_spawn_p4d( @args );
    }
    otherwise {
        my $e = shift;
        P4::Server::Exception::FailedExec->throw(
            command => join( ' ', @args ),
            reason  => $e,
        );
    };

    $pid_of{$ident} = $pid;

    my $timeout = $self->get_p4d_timeout();
    my $start_time = time();
    while( ! $process_quit ) {
        if( $self->_is_p4d_listening_on( $port ) ) {
            last;
        }

        if( time() - $start_time > $timeout ) {
            P4::Server::Exception::FailedToStart->throw(
                command => join( ' ', @args ),
                timeout => $timeout,
            );
        }
    }

    if( $process_quit ) {
        P4::Server::Exception::P4DQuit->throw();
    }

    return;
}

# This is restricted so it can be overridden for test failure injection.
sub _allocate_port : RESTRICTED {
    my ($self) = @_;

    # TODO: Is there a failure to test here?
    my $socket = IO::Socket::INET->new(
        Proto       => 'tcp',
        ReuseAddr   => 1,
        Listen      => 5, # Number doesn't matter, but presence does
        LocalAddr   => 'localhost',
    );

    $port_of{ident $self} = $socket->sockport();

    close( $socket );

    return;
}

}

1;
__END__

=head1 NAME

P4::Server - Perl wrapper for control of a Perforce server

=head1 VERSION

Version 0.11

=head1 SYNOPSIS

This module provides for control and configuration of a Perforce server.

    use Error qw( :try );
    use P4::Server;

    my $server = P4::Server->new( {
            port    => $port,
    ) };
    $server->create_temp_root();
    $server->set_cleanup( 1 );
    $server->start_p4d();

    try {
        $server->load_journal_file( $journalfile );
    }
    catch P4::Server::Exception with {
        # Handle the error
    };
    
    # Do some operations against the server
    # Automatically stops the server and cleans up based on the cleanup flag

=head1 METHODS

=head2 clean_up_root

If the clean up flag is set and the root is defined, automatically removes the
server root.

=head3 Throws

=over

=item *

P4::Server::Exception::ServerRunning - when attempting to clean up the root
directory of a running server

=back

=head2 create_temp_root

Creates a temporary directory and sets it as the server root. This directory
will be cleaned up when the program exits according to the state of the
cleanup attribute when this method is called.

=head2 get_cleanup

Returns whether the object is set to clean up the server root upon
destruction.

=head2 get_journal

Returns the server journal name.

=head2 get_log

Returns the server log name.

=head2 get_p4d_exe

Returns the name of the currently set p4d executable.

=head2 get_p4d_timeout

Returns the number of seconds P4::Server will wait for p4d to start. See
L</set_p4d_timeout> for the exact definition of what this means.

=head2 get_pid

Returns the PID of the running server, if any.

=head2 get_port

Returns the Perforce port for the server.

=head2 get_root

Returns the server root.

=head2 load_journal_file

Loads the specified file as a journal into the Perforce server for this
object. The server does not have to be running.

=head3 Parameters

=over

=item *

journal - Journal file to load

=back

=head3 Throws

=over

=item *

P4::Server::Exception::NoJournalFile - If the supplied journal file name
doesn't exist

=item *

P4::Server::Exception::FailedSystem - If the system() call invoking the
journal load fails

=back

=head2 load_journal_string

Loads the specified string as a journal into the Perforce server for this
object. Creates a temporary file, loads the journal file from it, and removes
the file. The server does not have to be running.

=over

=item *

contents - String containing the journal content to load.

=back

=head2 new

Constructor for P4::Server. Takes an optional hash argument of parameters for
the server. The valid keys in the hash are:

=over

=item *

p4d_exe - The name of the p4d executable to be used. Default: 'p4d'

=item *

port - The value of P4PORT for the server. Default: '1666'

=item *

root - The value of P4ROOT for the server. No default indicating current
directory.

=item *

log - The value of P4LOG for the server. Default: 'log'

=item *

journal - The value of P4JOURNAL for the server. Default: 'journal'

=back

=head3 Throws

=over

=item *

P4::Server::Exception::InvalidExe - the p4d or p4 executables do not exist or
are not executable files

=back

=head2 set_cleanup

A true value tells the object to clean up the server root upon destruction.

=head2 set_journal

Gets the server journal name.

=head2 set_log

Sets the server log name.

=head2 set_p4d_exe

Sets the p4d executable to use. An undefined argument sets the value back to
the default ('p4d').

=head3 Throws

=over

=item *

P4::Server::Exception::InvalidExe - the p4d executable does not exist or is
not an executable file

=back

=head2 set_p4d_timeout

Sets the minimum number of seconds P4::Server will wait for p4d to start
before giving up. Because of the nature of the tests being applied, the actual
wait time is unpredictable and theoretically unbounded, although practically
very finite.

=head3 Throws

Nothing

=head2 set_port

Sets the Perforce port for the server. If the port is set to undef, the port
will be dynamically allocated when the server is started. At that point a port
will be assigned. If the server is stopped and restarted, the assigned port
will continue to be used unless the port is reset to undef.

=head2 set_root

Sets the server root with the side-effect of invoking L<clean_up_root>.

=head3 Throws

=over

=item *

P4::Server::Exception::ServerRunning - when attempting to change the root
directory of a running server

=back

=head2 start_p4d

Starts the server with the current settings. If the port is undefined, a port
will be dynamically assigned. That port will continue to be used through stops
and starts until the port is reset to undef.

=head3 Throws

=over

=item *

P4::Server::Exception::FailedExec - if the execution of the Perforce server
fails

=item *

P4::Server::Exception::FailedToStart - The server failed to start servicing
requests in the specified time despite executing successfully

=item *

P4::Server::Exception::P4DQuit - The server stopped after initially executing
successfully

=item *

P4::Server::Exception::ServerListening - Another server is already listening
on the specified port

=item *

P4::Server::Exception::ServerRunning - if the server is already running when
this method is called

=back

=head2 stop_p4d

Stops the currently running server for this object.

=head2 unpack_archive_to_root_dir

Unpacks an archive of any type supported by Archive::Extract into the
currently set root directory for the server.

It is expected that the archive consists of depot files and checkpoints made
relative to the server root directory.

=head3 Returns

An array reference with the paths of all the files in the archive, relative to
the server root.

=head3 Throws

=over

=item *
P4::Server::Exception::NoArchiveFile - When the specified archive file does
not exist or is not readable

=item *

P4::Server::Exception::ArchiveError - When Archive::Extract returns an error

=item *

P4::Server::Exception::UndefinedRoot - When the root directory has not yet been
defined.

=item *

P4::Server::Exception::RootDoesNotExist - When the root directory does not
exist

=back

=head2 BUILD

Constructor invoked by L<Class::Std>

=head2 DEMOLISH

Destructor invoked by L<Class::Std>. Invokes L<stop_p4d> and L<clean_up_root>.

=head1 AUTHOR

Stephen Vance, C<< <steve at vance.com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-p4-server at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=P4-Server>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc P4::Server

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/P4-Server>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/P4-Server>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=P4-Server>

=item * Search CPAN

L<http://search.cpan.org/dist/P4-Server>

=back

=head1 ACKNOWLEDGEMENTS

Thank you to The MathWorks, Inc. for sponsoring this work and to the BaT Team
for their valuable input, review, and contributions.

=head1 COPYRIGHT & LICENSE

Copyright 2007-8 Stephen Vance, all rights reserved.

This program is released under the following license: Artistic

=cut

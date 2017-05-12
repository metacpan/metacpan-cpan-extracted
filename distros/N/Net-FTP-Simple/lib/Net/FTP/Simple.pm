#
# Net::FTP::Simple - Simplified Net::FTP interface encapsulating a few simple
# operations.
#
# Written by Wil Cooley <wcooley@nakedape.cc>
#
# $Id: Simple.pm 758 2008-10-11 04:29:18Z wcooley $
#
package Net::FTP::Simple;
use strict;
use warnings;
use Carp;
use English         qw( -no_match_vars );
use File::Basename  qw( basename dirname );
use File::Spec;
use Net::FTP;

# FIXME MakeMaker handles it okay if it's all on one line, but Perl::Critic
# pukes :(
#eval q{ use version; our $VERSION = qv(0.0.5) }; our $VERSION = '0.0005' if ($EVAL_ERROR);
our $VERSION = '0.0007';


sub send_files {
    # Allow calls either as Net::FTP::Simple->send_files or
    #  Net::FTP::Simple::send_files
    my ($opt_ref) = $_[-1];

    my @successful_transfers;
    my $ftp = Net::FTP::Simple->_new($opt_ref);

    $ftp->_create_and_cwd_remote_dir()
        if ($ftp->{'remote_dir'});

    FILE_TO_TRANSFER:
    for my $file (@{ $ftp->{'files'} }){
        my $try_count;
        my $basename    = basename($file);
        my $tmpname     = $basename . '.tmp';

        unless ( -r $file ) {
            carp $ftp->_error("Local file '$file' unreadable; unable to transfer")
                unless ($ftp->{'quiet_mode'});
            next FILE_TO_TRANSFER;
        }

        unless ( $ftp->_conn()->put($file, $tmpname) ) {
            carp $ftp->_error("Error transferring file '$file' to '$tmpname'")
                unless ($ftp->{'quiet_mode'});
            next FILE_TO_TRANSFER;
        }

        eval {
            $try_count = $ftp->_op_retry('rename', $tmpname, $basename);
        };

        if ($EVAL_ERROR =~ m/'rename' failed after \d+ attempts/ms) {
            carp "Error renaming '$tmpname' to '$basename'";
            next FILE_TO_TRANSFER;
        }
        elsif($EVAL_ERROR) {
            # Rethrow unexpected exceptions
            croak $EVAL_ERROR;
        }

        if ($try_count > 1) {
            carp "Transfer of file '$file' succeeded after $try_count tries";
        }

        push @successful_transfers, $file;
    }

    wantarray   ?   return @successful_transfers
                :   return \@successful_transfers
                ;

}

sub rename_files {
    # Allow calls either as Net::FTP::Simple->rename_files or
    #  Net::FTP::Simple::rename_files
    my ($opt_ref) = $_[-1];

    my @successful_renames;

    my $ftp = Net::FTP::Simple->_new($opt_ref);

    if (exists $ftp->{'remote_dir'}) {
        $ftp->_conn()->cwd($ftp->{'remote_dir'})
            or croak $ftp->_error("Error changing to remote directory",
                                  "'$ftp->{'remote_dir'}'");
    }

    FILE_TO_RENAME:
    for my $src (sort keys %{ $ftp->{'rename_files'} }) {
        my $dst = $ftp->{'rename_files'}{ $src };
        my $try_count;

        eval {
            $try_count = $ftp->_op_retry('rename', $src, $dst);
        };

        if ($EVAL_ERROR =~ m/'rename' failed after \d+ attempts/ms) {
            carp "Error renaming '$src' to '$dst'";
            next FILE_TO_RENAME;
        }
        elsif ($EVAL_ERROR) {
            # Rethrow the exception if it's not recognized
            croak $EVAL_ERROR;
        }

        if ($try_count > 1 ) {
            carp "Rename of file from '$src' to '$dst' succeeded after"
                . " $try_count tries";
        }

        push @successful_renames, $src;

    }

    @successful_renames = sort @successful_renames;

    wantarray   ?   return  @successful_renames
                :   return \@successful_renames
                ;

}

sub retrieve_files {
    # Allow calls either as Net::FTP::Simple->retrieve_files or
    #  Net::FTP::Simple::retrieve_files
    my ($opt_ref) = $_[-1];

    my @successful_transfers;

    my $ftp = Net::FTP::Simple->_new($opt_ref);

    if ($ftp->{'remote_dir'}) {

        $ftp->_conn()->cwd($ftp->{'remote_dir'})
            or croak $ftp->_error("Error changing to remote directory",
                     "'$ftp->{'remote_dir'}'");
    }

    if (not exists $ftp->{'files'}) {
        if (exists $ftp->{'file_filter'}) {
            $ftp->_list_and_filter();       # Populate $ftp->{'files'}
        }
        else {
            # Punt if we have neither files nor a file filter
            return;
        }
    }

    FILES_TO_TRANSFER:
    for my $file (@{ $ftp->{'files'} }) {
        my $basename = basename($file);

        unless ( $ftp->_conn()->get($file, $basename) ) {
            carp $ftp->_error("Error getting file '$file'")
                unless ($ftp->{'quiet_mode'});
            next FILES_TO_TRANSFER;
        }

        push @successful_transfers, $basename;

        if ($ftp->{'delete_after'}) {
            $ftp->_conn()->delete($file)
                or carp $ftp->_error("Error deleting remote file '$file'");
        }
    }

    wantarray   ?   return @successful_transfers
                :   return \@successful_transfers
                ;

}

sub list_files {
    # Allow calls either as Net::FTP::Simple->list_files or
    #  Net::FTP::Simple::list_files
    my ($opt_ref) = $_[-1];

    my @remote_files;

    my $ftp = Net::FTP::Simple->_new($opt_ref);

    if ($ftp->{'remote_dir'}) {

        $ftp->_conn()->cwd($ftp->{'remote_dir'})
            or croak $ftp->_error("Error changing to remote directory",
                     "'$ftp->{'remote_dir'}'");
    }

    @remote_files = $ftp->_list_and_filter();

    wantarray   ?   return @remote_files
                :   return \@remote_files
                ;

}

#######################################################################
# Private data
#######################################################################

# Error messages which indicate a possibly temporary error condition
our %retryable_errors = (
    rename  => [
        qq/The process cannot access the file because /
        . qq/it is being used by another process/,
    ],
);

# Maximum number of times to retry an operation.
our %retry_max = (
    default => 0,
    rename  => 3,
);

# Time to wait on retry in seconds
our %retry_wait = (
    default => 10,
    rename  => 10,
);


#######################################################################
# Private class below here
#######################################################################
#
# Private constructor!
#
sub _new {
    my ($class, $opt_ref) = @_;
    my $obj = bless $opt_ref, $class;

    # Capture which of the wrapper subs called us so we can be identified as
    # that instead of the actual object.
    $obj->_set_caller( (caller(1))[3] );

    # mmm required options
    croak $obj->_caller(), " requires at least 'server' parameter"
        unless($obj->{'server'});

    #
    # Allow the user to pass in an object instead of creating a new instance.
    # This allows test scripts to use a mock Net::FTP object and simulate a
    # number of different cases.
    #
    unless ($obj->{'conn'}) {
        my $ftpconn = Net::FTP->new($obj->{'server'}, 
                                    Debug => $obj->{'debug_ftp'})
            or croak $obj->_error("Error creating Net::FTP object:",
                                  "'$EVAL_ERROR'");

        $obj->_set_conn($ftpconn);
    }
    else {
        $obj->_set_conn($obj->{'conn'});
    }

    $obj->_conn()->login( @{ $obj }{ qw( username password ) } )
        or croak $obj->_error("Error logging in to '$obj->{'server'}'");

    $obj->_setup_mode();

    return $obj;
}

sub DESTROY {
    my ($self) = shift;

    if($self->_conn()) {
        $self->_conn()->quit()
            or croak $self->_error("Error closing FTP connection:",
                                   "'$EVAL_ERROR'");
    }

    $self->_set_conn(undef);
}

sub _setup_mode {
    my ($self) = shift;

    if (exists $self->{'mode'} and $self->{'mode'} eq 'ascii') {
        $self->_conn()->ascii()
            or croak $self->_error('Error setting transfer mode to ascii');
    }
    else {
        $self->_conn()->binary()
            or croak $self->_error('Error setting transfer mode to binary');
    }
}

#sub _setup_connection {
#my ($self) = shift;
#
#}

#######################################################################
# Accessors
#######################################################################
sub _conn {
    my ($self) = shift;
    return $self->{'connection'};
}

sub _set_conn {
    my ($self) = shift;
    my ($conn) = @_;

    return $self->{'connection'} = $conn;
}

sub _caller {
    my ($self) = shift;
    return $self->{'caller'};
}

sub _set_caller {
    my ($self) = shift;
    my ($caller) = @_;

    # It should always be something; if _new is called directly (as it usually
    # shouldn't be, but may be in test scripts)
    $caller = 'main' unless ($caller);

    return $self->{'caller'} = $caller;
}

#
# _error - Format the FTP error string to include the error code.
#
sub _error {
    my ($self)  = shift;
    my ($msg)   = join(" ", @_);
    my $ftp_err = q{};

    # This may be called for errors other than those from Net::FTP
    # and there may not be a connection object
    if ($self->_conn() and not $self->_conn()->ok()) {
        my $msg = $self->_conn()->message();
        chomp $msg;

        $ftp_err = sprintf(q(: '%d %s'), $self->_conn()->code(), $msg);
    }

    return sprintf(q(%s: %s%s),
                $self->_caller(),
                $msg,
                $ftp_err,
            );
}


sub _create_and_cwd_remote_dir {
    my ($self) = shift;

    # Try first change to the directory
    unless ($self->_conn()->cwd($self->{'remote_dir'})) {

        # Give up now if user requested _not_ creating the remote
        # directory
        if ($self->{'disable_create_remote_dir'}) {
            croak $self->_error("Error changing to remote directory",
                "'$self->{'remote_dir'}'");
        }

        # Try to create the output path if it doesn't exist
        $self->_conn()->mkdir($self->{'remote_dir'}, 1)
            or croak $self->_error("Error making remote directory",
                                   "'$self->{'remote_dir'}'");

        $self->_conn()->cwd($self->{'remote_dir'})
            or croak $self->_error("Error changing to remote directory after",
                                   "creating '$self->{'remote_dir'}'");
    }

}


sub _op_retry {
    my ($self, $op, @op_args) = @_;
    my $conn = $self->_conn();
    my $try_count = 1;

    croak ref $conn, " cannot do '$op'"
        unless ($conn->can($op));

    OP_TRY:
    while(not $conn->$op(@op_args)) {
        $try_count += 1;

        croak "'$op' failed after $try_count attempts"
            unless ( $self->_is_retryable_op($op, $try_count) );

        $self->_sleep_for_op($op);
    }

    return $try_count;
}

# 
# Sleep for operation; returns nothing useful.
#
sub _sleep_for_op {
    my $self = shift;
    my ($op) = @_;

    my $retry_wait  = exists $retry_wait{ $op } ? $retry_wait{ $op }
                                                : $retry_wait{ 'default' }
                                                ;

    sleep $retry_wait;

}

#
# _is_retryable_op - Tests if a failing operation is retryable, 
#                    comparing both the error message and the retry count.
#
sub _is_retryable_op {
    my $self = shift;
    my ($op, $count) = @_;

    my $caller_error_message = $self->_conn()->message();

    my $retry_max = exists $retry_max{ $op }  ? $retry_max{ $op }   
                                                : $retry_max{ 'default' }
                                                ;

    return unless   (exists $retryable_errors{ $op });
    return if       ($count > $retry_max);

    for my $msg (@{ $retryable_errors{ $op } }) {
        if ($caller_error_message =~ m/$msg/ms) {  # No 'x'!
            return 1;
        }
    }

    # False if we fall through the loop
    return;
}

# Assume everything else is set up
sub _list_and_filter {
    my ($self) = shift;

    my $filter = $self->{'file_filter'} || qr/./xms;
    my @remote_list;
    my @remote_files;

    # FIXME I need to figure out how to distinguish between an empty list (no
    # files in the directory) and an error.  Hopefully, if the directory
    # permissions are such that the directory cannot be listed, the cwd will
    # also fail (assuming one is done prior to this :\).  Of course, it's
    # possible to have +x-r, but for now, just hope for the best :)
    return unless (@remote_list = $self->_conn()->dir());

    REMOTE_LIST:
    for my $entry (@remote_list) {
        chomp $entry;

        # This correctly splits a line where the filename has spaces; the '9'
        # collects the 9th field and everything after into one item
        my ($mode, $filename) = (split /\s+/, $entry, 9)[0,-1];

        # Skip non-file things
        next REMOTE_LIST unless ($mode && $mode =~ /\A-/xms);

        # Skip files not matching the filter
        next REMOTE_LIST unless ($filename =~ m/$filter/xms);

        push @remote_files, $filename;
    }

    push @{ $self->{'files'} }, @remote_files;

    wantarray   ?   return @remote_files
                :   return \@remote_files
                ;
}



1;

__END__

=head1 NAME

Net::FTP::Simple - Simplified interface to a few common FTP tasks with
Net::FTP.

=head1 VERSION

This document describes Net::FTP::Simple version 0.0005.

=head1 SYNOPSIS

    use Net::FTP::Simple;

    my @remote_files = Net::FTP::Simple->list_files({
            username        => $username,
            password        => $password,
            server          => $server,
            remote_dir      => 'path/to/dir',
            debug_ftp       => 1,
            file_filter     => qr/foo/,
        });

    print "List:\n\t", join("\n\t", @remote_files), "\n")
        if @remote_files;

    my @sent_files = Net::FTP::Simple->send_files({
            username        => $username,
            password        => $password,
            server          => $server,
            remote_dir      => 'path/to/dir',
            debug_ftp       => 1,
            files           => [
                                    'foo.txt',
                                    'bar.txt',
                                    'baz.txt',
                                ],
        });

    print "The following files were sent successfully:\n\t",
        join("\n\t", @sent_files), "\n"
            if @sent_files;


    my @received_files = Net::FTP::Simple->retrieve_files({
            username        => $username,
            password        => $password,
            server          => $server,
            remote_dir      => 'path/to/dir',
            debug_ftp       => 1,
            files           => [
                                    'foo.txt',
                                    'bar.txt',
                                    'baz.txt',
                                ],
        });

    print "The following files were retrieved successfully:\n\t",
        join("\n\t", @received_files), "\n"
            if @received_files;

    my @received_filtered_files = Net::FTP::Simple->retrieve_files({
            username        => $username,
            password        => $password,
            server          => $server,
            remote_dir      => 'path/to/dir',
            debug_ftp       => 1,
            file_filter     => qr/^ba.\.txt/,
            delete_after    => 1,
        });

    print "The following files were retrieved successfully:\n\t",
        join("\n\t", @received_filtered_files), "\n"
            if @received_filtered_files;

    my @renamed_files = Net::FTP::Simple->rename_files({
            username        => $username,
            password        => $password,
            server          => $server,
            remote_dir      => 'path/to/dir',
            debug_ftp       => 1,
            rename_files    => {
                    'old_name'  => 'new_name',
            },
    });

=head1 INTERFACE 

Net::FTP::Simple provides the user with four operations: list a directory,
retrieve a directory or list of files, send a list of files and rename a list
of files.

All four operations, L<list_files()>, L<retrieve_files()>, L<send_files()>
and L<rename_files()> may be invoked using either module or class syntax;
i.e., Net::FTP::Simple::list_files() or Net::FTP::Simple->list_files().
As these are one-shot operations, there is no publically-instantiable object.

All operations are invoked with a single hash ref argument with the options
described below as hash keys.

There is a generalized retry infrastructure; currently only renames (used in
both L<send_files()> and L<rename_files()>) are retried, but future
enhancement should allow all operations to be retried.  To disable retries for
rename, set

 $Net::FTP::Simple::retry_max{'rename'} = 0;

The retry infrastructure also sleeps for 10 seconds by default between tries.
This may be adjusted with

 $Net::FTP::Simple::retry_wait{'rename'} = 0;

B<WARNING:> Directly fiddling with package variables like this does not make a
good interface, so don't expect it to stay around!

=head2 Subroutines

=over 4

=item C<send_files()>

Given a list of files, send them via FTP.

It does not preserve the local path of the files; it strips the filename
down to the base filename and sends it to the directory on the FTP server 
named in the 'remote_dir' parameter.  

When uploading, files are sent with '.tmp' appended to their names and 
then renamed into place, because some FTP servers process files based on 
their extensions and this ensures each file is sent completely before 
processing.

'remote_dir' is created if it does not exist.

Returns an array or array ref of the original names of the sent files.

=item C<retrieve_files()>

Retrieve a list of files or a directory of files.

Does not work recursively.

Unlike send_files, it does not create the (local) destination nor does it
change to it.

If 'delete_after' is true, then the remote files are deleted after being
successfully downloaded.  [ FIXME Should a transfer be considered successful
if the file is retrieved but not deleted? Currently, it is. ]

Files may be specified with a list called 'files' or a regular expression
'file_filter'.  'files' takes precedence over 'file_filter'; if both are
given, the latter is ignored.

=item C<list_files()>

List files in a given directory.

Ignores anything that is not a normal file--directories, device files, FIFOs,
sockets, etc.  Currently only works with UNIX-like directory listings.

=item C<rename_files()>

Renames the files given in the hash ref 'rename_files', after first changing
to 'remote_dir'.

Returns a list (or list ref, in scalar context) of the original names of the
renamed files.

=back

=head2 Common Options

=over 4

=item * C<server>

Hostname or IP address of FTP server.

=item * C<username>

Login username.

=item * C<password>

Login password.

=item * C<mode>

C<ascii> or C<binary> (default C<binary>).

=item * C<debug_ftp>

(bool) Turn on C<Net::FTP> debugging.

=item * C<remote_dir>

Remote directory against which to operate.

=item * C<files>

List ref of files to operate one.

=back

=head2 retrieve_files() Options

=over 4

=item * C<delete_after>

(bool) Delete files after retrieving them.

=item * C<file_filter>

Regex against which to apply to list of remote files.

=back

=head2 list_files() Options

=over 4

=item * C<file_filter>

Regex against which to apply to list of remote files.

=back

=head1 DIAGNOSTICS

This module is intended to be a simplified interface to complex options;
as such, it handles almost all errors itself--by croaking.  Errors with
individual files (even if it involves all such files) are reported and the
failing files not added to the list of successful transfers.

In some cases, operations which are known to fail with transient errors
can be retried.


=head1 CONFIGURATION AND ENVIRONMENT

Net::FTP::Simple requires no configuration files or environment variables.


=head1 DEPENDENCIES

As this module is a facade layer on top of Net::FTP, it requires Net::FTP.

=head1 INCOMPATIBILITIES

None known.

=head1 BUGS AND LIMITATIONS

No bugs have been reported (so far).  It is unlikely that the behaviours
encapsulated in this module with meet with everyone's needs, but hey,
that's life.  For one thing, it probably should support proxying.

Please report any bugs or feature requests to
C<bug-net-ftp-simple@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 TODO

=over 4

=item * Implement retry for all C<Net::FTP> operations

=item * Move carp messages into a package hash for easier testing and
        client-based filtering of warnings.

=item * Add ability to disable renaming in C<send_files()>.

=item * Split major operations into separate test modules, with separate
        module for private subroutines.

=item * Add unit testing for C<retrieve_files()>.

=item * More thorough testing all around.

=back

=head1 AUTHOR

Wil Cooley  <wcooley@nakedape.cc>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2006, Wil Cooley <wcooley@nakedape.cc>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY FOR THE
SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN OTHERWISE
STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES PROVIDE THE
SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED,
INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
FITNESS FOR A PARTICULAR PURPOSE. THE ENTIRE RISK AS TO THE QUALITY AND
PERFORMANCE OF THE SOFTWARE IS WITH YOU.  IF SOMETHING IS TYPED IN ALL CAPITAL
LETTERS IT LOOKS REALLY MEAN AND OFFICIAL, WHICH IS WHY LAWYERS LOVE IT.
SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL NECESSARY
SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.



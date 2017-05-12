package Path::Class::File::Lockable;

use warnings;
use strict;
use base qw( Path::Class::File );
use File::NFSLock;
use Fcntl qw(LOCK_EX LOCK_NB);
use Carp;

our $VERSION = '0.03';

=head1 NAME

Path::Class::File::Lockable - lock your files with Path::Class::File

=head1 SYNOPSIS

 my $file = Path::Class::File::Lockable->new('path/to/file');
 $file->lock;
 # do stuff with $file
 $file->unlock;

=head1 DESCRIPTION

Path::Class::File::Lockable uses simple files to indicate whether
a file is locked or not. It does not use flock(), since that is
unstable over NFS. Effort has been made to avoid race conditions.

Path::Class::File::Lockable is intended for long-standing locks, as in a
Subversion workspace. See SVN::Class for example.

=head1 METHODS

This is a subclass of Path::Class::File. Only new or overridden methods
are documented here.

=cut

=head2 lock_ext

Returns the file extension used to indicate a lock file. Default is
C<.lock>.

=cut

sub lock_ext {'.lock'}

=head2 lock_file

Returns a Path::Class::File object representing the lock file
itself. No check is made as to whether the lock file exists.

=cut

sub lock_file {
    my $self = shift;
    return Path::Class::File->new( join( '', $self, $self->lock_ext ) );
}

=head2 lock_info

Returns a colon-limited string with the contents of the lock file. 
Will croak if the lock file does not exist.

B<Note> that the owner and timestamp in the file contents
are not from a stat() of the file.
They are written
at the time the lock file is created. So chown'ing or touch'ing
a lock file do not alter its status.

See lock_owner() and lock_time() for easier ways to get at specific
information.

=cut

sub lock_info {
    my $self  = shift;
    my $lfile = $self->lock_file;
    if ( !-s $lfile ) {
        croak "no such lock file: $lfile";
    }
    return $lfile->slurp;
}

=head2 lock_owner

Returns the name of the person who locked the file.

=cut

sub lock_owner {
    my $self = shift;
    return ( split( m/:/, $self->lock_info ) )[0];
}

=head2 lock_time

Returns the time the file was locked (in Epoch seconds).

=cut

sub lock_time {
    my $self = shift;
    return ( split( m/:/, $self->lock_info ) )[1];
}

=head2 lock_pid

Returns the PID of the process that locked the file.

=cut

sub lock_pid {
    my $self = shift;
    return ( split( m/:/, $self->lock_info ) )[2];
}

=head2 locked

Returns true if the file has an existing lock file.

=cut

sub locked {
    my $self = shift;
    return -s $self->lock_file;
}

=head2 lock( [I<owner>] )

Acquire a lock on the file.

This method should be NFS-safe via File::NFSLock.

=cut

sub lock {
    my $self = shift;
    my $owner;
    if ( $^O eq 'MSWin32' ) {
        require Win32;
        $owner = Win32::LoginName();
    }
    else {
        $owner = shift || getlogin() || ( getpwuid($<) )[0] || 'anonymous';
    }

    # we have to lock our lock file first, to avoid
    # NFS and race condition badness.
    # so obtain a lock on our lock file, write our lock
    # then release the lock on our lock file.
    # we can't use File::NFSLock all by itself since it is
    # not persistent across processes.
    my $lock = File::NFSLock->new(
        {   file               => $self->lock_file,
            lock_type          => LOCK_EX | LOCK_NB,
            blocking_timeout   => 5,
            stale_lock_timeout => 5
        }
    );

    if ( !$lock ) {
        croak "can't get safe lock on lock file: $File::NFSLock::errstr";
    }

    my $fh = $self->lock_file->openw() or croak "can't write lock file: $!";
    print {$fh} join( ':', $owner, time(), $$ );
    $fh->close;

    $lock->unlock;
}

=head2 unlock

Removes lock file. Uses system() call to enable unlinking across
NFS. Will croak on any error.

=cut

sub unlock {
    my $self = shift;
    $self->lock_file->remove or croak "can't unlink lock file: $!";
    return 1;
}

=head1 AUTHOR

Peter Karman, C<< <karman at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-path-class-file-lockable at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Path-Class-File-Lockable>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Path::Class::File::Lockable

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Path-Class-File-Lockable>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Path-Class-File-Lockable>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Path-Class-File-Lockable>

=item * Search CPAN

L<http://search.cpan.org/dist/Path-Class-File-Lockable>

=back

=head1 ACKNOWLEDGEMENTS

There are lots of lock file modules on CPAN. Some of them are probably better
suited to your needs than this one.

The Minnesota Supercomputing Institute C<< http://www.msi.umn.edu/ >>
sponsored the development of this software.

=head1 SEE ALSO

File::NFSLock, Path::Class::File

=head1 COPYRIGHT & LICENSE

Copyright 2007 by the Regents of the University of Minnesota.
All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;

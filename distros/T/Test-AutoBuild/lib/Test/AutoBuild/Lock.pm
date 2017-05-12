# -*- perl -*-
#
# Test::AutoBuild::Lock
#
# Daniel Berrange <dan@berrange.com>
# Dennis Gregorovic <dgregorovic@alum.mit.edu>
#
# Copyright (C) 2004 Red Hat, Inc, 2005 Daniel P. Berrange
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#
# $Id$

=pod

=head1 NAME

Test::AutoBuild::Lock - Manage a lock file to prevent concurrent execution

=head1 SYNOPSIS

  use Test::AutoBuild::Lock


=head1 DESCRIPTION

This module takes out an exclusive lock on a file, preventing
multiple instances of the builder running concurrently against
the same build home. The scheme to use for locking the file, can
be one of C<flock>, C<fcntl>, or C<file>. C<fcntl> is preferred
since it works across NFS. If this isn't supported on the OS running
the builder, then C<flock> should be used. As a last resort the C<file>
method should be used, with does a simple file presence/creation check,
although if the builder fails in a bad way it is possible the lock will
not be cleaned up correctly.

=head1 METHODS

=over 4

=cut

package Test::AutoBuild::Lock;

use warnings;
use strict;
use IO::File;
use Class::MethodMaker
    new_with_init => 'new';
use File::Spec::Functions qw(catfile);
use Fcntl qw(:flock F_SETLK F_WRLCK);
use POSIX qw(:unistd_h :errno_h);


use Log::Log4perl;

=item my $stage = Test::AutoBuild::Lock->new(file => $lock_file_path,
					     method => $lock_method);

Creates a new lock manager, for the file specified by the C<file>
parameter. This should be a fully qualified path for the file to be locked.
The file does not have to exist beforehand, but the path must be writable
by the user running the build instance. The C<method> parameter should be
one of the strings 'fcntl', 'flock' or 'file' designating the method used
to acquire the lock.

=cut

sub init {
    my $self = shift;
    my %params = @_;

    $self->{file} = exists $params{"file"} ? $params{"file"} : catfile($ENV{HOME}, ".build.mutex");
    $self->{method} = exists $params{"method"} ? $params{"method"} : "fcntl";
    $self->{lock} = undef;
}

=item my $status = $lock->lock;

Attempt to acquire the lock, returning a true value if successfull,
otherwise a false value to indicate failure (due to the lock being
held by another process).

=cut

sub lock {
    my $self = shift;
    my $log = Log::Log4perl->get_logger();

    #----------------------------------------------------------------------
    # Grab the global build lock.

    my $lockfile = $self->{file};
    my $method = $self->{method};
    my $subname = "_lock_$method";
    if (!$self->can($subname)) {
	die "unsupported locking scheme $method";
    }

    my ($lock, $message) = $self->$subname($lockfile);
    if (defined $lock) {
	$log->debug("Got lock ($lockfile) with $method");
	$self->{lock} = $lock;
	return 1;
    } else {
	$log->debug("Fail lock ($lockfile) with $method: '$message'");
	$self->{lock} = undef;
	return 0;
    }
}


sub DESTROY {
    my $self = shift;
    $self->unlock();
}

=item $lock->unlock;

Release a lock previously acquired by the C<lock> method. If a
lock is not explicitly released, it will be unlocked during
garbage collection (via a DESTROY method hook on this object).

=cut

sub unlock {
    my $self = shift;
    if ($self->{lock}) {
	my $method = $self->{method};
	my $subname = "_unlock_$method";
	if ($self->can($subname)) {
	    $self->$subname($self->{file}, $self->{lock});
	    $self->{lock} = undef;
	}
    }
}

sub _lock_file {
    my $self = shift;
    my $lockfile = shift;

    # Note: There really isn't a race condition here.
    # since this script is only invoked every 5 mins
    if (-f $lockfile) {
	return (undef, "lock held by another process");
    }
    my $fh = IO::File->new(">$lockfile");
    if (!$fh) {
	return (undef, "cannot create $lockfile: $!");
    }

    my $old_sigint = $SIG{'INT'};
    $SIG{'INT'} = sub { $self->_unlock_file(); if ($old_sigint) {&{$old_sigint};} exit 1};

    return $fh;
}

sub _lock_flock {
    my $self = shift;
    my $lockfile = shift;

    my $fh = IO::File->new(">$lockfile");
    if (!$fh) {
	return (undef, "cannot create $lockfile: $!");
    }
    flock ($fh, LOCK_EX | LOCK_NB)
	or return (undef, "cannot obtain lock on $lockfile: $!");

    return $fh;
}

sub _lock_fcntl {
    my $self = shift;
    my $lockfile = shift;

    my $fh = IO::File->new(">$lockfile");
    if (!$fh) {
	return (undef, "cannot create $lockfile: $!");
    }

    my $lock = $self->_fcntl_data(F_WRLCK, SEEK_SET, 0, 0, 0);
    if (!defined $lock) {
	return (undef, "fcntl locking not implemented for this operating system ($^O)");
    }

    fcntl($fh, F_SETLK, $lock)
	or return (undef, "cannot obtain lock on $lockfile: $!");

    return $fh;
}

sub _unlock_file {
    my $self = shift;
    my $lockfile = shift;
    my $lock = shift;

    $lock->close()
	or die "cannot lock lock $lockfile: $!";
    unlink $lockfile
	or die "cannot unlink lock $lockfile: $!";
}

sub _unlock_fcntl {
    my $self = shift;
    my $lockfile = shift;
    my $lock = shift;

    $lock->close()
	or die "cannot close lock $lockfile: $!";
}

sub _unlock_flock {
    my $self = shift;
    my $lockfile = shift;
    my $lock = shift;

    $lock->close()
	or die "cannot close lock $lockfile: $!";
}

sub _fcntl_data {
    my $self = shift;

    if ($^O =~ /linux/) {
	return $self->_fcntl_data_linux(@_);
    } elsif ($^O =~ /bsd/) {
	return $self->_fcntl_data_bsd(@_);
    } elsif ($^O =~ /sunos/) {
	return $self->_fcntl_data_sunos(@_);
    } else {
	return undef;
    }
}

# Thanks go out to Perl Cookbook for this information

# Linux struct flock
#   short l_type;
#   short l_whence;
#   off_t l_start;
#   off_t l_len;
#   pid_t l_pid;
sub _fcntl_data_linux {
    my $self = shift;
    my ($type, $whence, $start, $len, $pid) = @_;

    my $signature = 's s l l i';
    return pack($signature, $type, $whence, $start, $len, $pid);
}


# (Free)BSD struct flock:
#   off_t   l_start;        /* starting offset */
#   off_t   l_len;          /* len = 0 means until end of file */
#   pid_t   l_pid;          /* lock owner */
#   short   l_type;         /* lock type: read/write, etc. */
#   short   l_whence;       /* type of l_start */
sub _fcntl_data_bsd {
    my $self = shift;
    my ($type, $whence, $start, $len, $pid) = @_;

    my $signature = 'll ll i s s';
    return pack($signature, 0, $start, 0, $len, $pid, $type, $whence);
}


# SunOS struct flock:
#   short   l_type;         /* F_RDLCK, F_WRLCK, or F_UNLCK */
#   short   l_whence;       /* flag to choose starting offset */
#   long    l_start;        /* relative offset, in bytes */
#   long    l_len;          /* length, in bytes; 0 means lock to EOF */
#   short   l_pid;          /* returned with F_GETLK */
#   short   l_xxx;          /* reserved for future use */
sub _fcntl_data_sunos {
    my $self = shift;
    my ($type, $whence, $start, $len, $pid) = @_;

    my $signature = 's s l l s s';
    return pack($signature, $type, $whence, $start, $len, $pid, 0);
}

1 # So that the require or use succeeds.

__END__

=back

=head1 AUTHORS

Daniel Berrange <dan@berrange.com>
Dennis Gregorovic <dgregorovic@alum.mit.edu>

=head1 COPYRIGHT

Copyright (C) 2004 Red Hat, Inc.
Copyright (C) 2005 Daniel Berrange.

=head1 SEE ALSO

C<perl(1)>, C<fcntl(2)>, C<flock(2)>, L<Test::AutoBuild>

=cut

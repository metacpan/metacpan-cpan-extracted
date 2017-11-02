package Proc::tored::PidFile;
# ABSTRACT: Manage a service using a pid file
$Proc::tored::PidFile::VERSION = '0.20';

use warnings;
use strict;
use Moo;
use Carp;
use Guard qw(guard);
use Path::Tiny qw(path);
use Try::Tiny;
use Types::Standard -types;
use Proc::tored::LockFile;

has file_path => (is => 'ro', isa => Str, required => 1);

has file => (is => 'lazy', isa => InstanceOf['Path::Tiny'], handles => ['touch']);
sub _build_file { path(shift->file_path) }

has lockfile => (is => 'lazy', isa => InstanceOf['Proc::tored::LockFile']);
sub _build_lockfile { Proc::tored::LockFile->new(file_path => shift->file_path . '.lock') }

has mypid => (is => 'ro', isa => Int, default => sub { $$ }, init_arg => undef);


sub is_running {
  my $self = shift;
  $self->running_pid == $$;
}


sub running_pid {
  my $self = shift;
  my $pid = $self->read_file;
  return 0 unless $pid;
  return $pid if kill 0, $pid;
  return 0;
}


sub read_file {
  my $self = shift;
  return 0 unless $self->file->is_file;
  my ($line) = $self->file->lines({count => 1, chomp => 1}) or return 0;
  my ($pid) = $line =~ /^(\d+)$/;
  return $pid || 0;
}


sub write_file {
  my $self = shift;
  my $lock = $self->write_lock or return 0;
  return 0 if $self->running_pid;
  $self->file->spew("$$\n");
  return 1;
}


sub clear_file {
  my $self = shift;
  my $lock = $self->write_lock or return;
  return unless $self->is_running;
  return unless $self->file->exists;
  $self->file->append({truncate => 1});
  try { $self->file->remove }
  catch { warn "error unlinking pid file: $_" }
}


sub lock {
  my $self = shift;
  return guard { $self->clear_file } if $self->write_file;
  return;
}

#-------------------------------------------------------------------------------
# Creates a .lock file based on $self->pid_file. While the file exists, the
# lock is considered to be held. Returns a Guard that removes the file.
#-------------------------------------------------------------------------------
sub write_lock {
  my $self = shift;
  return unless $$ eq $self->mypid;
  return unless $self->lockfile;
  return $self->lockfile->lock;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Proc::tored::PidFile - Manage a service using a pid file

=head1 VERSION

version 0.20

=head1 SYNOPSIS

  use Proc::tored::PidFile;

  my $pidfile = Proc::tored::PidFile->new(file_path => $pid_file_path);

  if (my $lock = $pidfile->lock) {
    run_service;
  }
  else {
    die "service is already running under process id "
      . $pidfile->running_pid;
  }

=head1 DESCRIPTION

Allows the use of a pid file to manage a running service.

=head1 METHODS

=head2 is_running

Returns true if the pid indicated by the pid file is the current process.

=head2 running_pid

Returns true if the pid indicated by the pid file is an active, running
process. This is determined by attempting to signal the process using C<kill(0,
$pid)>.

=head2 read_file

Returns the pid stored in the pid file or 0 if the pid file does not exist or
is empty.

=head2 write_file

Writes the current process id to the pid file. Returns true on success, false
if the pid file exists and contains a running process id or if unable to
atomically write the pid file out.

=head2 clear_file

Truncates the pid file and then unlinks it.

=head2 lock

Attempts to write the current process id to the pid file and returns a L<Guard>
that will truncate and unlink the pid file if it goes out of scope.

  {
    my $lock = $pidfile->lock;
    run_service;
  }

  # $lock goes out of scope and pid file is truncated and unlinked

=head1 AUTHOR

Jeff Ober <sysread@fastmail.fm>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Jeff Ober.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

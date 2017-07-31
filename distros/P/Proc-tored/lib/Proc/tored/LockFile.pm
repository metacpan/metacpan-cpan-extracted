package Proc::tored::LockFile;
# ABSTRACT: Guard actions with atomic writes
$Proc::tored::LockFile::VERSION = '0.18';

use warnings;
use strict;
use Moo;
use Carp;
use Guard qw(guard);
use Path::Tiny qw(path);
use Try::Tiny;
use Types::Standard -types;


has file_path => (
  is  => 'ro',
  isa => Str,
  required => 1,
);

has file => (
  is  => 'lazy',
  isa => InstanceOf['Path::Tiny'],
  handles => [qw(exists)],
);

sub _build_file { path(shift->file_path) }


sub lock {
  my $self = shift;

  # Existing lock file means another process came in ahead
  return if $self->exists;

  my $locked = try {
      $self->file->filehandle({exclusive => 1}, '>');
    }
    catch {
      # Rethrow if error was something other than the file already existing.
      # Assume any 'sysopen' error matching 'File exists' is an indication
      # of that.
      die $_
        unless $_->{op} eq 'sysopen' && $_->{err} =~ /File exists/i
            || $self->exists;
    };

  return unless $locked;

  return guard {
    try { $self->exists && $self->file->remove }
    catch { carp "unable to remove lock file: $_" }
  };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Proc::tored::LockFile - Guard actions with atomic writes

=head1 VERSION

version 0.18

=head1 SYNOPSIS

  use Proc::tored::LockFile;

  my $lockfile = Proc::tored::LockFile->new(file_path => '/path/to/something.lock');

  if (my $lock = $lockfile->lock) {
    ...
  }

=head1 ATTRIBUTES

=head2 file_path

Path where lock file should be created.

=head1 METHODS

=head2 lock

Attempts to lock the guarded resource by created a new file at L</file_path>.
If the file could not be created because it already exists (using
C<O_CREAT|O_EXCL>), the lock attempt fails and undef is returned. If the lock
is successfully acquired, a L<Guard> object is returned that will unlink the
lock file as it falls out of scope.

=head1 AUTHOR

Jeff Ober <sysread@fastmail.fm>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Jeff Ober.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

package Mysql::NameLocker;
use strict;
use Carp;
our $VERSION = '1.00';

=head1 NAME

Mysql::NameLocker - Safe way of locking and unlocking MySQL tables using named locks.

=head1 SYNOPSIS

 use Mysql::NameLocker;

 # Simulate a record lock
 my $tablename = 'category'
 my $id = 123;
 my $lockname = "$tablename_$id";
 my $timeout = 10;
 my $locker = new Mysql::NameLocker($dbh,$lockname,$timeout);

 # Execute some tricky statements here...

 # Locks are automically released when $locker goes out of scope.
 undef($locker);

=head1 DESCRIPTION

Mysql::NameLocker is a simple class for safely using MySQL named locks.
A locks is created when you instantiate the class and is automatically
released when the object goes out of scope (or when you call undef on the
object). One situation where this class is useful is when you have
persistent database connections such as in some mod_perl scripts and you
want to be sure that locks are always released even when a script dies
somewhere unexpectedly.

=head1 CLASS METHODS

=head2 new ($dbh,$lockname,$timeout)

Attempts to acquire a named lock and returns a Mysql::NameLocker object
that encapsulates this lock. If a timeout occurs, then undef is returned.
If an error occurs (The MySQL statement GET_LOCK() returns NULL) then this
constructor croaks.

Parameters:

=over 4

=item 1. DBI database handle object.

=item 2. Lock name.

=item 3. Timeout in seconds.

=back

Returns: Mysql::NameLocker object or undef if failed to acquire lock.

=cut

sub new {
 my $proto = shift;
 my $dbh = shift;
 my $lockname = shift;
 my $timeout = shift;
 unless(defined($dbh) && defined($lockname) && length($lockname) && defined($timeout)) {
  croak('Invalid parameters for ' . __PACKAGE__ . '->new() constructor!');
 }
 my $sth = $dbh->prepare('SELECT GET_LOCK(?,?)');
 unless(defined($sth)) {
  croak($dbh->errstr());
 }
 $sth->bind_param(1,$lockname);
 $sth->bind_param(2,$timeout);
 unless($sth->execute()) {
  croak($sth->errstr());
 }
 my ($result) = $sth->fetchrow_array();
 $sth->finish();
 unless(defined($result)) {
  croak("Error trying to acquire named lock.\n");
 }
 unless($result) {
  return undef;
 }
 my $self  = {'_dbh' => $dbh,
              '_lockname' => $lockname};
 my $class = ref($proto) || $proto;
 bless $self,$class;
 return $self;
}






=head2 DESTROY

Destructor called implicitly by perl when object is destroyed. The acquired
lock is released here if the DBI database handle is still connected.

=cut

sub DESTROY {
 my $self = shift;
 my $dbh = $self->{'_dbh'};
 if ($dbh->ping()) {
  my $sth = $dbh->prepare('SELECT RELEASE_LOCK(?)');
  $sth->bind_param(1,$self->{'_lockname'});
  $sth->execute();
  $sth->finish();
 }
}




1;


__END__


=head1 HISTORY

=over 4

=item Version 1.00  2002-03-26

Initial version

=back

=head1 AUTHOR

Craig Manley	E<lt>B<cmanley> at B<cpan> dot B<org>E<gt>

=head1 COPYRIGHT

Copyright (C) 2001 Craig Manley.  All rights reserved.
This program is free software; you can redistribute it and/or modify
it under under the same terms as Perl itself. There is NO warranty;
not even for MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=head1 SEE ALSO

The MySQL documentation about GET_LOCK() and RELEASE_LOCK().

=cut
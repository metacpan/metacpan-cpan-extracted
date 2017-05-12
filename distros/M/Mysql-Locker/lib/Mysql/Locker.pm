package Mysql::Locker;
#### Package information ####
# Description and copyright:
#   See POD (i.e. perldoc Mysql::Locker).
####

use strict;
use Carp;
our $VERSION = '1.00';
1;

####
# Constructor new()
# Parameters:
#	1. Database handle.
#	2. Reference to hash containing TABLENAME => LOCKTYPE pairs.
####
sub new {
 my $package = shift;
 my $dbh = shift;
 my $locks = shift;
 unless(defined($dbh) && defined($locks) && (ref($locks) eq 'HASH')) {
  croak('Invalid parameters for ' . __PACKAGE__ . ' constructor!');
 }
 my @tables = keys %{$locks};
 unless(@tables) {
  croak('No table locks specified in ' . __PACKAGE__ . ' constructor!');
 }
 my @pairs;
 foreach (@tables) {
  push(@pairs,"$_ " . $locks->{$_});
 }
 unless($dbh->do('LOCK TABLES ' . join(', ',@pairs))) {
  croak('Error locking tables: ' . $dbh->errstr());
 }
 my $self  = {'_dbh' => $dbh};
 bless $self;
 return $self;
}

####
# Destructor DESTROY()
####
sub DESTROY {
 my $self = shift;
 my $dbh = $self->{'_dbh'};
 if (defined($dbh)) {
  unless($dbh->do('UNLOCK TABLES')) {
   croak('Error unlocking tables: ' . $dbh->errstr());
  }
 }
}


__END__

=head1 NAME

Mysql::Locker - Safe way of locking and unlocking MySQL tables.

=head1 SYNOPSIS

 use Mysql::Locker;

 # Create table locks
 my $locker = new Mysql::Locker($dbh,
                                {'Customers' => 'READ',
                                 'Articles' => 'WRITE'});

 # Execute some tricky statements here...

 # Locks are automically released when $locker goes out of scope.
 undef($locker);

=head1 DESCRIPTION

Mysql::Locker is a simple class for safely using MySQL locks. Locks are
created when you instantiate the class and are automatically released when
the object goes out of scope (or when you call undef on the object). One
situation where this class is useful is when you have persistent database
connections such as in some mod_perl scripts and you want to be sure that
locks are always released even when a script dies somewhere unexpectedly.

=head1 CLASS METHODS

=over 4

=item new ($dbh,$locks);

Returns a new Mysql::Locker object.

=back

=head1 HISTORY

=over 4

=item Version 1.00  2002-01-02

Initial version

=back

=head1 AUTHOR

Craig Manley	c.manley@skybound.nl

=head1 COPYRIGHT

Copyright (C) 2001 Craig Manley <c.manley@skybound.nl>.  All rights reserved.
This program is free software; you can redistribute it and/or modify
it under under the same terms as Perl itself. There is NO warranty;
not even for MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=cut
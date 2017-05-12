package MyDBI;

use strict;
use vars qw($VERSION $DSN $USER $PASS $OPT);

$VERSION = sprintf "%d.%03d", q$Revision: 1.2 $ =~ /: (\d+)\.(\d+)/;

use base qw( SPOPSx::Ginsu::DBI );
use SPOPSx::Ginsu::DBI;

## database handle and DBI connection parameter vars used in closure
my ($DBH, $DBI_DSN, $DBI_USER, $DBI_PASS, $DBI_OPT);

sub DBH { 		return $DBH; }
sub DBI_DSN {	return $DBI_DSN; }
sub DBI_USER {	return $DBI_USER; }
sub DBI_PASS {	return $DBI_PASS; }
sub DBI_OPT {	return $DBI_OPT; }

sub set_DBH { $DBH = $_[1]; }
sub set_dbi_connect_args {
	my $self	= shift;
	$DBI_DSN	= shift || 'DBI:mysql:GinsuTest';
	$DBI_USER	= shift || 'test';
	$DBI_PASS	= shift || '';
	$DBI_OPT	= shift || { PrintError => 0, RaiseError => 1, AutoCommit => 1 };
}

## use globals to initialize DBI connection parameters at compile time
__PACKAGE__->set_dbi_connect_args($DSN, $USER, $PASS, $OPT);

1;
__END__

=head1 NAME

MyDBI - Datasource class with DBI connection parameters and DB handle.

=head1 SYNOPSIS

  BEGIN {
	$MyDBI::DSN  = "$database";	## or
	$MyDBI::DSN  = "database=$database;host=$host;port=$port";
	$MyDBI::USER = 'joe_user';
	$MyDBI::PASS = 'joes_password';
	$MyDBI::OPT  = { PrintError => 0, RaiseError => 1, AutoCommit => 1 };
  }

  use MyObject;		## where MyObject inherits from MyDBI
  
  $dbh = MyObject->global_datasource_handle;

=head1 DESCRIPTION

This class contains the variables holding the current database handle
and the connection parameters used to get a database handle if needed.

It is intended to serve as a base class for a set of SPOPSx::Ginsu
classes which use the same database. Classes using a different databases
should only need a copy of this file with a different name and possibly
different default connection parameters.

=head1 METHODS

=head2 Public Class Methods

=over 4

=item DBH

 $dbh = CLASS->DBH

Returns the DBI database handle if it is connected, undef otherwise.

=item DBI_DSN

 $dsn = CLASS->DBI_DSN

Returns the DSN parameter to use in the DBI connect() method.

=item DBI_USER

 $user = CLASS->DBI_USER

Returns the user parameter to use in the DBI connect() method.

=item DBI_PASS

 $pass = CLASS->DBI_PASS

Returns the password parameter to use in the DBI connect() method.

=item DBI_OPT

 $opt = CLASS->DBI_OPT

Returns the options hashref parameter to use in the DBI connect()
method.

=item set_DBH

 CLASS->set_DBH( $dbh )

Given a DBI database handle, it sets it to be returned by the DBH()
method.

=item set_dbi_connect_args

 CLASS->set_dbi_connect_args( $dsn, $user, $pass, $opt )

Sets the values to be returned by the DBI_DSN, DBI_USER, DBI_PASS and
DBI_OPT methods. All parameters are optional.

=back

=head1 COPYRIGHT

Copyright (c) 2001-2004 PSERC. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHORS

  Ray Zimmerman, <rz10@cornell.edu>

=head1 SEE ALSO

SPOPSx::Ginsu::DBI(3)
DBI(3)
SPOPS(3)
SPOPS::DBI(3)
SPOPS::DBI::MySQL(3)
perl(1)

=cut

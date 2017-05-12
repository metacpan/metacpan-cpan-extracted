########################################################################
# File:     mSQL.pm
# Author:   David Winters <winters@bigsnow.org>
# RCS:      $Id: mSQL.pm,v 1.1 2000/02/10 01:52:04 winters Exp winters $
#
# A class that implements object persistence using a mSQL database.
#
# This file contains POD documentation that may be viewed with the
# perldoc, pod2man, or pod2html utilities.
#
# Copyright (c) 1998-2000 David Winters.  All rights reserved.
# This program is free software; you can redistribute it
# and/or modify it under the same terms as Perl itself.
########################################################################

package Persistent::mSQL;
require 5.004;

use strict;
use vars qw(@ISA $VERSION $REVISION);

use Carp;
use English;

### we are a subclass of the all-powerful Persistent::DBI class ###
use Persistent::DBI;
@ISA = qw(Persistent::DBI);

### copy version number from superclass ###
$VERSION = '0.50';
$REVISION = (qw$Revision: 1.1 $)[1];

=head1 NAME

Persistent::mSQL - A Persistent Class implemented using a mSQL database

=head1 SYNOPSIS

  use Persistent::mSQL;
  use English;  # import readable variable names like $EVAL_ERROR

  eval {  ### in case an exception is thrown ###

    ### allocate a persistent object ###
    my $emp = new Persistent::mSQL($data_source, undef, undef, $table);

    ### define attributes of the object ###
    $emp->add_attribute('empno',    'ID',         'Number',   undef, 4);
    $emp->add_attribute('ename',    'Persistent', 'VarChar',  undef, 10);
    $emp->add_attribute('job',      'Persistent', 'VarChar',  undef, 9);
    $emp->add_attribute('mgr',      'Persistent', 'Number',   undef, 4);
    $emp->add_attribute('hiredate', 'Persistent', 'DateTime', undef);
    $emp->add_attribute('sal',      'Persistent', 'Number',   undef, 7, 2);
    $emp->add_attribute('comm',     'Persistent', 'Number',   undef, 7, 2);
    $emp->add_attribute('deptno',   'Persistent', 'Number',   undef, 2);

    ### query the datastore for some objects ###
    $emp->restore_where(qq{
                              sal > 1000 and
                              job = 'CLERK' and
                              ename LIKE 'M%'
                          }, "sal, ename");
    while ($emp->restore_next()) {
      printf "ename = %s, emp# = %s, sal = %s, hiredate = %s\n",
             $emp->ename, $emp->empno, $emp->sal, $emp->hiredate;
    }
  };

  if ($EVAL_ERROR) {  ### catch those exceptions! ###
    print "An error occurred: $EVAL_ERROR\n";
  }

=head1 ABSTRACT

This is a Persistent class that uses a mSQL database table to store
and retrieve objects.  This class can be instantiated directly or
subclassed.  The methods described below are unique to this class, and
all other methods that are provided by this class are documented in
the L<Persistent> documentation.  The L<Persistent> documentation has
a very thorough introduction to using the Persistent framework of
classes.

This class is part of the Persistent mSQL package which is available
from:

  http://www.bigsnow.org/persistent
  ftp://ftp.bigsnow.org/pub/persistent

=head1 DESCRIPTION

Before we get started describing the methods in detail, it should be
noted that all error handling in this class is done with exceptions.
So you should wrap an eval block around all of your code.  Please see
the L<Persistent> documentation for more information on exception
handling in Perl.

=head1 METHODS

=cut

########################################################################
#
# -----------------------------------------------------------
# PUBLIC METHODS OVERRIDDEN (REDEFINED) FROM THE PARENT CLASS
# -----------------------------------------------------------
#
########################################################################

########################################################################
# initialize
########################################################################

=head2 new -- Object Constructor

  use Persistent::mSQL;

  eval {
    $obj = new Persistent::mSQL($data_source, undef, undef, $table);
    ### or ###
    $obj = new Persistent::mSQL($dbh, $table);
  };
  croak "Exception caught: $@" if $@;

Allocates an object.  This method throws Perl execeptions so use it
with an eval block.

Parameters:

=over 4

=item These are the same as for the I<datastore> method below.

=back

=cut

########################################################################
# datastore
########################################################################

=head2 datastore -- Sets/Returns the Data Store Parameters

  eval {
    ### set the data store ###
    $obj->datastore($data_source, undef, undef, $table);
    ### or ###
    $obj->datastore($dbh, $table);

    ### get the data store ###
    $dbh = $obj->datastore();
  };
  croak "Exception caught: $@" if $@;

Returns (and optionally sets) the data store of the object.  This
method throws Perl execeptions so use it with an eval block.

Parameters:

=over 4

=item I<$data_source>

DBI data source name for the database.  Please refer to the
C<DBD::mSQL> documentation for valid data source names.

=item I<$username>

Connect to the database with this given username.  mSQL does not
support usernames and passwords currently so just pass B<undef> for
now.

=item I<$password>

Password for the username.  mSQL does not support usernames and
passwords currently so just pass B<undef> for now.

=item I<$table>

Table in the database that contains the objects.  This table should
exist prior to instantiating a Persistent class that will use it.

=item I<$dbh> (also a return value)

DBI handle to the database

=back

=cut

sub datastore {
  (@_ > 0) or croak 'Usage: $obj->datastore()';
  my $this = shift;
  ref($this) or croak "$this is not an object";

  $this->_trace();

  ### turn off transactions ###
  $this->{AutoCommit} = 1;

  $this->SUPER::datastore(@_);
}

########################################################################
# restore_where
########################################################################

=head2 restore_where -- Conditionally Restoring Objects

  use Persistent::mSQL;

  eval {
    my $emp = new Persistent::mSQL($data_source, undef, undef, $table);
    $emp->restore_where(
      " job = 'CLERK' and sal > 1000",
      "sal DESC, ename"
    );
    while ($emp->restore_next()) {
      print "Restored: ";  print_person($person);
    }
  };
  croak "Exception caught: $@" if $@;

Restores objects from the data store that meet the specified
conditions.  The objects are returned one at a time by using the
I<restore_next> method and in a sorted order if specified.  This
method throws Perl execeptions so use it with an eval block.

Since this is a SQL based Persistent class, the I<restore_where>
method expects a valid SQL WHERE clause for the first argument,
I<$where>, and a valid SQL ORDER BY clause for the optional second
argument, I<$order_by>.

Parameters:

=over 4

=item I<$where>

Conditional expression for the requested objects.  The format of this
expression is a SQL WHERE clause without the WHERE keyword.  This
argument is optional.

=item I<$order_by>

Sort expression for the requested objects.  The format of this
expression is a SQL ORDER BY clause with the ORDER BY keywords.  This
argument is optional.

=back

Returns:

=over 4

=item I<$num_of_objs>

The number of objects that match the conditions.

=back

See the L<Persistent> documentation for more information.

=cut

=head1 OTHER METHODS

For a description of the other methods that this subclass provides,
please refer to the L<Persistent::DBI> documentation which is the
parent class.  Or refer to the L<Persistent> documentation for a very
thorough introduction and reference to the Persistent Framework of
Classes.

=cut

########################################################################
#
# ---------------
# PRIVATE METHODS
# ---------------
#
########################################################################

########################################################################
# Function:    _get_sql_for_string_to_date
# Description: Returns the SQL to convert a string into a date.
#              The returned SQL is mSQL specific.
# Parameters:  $dt_str = Date string in the following format:
#                   YYYY-MM-DD HH24:MI:SS
# Returns:     $sql = SQL to convert the string to a date
########################################################################

sub _get_sql_for_string_to_date {
  (@_ > 1) or croak 'Usage: $obj->_get_sql_for_string_to_date($dt_str)';
  my($this, $dt_str) = @_;
  ref($this) or croak "$this is not an object";

  $this->_trace();

  my @months = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
  my($year, $month, $day) = split('-', (split(' ', $dt_str))[0]);

  "'$day-$months[$month-1]-$year'";
}

########################################################################
# Function:    _get_sql_for_date_to_string
# Description: Returns the SQL to convert a date into a string.
#              The returned SQL is mSQL specific.
# Parameters:  $dt_col = name of a Date column to be converted into a
#              string.
# Returns:     $sql = SQL to convert the date column into a string
########################################################################

sub _get_sql_for_date_to_string {
  (@_ > 1) or croak 'Usage: $obj->_get_sql_for_date_to_string($dt_col)';
  my($this, $dt_col) = @_;
  ref($this) or croak "$this is not an object";

  $this->_trace();

  "$dt_col";
}

########################################################################
# Function:    _get_column_name
# Description: Returns the name of the column for the attribute of the object.
# Parameters:  $attribute = name of the attribute of the object
# Returns:     $column = name of the column in the table that stores
#                        the attribute of the object
########################################################################

sub _get_column_name {
  (@_ > 1) or croak 'Usage: $obj->_get_column_name($attribute)';
  my($this, $attribute) = @_;
  ref($this) or croak "$this is not an object";

  $this->_trace();

  $attribute;
}

### end of library ###
1;
__END__

=head1 SEE ALSO

L<Persistent>, L<Persistent::DBI>, L<Persistent::DataType::DateTime>

=head1 BUGS

Due to the limitation of the DATE column in mSQL, the time (hours,
minutes, and seconds) associated with a DateTime attribute is not
stored or retrieved.  In other words, a DateTime attribute is only
good for a date (year, month, and day) when using mSQL as the data
store.  This is because mSQL has both a DATE and TIME column, but no
combined DATE and TIME column.  This problem should have a work-around
available when a Time datatype object is created for the Persistent
classes.

This software is definitely a work in progress.  So if you find any
other bugs please email them to me with a subject of 'Persistent Bug'
at:

  winters@bigsnow.org

And you know, include the regular stuff: OS, Perl, mSQL versions,
snippet of code, etc.

=head1 AUTHORS

  David Winters <winters@bigsnow.org>

=head1 COPYRIGHT

Copyright (c) 1998-2000 David Winters.  All rights reserved. This program
is free software; you can redistribute it and/or modify it under the
same terms as Perl itself.

=cut

########################################################################
# File:     DBI.pm
# Author:   David Winters <winters@bigsnow.org>
# RCS:      $Id: DBI.pm,v 1.2 2000/02/10 00:18:34 winters Exp winters $
#
# An abstract class that implements object persistence using DBI.
# This class should be inherited by other persistent classes that
# implement object persistence using a DBI database.
#
# This file contains POD documentation that may be viewed with the
# perldoc, pod2man, or pod2html utilities.
#
# Copyright (c) 1998-2000 David Winters.  All rights reserved.
# This program is free software; you can redistribute it
# and/or modify it under the same terms as Perl itself.
########################################################################

package Persistent::DBI;
require 5.004;

use strict;
use vars qw(@ISA $VERSION $REVISION);

use Carp;
use English;
use DBI;

### we are a subclass of the all-powerful Persistent::Base class ###
use Persistent::Base;
@ISA = qw(Persistent::Base);

### copy version number from superclass ###
$VERSION = '0.50';
$REVISION = (qw$Revision: 1.2 $)[1];

=head1 NAME

Persistent::DBI - An Abstract Persistent Class implemented using a DBI Data Source

=head1 SYNOPSIS

  ### we are a subclass of ... ###
  use Persistent::DBI;
  @ISA = qw(Persistent::DBI);

=head1 ABSTRACT

This is an abstract class used by the Persistent framework of classes
to implement persistence using DBI data stores.  This class provides
the methods and interface for implementing Persistent DBI classes.
Refer to the L<Persistent> documentation for a very thorough
introduction to using the Persistent framework of classes.

This class is part of the Persistent DBI package which is available
from:

  http://www.bigsnow.org/persistent
  ftp://ftp.bigsnow.org/pub/persistent

=head1 DESCRIPTION

Before we get started describing the methods in detail, it should be
noted that all error handling in this class is done with exceptions.
So you should wrap an eval block around all of your code.  Please see
the L<Persistent> documentation for more information on exception
handling in Perl.

=head1 OVERRIDDEN PUBLIC METHODS PROVIDED IN THIS CLASS

=cut

########################################################################
#
# -----------------------------------------------------------
# PUBLIC METHODS OVERRIDDEN (REDEFINED) FROM THE PARENT CLASS
# -----------------------------------------------------------
#
########################################################################

########################################################################
# Function:    DESTROY
# Description: Object destructor.
# Parameters:  None
# Returns:     None
########################################################################

sub DESTROY {
  my $this = shift;

  $this->_trace();

  ### if the object created a DBH (i.e. it was not passed a DBH) ###
  ### then disconnect it ###
  if ($this->{DataStore}->{CreatedDBH}) {
    $this->{DataStore}->{DBH}->disconnect();
    _check_dbi_error("Can't disconnect from database");
  }
}

########################################################################
# initialize
########################################################################

=head2 new -- Object Constructor

  use Persistent::DBI;

  eval {
    my $obj = new Persistent::DBI($data_source, $username, $password, $table);
    ### or ###
    my $obj = new Persistent::DBI($dbh, $table);
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
    $dbh = $obj->datastore($data_source, $username, $password, $table);
    ### or ###
    $dbh = $obj->datastore($dbh, $table);

    ### get the data store ###
    $dbh = $obj->datastore();
  };
  croak "Exception caught: $@" if $@;

Returns (and optionally sets) the data store of the object.  This
method throws Perl execeptions so use it with an eval block.

Parameters:

=over 4

=item I<$data_source>

DBI data source name for the database.  Please refer to the L<DBI>
documentation for valid data source names.

=item I<$username>

Connect to the database with this given username

=item I<$password>

Password for the username

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

  my $dbh;  ### database handle ###

  ### determine number of args passed ###
  if (@_ == 0) {
    $dbh = $this->{DataStore}->{DBH};
  } elsif (@_ == 2) {  ### database handle passed ###
    ### save the database handle ###
    $dbh = shift;
    my $table = shift;
    $this->{DataStore}->{DBH} = $dbh;
    $this->{DataStore}->{CreatedDBH} = 0;
    $this->{DataStore}->{Table} = $table;
  } elsif (@_ >= 3) {
    ### connect to the database ###
    my($data_source, $username, $password, $table) = @_;
    $dbh = DBI->connect($data_source, $username, $password,
			{AutoCommit => $this->{AutoCommit},
			 PrintError => 0,
			 RaiseError => 0});
    $this->_check_dbi_error("Can't connect to database: $data_source");

    ### save the database handle ###
    $this->{DataStore}->{DBH} = $dbh;
    $this->{DataStore}->{CreatedDBH} = 1;
    $this->{DataStore}->{Table} = $table;
  } else {
    croak('Usage: $obj->datastore([$data_source, $username, $password, $table])' .
	  "\n" .
	  '  -or- $obj->datastore([$dbh, $table]');
  }

  $dbh;
}

########################################################################
# insert
########################################################################

=head2 insert -- Insert an Object into the Data Store

  eval {
    $person->insert();
  };
  croak "Exception caught: $@" if $@;

Inserts an object into the data store.  This method throws Perl
execeptions so use it with an eval block.

Parameters:

=over 4

=item None.

=back

Returns:

=over 4

=item Nothing.

=back

See the L<Persistent> documentation for more information.

=cut

sub insert {
  (@_ == 1) or croak 'Usage: $obj->insert()';
  my $this = shift;
  ref($this) or croak "$this is not an object";

  $this->_trace();

  $this->_check_id();  ### check validity of object ID ###

  my $dbh = $this->_get_dbh();  ### database handle ###

  ### build the SQL ###
  my $sql = "INSERT INTO $this->{DataStore}->{Table} (\n";
  $sql   .= join(",\n", @{$this->{DataOrder}});
  $sql   .= ")\n";
  $sql   .= "VALUES (\n";
  my @values;
  foreach my $field (@{$this->{DataOrder}}) {
    if ((ref $this->{Data}->{$field}->[0]) =~ /DateTime$/) {
      if (defined $this->value($field)) {
	push(@values,
	     $this->_get_sql_for_string_to_date($this->value($field)));
      } else {
	push(@values, "NULL");
      }
    } else {
      push(@values, $dbh->quote($this->value($field)));
    }
  }
  $sql .= join(",\n", @values);
  $sql .= ")\n";

  print "SQL = $sql\n" if $this->debug() eq 'SQL';

  ### execute the SQL ###
  eval {
    $dbh->do($sql);
    $this->_check_dbi_error("Can't execute SQL statement:\n$sql");
  };
  if ($EVAL_ERROR) {
    $dbh->rollback() unless $this->{AutoCommit};
    croak $EVAL_ERROR;
  } else {
    $dbh->commit() unless $this->{AutoCommit};
  }

  ### save the object ID ###
  $this->_prev_id($this->_id());
}

########################################################################
# update
########################################################################

=head2 update -- Update an Object in the Data Store

  eval {
    $person->update();
  };
  croak "Exception caught: $@" if $@;

Updates an object in the data store.  This method throws Perl
execeptions so use it with an eval block.

Parameters:

=over 4

=item I<@id>

Values of the Identity attributes of the object.  This argument is
optional and will default to the Identifier values of the object as
the default.

This argument is useful if you are updating the Identity attributes of
the object and you already have all of the attribute values so you do
not need to restore the object (like a CGI request with hidden fields,
maybe).  So you can just set the Identity attributes of the object to
the new values and then pass the old Identity values as arguments to
the I<update> method.  For example, if Pebbles Flintstone married Bam
Bam Rubble, then you could update her last name like this:

  ### Pebbles already exists in the data store, but we don't ###
  ### want to do an extra restore because we already have    ###
  ### all of the attribute values ###

  $person->lastname('Rubble');
  $person->firstname('Pebbles');
  ### set the rest of the attributes ... ###

  $person->update('Flintstone', 'Pebbles');

Or, if don't want to set all of the object's attributes, you can just
restore it and then update it like this:

  ### restore object from data store ###
  if ($person->restore('Flintstone', 'Pebbles')) {
    $person->lastname('Rubble');
    $person->update();
  }

=back

Returns:

=over 4

=item Nothing.

=back

See the L<Persistent> documentation for more information.

=cut

########################################################################
# save
########################################################################

=head2 save -- Save an Object to the Data Store

  eval {
    $person->save();
  };
  croak "Exception caught: $@" if $@;

Saves an object to the data store.  The object is inserted if it does
not already exist in the data store, otherwise, it is updated.  This
method throws Perl execeptions so use it with an eval block.

Parameters:

=over 4

=item None.

=back

Returns:

=over 4

=item I<$flag>

A true value if the object previously existed in the data store (it
was updated), and a false value if not (it was inserted).

=back

See the L<Persistent> documentation for more information.

=cut

########################################################################
# delete
########################################################################

=head2 delete -- Delete an Object from the Data Store

  eval {
    $person->delete();
  };
  croak "Exception caught: $@" if $@;

Deletes an object from the data store.  This method throws Perl
execeptions so use it with an eval block.

Parameters:

=over 4

=item I<@id>

Values of the Identity attributes of the object.  This argument is
optional and will default to the Identifier values of the object as
the default.

=back

Returns:

=over 4

=item Nothing.

=back

See the L<Persistent> documentation for more information.

=cut

sub delete {
  (@_ > 0) or croak 'Usage: $obj->delete([@id])';
  my ($this, @id) = @_;
  ref($this) or croak "$this is not an object";

  $this->_trace();

  ### get ID of object ###
  @id = $this->_prev_id() if !@id;
  $this->_check_id(@id);  ### check that the ID is valid ###

  my $dbh = $this->_get_dbh();  ### database handle ###

  ### build the SQL ###
  my $sql = "DELETE FROM $this->{DataStore}->{Table}\n";
  my @values;
  foreach my $field (@{$this->{IdFields}}) {
    my $id = shift @id;
    if ((ref $this->{Data}->{$field}->[0]) =~ /DateTime$/) {
      push(@values,
	   $this->_get_sql_for_string_to_date($this->value($field)));
    } else {
      if (defined $id && $id ne '') {
	push(@values, sprintf("$field = %s", $dbh->quote($id)));
      } else {
	push(@values, "$field IS NULL");
      }
    }
  }
  $sql .= "WHERE " . join(" AND ", @values) . "\n";

  print "SQL = $sql\n" if $this->debug() eq 'SQL';

  ### execute the SQL ###
  eval {
    $dbh->do($sql);
    $this->_check_dbi_error("Can't execute SQL statement:\n$sql");
  };
  if ($EVAL_ERROR) {
    $dbh->rollback() unless $this->{AutoCommit};
    croak $EVAL_ERROR;
  } else {
    $dbh->commit() unless $this->{AutoCommit};
  }

  ### clear the previous ID ###
  undef(%{$this->{PrevId}});

  1;
}

########################################################################
# restore
########################################################################

=head2 restore -- Restore an Object from the Data Store

  eval {
    $person->restore(@id);
  };
  croak "Exception caught: $@" if $@;

Restores an object from the data store.  This method throws Perl
execeptions so use it with an eval block.

Parameters:

=over 4

=item I<@id>

Values of the Identity attributes of the object.  This method throws
Perl execeptions so use it with an eval block.

=back

Returns:

=over 4

=item I<$flag>

A true value if the object previously existed in the data store (it
was restored), and a false value if not (nothing to restore).

=back

See the L<Persistent> documentation for more information.

=cut

########################################################################
# restore_where
########################################################################

=head2 restore_where -- Conditionally Restoring Objects

  use Persistent::DBI;

  eval {
    my $emp = new Persistent::DBI('ORCL', 'scott', 'tiger', 'emp');
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

sub restore_where {
  (@_ < 4) or croak 'Usage: $obj->restore_where([$where], [$order_by])';
  my ($this, $where, $order_by) = @_;
  ref($this) or croak "$this is not an object";

  $this->_trace();

  my $dbh = $this->_get_dbh();  ### database handle ###

  ### build the SQL ###
  my $sql = "SELECT\n";
  my @values;
  foreach my $field (@{$this->{DataOrder}}) {
    if ((ref $this->{Data}->{$field}->[0]) =~ /DateTime$/) {
      push(@values, $this->_get_sql_for_date_to_string($field));
    } else {
      push(@values, $field);
    }
  }
  $sql .= join(",\n", @values) . "\n";
  $sql .= "FROM $this->{DataStore}->{Table}\n";
  if (defined($where) && $where =~ /\S/) {
    $sql .= "WHERE $where\n";
  }
  if (defined($order_by) && $order_by =~ /\S/) {
    $sql .= "ORDER BY $order_by\n";
  }

  print "SQL = $sql\n" if $this->debug() eq 'SQL';

  ### execute the SQL ###
  my $sth = $dbh->prepare($sql);
  $this->_check_dbi_error("Can't prepare SQL statement:\n$sql");
  $sth->execute();
  $this->_check_dbi_error("Can't execute SQL statement:\n$sql");

  ### save the restored objects ###
  my @objs_data;
  while (my $href = $sth->fetchrow_hashref()) {
    my $data = [];
    foreach my $field (@{$this->{DataOrder}}) {
      push(@$data, $href->{$this->_get_column_name($field)});
    }
    push(@objs_data, $data);
  }
  $sth->finish();
  $this->{RestoredData} = \@objs_data;

  scalar @objs_data;
}

########################################################################
# quote
########################################################################

=head2 quote -- Quotes a String Literal for Use in a SQL Query

  $person->restore_where(sprintf("lastname = %s",
                                 $person->quote($lastname)));

Quotes a string literal for use in an SQL statement by escaping any
special characters (such as quotation marks) contained within the
string and adding the required type of outer quotation marks.

Parameters:

=over 4

=item I<$str>

String to quote and escape.

=back

Returns:

=over 4

=item I<$quoted_str>

Quoted and escaped string.

=back

=cut

sub quote {
  (@_ == 2) or croak 'Usage: $obj->quote($str)';
  my ($this, $str) = @_;

  if (defined $str) {
    $str =~ s/\'/\'\'/g;         # ISO SQL2
    "'$str'";
  } else {
    "NULL";
  }
}

########################################################################
#
# ------------------
# NEW PUBLIC METHODS
# ------------------
#
########################################################################

########################################################################
#
# ---------------
# PRIVATE METHODS
# ---------------
#
########################################################################

########################################################################
# Function:    _check_dbi_error
# Description: Checks for errors in DBI and croaks if an error has
#              occurred.
# Parameters:  $err_str (optional) = error string prepended to the
#                                    DBI error message
# Returns:     None
########################################################################

sub _check_dbi_error {
  (@_ > 0) or croak 'Usage: $obj->_check_dbi_error()';
  my($this, $err_str) = @_;

  if ($DBI::err) {  ### check for an error ###
    if ($err_str) {
      $err_str = "$err_str\n";
    }
    croak($err_str .
	  "DBI Error Code: $DBI::err\n" .
	  "DBI Error Message: $DBI::errstr\n");
  }
}

########################################################################
# Function:    _get_dbh
# Description: Returns the handle of the database.
# Parameters:  None.
# Returns:     $dbh = handle of the datastore
########################################################################

sub _get_dbh {
  (@_ > 0) or croak 'Usage: $obj->_get_dbh()';
  my($this) = @_;

  $this->_trace();

  $this->{DataStore}->{DBH};
}

=head1 ABSTRACT METHODS THAT NEED TO BE OVERRIDDEN IN THE SUBCLASS

=cut

########################################################################
#
# --------------------------------------------------------------------------
# PRIVATE ABSTRACT METHODS TO BE OVERRIDDEN (REDEFINED) IN THE DERIVED CLASS
# --------------------------------------------------------------------------
#
# NOTE: These methods MUST be overridden in the subclasses.
#       In order for even a minimal subclass to work, you must
#       override these methods in the subclass.
#
########################################################################

########################################################################
# datastore
########################################################################

=head2 datastore -- Sets/Returns the Data Store Parameters

  eval {
    ### set the data store ###
    $obj->datastore(@args);

    ### get the data store ###
    $dbh = $obj->datastore();
  };
  croak "Exception caught: $@" if $@;

Returns (and optionally sets) the data store of the object.  This
method throws Perl execeptions so use it with an eval block.

Setting the data store usually involves formatting the arguments into
a DBI connect string and passing them to the
Persistent::DBI::datastore method.  Getting the data store usually
involves returning whatever the Persistent::DBI::datastore method
returns.

This method requires implementing.

Parameters:

=over 4

=item Varies by implementation.

=back

Returns:

=over 4

=item Varies by implementation.

=back

=cut

########################################################################
# _get_sql_for_string_to_date
########################################################################

=head2 _get_sql_for_string_to_date -- Returns the SQL to Convert a
Perl String into a RDBMS specific Date Format

  eval {
    $sql = $obj->_get_sql_for_string_to_date($dt_str);
  };
  croak "Exception caught: $@" if $@;

Returns the SQL to convert a Perl string into a database specific date
format.  This method is abstract and should be implemented in the
children of this class.  This method throws Perl execeptions so use it
with an eval block.

This method requires implementing.

Parameters:

=over 4

=item I<$dt_str>

Date string in the following format:

  YYYY-MM-DD HH24:MI:SS

where YYYY is a 4 digit year, MM is a 2 digit month (1-12), DD is a 2
digit day (1-31), HH24 is the hour using a 24 hour clock (0-23), MI is
minutes (0-59), and SS is seconds (0-59).

=back

Returns:

=over 4

=item I<$sql>

SQL that will convert the date string into a valid date format for the
database.  For example, an Oracle database would need some SQL
returned that looked something like this:

  "TO_DATE('$dt_str', 'YYYY-MM-DD HH24:MI:SS')"

=back

=cut

sub _get_sql_for_string_to_date {
  (@_ > 1) or croak 'Usage: $obj->_get_sql_for_string_to_date($dt_str)';
  my($this, $dt_str) = @_;
  ref($this) or croak "$this is not an object";

  $this->_trace();

  croak "method not implemented";
}

########################################################################
# _get_sql_for_date_to_string
########################################################################

=head2 _get_sql_for_date_to_string -- Returns the SQL to Convert a
RDBMS specific Date Column into a Perl string

  eval {
    $sql = $obj->_get_sql_for_date_to_string($dt_col);
  };
  croak "Exception caught: $@" if $@;

Returns the SQL to convert a database specific date column into a Perl
string that is formatted for a Persistent::DataType::DateTime
constructor.  This method is abstract and should be implemented in the
children of this class.  This method throws Perl execeptions so use it
with an eval block.

This method requires implementing.

Parameters:

=over 4

=item I<$dt_col>

Name of a date column from the database to be converted into a string.

=back

Returns:

=over 4

=item I<$sql>

SQL that will convert the date column into a valid format for the
Persistent::DataType::DateTime constructor such as the following
format:

  YYYY-MM-DD HH24:MI:SS

where YYYY is a 4 digit year, MM is a 2 digit month (1-12), DD is a 2
digit day (1-31), HH24 is the hour using a 24 hour clock (0-23), MI is
minutes (0-59), and SS is seconds (0-59).

=back

=cut

sub _get_sql_for_date_to_string {
  (@_ > 1) or croak 'Usage: $obj->_get_sql_for_date_to_string($dt_col)';
  my($this, $dt_col) = @_;
  ref($this) or croak "$this is not an object";

  $this->_trace();

  croak "method not implemented";
}

########################################################################
# _get_column_name
########################################################################

=head2 _get_column_name -- Returns the Column Name for the Attribute

  eval {
    $column = $obj->_get_column_name($field);
  };
  croak "Exception caught: $@" if $@;

Returns the name of the column from the table for the attribute of the
object.  This is database dependent since some databases are
case-sensitive and others are not.  This method is abstract and should
be implemented in the children of this class.  This method throws Perl
execeptions so use it with an eval block.

This method requires implementing.

Parameters:

=over 4

=item I<$field>

Name of an attribute (or field) of an object.

=back

Returns:

=over 4

=item I<$column>

Name of the column in the table that stores the attribute of the
object.

=back

=cut

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

L<Persistent>, L<Persistent::Oracle>, L<Persistent::MySQL>,
L<Persistent::mSQL>, L<Persistent::DataType::DateTime>

=head1 BUGS

This software is definitely a work in progress.  So if you find any
bugs please email them to me with a subject of 'Persistent Bug' at:

  winters@bigsnow.org

And you know, include the regular stuff, OS, Perl version, snippet of
code, etc.

=head1 AUTHORS

  David Winters <winters@bigsnow.org>

=head1 COPYRIGHT

Copyright (c) 1998-2000 David Winters.  All rights reserved. This program
is free software; you can redistribute it and/or modify it under the
same terms as Perl itself.

=cut

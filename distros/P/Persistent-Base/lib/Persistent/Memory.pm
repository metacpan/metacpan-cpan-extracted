########################################################################
# File:     Memory.pm
# Author:   David Winters <winters@bigsnow.org>
# RCS:      $Id: Memory.pm,v 1.10 2000/02/08 02:35:02 winters Exp $
#
# A class that implements object persistence using memory (RAM).
# This class inherits from other persistent classes.
#
# This file contains POD documentation that may be viewed with the
# perldoc, pod2man, or pod2html utilities.
#
# Copyright (c) 1998-2000 David Winters.  All rights reserved.
# This program is free software; you can redistribute it
# and/or modify it under the same terms as Perl itself.
########################################################################

package Persistent::Memory;
require 5.004;

use strict;
use vars qw(@ISA $VERSION $REVISION);

use Carp;
use English;
use Fcntl ':flock';                        # import LOCK_* constants

### we are a subclass of the all-powerful Persistent::Base class ###
use Persistent::Base;
@ISA = qw(Persistent::Base);

### copy version number from superclass ###
$VERSION = $Persistent::Base::VERSION;
$REVISION = (qw$Revision: 1.10 $)[1];

=head1 NAME

Persistent::Memory - A Persistent Class implemented using Memory (RAM)

=head1 SYNOPSIS

  use Persistent::Memory;
  use English;  # import readable variable names like $EVAL_ERROR

  eval {  ### in case an exception is thrown ###

    ### allocate a persistent object ###
    my $person = new Persistent::Memory();

    ### define attributes of the object ###
    $person->add_attribute('firstname', 'ID', 'VarChar', undef, 10);
    $person->add_attribute('lastname',  'ID', 'VarChar', undef, 20);
    $person->add_attribute('telnum', 'Persistent',
                           'VarChar', undef, 15);
    $person->add_attribute('bday', 'Persistent', 'DateTime', undef);
    $person->add_attribute('age', 'Transient', 'Number', undef, 2);

    ### query the datastore for some objects ###
    $person->restore_where(qq{
                              lastname = 'Flintstone' and
                              telnum =~ /^[(]?650/
                             });
    while ($person->restore_next()) {
      printf "name = %s, tel# = %s\n",
             $person->firstname . ' ' . $person->lastname,
             $person->telnum;
    }
  };

  if ($EVAL_ERROR) {  ### catch those exceptions! ###
    print "An error occurred: $EVAL_ERROR\n";
  }

=head1 ABSTRACT

This is a Persistent class that uses memory (RAM) to store and
retrieve objects.  This can be useful when you want to create a cache
of objects (i.e. a server-side web cache).  This class can be
instantiated directly or subclassed.  The methods described below are
unique to this class, and all other methods that are provided by this
class are documented in the L<Persistent> documentation.  The
L<Persistent> documentation has a very thorough introduction to using
the Persistent framework of classes.

This class is part of the Persistent base package which is available
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

  use Persistent::Memory;

  eval {
    my $person = new Persistent::Memory($field_delimiter);
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
    $person->datastore($field_delimiter);

    ### get the data store ###
    $href = $person->datastore();
  };
  croak "Exception caught: $@" if $@;

Returns (and optionally sets) the data store of the object.  This
method throws Perl execeptions so use it with an eval block.

Parameters:

=over 4

=item I<$field_delimiter>

Delimiter used to separate the attributes of the object in the data
store.  This argument is optional and will be initialized to the value
of the special Perl variable I<$;> (or I<$SUBSCRIPT_SEPARATOR> if you
are using the English module) as a default.

=back

Returns:

=over 4

=item I<$href>

Reference to the hash used as the data store.

=back

=cut

sub datastore {
  (@_ > 0) or croak 'Usage: $obj->datastore()';
  my $this = shift;
  ref($this) or croak "$this is not an object";

  $this->_trace();

  ### set it ###
  $this->{DataStore}->{Hash} = {} if !defined($this->{DataStore}->{Hash});
  $this->field_delimiter(shift) if @_;

  ### return it ###
  $this->{DataStore}->{Hash};
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

=item None.

=back

See the L<Persistent> documentation for more information.

=cut

sub insert {
  (@_ == 1) or croak 'Usage: $obj->insert()';
  my $this = shift;
  ref($this) or croak "$this is not an object";

  $this->_trace();

  $this->_check_id();  ### check validity of object ID ###

  ### get ID of object ###
  my @id = $this->_id();
  my $delimiter = $this->field_delimiter();  ### datastore field delimiter ###
  my $id = join($delimiter, @id);

  $this->_lock_datastore('MUTEX');      ### start of critical section ###
  my $href = $this->_load_datastore();  ### get hash ref to data store ###

  ### check for previous existence of object in data store ###
  if (defined $href->{$id}) {
    croak(sprintf("An object with this ID (%s) already exists " .
		  "in the data store",
		  join(', ', @id)));
  }

  ### join attributes together ###
  my @data;
  foreach my $attr (@{$this->{DataOrder}}) {
    my $value = $this->value($attr);
    push(@data, defined $value ? $value : '');
  }
  my $data = join($delimiter, @data);

  ### store object ###
  $href->{$id} = $data;

  ### save the object ID ###
  $this->_prev_id(@id);

  $this->_flush_datastore();
  $this->_unlock_datastore();  ### end of critical section ###
}

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

=item I<$flag>

A true value if the object previously existed in the data store (it
was deleted), and a false value if not (nothing to delete).

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
  my $delimiter = $this->field_delimiter();  ### datastore field delimiter ###
  my $id = join($delimiter, @id);

  $this->_lock_datastore('MUTEX');      ### start of critical section ###
  my $href = $this->_load_datastore();  ### get hash ref to data store ###

  ### check for previous existence of object in data store ###
  my $rc = defined $href->{$id} ? 1 : 0;

  ### delete object from data store ###
  delete $href->{$id};

  ### clear the previous ID ###
  undef(%{$this->{PrevId}});

  $this->_flush_datastore();
  $this->_unlock_datastore();  ### end of critical section ###

  $rc;
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

sub restore {
  (@_ > 1) or croak 'Usage: $obj->restore()';
  my ($this, @id) = @_;
  ref($this) or croak "$this is not an object";

  $this->_trace();

  $this->_check_id(@id);  ### check validity of object ID ###

  ### get hash key of object ###
  my $delimiter = $this->field_delimiter();  ### datastore field delimiter ###
  my $id = join($delimiter, @id);

  $this->_lock_datastore('SHARED');     ### start of critical section ###
  my $href = $this->_load_datastore();  ### get hash ref to data store ###

  ### check for previous existence of object in data store ###
  my $rc;
  if (defined $href->{$id}) {  ### found an object ###

    ### clear the transient data ###
    foreach my $attr (keys %{$this->{TempData}}) {
      $this->value($attr, undef);
    }

    ### load the persistent data ###
    my @data = split("\Q$delimiter\E", $href->{$id});  ### quote metachars ###
    foreach my $attr (@{$this->{DataOrder}}) {
      $this->value($attr, shift @data);
    }

    ### save the object ID ###
    $this->_prev_id($this->_id());

    $rc = 1;
  } else {              ### no more objects left ###
    $rc = 0;
  }

  $this->_close_datastore();
  $this->_unlock_datastore();  ### end of critical section ###

  $rc;
}

########################################################################
# restore_where
########################################################################

=head2 restore_where -- Conditionally Restoring Objects

  use Persistent::Memory;

  eval {
    my $person = new Persistent::Memory('|');
    $person->restore_where(
      "lastname = 'Flintstone' and telnum =~ /^[(]?650/",
      "lastname, firstname, telnum DESC"
    );
    while ($person->restore_next()) {
      print "Restored: ";  print_person($person);
    }
  };
  croak "Exception caught: $@" if $@;

Restores objects from the data store that meet the specified
conditions.  The objects are returned one at a time by using the
I<restore_next> method and in a sorted order if specified.  This
method throws Perl execeptions so use it with an eval block.

Since this is a Perl based Persistent class, the I<restore_where>
method expects the I<$where> argument to use Perl expressions.

Parameters:

=over 4

=item I<$where>

Conditional expression for the requested objects.  The format of this
expression is similar to a SQL WHERE clause.  This argument is
optional.

=item I<$order_by>

Sort expression for the requested objects.  The format of this
expression is similar to a SQL ORDER BY clause.  This argument is
optional.

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

  ### iterate through all of the objects in the datastore ###
  ### and check if they satisfy the boolean expression (WHERE clause) ###
  my @objs_data;
  my $bool_expr = $this->_parse_query($where);
  my $delimiter = $this->field_delimiter();  ### datastore field delimiter ###

  $this->_lock_datastore('SHARED');     ### start of critical section ###
  my $href = $this->_load_datastore();  ### get hash ref to datastore ###

  while (my($key, $data) = each %$href) {
    my @data = split("\Q$delimiter\E", $data);  ### quote regexp metachars ###

    ### save the object data that satisfies the boolean expression ###
    my $my_stmt =
      "my(" . join(", ", map("\$$_", @{$this->{DataOrder}})) . ') = @data;';
    my $eval_str = qq{
      $my_stmt
      push(\@objs_data, [\@data]) if ($bool_expr);
    };
    eval($eval_str);
    if ($EVAL_ERROR) {
      croak "Query statement failed: $eval_str\nError: $EVAL_ERROR";
    }
  }

  ### sort the objects ###
  $this->_sort_objects($order_by, \@objs_data) if $order_by;

  ### save the restored objects ###
  $this->{RestoredData} = \@objs_data;

  $this->_close_datastore();
  $this->_unlock_datastore();  ### end of critical section ###

  scalar @objs_data;
}

########################################################################
#
# ------------------
# NEW PUBLIC METHODS
# ------------------
#
########################################################################

########################################################################
# Function:    field_delimiter
# Description: Gets/sets the delimiter used to join the fields together
#              for storage in the datastore.
# Parameters:  None.
# Returns:     $delimiter = field delimiter of the datastore
########################################################################

sub field_delimiter {
  (@_ > 0) or croak 'Usage: $obj->field_delimiter([$delimiter])';
  my $this = shift;
  ref($this) or croak "$this is not an object";

  $this->_trace();

  ### set it ###
  $this->{DataStore}->{Delimiter} = shift if @_;

  ### return it ###
  if (defined $this->{DataStore}->{Delimiter}) {
    $this->{DataStore}->{Delimiter};
  } else {
    $SUBSCRIPT_SEPARATOR;
  }
}

########################################################################
#
# ---------------
# PRIVATE METHODS
# ---------------
#
########################################################################

########################################################################
# Function:    _load_datastore
# Description: No loading of the datastore into a hash is needed, so
#              just a reference to it is returned.
# Parameters:  None.
# Returns:     $href = hash reference to the datstore
########################################################################

sub _load_datastore {
  (@_ > 0) or croak 'Usage: $obj->_load_datastore()';
  my $this = shift;
  ref($this) or croak "$this is not an object";

  $this->_trace();

  ### return the hash ref to the datastore ###
  $this->{DataStore}->{Hash};
}

########################################################################
# Function:    _flush_datastore
# Description: Flushes the hash containing the data back to the
#              datastore.
#              In this case, the method does nothing for this module.
# Parameters:  None.
# Returns:     None.
########################################################################

sub _flush_datastore {
  (@_ > 0) or croak 'Usage: $obj->_flush_datastore()';
  my $this = shift;
  ref($this) or croak "$this is not an object";

  $this->_trace();

  0;
}

########################################################################
# Function:    _close_datastore
# Description: Closes the datastore.
#              In this case, the method does nothing for this module.
# Parameters:  None.
# Returns:     None.
########################################################################

sub _close_datastore {
  (@_ > 0) or croak 'Usage: $obj->_close_datastore()';
  my $this = shift;
  ref($this) or croak "$this is not an object";

  $this->_trace();

  0;
}

########################################################################
# Function:    _lock_datastore
# Description: Locks the datastore for query or update.
#              For datastore query, use a 'SHARED' lock.
#              For datastore update, use a 'MUTEX' lock.
#              NOTE: Does nothing for this module.
# Parameters:  $lock_type = 'SHARED' or 'MUTEX'
#              'SHARED' is for read-only.
#              'MUTEX' is for read/write.
# Returns:     None.
########################################################################

sub _lock_datastore {
  (@_ > 0) or croak 'Usage: $obj->_lock_datastore($lock_type)';
  my($this, $lock_type) = @_;
  ref($this) or croak "$this is not an object";

  $this->_trace();

  0;
}

########################################################################
# Function:    _unlock_datastore
# Description: Unlocks the datastore.
#              Unlocks both types of locks, 'SHARED' and 'MUTEX'.
#              In this case, the method does nothing for this module.
# Parameters:  None.
# Returns:     None.
########################################################################

sub _unlock_datastore {
  (@_ > 0) or croak 'Usage: $obj->_unlock_datastore()';
  my $this = shift;
  ref($this) or croak "$this is not an object";

  $this->_trace();

  0;
}

### end of library ###
1;
__END__

=head1 SEE ALSO

L<Persistent>, L<Persistent::Base>, L<Persistent::DBM>,
L<Persistent::Memory>

=head1 NOTES

This Persistent class does not lock the data store (a hash in this
case) before reading or writing it.  This should not be a problem
unless you are using threaded Perl or forking processes that share an
object of this class.

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

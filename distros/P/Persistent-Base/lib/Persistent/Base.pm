########################################################################
# File:     Base.pm
# Author:   David Winters <winters@bigsnow.org>
# RCS:      $Id: Base.pm,v 1.16 2000/02/26 03:38:28 winters Exp winters $
#
# An abstract base class for persistent objects.
# This class should be inherited by other persistent classes that
# implement object persistence.
#
# This file contains POD documentation that may be viewed with the
# perldoc, pod2man, or pod2html utilities.
#
# Copyright (c) 1998-2000 David Winters.  All rights reserved.
# This program is free software; you can redistribute it
# and/or modify it under the same terms as Perl itself.
########################################################################

package Persistent::Base;
require 5.004;

use strict;
use vars qw($VERSION $REVISION $AUTOLOAD);

use Carp;
use English;

$VERSION = '0.52';
$REVISION = (qw$Revision: 1.16 $)[1];

=head1 NAME

Persistent::Base - An Abstract Persistent Base Class

=head1 SYNOPSIS

  ### we are a subclass of ... ###
  use Persistent::Base;
  @ISA = qw(Persistent::Base);

=head1 ABSTRACT

This is an abstract class used by the Persistent framework of classes
to implement persistence with various types of data stores.  This
class provides the methods and interface for implementing Persistent
classes.  Refer to the L<Persistent> documentation for a very thorough
introduction to using the Persistent framework of classes.

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

=cut

########################################################################
#
# --------------
# PUBLIC METHODS
# --------------
#
# NOTE: These methods do not need to be overridden in the subclasses.
#       However, you may certainly override these methods if you see
#       the need to.  Perhaps, for performance or reuseability reasons.
#
########################################################################

########################################################################
# Function:    new
# Description: Object constructor.
# Parameters:  @params = initialization parameters
# Returns:     $this = reference to the newly allocated object
########################################################################
sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;

  ### allocate a hash for the object's data ###
  my $this = {};
  bless $this, $class;
  $this->_trace();
  $this->initialize(@_);  ### call hook for subclass initialization ###

  return $this;
}

########################################################################
# Function:    initialize
# Description: Initializes an object.
# Parameters:  @params = initialization parameters
# Returns:     None
########################################################################
sub initialize {
  my $this = shift;
  ref($this) or croak "$this is not an object";

  $this->_trace();
  $this->datastore(@_);  ### initialize the data store ###

  0;
}

########################################################################
# Function:    DESTROY
# Description: Object destructor.
# Parameters:  None
# Returns:     None
########################################################################
sub DESTROY {
  my $this = shift;
  ref($this) or croak "$this is not an object";

  $this->_trace();

  0;
}

########################################################################
# Function:    AUTOLOAD
# Description: Gets/sets the attributes of the object.
#              Uses autoloading to access any instance field.
# Parameters:  $value (optional) = value to set the attribute to
# Returns:     $value = value of the attribute
########################################################################
sub AUTOLOAD {
  my($this, @data) = @_;
  ref($this) or croak "$this is not an object";

  $this->_trace();

  my $name = $AUTOLOAD;   ### get name of attribute ###
  $name =~ s/.*://;       ### strip fully-qualified portion ###
  $this->value($name, @data);
}

########################################################################
# Function:    datastore_type
# Description: Gets/sets the type of the datastore.
#              The persistent subclass for the type ($type) of datastore
#              will be loaded at run-time and initialized with the
#              arguments passed (@args);
# Parameters:  $type = type of datastore
#              @args = arguments to pass to the specific datastore
#                      method for the type ($type)
# Returns:     whatever is returned by the datastore method for the type
########################################################################
sub datastore_type {
  (@_ > 0) or croak 'Usage: $obj->datastore_type([$type])';
  my $this = shift;
  my $class = ref $this;
  $class or croak "$this is not an object";

  $this->_trace();

  if ($class =~ /Persistent::/) {  ### direct instantiation ###
    $this->object_type(@_);
  } else {                         ### inheritance ###
    $this->parent_type(@_);
  }
}

########################################################################
# Function:    object_type
# Description: Gets/sets the type of the object.
#              The persistent subclass for the type ($type) of datastore
#              will be loaded at run-time and initialized with the
#              arguments passed (@args);
# Parameters:  $type = type of datastore
#              @args = arguments to pass to the specific datastore
#                      method for the type ($type)
# Returns:     whatever is returned by the datastore method for the type
########################################################################
sub object_type {
  (@_ > 0) or croak 'Usage: $obj->object_type([$type])';
  my $this = shift;
  ref($this) or croak "$this is not an object";

  $this->_trace();

  my $type = shift;
  if (defined $type) {  ### set it ###
    ### free the object's resources ###
    $this->DESTROY();

    ### set the object's class ###
    my $class = "Persistent::${type}";
    eval "require $class";
    croak $EVAL_ERROR if $EVAL_ERROR;
    bless $this, $class;
  } else {              ### get it ###
    $type = ref $this;
    $type =~ s/Persistent:://;
  }

  $type;
}

########################################################################
# Function:    parent_type
# Description: Gets/sets the type of the object.
#              The persistent subclass for the type ($type) of datastore
#              will be loaded at run-time and initialized with the
#              arguments passed (@args);
# Parameters:  $type = type of datastore
#              @args = arguments to pass to the specific datastore
#                      method for the type ($type)
# Returns:     whatever is returned by the datastore method for the type
########################################################################
sub parent_type {
  (@_ > 0) or croak 'Usage: $obj->parent_type([$type])';
  my $this = shift;
  my $class = ref $this;
  $class or croak "$this is not an object";

  $this->_trace();

  my $type = shift;
  if (defined $type) {  ### set it ###
    ### free the object's resources ###
    $this->DESTROY();

    ### set parent class ###
    eval("require Persistent::${type}; " .
	 "\@${class}::ISA = qw(Persistent::${type});");
    croak $EVAL_ERROR if $EVAL_ERROR;
  } else {              ### get it ###
    ($type) = eval "\@${class}::ISA";  ### get parent class ###
    $type =~ s/Persistent:://;
  }

  $type;
}

########################################################################
# Function:    data_type
# Description: Returns the data type of an attribute.
# Parameters:  $attribute = name of an attribute of the object
# Returns:     $data_type = data type for the attribute
########################################################################
sub data_type {
  (@_ == 2) or croak 'Usage: $obj->data_type($attribute)';
  my($this, $attribute) = @_;
  ref($this) or croak "$this is not an object";

  $this->_trace();

  if (defined $this->{MetaData}->{$attribute}) {
    $this->{MetaData}->{$attribute}->{DataType};
  } else {
    croak "'$attribute' is not an attribute of this object";
  }
}

########################################################################
# Function:    data_type_params
# Description: Returns the data type parameters of an attribute.
#              The parameters are dependent on the data type.
# Parameters:  $attribute = name of an attribute of the object
# Returns:     \@data_type_params = reference to an array containing the
#                                   data type parameters for the attribute
########################################################################
sub data_type_params {
  (@_ == 2) or croak 'Usage: $obj->data_type_params($attribute)';
  my($this, $attribute) = @_;
  ref($this) or croak "$this is not an object";

  $this->_trace();

  if (defined $this->{MetaData}->{$attribute}) {
    [@{$this->{MetaData}->{$attribute}->{DataTypeParams}}];
  } else {
    croak "'$attribute' is not an attribute of this object";
  }
}

########################################################################
# Function:    data_type_object
# Description: Returns the data type object of an attribute.
# Parameters:  $attribute = name of an attribute of the object
# Returns:     $data_type_obj = data type object for the attribute
########################################################################
sub data_type_object {
  (@_ == 2) or croak 'Usage: $obj->data_type_object($attribute)';
  my($this, $attribute) = @_;
  ref($this) or croak "$this is not an object";

  $this->_trace();

  if (defined $this->{Data}->{$attribute}) {
    $this->{Data}->{$attribute};
  } else {
    croak "'$attribute' is not an attribute of this object";
  }
}

########################################################################
# Function:    add_attribute
# Description: Adds an attribute to the object.
# Parameters:  $name = name of the attribute
#              $type = type of the attribute
#                valid values are the following:
#                  'id' or 'i'
#                  'persistent' or 'p'
#                  'transient' or 't'
#              $data_type = data type of the attribute
#                valid values are the following:
#                  'varchar'
#                  'char'
#                  'string'
#                  'number'
#                  'datetime'
#              @args = arguments to be passed to the data type constructor
# Returns:     None
########################################################################
sub add_attribute {
  (@_ > 3) or
    croak 'Usage: $obj->add_attribute($name, $type, $data_type, @args)';
  my($this, $name, $type, $data_type, @args) = @_;
  ref($this) or croak "$this is not an object";

  ### validate arguments ###
  croak "name must be defined" if !defined($name) || $name eq '';
  croak "type must be defined" if !defined($type) || $type eq '';
  croak "data type must be defined"
    if !defined($data_type) || $data_type eq '';

  ### store the field metadata and allocate the field ###
  $this->{MetaData}->{$name}->{DataType} = $data_type;
  $this->{MetaData}->{$name}->{DataTypeParams} = [@args];
  my $dt_obj = $this->_allocate_data_type($data_type, @args);
  if ($type =~ /^i/i) {       ### ID fields ###
    $this->{Data}->{$name}->[0] = $dt_obj;
    push(@{$this->{DataOrder}}, $name);
    push(@{$this->{IdFields}}, $name);
  } elsif ($type =~ /^p/i) {  ### persistent fields ###
    $this->{Data}->{$name}->[0] = $dt_obj;
    push(@{$this->{DataOrder}}, $name);
  } elsif ($type =~ /^t/i) {  ### transient fields ###
    $this->{TempData}->{$name}->[0] = $dt_obj;
  } else {
    croak "field type ($type) is invalid";
  }
}

########################################################################
# Function:    value
# Description: Gets/sets the value of an attribute.
# Parameters:  $attribute = name of the attribute
#              $value (optional) = value to set the attribute to
# Returns:     $value = value of the attribute
########################################################################
sub value {
  my($this, $attribute, @data) = @_;
  ref($this) or croak "$this is not an object";

  $this->_trace();

  $attribute = lc($attribute);  ### attributes are case insensitive ###

  ### check for existence of the attribute ###
  if (exists $this->{Data}->{$attribute}) {           ### persistent ###
    $this->{Data}->{$attribute}->[0]->value(@data);
  } elsif (exists $this->{TempData}->{$attribute}) {  ### transient ###
    $this->{TempData}->{$attribute}->[0]->value(@data);
  } else {
    croak "'$attribute' is not an attribute of this object";
  }
}

########################################################################
# Function:    clear
# Description: Clears the fields of the object.
# Parameters:  None
# Returns:     None
########################################################################
sub clear {
  (@_ == 1) or croak 'Usage: $obj->clear()';
  my $this = shift;
  ref($this) or croak "$this is not an object";

  $this->_trace();

  ### clear the persistent data ###
  foreach my $attr (keys %{$this->{Data}}) {
    $this->value($attr, undef);
  }

  ### clear the transient data ###
  foreach my $attr (keys %{$this->{TempData}}) {
    $this->value($attr, undef);
  }

  ### clear the previous ID ###
  undef(%{$this->{PrevId}});
}

########################################################################
# Function:    update
# Description: Updates the object in the data store.
# Parameters:  None
# Returns:     true  = the object did previously exist in the datastore
#              false = the object did not previously exist
########################################################################
sub update {
  (@_ > 0) or croak 'Usage: $obj->update([@id])';
  my ($this, @id) = @_;
  ref($this) or croak "$this is not an object";

  $this->_trace();

  ### set previous ID if passed ###
  if (@id) {
    $this->_check_id(@id);
    $this->_prev_id(@id);
  }

  ### check that the object exists in the data store ###
  if (!$this->_is_valid_id($this->_prev_id())) {
    croak "Object does not already exist in the data store";
  }

  my $rc = $this->delete();
  $this->insert();

  $rc;
}

########################################################################
# Function:    save
# Description: Saves the object to the data store.
# Parameters:  None
# Returns:     true  = the object did previously exist in the datastore
#              false = the object did not previously exist
########################################################################
sub save {
  (@_ == 1) or croak 'Usage: $obj->save()';
  my $this = shift;
  ref($this) or croak "$this is not an object";

  $this->_trace();

  ### determine if the object is already saved in the database ###
  if ($this->_is_valid_id($this->_prev_id())) {
    $this->update();  ### return what update returned ###
  } else {
    $this->insert();
    0;  ### object did not previously exist ###
  }
}

########################################################################
# Function:    restore
# Description: Restores the object from the data store.
# Parameters:  @id = unique identifier assigned to the object
# Returns:     true  = an object was restored
#              false = an object was not restored
########################################################################
sub restore {
  (@_ > 1) or croak 'Usage: $obj->restore()';
  my ($this, @id) = @_;
  ref($this) or croak "$this is not an object";

  $this->_trace();

  ### check that the ID is valid ###
  $this->_check_id(@id);

  ### build SQL-like WHERE clause with ID ###
  my @exprs;
  foreach my $idfield (@{$this->{IdFields}}) {
    push(@exprs, sprintf("$idfield = %s", $this->quote(shift @id)));
  }
  my $expr = join(' and ', @exprs);

  ### restore the object ###
  $this->restore_where($expr);
  my $rc = $this->restore_next();

  ### check if more than one object exists with the same ID ###
  if ($this->restore_next()) {
    $expr =~ s/ AND /, /;  ### a bit of formatting ###
    croak("More than one object exists with this ID ($expr)");
  }

  $rc;
}

########################################################################
# Function:    restore_all
# Description: Restores all the objects from the data store and optionally
#              sorted.
# Parameters   $order_by (optional) = sort expression for the objects
#                                     in the form of an SQL ORDER BY clause
# Returns:     None
########################################################################
sub restore_all {
  (@_ < 3) or croak 'Usage: $obj->restore_all([$order_by])';
  my ($this, $order_by) = @_;
  ref($this) or croak "$this is not an object";

  $this->_trace();

  $this->restore_where(undef, $order_by);  ### null query => restore all ###
}

########################################################################
# Function:    restore_next
# Description: Restores the next object from the data store that matches the
#              query expression in the previous restore_where or restore_all
#              method calls.
# Parameters:  None
# Returns:     true  = an object was restored
#              false = an object was not restored; no more objects to restore
########################################################################
sub restore_next {
  (@_ == 1) or croak 'Usage: $obj->restore_next()';
  my ($this) = @_;
  ref($this) or croak "$this is not an object";

  $this->_trace();

  my $aref = shift(@{$this->{RestoredData}});
  if (defined $aref) {  ### found an object ###

    ### clear the transient data ###
    foreach my $attr (keys %{$this->{TempData}}) {
      $this->value($attr, undef);
    }

    ### load the persistent data ###
    foreach my $attr (@{$this->{DataOrder}}) {
      $this->value($attr, shift @$aref);
    }

    ### save the object ID ###
    $this->_prev_id($this->_id());

    1;
  } else {              ### no more objects left ###
    0;
  }
}

########################################################################
# Function:    data
# Description: Gets/Sets all data fields of an object.
# Parameters:  $href (optional) = a reference to a hash of object data
# Returns:     $href = a reference to a hash of object data
########################################################################
sub data {
  (@_ > 0) or croak 'Usage: $obj->data([$href])';
  my ($this, $href) = @_;
  ref($this) or croak "$this is not an object";

  $this->_trace();

  ### set data fields ###
  if (defined $href && ref $href eq 'HASH') {
    foreach my $attr (keys %$href) {
      $this->value($attr, $href->{$attr});
    }
  }

  ### get data fields ###
  $href = {};
  foreach my $attr (@{$this->{DataOrder}}) {
    my @values = $this->value($attr);
    if (@values > 1) {
      $href->{$attr} = [@values];
    } else {
      $href->{$attr} = pop @values;
    }
  }

  ### return reference to hash of data ###
  $href;
}

########################################################################
# Function:    quote
# Description: Quote a string literal for use in a query statement by
#              escaping any special characters (such as quotation marks)
#              contained within the string and adding the required type
#              of outer quotation marks.
# Parameters:  $str = string to quote and escape
# Returns:     $quoted_str = quoted string
########################################################################
sub quote {
  (@_ == 2) or croak 'Usage: $obj->quote($str)';
  my ($this, $str) = @_;
  ref($this) or croak "$this is not an object";

  if (defined $str) {
    $str =~ s/\'/\\\'/g;         # Perl escaping
    "'$str'";
  } else {
    "";
  }
}

########################################################################
# Function:    debug
# Description: Gets/Sets the debugging level.
# Parameters:  $level = a string representing the debug level/type
#                       Valid levels/types are the following:
#                           'Trace' -> show a call stack trace
#                           'SQL'   -> show SQL statements generated
#                           'LDAP'  -> show LDAP filters
# Returns:     None
########################################################################
sub debug {
  (@_ > 0) or croak 'Usage: $obj->debug([$flag])';
  my $this = shift;

  $this->_trace();

  $this->{Debug} = shift if @_;
  $this->{Debug} or '';
}

=head1 ABSTRACT METHODS THAT NEED TO BE OVERRIDDEN IN THE SUBCLASS

=cut

########################################################################
#
# -------------------------------------------------------------------------
# PUBLIC ABSTRACT METHODS TO BE OVERRIDDEN (REDEFINED) IN THE DERIVED CLASS
# -------------------------------------------------------------------------
#
# NOTE: These methods MUST be overridden in the subclasses.
#       In order, for even a minimal subclass to work, you must
#       override these methods in the subclass.
#
########################################################################

########################################################################
# datastore
########################################################################

=head2 datastore -- Sets/Returns the Data Store Parameters

  eval {
    ### set the data store ###
    $person->datastore(@args);

    ### get the data store ###
    $href = $person->datastore();
  };
  croak "Exception caught: $@" if $@;

Returns (and optionally sets) the data store of the object.  This
method throws Perl execeptions so use it with an eval block.

Setting the data store can involve anything from initializing a
connection to opening a file.  Getting a data store usually means
returning information pertaining to the data store in a useful form,
such as a connection to a database or a location of a file.

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

sub datastore {
  (@_ > 0) or croak 'Usage: $obj->datastore()';
  my $this = shift;
  ref($this) or croak "$this is not an object";

  $this->_trace();

  croak "method not implemented";
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

This method requires implementing.

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
  (@_ > 0) or croak 'Usage: $obj->insert()';
  my $this = shift;
  ref($this) or croak "$this is not an object";

  $this->_trace();

  croak "method not implemented";
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

This method requires implementing.

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

  croak "method not implemented";
}

########################################################################
# restore_where
########################################################################

=head2 restore_where -- Conditionally Restoring Objects

  use Persistent::File;

  eval {
    my $person = new Persistent::File('people.txt', '|');
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

Since this is a Perl implemented Persistent class, the
I<restore_where> method expects all patterm matching to use Perl
regular expressions.

This method requires implementing.

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

  croak "method not implemented";
}

########################################################################
# PRIVATE METHODS
########################################################################

########################################################################
#
# ---------------
# PRIVATE METHODS
# ---------------
#
# NOTE: These methods do not need to be overridden in the subclasses.
#       However, you may certainly override these methods if you see
#       the need to.
#
########################################################################

########################################################################
# Function:    _id
# Description: Gets/Sets the ID of the object.
# Parameters:  @id (optional) = the unique attribute(s) of the object
# Returns:     @id = the unique attribute(s) of the object
########################################################################
sub _id {
  my($this, @id) = @_;
  ref($this) or croak "$this is not an object";

  $this->_trace();

  if (@id) {  ### set the ID ###
    my @new_id = @id;
    foreach my $idfield (@{$this->{IdFields}}) {
      $this->value($idfield, shift @new_id);
    }
  } else {    ### get the ID ###
    foreach my $idfield (@{$this->{IdFields}}) {
      push(@id, $this->value($idfield));
    }
  }

  @id;
}

########################################################################
# Function:    _prev_id
# Description: Gets/Sets the previous ID of the object.
# Parameters:  @id (optional) = the unique attribute(s) of the object
# Returns:     @id = the unique attribute(s) of the object
########################################################################
sub _prev_id {
  my($this, @id) = @_;
  ref($this) or croak "$this is not an object";

  $this->_trace();

  if (@id) {  ### set the previous ID ###
    my @new_id = @id;
    foreach my $idfield (@{$this->{IdFields}}) {
      $this->{PrevId}->{$idfield} = shift @new_id;
    }
  } else {    ### get the previous ID ###
    foreach my $idfield (@{$this->{IdFields}}) {
      push(@id, $this->{PrevId}->{$idfield});
    }
  }

  @id;
}

########################################################################
# Function:    _is_valid_id
# Description: Returns whether the ID is valid or not.
# Parameters:  @id (optional) = ID of the object
# Returns:     1 = ID is valid
#              0 = ID is not valid
########################################################################
sub _is_valid_id {
  my($this, @id) = @_;
  ref($this) or croak "$this is not an object";

  $this->_trace();

  @id = $this->_id() if !@id;
  foreach my $idfield (@{$this->{IdFields}}) {
    return 0 if !defined(shift @id);
  }
  1;
}

########################################################################
# Function:    _check_id
# Description: Checks that the ID is valid.
# Parameters:  @id (optional) = ID of the object
# Returns:     None
########################################################################
sub _check_id {
  my($this, @id) = @_;
  ref($this) or croak "$this is not an object";

  $this->_trace();

  @id = $this->_id() if !@id;
  if (!$this->_is_valid_id(@id)) {
    croak(sprintf("The ID (%s) is not valid for this object",
		  join(', ', map($_ || '', @id))));
  }
}

########################################################################
# Function:    _parse_query
# Description: Parses an SQL-like WHERE clause query and converts it
#              into a Perl boolean expression.
# Parameters:  $query = SQL-like WHERE clause
# Returns:     $bool_expr = Perl boolean expression
########################################################################

sub _parse_query {
  (@_ > 0) or croak 'Usage: $obj->_parse_query()';
  my($this, $query) = @_;
  ref($this) or croak "$this is not an object";

  $this->_trace();

  my %string_op = (  ### map operators to string operators ###
		   '==' => 'eq',
		   '<'  => 'lt',
		   '<=' => 'le',
		   '>'  => 'gt',
		   '>=' => 'ge',
		   '!=' => 'ne',
		   '=~' => '=~',
		  );
  my $any_op = '<=|>=|<|>|!=|==|=~';  ### any comparison operator ###

  ### convert SQL-like query into a Perl boolean expression ###
  if (!defined($query) || $query =~ /^\s*$/) {
    1;
  } else {

    ### squirrel away all instances of escaped quotes for later ###
    $query =~ s/\\\'/\200/g;  ### hopefully, \200 and \201 aren't used ###
    $query =~ s/\\\"/\201/g;

    ### replace all '=' with '==' ###
    $query =~ s/([^!><=])=([^~])/$1==$2/g;

    ### replace var with $var ###
    $query =~ s/(\w+)\s*($any_op)/\$$1 $2/g;

    ### replace comparison operators before quoted strings ###
    ### with string comparison operators ###
    $query =~ s{
		($any_op)  ### any comparison operator ###
		\s*        ### followed by zero or more spaces ###
		([\'\"])   ### then by a quoted string ###
	       }{
		 "$string_op{$1} $2"
	       }goxse;  ### global, compile-once, extended, ###
                        ### treat as single line, eval ###

    ### restore all escaped quote characters ###
    $query =~ s/\200/\\\'/g;
    $query =~ s/\201/\\\"/g;

    ### return modified query and field list ###
    $query;
  }
}

########################################################################
# Function:    _sort_objects
# Description: Sorts the objects returned from a datastore.
# Parameters:  $order_by = SQL-like ORDER BY clause
#              \@objs_data = reference to an array of objects data
# Returns:     None
########################################################################

sub _sort_objects {
  (@_ > 0) or croak 'Usage: $obj->_sort_objects()';
  my($this, $order_by, $objs_data) = @_;
  ref($this) or croak "$this is not an object";

  $this->_trace();

  ### make sure an ORDER BY clause has been passed ###
  if (defined $order_by && $order_by !~ /^\s*$/) {
    my $sort_expr = $this->_build_sort_expr($order_by);
    local $^W = 0;  ### turn off warnings for the eval ###
    @$objs_data = sort {eval($sort_expr)} @$objs_data;
  }
}

########################################################################
# Function:    _build_sort_expr
# Description: Parses an SQL-like ORDER BY clause and converts it
#              into a Perl sort expression.
# Parameters:  $order_by = SQL-like ORDER BY clause
# Returns:     $sort_expr = Perl sort expression
########################################################################

sub _build_sort_expr {
  (@_ > 0) or croak 'Usage: $obj->_build_sort_expr()';
  my($this, $order_by) = @_;
  ref($this) or croak "$this is not an object";

  $this->_trace();

  ### make sure an ORDER BY clause has been passed ###
  my $sort_expr;
  if (!defined $order_by || $order_by =~ /^\s*$/) {
    $sort_expr = 0;
  } else {

    ### build a map from column name to column number ###
    my $i = 0;
    my %field_num = map {$_ => $i++} @{$this->{DataOrder}};

    ### build the sort expression ###
    my @exprs;
    foreach my $stmt (split(/\s*,\s*/, $order_by)) {

      ### parse ORDER BY clause ###
      my($field, $order) = split(/\s/, $stmt);
      my $field_num = $field_num{$field};
      if (!defined($field_num)) {
	croak "'$field' is not a persistent attribute of the object";
      }

      ### determine sort order ###
      my($var1, $var2);
      if (defined $order && $order =~ /DESC/i) {
	$var1 = '$b';  $var2 = '$a';
      } else {
	$var1 = '$a';  $var2 = '$b';
      }

      ### get the comparison operator for the data type ###
      my $cmp_op = $this->{Data}->{$field}->[0]->get_compare_op();

      ### build and store the sort expression ###
      my $data_access_str = $this->_get_data_access_str();
      push(@exprs, sprintf("$data_access_str %s $data_access_str",
			   $var1, $field_num, $cmp_op, $var2, $field_num));
    }

    ### join sort the expressions together ###
    $sort_expr = join(' || ', @exprs);
  }

  $sort_expr;  ### return the sort expression ###
}

########################################################################
# Function:    _get_data_access_str
# Description: Returns a string that contains the format for how to
#              access the data of the restored objects.
# Parameters:  None
# Returns:     $str = data access string
########################################################################

sub _get_data_access_str {
  (@_ > 0) or croak 'Usage: $obj->_data_access_str()';
  my $this = shift;
  ref($this) or croak "$this is not an object";

  '%s->[%s]';
}

########################################################################
# Function:    _allocate_data_type
# Description: Allocatea a data type.
# Parameters:  $data_type = data type to allocate
#                valid values are the following:
#                  'varchar'
#                  'char'
#                  'string'
#                  'number'
#                  'datetime'
#              @args = arguments to be passed to the data type constructor
# Returns:     $ref = reference to the allocated data type
########################################################################

sub _allocate_data_type {
  (@_ > 1) or croak 'Usage: $obj->_allocate_data_type($data_type, @args)';
  my($this, $data_type, @args) = @_;
  ref($this) or croak "$this is not an object";

  ### validate arguments ###
  croak "data type must be defined"
    if !defined($data_type) || $data_type eq '';

  my $ref;
  if ($data_type =~ /^varchar$/i) {
    require Persistent::DataType::VarChar;
    $ref = new Persistent::DataType::VarChar(@args);
  } elsif ($data_type =~ /^char$/i) {
    require Persistent::DataType::Char;
    $ref = new Persistent::DataType::Char(@args);
  } elsif ($data_type =~ /^string$/i) {
    require Persistent::DataType::String;
    $ref = new Persistent::DataType::String(@args);
  } elsif ($data_type =~ /^number$/i) {
    require Persistent::DataType::Number;
    $ref = new Persistent::DataType::Number(@args);
  } elsif ($data_type =~ /^datetime$/i) {
    require Persistent::DataType::DateTime;
    $ref = new Persistent::DataType::DateTime(@args);
  } else {
    croak "data type ($data_type) is invalid";
  }

  $ref;
}

########################################################################
# Function:    _trace
# Description: Print a trace message for the subroutine caller if
#              debugging is turned on.
# Parameters:  None
# Returns:     None
########################################################################
sub _trace {
  my $this = shift;
  ref($this) or croak "$this is not an object";

  if (defined $this->{Debug} && $this->{Debug} eq 'Trace') {
    my $i = 1;

    my ($package, $filename, $line, $subroutine) = caller($i);
    my $msg = "$subroutine() ... ";

    for ($i = 1; my $f = caller($i); $i++) {}

    ($package, $filename, $line, $subroutine) = caller($i - 1);
    $msg .= "$subroutine() called from $filename $line\n";

    warn $msg;
  }
}

### end of library ###
1;
__END__

=head1 SEE ALSO

L<Persistent>, L<Persistent::Base>, L<Persistent::DBM>,
L<Persistent::File>, L<Persistent::Memory>

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

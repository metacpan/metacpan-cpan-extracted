########################################################################
# File:     LDAP.pm
# Author:   David Winters <winters@bigsnow.org>
# RCS:      $Id: LDAP.pm,v 1.1 2000/02/02 21:16:33 winters Exp winters $
#
# A class that implements object persistence using a LDAP directory.
#
# This file contains POD documentation that may be viewed with the
# perldoc, pod2man, or pod2html utilities.
#
# Copyright (c) 1998-2000 David Winters.  All rights reserved.
# This program is free software; you can redistribute it
# and/or modify it under the same terms as Perl itself.
########################################################################

package Persistent::LDAP;
require 5.004;

use strict;
no strict qw(refs);
use vars qw(@ISA $VERSION $REVISION);

use Carp;
use English;
use Net::LDAP;

### we are a subclass of the all-powerful Persistent::Base class ###
use Persistent::Base;
@ISA = qw(Persistent::Base);

### copy version number from superclass ###
$VERSION = '0.50';
$REVISION = (qw$Revision: 1.1 $)[1];

=head1 NAME

Persistent::LDAP - A Persistent Class implemented using a LDAP Directory

=head1 SYNOPSIS

  use Persistent::LDAP;
  use English;  # import readable variable names like $EVAL_ERROR

  eval {  ### in case an exception is thrown ###

    ### allocate a persistent object ###
    my $person =
      new Persistent::LDAP('localhost', 389,
			   'cn=Directory Manager', 'test1234',
			   'ou=Engineering,o=Big Snow Org,c=US');

    ### declare attributes of the object ###
    $person->add_attribute('uid',             'ID',         'String');
    $person->add_attribute('userpassword',    'Persistent', 'String');
    $person->add_attribute('objectclass',     'Persistent', 'String');
    $person->add_attribute('givenname',       'Persistent', 'String');
    $person->add_attribute('sn',              'Persistent', 'String');
    $person->add_attribute('cn',              'Persistent', 'String');
    $person->add_attribute('mail',            'Persistent', 'String');
    $person->add_attribute('telephonenumber', 'Persistent', 'String');

    ### query the datastore for some objects ###
    $person->restore_where('& (objectclass=person)(mail=*bigsnow.org)',
			   'sn, givenname');
    while ($person->restore_next()) {
      printf("name = %s, email = %s\n",
             $person->givenname . ' ' . $person->sn,
             $person->mail);
    }
  };

  if ($EVAL_ERROR) {  ### catch those exceptions! ###
    print "An error occurred: $EVAL_ERROR\n";
  }

=head1 ABSTRACT

This is a Persistent class that uses a LDAP directory to store and
retrieve objects.  This class can be instantiated directly or
subclassed.  The methods described below are unique to this class, and
all other methods that are provided by this class are documented in
the L<Persistent> documentation.  The L<Persistent> documentation has
a very thorough introduction to using the Persistent framework of
classes.

This class is part of the Persistent LDAP package which is available
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
# Function:    DESTROY
# Description: Object destructor.
# Parameters:  None
# Returns:     None
########################################################################
sub DESTROY {
  my $this = shift;

  $this->_trace();

  ### if the object created a LDAP binding ###
  ### (i.e. it was not passed a LDAP binding) ###
  ### then disconnect it ###
  if ($this->{DataStore}->{CreatedLDAP}) {
    $this->_check_ldap_error($this->{DataStore}->{LDAP}->unbind(),
			     "Can't unbind from directory");
  }
}

########################################################################
# initialize
########################################################################

=head2 new -- Object Constructor

  use Persistent::LDAP;

  eval {
    my $obj = new Persistent::LDAP($host, $port,
				   $bind_dn, $password,
				   $base_dn);
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
    $ldap = $obj->datastore($host, $port, $bind_dn, $password,
                            $base_dn);
    ### or set it like this ###
    $ldap = $obj->datastore($ldap, $base_dn);

    ### get the data store ###
    $ldap = $obj->datastore();
  };
  croak "Exception caught: $@" if $@;

Returns (and optionally sets) the data store of the object.  This
method throws Perl execeptions so use it with an eval block.

Parameters:

=over 4

=item I<$host>

Hostname or IP address of the remote (LDAP Directory) server

=item I<$port>

Port to connect to on the remote server

=item I<$bind_dn>

Bind to the LDAP directory with the given DN

=item I<$password>

Password for the bind DN

=item I<$base_dn>

The base DN to start all searches/updates

=item I<$ldap> (also a return value)

Connection to the LDAP directory

=back

=cut

sub datastore {
  (@_ > 0) or croak('Usage: $obj->datastore([$host, $port, $bind_dn, ' .
		    '$password, $base_dn])');
  my $this = shift;
  ref($this) or croak "$this is not an object";

  $this->_trace();

  my $ldap;  ### directory connection ###

  ### determine number of args passed ###
  if (@_ == 0) {
    $ldap = $this->{DataStore}->{LDAP};
  } elsif (@_ == 2) {  ### directory connection passed ###
    ### save the database handle ###
    $ldap = shift;
    my $base_dn = shift;
    $this->{DataStore}->{LDAP} = $ldap;
    $this->{DataStore}->{CreatedLDAP} = 0;
    $this->{DataStore}->{BaseDN} = $base_dn;
  } elsif (@_ >= 3) {
    ### connect to the directory ###
    my($host, $port, $bind_dn, $password, $base_dn) = @_;
    $ldap = new Net::LDAP($host, port => $port) or croak $EVAL_ERROR;
    $this->_check_ldap_error($ldap->bind($bind_dn, password => $password),
			     "Can't bind to directory: $host:$port");

    ### save the directory connection ###
    $this->{DataStore}->{LDAP} = $ldap;
    $this->{DataStore}->{CreatedLDAP} = 1;
    $this->{DataStore}->{BaseDN} = $base_dn;
  } else {
    croak('Usage: ' .
	  '$obj->datastore([$host, $port, $bind_dn, $password, $base_dn])' .
	  "\n" .
	  '  -or- $obj->datastore([$ldap, $base_dn]');
  }

  $ldap;
}

########################################################################
# insert
########################################################################

=head2 insert -- Insert an Object into the Data Store

  eval {
    $obj->insert();
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

  my $ldap = $this->{DataStore}->{LDAP};  ### directory connection ###

  ### pack attributes into an array ###
  my @attrs;
  foreach my $field (@{$this->{DataOrder}}) {
    my @values = $this->value($field);
    push(@attrs, $field, \@values);
  }

  ### add the object to the directory ###
  my $dn = $this->_get_dn();
  $this->_check_ldap_error($ldap->add($dn, attrs => \@attrs),
			   "Can't add entry to directory: $dn");

  ### save the object ID ###
  $this->_prev_id($this->_id());
}

########################################################################
# update
########################################################################

=head2 update -- Update an Object in the Data Store

  eval {
    $obj->update();
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

  $person->uid('pflintstone');      ### new value of ID attribute ###
  $person->sn('Rubble');            ### new lastname ###
  $person->commonname('Pebbles');   ### old firstname ###
  ### set the rest of the attributes ... ###

  $person->update('prubble');   ### old value of ID attribute ###

Or, if don't want to set all of the object's attributes, you can just
restore it and then update it like this:

  ### restore object from data store ###
  if ($person->restore('pflintstone')) {
    $person->uid('prubble');
    $person->sn('Rubble');
    $person->update();
  }

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
    $obj->delete();
    ### or ###
    $obj->delete(@id);
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

  my $ldap = $this->{DataStore}->{LDAP};  ### directory connection ###

  ### delete the object from the directory ###
  my $rc = 1;  ### return code: was object deleted? ###
  my $dn = $this->_get_dn(@id);
  my $mesg = $ldap->delete($dn);
  if ($mesg->code == 0x20) {  ### check if object didn't exist already ###
    $rc = 0;
  } else {
    $this->_check_ldap_error($mesg, "Can't delete entry from directory: $dn");
  }

  ### clear the previous ID ###
  undef(%{$this->{PrevId}});

  $rc;
}

########################################################################
# restore
########################################################################

=head2 restore -- Restore an Object from the Data Store

  eval {
    $obj->restore(@id);
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

  my $ldap = $this->{DataStore}->{LDAP};  ### directory connection ###

  ### build LDAP filter ###
  my @filter;
  foreach my $idfield (@{$this->{IdFields}}) {
    push(@filter, "($idfield=" . (shift @id || '') . ')');
  }
  my $filter = "& @filter";

  ### search for the object in the directory ###
  my $mesg = $ldap->search(base => $this->{DataStore}->{BaseDN},
			   filter => $filter);
  $this->_check_ldap_error($mesg, "Directory search failed: $filter");

  ### check how many objects were found ###
  my $rc;  ### return code: was an object found? ###
  my @entries = $mesg->entries;
  if (@entries == 0) {
    $rc = 0;
  } elsif (@entries > 1) {
    croak "More than one object exists with this ID ($filter)";
  } else {
    ### load the persistent data ###
    foreach my $field (@{$this->{DataOrder}}) {
      my @values = $entries[0]->get($field);
      $this->value($field, @values);
    }

    ### clear the transient data ###
    foreach my $attr (keys %{$this->{TempData}}) {
      $this->value($attr, undef);
    }

    ### save the object ID ###
    $this->_prev_id($this->_id());

    $rc = 1;
  }

  $rc;
}

########################################################################
# restore_where
########################################################################

=head2 restore_where -- Conditionally Restoring Objects

  use Persistent::LDAP;

  eval {
    ### allocate a persistent object ###
    my $person =
      new Persistent::LDAP('localhost', 389,
			   'cn=Directory Manager', 'test1234',
			   'ou=Engineering,o=Big Snow Org,c=US');

    ### query the datastore for some objects ###
    $person->restore_where('& (objectclass=person)(mail=*bigsnow.org)',
			   'sn, givenname');
    while ($person->restore_next()) {
      printf("name = %s, email = %s\n",
             $person->givenname . ' ' . $person->sn,
             $person->mail);
    }
  };
  croak "Exception caught: $@" if $@;

Restores objects from the data store that meet the specified
conditions.  The objects are returned one at a time by using the
I<restore_next> method and in a sorted order if specified.  This
method throws Perl execeptions so use it with an eval block.

Since this is a LDAP implemented Persistent class, the
I<restore_where> method expects a RFC-2254 compliant LDAP search
filter as the first argument, I<$where>.  Please see the
C<Net::LDAP::Filter> documentation or RFC-2254 for more information.
A good starting point for finding RFCs on the web is the following:

  http://www.yahoo.com/Computers_and_Internet/Standards/RFCs/

The second argument, I<$order_by>, should be a valid SQL ORDER BY
clause.  Which is just a comma separated list of attribute values to
sort by with an optional ASC or DESC token to sort in ascending or
descending order.  Please refer to a SQL reference for a more detailed
explanation of ORDER BY clauses.

Since LDAP directories allow multiple values for an attribute, when an
attribute with multiple values is used to sort by (used in an ORDER BY
clause), only the first value of the attribute is used for sorting.
For more information on attributes with multiple values, please see
the following section in this document on using accessor methods.

Parameters:

=over 4

=item I<$where>

Conditional expression for the requested objects.  This is a RFC-2254
compliant LDAP search filter.  This argument is optional.

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

  my $ldap = $this->{DataStore}->{LDAP};  ### directory connection ###

  ### build LDAP filter ###
  my $filter = $where;
  if (!defined($filter) || $filter eq '') {
    my @filter;
    foreach my $idfield (@{$this->{IdFields}}) {
      push(@filter, "($idfield=*)");
    }
    $filter = "& @filter";  ### wild card filter => restore all ###
  }

  print "LDAP Filter = $filter\n" if $this->debug() eq 'LDAP';

  ### search for the object(s) in the directory ###
  my $mesg = $ldap->search(base => $this->{DataStore}->{BaseDN},
			   filter => $filter);
  $this->_check_ldap_error($mesg, "Directory search failed: $filter");

  my @objs_data;
  foreach my $entry ($mesg->entries) {
    my $data = [];
    foreach my $field (@{$this->{DataOrder}}) {
      my @values = $entry->get($field);
      push(@$data, [@values]);
    }
    push(@objs_data, $data);
  }

  ### sort the objects ###
  $this->_sort_objects($order_by, \@objs_data) if $order_by;

  ### save the restored objects ###
  $this->{RestoredData} = \@objs_data;

  scalar @objs_data;
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

  $str;  ### LDAP filters don't need any quotes ###
}

########################################################################
# value
########################################################################

=head2 Accessor Methods -- Accessing the Attributes of an Object

  eval {
    ### getting attribute values ###
    my $mail = $person->mail();            ### a single value ###
    my @classes = $person->objectclass();  ### multiple values ###

    ### setting attribute values ###
    $person->mail($newmail);               ### a single value ###
    my @new_classes = ('top', 'person', 'organizationalPerson');
    $person->objectclass(@new_classes);    ### multiple values ###
    $person->objectclass(\@new_classes);   ### multiple values by ref ###
  };
  croak "Exception caught: $@" if $@;

Sets/gets the value(s) of the attributes of the object.  Since this
method is implemented using a LDAP directory, multiple values for an
attribute are allowed.  So in order to handle this, the accessor
methods can be used in an array context or a scalar context.  If the
attribute has only a single value then access it in a scalar context.
And if the attribute allows multiple values then access it in an array
context.  If the attribute has multiple values and it is accessed in a
scalar context only the first value will be returned but if a single
value is passed to it then the attribute will be set to the single
scalar value.

Example:

  $person->objectclass('top', 'person', 'inetOrgPerson');
  $class = $person->objectclass();
  ### $class == 'top' ###
  @classes = $person->objectclass();
  ### @classes == ('top', 'person', 'inetOrgPerson') ###

This method throws Perl execeptions so use it with an eval block.

Parameters:

=over 4

=item I<$value> or I<@values> or I<\@values>

Value(s) of the attribute of the object.  The value(s) can be either a
single scalar value, an array of multiple values, or a reference to an
array of multiple values.

=back

Returns:

=over 4

=item I<$value> or I<@values>

Returns a scalar value if used in a scalar context and returns an
array when used in an array context.

=back

See the L<Persistent> documentation for more information.

=cut

sub value {
  (@_ > 1) or croak('Usage: $obj->value($attribute)'           . "\n" .
		    ' -or-  $obj->value($attribute, $value)'   . "\n" .
		    ' -or-  $obj->value($attribute, @values)'  . "\n" .
		    ' -or-  $obj->value($attribute, \@values)' . "\n");
  my($this, $attribute, @args) = @_;

  $this->_trace();

  $attribute = lc($attribute);  ### attributes are case insensitive ###

  ### check for existence of the attribute and determine which data area ###
  my $data_area;
  if (exists $this->{Data}->{$attribute}) {           ### persistent ###
    $data_area = 'Data';
  } elsif (exists $this->{TempData}->{$attribute}) {  ### transient ###
    $data_area = 'TempData';
  } else {
    croak "'$attribute' is not an attribute of this object";
  }

  ### set or get the values? ###
  my @values;
  if (@args) {  ### setter ###
    my $values_aref;
    if (@args == 1) {
      if (ref($args[0]) eq 'ARRAY') {  ### array ref ###
	$values_aref = $args[0];
      } else {                         ### scalar ###
	$values_aref = [$args[0]];
      }
    } else {                           ### array ###
      $values_aref = \@args;
    }

    ### allocate, initialize, and store data type objects ###
    my $data_type = $this->data_type($attribute);
    my $params_aref = $this->data_type_params($attribute);
    my @dt_objs;
    foreach my $value (@$values_aref) {
      my $dt_obj = $this->_allocate_data_type($data_type, @$params_aref);
      push(@values, $dt_obj->value($value));
      push(@dt_objs, $dt_obj);
    }

    ### in case a reference to an empty array was passed ###
    if (@dt_objs == 0) {
      push(@dt_objs, $this->_allocate_data_type($data_type, @$params_aref))
    }

    $this->{$data_area}->{$attribute} = \@dt_objs;
  } else {      ### getter ###
    foreach my $dt_obj (@{$this->{$data_area}->{$attribute}}) {
      push(@values, $dt_obj->value);
    }
  }

  ### determine what to return ###
  wantarray ? @values : $values[0];
}

########################################################################
# data
########################################################################

=head2 data -- Accessing the Attribute Data of an Object

  eval {
    ### set the attributes  ###
    $person->data({givenname => 'Marge', sn => 'Simpson'});

    ### get and print the attributes ###
    my $href = $person->data();
    print "name  = ", $href->{'givenname'} . ' ' . $href->{'sn'};
    print "email = ", $href->{'mail'};
  };
  croak "Exception caught: $@" if $@;

Returns or sets all of the values of the attributes.  If an attribute
has multiple values then a reference to an array of values is returned
for that attribute.  And to set multiple values to an attribute, a
reference to an array of values should be passed.

Example:

  ### get the multiple values for the attribute ###
  my $href = $person->data();
  my @classes = @{$href->{'objectclass'}};   ### superfluous copy ###
  print "objectclasses = ", join(', ', @classes), "\n";

  ### set the multiple values for the attribute ###
  my @new_classes = ('top', 'person');
  $person->data({objectclass => \@new_classes});

This method throws Perl execeptions so use it with an eval block.

Parameters:

=over 4

=item I<\%hash>

A hash with keys that are the names of the attributes and values that
are the values of the attributes.  This argument is optional and is
used for setting the value(s) of the attributes.

=back

Returns:

=over 4

=item I<\%hash>

Same as the argument above except that it is the returned value(s) of
the attributes.

=back

See the L<Persistent> documentation for more information.

=cut

########################################################################
#
# ---------------
# PRIVATE METHODS
# ---------------
#
########################################################################

########################################################################
# Function:    _check_ldap_error
# Description: Checks for errors in Net::LDAP and croaks if an error
#              has occurred.
# Parameters:  $err_str (optional) = error string prepended to the
#                                    Net::LDAP error message
# Returns:     None
########################################################################

sub _check_ldap_error {
  (@_ > 1) or croak 'Usage: $obj->_check_ldap_error()';
  my($this, $mesg, $err_str) = @_;

  if ($mesg->code) {  ### check for an error ###

    ### look up Net::LDAP::Constant for code ###
    my $ldap_const = $this->_lookup_ldap_constant($mesg->code);

    if ($err_str) {
      $err_str = "$err_str\n";
    }

    croak($err_str .
	  "Net::LDAP Error Code: " . sprintf("0x%x", $mesg->code) . "\n" .
	  "Net::LDAP Error Constant: " . $ldap_const . "\n" .
	  "Net::LDAP Error Message: " . $mesg->error . "\n");
  }
}

########################################################################
# Function:    _lookup_ldap_constant
# Description: Looks up the name of the Net::LDAP::Constant
#              for the error code.
# Parameters:  $err_code = error code from Net::LDAP::Constant
# Returns:     $ldap_const = name of the Net::LDAP::Constant
#              NOTE: returns '' if no constant is found.
########################################################################

sub _lookup_ldap_constant {
  (@_ > 1) or croak 'Usage: $obj->_lookup_ldap_constant()';
  my($this, $err_code) = @_;

  my $ldap_const = '';
  foreach my $sub (grep /^LDAP_/, keys %{'Net::LDAP::Constant::'}) {
    eval "use Net::LDAP qw($sub)";
    if ($err_code == &$sub) {
      $ldap_const = $sub;
      last;
    }
  }

  $ldap_const;
}

########################################################################
# Function:    _get_dn
# Description: Gets the distinguished name.
# Parameters:  @id (optional) = ID of the object
# Returns:     $dn = the distinguished name
########################################################################

sub _get_dn {
  (@_ > 0) or croak 'Usage: $obj->_get_dn()';
  my($this, @id) = @_;

  $this->_trace();

  my @dn;
  @id = $this->_id() if !@id;
  foreach my $idfield (@{$this->{IdFields}}) {
    push(@dn, "$idfield=" . (shift @id || ''));
  }
  join(', ', @dn, $this->{DataStore}->{BaseDN});
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

  '%s->[%s]->[0]';
}

### end of library ###
1;
__END__

=head1 SEE ALSO

L<Persistent>, L<Persistent::Base>

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

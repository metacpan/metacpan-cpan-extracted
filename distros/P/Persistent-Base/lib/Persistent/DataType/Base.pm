########################################################################
# File:     Base.pm
# Author:   David Winters <winters@bigsnow.org>
# RCS:      $Id: Base.pm,v 1.9 2000/02/08 02:36:40 winters Exp winters $
#
# An abstract base class for persistent datatype objects.
#
# Copyright (c) 1998-2000 David Winters.  All rights reserved.
# This program is free software; you can redistribute it
# and/or modify it under the same terms as Perl itself.
########################################################################

package Persistent::DataType::Base;
require 5.004;

use strict;
use vars qw($VERSION $REVISION);

use Carp;

### copy version number from Persistent::Base class ###
$VERSION = $Persistent::Base::VERSION;
$REVISION = (qw$Revision: 1.9 $)[1];

=head1 NAME

Persistent::DataType::Base - An Abstract DataType Base Class

=head1 SYNOPSIS

  ### we are a subclass of ... ###
  use Persistent::DataType::Base;
  @ISA = qw(Persistent::DataType::Base);

=head1 ABSTRACT

This is an abstract base class used by the Persistent framework of
classes to implement the attributes of objects.  This class provides
methods for implementing data types.

This class is not instantiated.  Instead, it is inherited from or
subclassed by DataType classes.

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

  my $this = {};  ### allocate a hash for the object's data ###
  bless $this, $class;
  $this->_trace();
  $this->initialize(@_);  ### call hook for subclass initialization ###

  return $this;
}

########################################################################
# Function:    DESTROY
# Description: Object destructor.
# Parameters:  None
# Returns:     None
########################################################################
sub DESTROY {
  my $this = shift;

  $this->_trace();

  0;
}

########################################################################
# debug
########################################################################

=head2 debug -- Accesses the Debugging Flag

  ### set the debugging flag ###
  $object->debug($flag);

  ### get the debugging flag ###
  $flag = $object->debug();

Returns (and optionally sets) the debugging flag of an object.  This
method does not throw Perl execeptions.

Parameters:

=over 4

=item I<$flag>

If set to a true value then debugging is on, otherwise, a false value
means off.

=back

=cut

sub debug {
  (@_ == 2) or croak 'Usage: $obj->debug($flag)';
  my $this = shift;

  $this->_trace();

  $this->{Debug} = shift if @_;
  $this->{Debug};
}

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
# initialize
########################################################################

=head2 Constructor -- Creates a DataType Object

  eval {
    my $datatype = new Persistent::DataType::Object(@args);
  };
  croak "Exception caught: $@" if $@;

Initializes a data type object.  This method throws Perl execeptions
so use it with an eval block.

This method is abstract and needs implementing.

=cut

sub initialize {
  (@_ > 0) or croak 'Usage: $obj->initialize(...args...)';
  my $this = shift;
  ref($this) or croak "$this is not an object";

  $this->_trace();

  croak "method not implemented";
}

########################################################################
# value
########################################################################

=head2 value -- Accesses the Value of the DataType

  eval {
    ### set the value ###
    $datatype->value($new_value);

    ### get the value ###
    $value = $datatype->value();
  };
  croak "Exception caught: $@" if $@;

Returns (and optionally sets) the value of a DataType object.  This
method throws Perl execeptions so use it with an eval block.

This method is abstract and needs implementing.

=cut

sub value {
  (@_ > 0) or croak 'Usage: $obj->value(...args...)';
  my $this = shift;
  ref($this) or croak "$this is not an object";

  $this->_trace();

  croak "method not implemented";
}

########################################################################
# get_compare_op
########################################################################

=head2 get_compare_op -- Returns the Comparison Operator

  $cmp_op = $obj->get_compare_op();

Returns the comparison operator of a DataType object.  This method
does not throw Perl execeptions.

This method is abstract and needs implementing.

Can return a couple of different comparison operators:

=over 4

=item 'cmp'

if the value of the object should be compared as a string.

=item '<=>'

if the value of the object should be compared as a number.

=back

=cut

sub get_compare_op {
  (@_ == 1) or croak 'Usage: $obj->get_compare_op()';
  my $this = shift;
  ref($this) or croak "$this is not an object";

  $this->_trace();

  croak "method not implemented";
}

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
# Function:    _trace
# Description: trace functions for debugging
# Parameters:  None
# Returns:     None
########################################################################
sub _trace {
  my $this = shift;

  if ($this->{Debug}) {
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

L<Persistent>, L<Persistent::DataType::Char>,
L<Persistent::DataType::DateTime>, L<Persistent::DataType::Number>,
L<Persistent::DataType::String>, L<Persistent::DataType::VarChar>

=head1 BUGS

This software is definitely a work in progress.  So if you find any
bugs please email them to me with a subject of 'Persistent::DataType
Bug' at:

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

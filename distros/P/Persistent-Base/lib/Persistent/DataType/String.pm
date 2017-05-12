########################################################################
# File:     String.pm
# Author:   David Winters <winters@bigsnow.org>
# RCS:      $Id: String.pm,v 1.7 2000/02/08 02:36:40 winters Exp winters $
#
# A character string class.
#
# This file contains POD documentation that may be viewed with the
# perldoc, pod2man, or pod2html utilities.
#
# Copyright (c) 1998-2000 David Winters.  All rights reserved.
# This program is free software; you can redistribute it
# and/or modify it under the same terms as Perl itself.
########################################################################

package Persistent::DataType::String;
require 5.004;

use strict;
use vars qw($VERSION $REVISION @ISA);

### we are a subclass of the all-powerful Persistent::DataType::Base class ###
use Persistent::DataType::Base;
@ISA = qw(Persistent::DataType::Base);

use Carp;

### copy version number from superclass ###
$VERSION = $Persistent::DataType::Base::VERSION;
$REVISION = (qw$Revision: 1.7 $)[1];

=head1 NAME

Persistent::DataType::String - A Character String Class

=head1 SYNOPSIS

  use Persistent::DataType::String;
  use English;

  eval {  ### in case an exception is thrown ###

    ### allocate a string ###
    my $string = new Persistent::DataType::String($value,
                                                  $max_length);

    ### get/set value of string ###
    $value = $string->value($new_value);

    ### get length of string ###
    my $length = $string->length();

    ### get/set maximum length of string ###
    my $max = $string->max_length($new_max);

    ### returns 'eq' for strings ###
    my $cmp_op = $string->get_compare_op();
  };

  if ($EVAL_ERROR) {  ### catch those exceptions! ###
    print "An error occurred: $EVAL_ERROR\n";
  }

=head1 ABSTRACT

This is a character string class used by the Persistent framework of
classes to implement the attributes of objects.  This class provides
methods for accessing the value, length, maximum length, and
comparison operator of a character string.

This class is usually not invoked directly, at least not when used
with the Persistent framework of classes.  However, the constructor
arguments of this class are usually of interest when defining the
attributes of a Persistent object since the I<add_attribute> method of
the Persistent classes instantiates this class directly.  Also, the
arguments to the I<value> method are of interest when dealing with the
accessor methods of the Persistent classes since the accessor methods
pass their arguments to the I<value> method and return the string
value from the I<value> method.

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
# --------------------------------------------------------------------
# PUBLIC ABSTRACT METHODS OVERRIDDEN (REDEFINED) FROM THE PARENT CLASS
# --------------------------------------------------------------------
#
########################################################################

########################################################################
# initialize
########################################################################

=head2 Constructor -- Creates the String Object

  eval {
    my $string = new Persistent::DataType::String($value,
                                                  $max_length);
  };
  croak "Exception caught: $@" if $@;

Initializes a character string object.  This method throws Perl
execeptions so use it with an eval block.

Parameters:

=over 4

=item I<$value>

Actual value of the string.  This argument is optional and may be set
to undef.

=item I<$max_length>

Maximum length of the string value.  This argument is optional and
will be initialized to an unlimitied length (0) as a default.

=back

=cut

sub initialize {
  my($this, $value, $max_length) = @_;

  $this->_trace();

  $max_length = 0 if !defined($max_length);
  $this->max_length($max_length);
  $this->value($value);
}

########################################################################
# value
########################################################################

=head2 value -- Accesses the Value of the String

  eval {
    ### set the value ###
    $string->value($value);

    ### get the value ###
    $value = $string->value();
  };
  croak "Exception caught: $@" if $@;

Sets the value of the string and/or returns the value.  This method
throws Perl execeptions so use it with an eval block.

Parameters:

=over 4

=item I<$value>

Actual value of the string.  This argument is optional and may be set
to undef.

=back

=cut

sub value {
  (@_ == 1 || @_ == 2) or croak 'Usage: $obj->value([$value])';
  my $this = shift;
  ref($this) or croak "$this is not an object";

  $this->_trace();

  ### set the value ###
  if (@_) {
    my $value = shift;
    $value = undef if defined $value && $value eq '';
    my $max_length = $this->max_length();

    ### check the length ###
    if (defined $value && $max_length > 0 && length($value) > $max_length) {
      croak "'$value' is longer than $max_length character(s)";
    } else {
      $this->{Data}->{Value} = $value;
    }
  }

  ### return the value ###
  $this->{Data}->{Value};
}

########################################################################
# get_compare_op
########################################################################

=head2 get_compare_op -- Returns the Comparison Operator

  $cmp_op = $string->get_compare_op();

Returns the comparison operator for the String class which is 'cmp'.
This method does not throw execeptions.

Parameters:

=over 4

=item None

=back

=cut

sub get_compare_op {
  (@_ == 1) or croak 'Usage: $obj->get_compare_op()';
  my $this = shift;
  ref($this) or croak "$this is not an object";

  $this->_trace();

  'cmp';  ### string comparison operator ###
}

########################################################################
#
# --------------
# PUBLIC METHODS
# --------------
#
########################################################################

########################################################################
# length
########################################################################

=head2 length -- Returns the Length of the String

  eval {
    $value = $string->length();
  };
  croak "Exception caught: $@" if $@;

Returns the length of the string.  This method throws Perl execeptions
so use it with an eval block.

Parameters:

=over 4

=item None

=back

=cut

sub length {
  (@_ > 0) or croak 'Usage: $obj->length()';
  my $this = shift;
  ref($this) or croak "$this is not an object";

  $this->_trace();

  ### no setting allowed ###
  croak "length is read-only" if @_;

  ### return the length ###
  length(defined $this->value() ? $this->value() : '');
}

########################################################################
# max_length
########################################################################

=head2 max_length -- Accesses the Maximum Length of the String

  eval {
    ### set the maximum length ###
    $string->max_length($new_max);

    ### get the maximum length ###
    $max_length = $string->max_length();
  };
  croak "Exception caught: $@" if $@;

Sets the maximum length of the string and/or returns it.  This method
throws Perl execeptions so use it with an eval block.

Parameters:

=over 4

=item I<$max_length>

Maximum length of the string value.  If the maximum length is set to
undef, the empty string (''), or 0, then the string has an unlimited
maximum length.

=back

=cut

sub max_length {
  (@_ == 1 || @_ == 2) or croak 'Usage: $obj->max_length([$max_length])';
  my $this = shift;
  ref($this) or croak "$this is not an object";

  $this->_trace();

  ### set the maximum length ###
  if (@_) {
    my $max_length = shift;
    $max_length = 0 if !defined($max_length) || $max_length eq '';
    croak "max_length($max_length) must be >= 0" if $max_length < 0;
    $this->{Data}->{MaxLength} = $max_length;

    ### shorten the value if too long ###
    if ($max_length > 0) {
      my $value = $this->value();
      if (defined $value && CORE::length($value) > $max_length) {
	$value = substr($value, 0, $max_length);
	$this->value($value);
      }
    }
  }

  ### return the length ###
  $this->{Data}->{MaxLength};
}

### end of library ###
1;
__END__

=head1 SEE ALSO

L<Persistent>, L<Persistent::DataType::Char>,
L<Persistent::DataType::DateTime>, L<Persistent::DataType::Number>,
L<Persistent::DataType::VarChar>

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

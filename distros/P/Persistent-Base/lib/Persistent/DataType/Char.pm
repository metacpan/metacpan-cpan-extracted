########################################################################
# File:     Char.pm
# Author:   David Winters <winters@bigsnow.org>
# RCS:      $Id: Char.pm,v 1.7 2000/02/08 02:36:40 winters Exp winters $
#
# A fixed length character class.
#
# This file contains POD documentation that may be viewed with the
# perldoc, pod2man, or pod2html utilities.
#
# Copyright (c) 1998-2000 David Winters.  All rights reserved.
# This program is free software; you can redistribute it
# and/or modify it under the same terms as Perl itself.
########################################################################

package Persistent::DataType::Char;
require 5.004;

use strict;
use vars qw($VERSION $REVISION @ISA);

### a subclass of the all-powerful Persistent::DataType::String class ###
use Persistent::DataType::String;
@ISA = qw(Persistent::DataType::String);

use Carp;

### copy version number from superclass ###
$VERSION = $Persistent::DataType::String::VERSION;
$REVISION = (qw$Revision: 1.7 $)[1];

=head1 NAME

Persistent::DataType::Char - A Fixed Length Character String Class

=head1 SYNOPSIS

  use Persistent::DataType::Char;
  use English;

  eval {  ### in case an exception is thrown ###

    ### allocate a string ###
    my $string = new Persistent::DataType::Char($value,
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

This is a fixed length character string class used by the Persistent
framework of classes to implement the attributes of objects.  This
class provides methods for accessing the value, length, maximum
length, and comparison operator of a fixed length character string.  A
fixed length string (Char) always has a finite maximum length that can
not be exceeded.  If the string is shorter than this maximum length,
then the string is padded with spaces on the trailing end.  This is
different from a character string (String) which can have an unlimited
maximum length and a variable length string (VarChar) which is not
padded.

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

=head2 Constructor -- Creates the Char Object

  eval {
    my $string = new Persistent::DataType::Char($value,
                                                $max_length);
  };
  croak "Exception caught: $@" if $@;

Initializes a fixed length character string object.  This method
throws Perl execeptions so use it with an eval block.

Parameters:

=over 4

=item I<$value>

Actual value of the string.  This argument is optional and may be set
to undef.

=item I<$max_length>

Maximum length of the string value.  This argument is optional and
will be initialized to the length of the I<$value> as a default or 1
if no I<$value> argument is passed.

=back

=cut

sub initialize {
  my($this, $value, $max_length) = @_;

  $this->_trace();

  if (!defined($max_length)) {
    if (!defined($value) || $value eq '') {
      $max_length = 1;
    } else {
      $max_length = length($value);
    }
  }
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
to undef.  The value returned will be padded with spaces if the length
is less than the maximum length.

=back

=cut

sub value {
  (@_ == 1 || @_ == 2) or croak 'Usage: $obj->value([$value])';
  my $this = shift;
  ref($this) or croak "$this is not an object";

  $this->_trace();

  ### superclass does all the work, just pad the value with spaces ###
  my $value = $this->SUPER::value(@_);
  if (defined $value) {
    my $max_length = $this->max_length();
    sprintf("%-${max_length}s", $value);
  } else {
    $value;
  }
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

Returns the length of the string which is always the same as the
maximum length for a fixed length string.  This method throws Perl
execeptions so use it with an eval block.

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
  $this->max_length();
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

Maximum length of the string value.  The maximum length must be
greater than zero, otherwise, an exception is thrown.

=back

=cut

sub max_length {
  (@_ == 1 || @_ == 2) or croak 'Usage: $obj->max_length([$max_length])';
  my $this = shift;
  ref($this) or croak "$this is not an object";

  $this->_trace();

  ### check the arguments ###
  if (@_) {
    my($max_length) = @_;
    if (!defined($max_length) || $max_length eq '' || $max_length <= 0) {
      croak(sprintf("maximum length (%s) must be > 0",
		    defined $max_length ? $max_length : 'undef'));
    }
  }

  ### superclass does the work ###
  $this->SUPER::max_length(@_);
}

### end of library ###
1;
__END__

=head1 SEE ALSO

L<Persistent>, L<Persistent::DataType::DateTime>,
L<Persistent::DataType::Number>, L<Persistent::DataType::String>,
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

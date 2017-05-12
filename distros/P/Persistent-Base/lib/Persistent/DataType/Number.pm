########################################################################
# File:     Number.pm
# Author:   David Winters <winters@bigsnow.org>
# RCS:      $Id: Number.pm,v 1.6 2000/02/08 02:36:40 winters Exp winters $
#
# A floating point and integer class.
#
# This file contains POD documentation that may be viewed with the
# perldoc, pod2man, or pod2html utilities.
#
# Copyright (c) 1998-2000 David Winters.  All rights reserved.
# This program is free software; you can redistribute it
# and/or modify it under the same terms as Perl itself.
########################################################################

package Persistent::DataType::Number;
require 5.004;

use strict;
use vars qw($VERSION $REVISION @ISA);

### we are a subclass of the all-powerful Persistent::DataType::Base class ###
use Persistent::DataType::Base;
@ISA = qw(Persistent::DataType::Base);

use Carp;

### copy version number from superclass ###
$VERSION = $Persistent::DataType::Base::VERSION;
$REVISION = (qw$Revision: 1.6 $)[1];

=head1 NAME

Persistent::DataType::Number - A Floating Point and Integer Class

=head1 SYNOPSIS

  use Persistent::DataType::Number;
  use English;

  eval {  ### in case an exception is thrown ###

    ### allocate a number ###
    my $number = new Persistent::DataType::Number($value,
                                                  $precision,
						  $scale);

    ### get/set value of number ###
    $value = $number->value($new_value);

    ### get/set precision of the number ###
    $precision = $number->precision($new_precision);

    ### get/set scale of number ###
    $scale = $number->scale($new_scale);

    ### returns '<=>' for numbers ###
    my $cmp_op = $number->get_compare_op();
  };

  if ($EVAL_ERROR) {  ### catch those exceptions! ###
    print "An error occurred: $EVAL_ERROR\n";
  }

=head1 ABSTRACT

This is a floating point and integer class used by the Persistent
framework of classes to implement the attributes of objects.  This
class provides methods for accessing the value, precision, scale, and
comparison operator of a number.

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

=head2 Constructor -- Creates the Number Object

  eval {
    my $number = new Persistent::DataType::Number($value,
                                                  $precision,
                                                  $scale);
  };
  croak "Exception caught: $@" if $@;

Initializes a number object.  This method throws Perl execeptions so
use it with an eval block.

Parameters:

=over 4

=item I<$value>

Actual value of the number; this may be a floating point or integer.
This argument is optional and may be set to undef.

=item I<$precision>

The number of digits in the number not including the decimal point or
the sign.  This argument is optional and will be initialized to the
precision of the I<$value> argument as a default.

=item I<$scale>

The number of digits after the decimal point.  This argument is
optional and will be initialized to the scale of the I<$value>
argument as a default.

=back

=cut

sub initialize {
  my($this, $value, $precision, $scale) = @_;

  $this->_trace();

  ### parse out the digits before and after the decimal point ###
  my($before, $after) = _parse_number($value);

  ### set the attributes ###
  $precision = length($before) + length($after) if !defined($precision);
  $this->precision($precision);
  $scale = length($after) if !defined($scale);
  $this->scale($scale);
  $this->value($value);
}

########################################################################
# value
########################################################################

=head2 value -- Accesses the Value of the Number

  eval {
    ### set the value ###
    $number->value($value);

    ### get the value ###
    $value = $number->value();
  };
  croak "Exception caught: $@" if $@;

Sets the value of the number and/or returns the value.  This method
throws Perl execeptions so use it with an eval block.

Parameters:

=over 4

=item I<$value>

Actual value of the number; this may be a floating point or integer.
This argument is optional and may be set to undef.

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

    ### parse out the digits before and after the decimal point ###
    my($before, $after) = _parse_number($value);

    ### get the precision and scale of the object ###
    my $precision = $this->precision();
    my $scale = $this->scale();

    ### check the length ###
    if (length($before) + length($after) > $precision) {
      croak "'$value' is longer than $precision digit(s) of precision";
    } elsif (length($after) > $scale) {
      croak "'$value' is longer than $scale digit(s) of scale";
    } else {
      $value = $value + 0 if defined $value;  ### force numeric context ###
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

  $cmp_op = $number->get_compare_op();

Returns the comparison operator for the Number class which is '<=>'.
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

  '<=>';  ### number comparison operator ###
}

########################################################################
#
# --------------
# PUBLIC METHODS
# --------------
#
########################################################################

########################################################################
# precision
########################################################################

=head2 precision -- Accesses the Precision of the Number

  eval {
    ### set the precision ###
    $number->precision($new_precision);

    ### get the precision ###
    $precision = $number->precision();
  };
  croak "Exception caught: $@" if $@;

Sets the precision of the number and/or returns it.  This method
throws Perl execeptions so use it with an eval block.

Parameters:

=over 4

=item I<$precision>

The number of digits in the number not including the decimal point or
the sign.  The precision must be >= 0.  If it is undef or the empty
string (''), then it is set to 0.

=back

=cut

sub precision {
  (@_ == 1 || @_ == 2) or croak 'Usage: $obj->precision([$precision])';
  my $this = shift;
  ref($this) or croak "$this is not an object";

  $this->_trace();

  ### set the precision ###
  if (@_) {
    my $precision = shift;
    $precision = 0 if !defined($precision) || $precision eq '';
    croak "precision ($precision) must be >= 0" if $precision < 0;
    $this->{Data}->{Precision} = $precision;

    ### check that the value is not too long ###
    my $value = $this->value();
    if (defined $value) {
      $value =~ s/[\-\.]//g;
      if (length($value) > $precision) {
	croak(sprint("'%s' is longer than $precision digit(s) of precision",
		     $this->value()));
      }
    }
  }

  ### return the precision ###
  $this->{Data}->{Precision};
}

########################################################################
# scale
########################################################################

=head2 scale -- Accesses the Scale of the Number

  eval {
    ### set the scale ###
    $number->scale($new_scale);

    ### get the scale ###
    $scale = $number->scale();
  };
  croak "Exception caught: $@" if $@;

Sets the scale of the number and/or returns it.  This method throws
Perl execeptions so use it with an eval block.

Parameters:

=over 4

=item I<$scale>

The number of digits after the decimal point.  The scale must be >= 0.
If it is undef or the empty string (''), then it is set to 0.

=back

=cut

sub scale {
  (@_ == 1 || @_ == 2) or croak 'Usage: $obj->scale([$scale])';
  my $this = shift;
  ref($this) or croak "$this is not an object";

  $this->_trace();

  ### set the scale ###
  if (@_) {
    my $scale = shift;
    $scale = 0 if !defined($scale) || $scale eq '';
    croak "scale ($scale) must be >= 0" if $scale < 0;
    $this->{Data}->{Scale} = $scale;

    ### check that the value is not too long ###
    my $value = $this->value();
    if (defined $value) {
      if ($value =~ /^\d*\.(\d*)$/) {
	if (length($1) > $scale) {
	  croak(sprint("'%s' is longer than $scale digit(s) of scale",
		       $this->value()));
	}
      }
    }
  }

  ### return the scale ###
  $this->{Data}->{Scale};
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
# Function:    _parse_number
# Description: Parses the number into digits before and after the
#              decimal point.  Insignificant trailing zeroes will be
#              truncated.
# Parameters:  None
# Returns:     None
########################################################################
sub _parse_number {
  my $value = shift;

  my $before = '';
  my $after = '';

  if (defined $value) {
    if ($value =~ /^[+-]?(\d*)\.?(\d*)$/) {
      $before = $1;  $after = $2;
      $after =~ s/0+$//;  ### remove trailing zeroes ###
    } else {
      croak "'$value' is not a number";
    }
  }

  ($before, $after);
}

### end of library ###
1;
__END__

=head1 SEE ALSO

L<Persistent>, L<Persistent::DataType::Char>,
L<Persistent::DataType::DateTime>, L<Persistent::DataType::String>,
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

# ------------------------------------------------------------------------------
#  Copyright © 2003 by Matt Luker.  All rights reserved.
# 
#  Revision:
# 
#  $Header$
# 
# ------------------------------------------------------------------------------

# Exception.pm - provides a flexible Exception object to allow C++/Java like
# exception handling syntax, containing all the main exception classes for
# RSH projects.
#
# Granted, you could just use "die STRING", but it isn't very flexible and it
# doesn't provide any kind of "typing".  Which means you have to then rely on
# the string content if you want to do any kind of selective catch/throw
# logic.  And that just isn't a good idea.
#
# This is a very simple object, basically providing type and data values.  The
# catch method allows C++ syntax in perl code.
# 
# @author  Matt Luker
# @version $Revision: 3250 $

# Exception.pm - provides a flexible Exception object to allow C++/Java like
# exception handling syntax, containing all the main exception classes for
# RSH projects.
# 
# Copyright (C) 2003, Matt Luker
# 
# This library is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself. 

# If you have any questions about this software,
# or need to report a bug, please contact me.
# 
# Matt Luker
# Port Angeles, WA
# kostya@redstarhackers.com
# 
# TTGOG

package RSH::Exception;

use 5.008;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

our @EXPORT_OK = qw(
					);

our @EXPORT = qw(
				 &catch
				);

use Carp;
use overload 
  'cmp' => \&compare,
  '""' => \&string;


# ******************** PUBLIC Class Methods ********************

# catch
#
# Allows syntax close to C++/Java's catch(type) syntax
#
# params:
#   exception_type - the name of the exception type or "" for any type
#   exception - the exception
#
# returns:
#   1 if the exception matches the type (or is defined if type is ""), 0 otherwise
#
sub catch {
	my $exception_type = shift;
	my $exception = shift;
	my $block = shift;

	if (not defined($exception_type)) { die "Syntax Error: you must supply the exception type or \"\" for any type."; }

	my $match = 0;

	if (not defined($exception)) { $match = 0; }

	if (length($exception_type) == 0) {
		$match = defined($exception);
	} else {
		$match = UNIVERSAL::isa($exception, $exception_type);
	}
	
	if (not defined($block)) { return $match; }
	else {
		if ($match) { &$block($exception) }
		return $match;
	}
}

# ******************** CONSTRUCTOR Methods ********************

sub new {
	my $class = shift;

	my %params = @_;

	my $self = {};

	$self->{error_code} = $params{error_code};
	$self->{message} = $params{message};

	bless $self, $class;

	return $self;
}

# ******************** PUBLIC Instance Methods ********************

# ******************** Accessor Methods ********************

# error_code
#
# Read/Write accessor for error_code attribute
#
# params:
#   $value - (optional) new error_code value
#
# returns:
#   value of error_code attribute
#
sub error_code {
	my $self = shift;
	my $value = shift;

	if (defined($value)) {
		$self->{error_code} = $value;
	}
	
	return $self->{error_code};
}

# message
#
# Read/Write accessor for message attribute
#
# params:
#   $value - (optional) new message value
#
# returns:
#   value of message attribute
#
sub message {
	my $self = shift;
	my $value = shift;

	if (defined($value)) {
		$self->{message} = "". $value;
	}

	return $self->{message};
}

# ******************** Operator Overloading ********************

# compare
#
# Performs eq test.
#
sub compare {
	my $self = shift;
	my $val = shift;
	my $reversed = shift;

	if ($reversed eq '') { $reversed = 0; }

	if (UNIVERSAL::isa($val, 'RSH::Exception')) {
		# there really isn't any way to compare exceptions
		if (not $reversed) {
			return ($self->string cmp $val->string);
		} else {
			return ($val->string cmp $self->string);
		}
	} else {
		if (not $reversed) {
			return ($self->string cmp $val);
		} else {
			return ($val cmp $self->string);
		}
	}
}		

# string
#
# Returns a string representation of the Exception object.
#
sub string {
	my $self = shift;

	my $string = "";

	if (defined($self->{error_code})) {
		$string .= $self->{error_code};
	}
	if (defined($self->{message})) {
		if (length($string) > 0) {
			$string .= ": ";
		}
		$string .= $self->{message};
	}

	if (length($string) == 0) { $string = "Exception!"; }

	return Carp::longmess($string);
}

# #################### Exception.pm ENDS ####################

# CodeException.pm - exception class for code exceptions and errors.
#
# Examples would be parameter checking and handling.
#
# @author  Matt Luker

package RSH::CodeException;

our @ISA = qw(Exporter RSH::Exception);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

our @EXPORT_OK = qw(
					);

our @EXPORT = qw(
				 );

# ******************** PUBLIC Class Methods ********************


# ******************** CONSTRUCTOR Methods ********************

sub new {
	my $class = shift;

	my %params = @_;

	if (not defined($params{error_code})) { $params{error_code} = 'RSH00500'; }
	if (not defined($params{message})) { $params{message} = 'Code exception'; }

	my $self = new RSH::Exception %params;

	bless $self, $class;

	return $self;
}

# ******************** PUBLIC Instance Methods ********************

# #################### CodeException.pm ENDS ####################

# NotImplementedException.pm - exception class for code exceptions and errors.
#
# Examples would be parameter checking and handling.
#
# @author  Matt Luker

package RSH::NotImplementedException;

our @ISA = qw(Exporter RSH::Exception);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

our @EXPORT_OK = qw(
					);

our @EXPORT = qw(
				 );

# ******************** PUBLIC Class Methods ********************


# ******************** CONSTRUCTOR Methods ********************

sub new {
	my $class = shift;

	my %params = @_;

	if (not defined($params{error_code})) { $params{error_code} = 'RSH00510'; }
	if (not defined($params{message})) { $params{message} = 'Code exception'; }

	my $self = new RSH::CodeException %params;

	bless $self, $class;

	return $self;
}

# ******************** PUBLIC Instance Methods ********************

# #################### NotImplementedException.pm ENDS ####################

# SystemException.pm - exception class for system exceptions and errors.
#
# SystemExceptions should generally not be caught, or if caught,
# the application should fail with extreme prejudice.
#
# @author  Matt Luker

package RSH::SystemException;

our @ISA = qw(Exporter RSH::Exception);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

our @EXPORT_OK = qw(
					);

our @EXPORT = qw(
				 );

# ******************** PUBLIC Class Methods ********************


# ******************** CONSTRUCTOR Methods ********************

sub new {
	my $class = shift;

	my %params = @_;

	if (not defined($params{error_code})) { $params{error_code} = 'RSH00900'; }
	if (not defined($params{message})) { $params{message} = 'System exception'; }

	my $self = new RSH::Exception %params;

	bless $self, $class;

	return $self;
}

# ******************** PUBLIC Instance Methods ********************

# #################### SystemException.pm ENDS ####################

# DataIntegrityException.pm - exception class for dataintegrity exceptions and errors.
#
# @author  Matt Luker

package RSH::DataIntegrityException;

our @ISA = qw(Exporter RSH::Exception);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

our @EXPORT_OK = qw(
					);

our @EXPORT = qw(
				 );

# ******************** PUBLIC Class Methods ********************


# ******************** CONSTRUCTOR Methods ********************

sub new {
	my $class = shift;

	my %params = @_;

	if (not defined($params{error_code})) { $params{error_code} = 'RSH01000'; }
	if (not defined($params{message})) { $params{message} = 'DataIntegrity exception'; }

	my $self = new RSH::Exception %params;

	bless $self, $class;

	return $self;
}

# ******************** PUBLIC Instance Methods ********************

# #################### DataIntegrityException.pm ENDS ####################

# ConstraintException.pm - exception class for constraint exceptions and errors.
#
# @author  Matt Luker

package RSH::ConstraintException;

our @ISA = qw(Exporter RSH::DataIntegrityException);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

our @EXPORT_OK = qw(
					);

our @EXPORT = qw(
				 );

# ******************** PUBLIC Class Methods ********************


# ******************** CONSTRUCTOR Methods ********************

sub new {
	my $class = shift;

	my %params = @_;

	if (not defined($params{error_code})) { $params{error_code} = 'RSH01010'; }
	if (not defined($params{message})) { $params{message} = 'Constraint exception'; }

	my $self = new RSH::DataIntegrityException %params;

	bless $self, $class;

	return $self;
}

# ******************** PUBLIC Instance Methods ********************

# #################### ConstraintException.pm ENDS ####################

# SecurityException.pm - exception class for security exceptions and errors.
#
# @author  Matt Luker

package RSH::SecurityException;

our @ISA = qw(Exporter RSH::Exception);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

our @EXPORT_OK = qw(
					);

our @EXPORT = qw(
				 );

# ******************** PUBLIC Class Methods ********************


# ******************** CONSTRUCTOR Methods ********************

sub new {
	my $class = shift;

	my %params = @_;

	if (not defined($params{error_code})) { $params{error_code} = 'RSH02000'; }
	if (not defined($params{message})) { $params{message} = 'Security exception'; }

	my $self = new RSH::Exception %params;

	bless $self, $class;

	return $self;
}

# ******************** PUBLIC Instance Methods ********************

# #################### SecurityException.pm ENDS ####################

# BadPasswordException.pm - exception class for bad password exceptions and errors.
#
# @author  Matt Luker

package RSH::BadPasswordException;

our @ISA = qw(Exporter RSH::SecurityException);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

our @EXPORT_OK = qw(
					);

our @EXPORT = qw(
				 );

# ******************** PUBLIC Class Methods ********************


# ******************** CONSTRUCTOR Methods ********************

sub new {
	my $class = shift;

	my %params = @_;

	if (not defined($params{error_code})) { $params{error_code} = 'RSH02010'; }
	if (not defined($params{message})) { $params{message} = 'Bad password exception'; }

	my $self = new RSH::SecurityException %params;

	bless $self, $class;

	return $self;
}

# ******************** PUBLIC Instance Methods ********************

# #################### BadPasswordException.pm ENDS ####################

# FileException.pm - exception class for file exceptions and errors.
#
# Examples would be parameter checking and handling.
#
# @author  Matt Luker

package RSH::FileException;

our @ISA = qw(Exporter RSH::Exception);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

our @EXPORT_OK = qw(
					);

our @EXPORT = qw(
				 );

# ******************** PUBLIC Class Methods ********************


# ******************** CONSTRUCTOR Methods ********************

sub new {
	my $class = shift;

	my %params = @_;

	if (not defined($params{error_code})) { $params{error_code} = 'RSH03000'; }
	if (not defined($params{message})) { $params{message} = 'File Exception'; }

	my $self = new RSH::Exception %params;

	bless $self, $class;

	return $self;
}

# ******************** PUBLIC Instance Methods ********************

# #################### FileException.pm ENDS ####################

# FileNotFoundException.pm - exception class for filenotfound exceptions and errors.
#
# Examples would be parameter checking and handling.
#
# @author  Matt Luker

package RSH::FileNotFoundException;

our @ISA = qw(Exporter RSH::FileException);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

our @EXPORT_OK = qw(
					);

our @EXPORT = qw(
				 );

# ******************** PUBLIC Class Methods ********************


# ******************** CONSTRUCTOR Methods ********************

sub new {
	my $class = shift;

	my %params = @_;

	if (not defined($params{error_code})) { $params{error_code} = 'RSH03010'; }
	if (not defined($params{message})) { $params{message} = 'File not found exception'; }

	my $self = new RSH::FileException %params;

	bless $self, $class;

	return $self;
}

# ******************** PUBLIC Instance Methods ********************

# #################### FileNotFoundException.pm ENDS ####################

# RuntimeException.pm - exception class for runtime exceptions and errors.
#
# Examples would be parameter checking and handling.
#
# @author  Matt Luker

package RSH::RuntimeException;

our @ISA = qw(Exporter RSH::Exception);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

our @EXPORT_OK = qw(
					);

our @EXPORT = qw(
				 );

# ******************** PUBLIC Class Methods ********************


# ******************** CONSTRUCTOR Methods ********************

sub new {
	my $class = shift;

	my %params = @_;

	if (not defined($params{error_code})) { $params{error_code} = 'RSH09000'; }
	if (not defined($params{message})) { $params{message} = 'Runtime exception'; }

	my $self = new RSH::Exception %params;

	bless $self, $class;

	return $self;
}

# ******************** PUBLIC Instance Methods ********************

# #################### RuntimeException.pm ENDS ####################

# IndexOutOfBoundsException.pm - exception class for indexOutOfBounds exceptions and errors.
#
# Examples would be parameter checking and handling.
#
# @author  Matt Luker

package RSH::IndexOutOfBoundsException;

our @ISA = qw(Exporter RSH::Exception);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

our @EXPORT_OK = qw(
					);

our @EXPORT = qw(
				 );

# ******************** PUBLIC Class Methods ********************


# ******************** CONSTRUCTOR Methods ********************

sub new {
	my $class = shift;

	my %params = @_;

	if (not defined($params{error_code})) { $params{error_code} = 'RSH09010'; }
	if (not defined($params{message})) { $params{message} = 'Index out of bounds exception'; }

	my $self = new RSH::Exception %params;

	bless $self, $class;

	return $self;
}

# ******************** PUBLIC Instance Methods ********************

# #################### IndexOutOfBoundsException.pm ENDS ####################

1;

__END__

# TTGOG

# ------------------------------------------------------------------------------
# 
#  $Log$
#  Revision 1.5  2004/04/09 06:18:26  kostya
#  Added quote escaping capabilities.
#
#  Revision 1.4  2003/12/27 07:41:04  kostya
#  Spelling error ;-)
#
#  Revision 1.3  2003/11/14 05:26:58  kostya
#  Added some new exception types.
#
#  Revision 1.2  2003/10/15 01:07:00  kostya
#  documentation and license updates--everything is Artistic.
#
#  Revision 1.1.1.1  2003/10/13 01:38:04  kostya
#  First import
#
#  Revision 1.4  2003/08/23 07:11:43  kostya
#  New file exceptions.
#
#  Revision 1.3  2003/08/23 01:00:33  kostya
#  Added a lot of exceptions and set up some inheritance.
#
#  Revision 1.2  2003/08/01 06:12:54  kostya
#  Changed ConstraintException package name for less typing ;-)
#
#  Revision 1.1  2003/07/29 20:35:02  kostya
#  Exception class.
#
# 
# ------------------------------------------------------------------------------


# Money::ChangeMaker::Denomination -- A representation of a monetary unit for
#                                     use by Money::ChangeMaker
package Money::ChangeMaker::Denomination;

require 5;
use strict;

our $VERSION = '0.3';

##   Here there be methods

# The constructor method.
# It takes 2 required arguments and one optional argument
# The first argument must be the numeric value of the monetary unit.
#   It should be positive, but need not be integral.  See the documentation
#   for Money::ChangeMaker::Presets for information on the possible pitfalls
#   of making non-integer denominations.
# The second argument must be the name of the denomination.  ie "dime" or
#   "one pound note".
# The optional third argument is the pluralization of the name.  If this
#   is not provided, then an "s" is appended to the name.  It is
#   surprising how often this is correct.  :)  An example -- "pennies".
sub new {
  my($proto) = shift;
  my($class) = ref($proto) || $proto;
  my($self) = {};
  bless($self, $class);
	if (@_ != 2 && @_ != 3) {
		return Money::ChangeMaker::_warn(
			"Denomination constructor must take 2 or 3 arguments"
		);
	}
	# Allow "5f" to be treated as "5"
	my $val;
	unless (($val = _number_of($_[0])) > 0) {
		return Money::ChangeMaker::_warn(
			"Denomenation value must be a number greater than 0"
		);
	}
	$self->{_VALUE} = $_[0];
	$self->{_NAME} = $_[1];
	$self->{_PLURAL} = $_[2];
  return($self);
}

# Sets/returns the numeric value of this denomination
sub value {
	my($self) = shift;
	my($value) = shift;
	if (defined($value) && $value > 0) {
		$self->{_VALUE} = $value;
	}
	return $self->{_VALUE};
}

# Sets/returns the descriptive name of this denomination
sub name {
	my($self) = shift;
	my($name) = shift;
	if (defined($name)) {
		$self->{_NAME} = $name;
	}
	return $self->{_NAME};
}

# Sets/returns the descriptive name for plurals of this denomination.
# If this value is undef, will return the "name" value appended with an "s"
sub plural {
	my($self) = shift;
	my($plural) = shift;
	if (defined($plural)) {
		$self->{_PLURAL} = $plural;
	}
	return $self->{_PLURAL} ? $self->{_PLURAL} : $self->{_NAME} . "s";
}

# Converts a string containing numbers and letters into just a number.
# Returns -1 if there are no word-leading numbers
sub _number_of {
	my $test = shift;
	if ($test =~ /^([\d.]+)/) {
		return $1;
	}
	return -1;
}

1;

__END__

=head1 NAME

Money::ChangeMaker::Denomination - OO representation of a monetary unit

=head1 SYNOPSIS

	See L<Money::ChangeMaker>

=head1 DESCRIPTION

An object of type Denomination represents a monetary unit, such as a
dollar bill or a 5 rupee coin.  Objects such as this are used by the
Money::ChangeMaker.  Instead of subclassing this package, it will generally
use singelton exemplar objects to hold basic type information.

=head1 METHODS

=over 4


=item new(value, name, [plural])

This is the constructor method for the class.

The first argument must be numeric, and represents the value of this object.
If this Denomination is part of a set, it is important that its value be
expressed in the same base units as the other Denominations in that set.
For example, if the nickel Denomination has the value 5, then the 10 dollar
bill Denomination should have the value 1000, not 10. Please see the
documentation for the L<Money::ChangeMaker::Presets> module for notes on the
downsides of using non-integer values in denominations.

The second argument is the name of this Denomination, such as "dollar bill"
or "penny".  The third argument is optional, and if provided, sets the
'plural name' of the Denomination.  If this argument is not provided, then
the Denomination's name is appended with "s" to create the plural.  This
argument would be provided in the case of, for example, "pennies".


=item value([value])

Sets/gets the value of this object


=item name([name])

Sets/gets the name of this object.


=item plural([plural])

Sets/gets the plural name of this object.


=back

=head1 Future Work

=over 4

=item *

See L<Money::ChangeMaker>


=back

=head1 AUTHOR

Copyright 2006 Avi Finkel <F<avi@finkel.org>>

This package is free software and is provided "as is" without express
or implied warranty.  It may be used, redistributed and/or modified
under the terms of the Perl Artistic License (see
http://www.perl.com/perl/misc/Artistic.html)

=cut

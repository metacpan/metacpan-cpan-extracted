# Money::ChangeMaker -- Making change.

package Money::ChangeMaker;

require 5;
use strict;
use vars qw($VERSION);
use Money::ChangeMaker::Denomination;
use Money::ChangeMaker::Presets;

$VERSION = "0.3";

# These are private class members

# This is a reference to the set of predefined monetary sets.
# See perldocs in Presets.pm for more information.
my($_presets) = Money::ChangeMaker::Presets::_gen_presets_hash();

##   Here there be methods

# The constructor method.  It's very simple.
sub new {
  my($proto) = shift;
  my($options) = shift;
  my($class) = ref($proto) || $proto;
  my($self) = {};
  bless($self, $class);
  $self->{_DENOMINATIONS} = $_presets->{USA};
  unless ( defined($options) && (ref($options) eq "HASH") ) {
    $options = {};
  }
	if (exists($options->{'denominations'})) {
		$self->denominations($options->{'denominations'});
	}
  return($self);
}

# Sets the monetary denominations for making change, if a parameter is passed.
# Returns the new value.  A denominations value is a reference to an array of
# Money::ChangeMaker::Denomination objects.
sub denominations {
  my($self) = shift;
  my($option) = shift;
  if(defined($option)) {
		if (_check_denom($option)) {
			$self->{_DENOMINATIONS} = [(sort {$b->value <=> $a->value} @{$option})];
		}
  }
  return $self->{_DENOMINATIONS};
}

# The whole point of this module.  The entire algorithm is, um...  6 lines.
# :)  Sometimes I wonder.
# Take 2 values -- first the "price" of a thing, and second the amount
# of money that was paid.
# In list context, returns a list of Denomination objects, representing
# the units of currency that would make up the most efficient set of
# change given the transation.  Larger denominations are at the front of
# the list, and denomination objects will be repeated to indicate multiples.
# In scalar context, returns the results of passing the above described
# output through 
sub make_change {
	my($self) = shift;
	my($price) = shift;
	my($tendered) = shift;
	unless (defined($price) && defined($tendered)) {
		return _warn("Price and amount tendered must both be defined");
	}
	if ($price < 1 || $tendered < 1) {
		return _warn(
			"Price and amount tendered must both be numbers, greater than 0."
		);
	}
	if ($tendered < $price) {
		return _warn("Insufficient funds tendered to cover price.");
	}
	my @ret;
	for my $denom (@{$self->{_DENOMINATIONS}}) {
		while ($tendered - $price >= $denom->value) {
			push(@ret, $denom);
			$tendered -= $denom->value;
		}
	}
	if (wantarray) {
		return @ret;
	}
	else {
		return as_string(@ret);
	}
}

# This makes sure that a scalar is a proper reference to a list of
# proper Denomination objects.
sub _check_denom {
	my($test) = shift;
	unless (ref($test) eq 'ARRAY') {
		return _warn("The denominations must be a reference to a list.");
	}
	for my $i (0..$#{$test}) {
		unless (defined($test->[$i])) {
			return _warn("Element " . $i + 1 . " is undef in denomination array.");
		}
		unless ($test->[$i]->isa("Money::ChangeMaker::Denomination")) {
			return _warn(
				"Element " . $i + 1 .
				" is not of the proper type in denomination array."
			);
		}
	}
	return 1;
}

# A simple method to print a warning.
# I may want to consider a different mechanism for handling non-fatals, so
# this may change.
sub _warn {
	warn(shift());
	return undef;
}

# Gets a reference to a list from the set of preset money sets by name.
sub get_preset {
	# Get rid of the first arg if this was called as an object or class method
	shift if UNIVERSAL::isa($_[0], __PACKAGE__);
	my($preset) = shift;
	return $_presets->{$preset};
}

# Gets a list of available names of preset money sets.
sub get_preset_names {
	# Get rid of the first arg if this was called as an object or class method
	shift if UNIVERSAL::isa($_[0], __PACKAGE__);
	return (keys %{$_presets});
}

# Given, as input, the list output of the make_change method, will return a
# string with a basic english representation of the data.  See the
# make_change method for more information on its output.
sub as_string {
	# Get rid of the first arg if this was called as an object or class method
	shift if UNIVERSAL::isa($_[0], __PACKAGE__);
	my $thisDenom;
	my $num;
	my $ret;
	for my $denom (@_) {
		unless (UNIVERSAL::isa($denom, "Money::ChangeMaker::Denomination")) {
			return _warn("All arguments must be of proper Denomination class");
		}
		if (
			defined($thisDenom) && defined($denom) &&
			$denom->name eq $thisDenom->name
		) {
			$num++;
		}
		else {
			if (defined($thisDenom)) {
				if ($ret) {
					$ret .= ", ";
				}
				$ret .= "$num ";
				if ($num > 1) {
					$ret .= $thisDenom->plural;
				}
				else {
					$ret .= $thisDenom->name;
				}
			}
			$thisDenom = $denom;
			$num = 1;
		}
	}
	if ($ret) {
		$ret .= ", ";
	}
	$ret .= "$num ";
	if ($num > 1) {
		$ret .= $thisDenom->plural;
	}
	else {
		$ret .= $thisDenom->name;
	}
	$ret =~ s/(.*), (\d)/$1 and $2/;
	return $ret;
}

1;

__END__

=head1 NAME

Money::ChangeMaker - A module to make change based on a monetary quantity.

=head1 SYNOPSIS

 use Money::ChangeMaker;
 use strict;

 my($till) = new Money::ChangeMaker;
 $till->denominations($till->get_preset('USA'));
 # Change for 11 dollars, 38 cents from a 20 dollar bill
 print scalar $till->make_change(1138, 2000);
 # Prints:
 # 1 five dollar bill, 3 dollar bills, 2 quarters, 1 dime and 2 pennies

=head1 DESCRIPTION

Money::ChangeMaker represents, roughly, a cash register and the
process of giving change for a purchase.  As of this release, it only
really implements the change-making process, but future releases will
implement more of the "cash register" functionality.

=head1 METHODS

=over 4


=item new()
=item new(\%options)

This is the constructor method for the class.  You may optionally pass it
a hash reference with a set of C<option =E<gt> value> pairs.  The only
option available is 'denominations' which takes a reference
to an array of Money::ChangeMaker::Denomination objects, which will
define the currency set which this object will use.


=item denominations()
=item denominations(@denoms)

Takes one argument, which is optional.  If present, it must be a reference
to a list of Money::ChangeMaker::Denomination objects -- these objects
will define the currency set that this object will use.  The list need not
be in any particular order.  After setting the new value (if an argument
was provided), the current value will be returned.

=item make_change($price, $tendered)

This method requires 2 arguments -- the price of the "item", and the
amount of money that was tendered.  It will then calculate the numbers
and types of monetary units that will be returned as change.  The two
arguments must be numeric, and they should be properly scaled to the base
of the Denomination set you are using.  For example, the default
currency set is American money, which defines the base unit as one cent,
not one dollar.  So, to find change for $15.21 out of $20.00, you would
call C<$till-E<gt>make_change(1521, 2000)>.

Each denomination set should define its own base unit, and all of the
built-in sets in this module use the lowest possible base unit in order
to avoid rounding errors with floating point values.

In list context, this method returns a list of denomination objects
representing the monetary units to be returned in change, in descending
value-order.  If more than one of a given type of unit must be returned in
the change, that type of object will show up that many times in the returned
list.

For example, when getting change for $15.21 from $20.00, the resulting
list will have 11 elements, consisting of 4 dollar bill objects, 3 quarter
objects and 4 penny objects.

In scalar context, the results as just described are passed to the as_string
method before being returned.  See that method for more information.


=item get_preset_names()

Returns a list of the available preset currency groups.  This method may
be called as either an object or a class method.


=item get_preset($name)

Returns a reference to a list of Denomination objects, suitable for passing
to the 'denominations' method.  This mehod may be called as either an
object or a class method.


=item as_string(@denoms)

Accepts a list of Denomination objects, as returned by C<make_change()>,
and returns a human-readable description of the change as a string.
This mehod may be called as either an object or a class method.


=back

=head1 Future Work

=over 4

=item *

Support for limited amounts of certain types of currency, i.e.
"I have only 2 dimes left"

=item *

Support for "weighting" the preference of using a certain type of monetary
units, i.e. "I am really low on dimes, use nickels instead".

=item *

Add a "shell" interface, a la CPAN.pm.

=item *

Add more Denomination presets.  Please consider submitting a preset
currency set -- see the perldoc for L<Money::ChangeMaker::Presets> for
information on submitting them to me.

=back

=head1 AUTHOR

Copyright 2007 Avi Finkel <F<avi@finkel.org>>

This package is free software and is provided "as is" without express
or implied warranty.  It may be used, redistributed and/or modified
under the terms of the Perl Artistic License (see
http://www.perl.com/perl/misc/Artistic.html)

=cut

# Copyright (c) 2002-2005 Cunningham & Cunningham, Inc.
# Released under the terms of the GNU General Public License version 2 or later.

package Test::C2FIT::test::TypeAdapterTest;

use base 'Test::Unit::TestCase';
use strict;

use Test::C2FIT::TypeAdapter;

#===============================================================================================
# Public Methods
#===============================================================================================

sub test_isnumber
{
	my $self = shift;
	
	$self->assert_is_number('0');
	$self->assert_is_number('0e0');
	$self->assert_is_number('1');
	$self->assert_is_number('1.1');
	$self->assert_is_number('-1');
	$self->assert_is_number('1.1');
	$self->assert_is_number('12.34e-56');
	$self->assert_is_number('1/2');
	
	# Test of Fix provided by Christophe Hermier.
	$self->assert_not_a_number('-');
	$self->assert_not_a_number('001-002-345');
}

#===============================================================================================
# Protected Methods - Don't even think about calling these from outside the class.
#===============================================================================================

sub assert_is_number
{
	my ($self, $test) = @_;
	$self->assert( Test::C2FIT::TypeAdapter->_isnumber($test), "'$test' should be a number!");
	
}

sub assert_not_a_number
{
	my ($self, $test) = @_;
	$self->assert(! Test::C2FIT::TypeAdapter->_isnumber($test), "'$test' should not be a number!");
	
}

# Keep Perl happy.
1;

__END__

package fit;

import junit.framework.*;

public class FixtureTest extends TestCase {

	public FixtureTest(String name) {
		super(name);
	}
	
	public void testEscape() {
		assertEquals(" &nbsp; &nbsp; ", Fixture.escape("     "));
	}
}

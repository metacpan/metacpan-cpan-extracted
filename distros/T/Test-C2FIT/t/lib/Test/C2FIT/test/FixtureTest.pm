# Copyright (c) 2002-2005 Cunningham & Cunningham, Inc.
# Released under the terms of the GNU General Public License version 2 or later.

package Test::C2FIT::test::FixtureTest;

use base 'Test::Unit::TestCase';
use strict;

use Test::C2FIT::Fixture;

#===============================================================================================
# Public Methods
#===============================================================================================

sub test_escape
{
	my $self = shift;
	$self->assert_str_equals(" &nbsp; &nbsp; ", Test::C2FIT::Fixture->escape("     "));
	
	my $junk = "!@#$%^*()_-+={}|[]\\:\";',./?`";
	$self->assert_str_equals($junk, Test::C2FIT::Fixture->escape($junk));
	$self->assert_str_equals("", Test::C2FIT::Fixture->escape(""));
	$self->assert_str_equals("&lt;", Test::C2FIT::Fixture->escape("<"));
	$self->assert_str_equals("&lt;&lt;", Test::C2FIT::Fixture->escape("<<"));
	$self->assert_str_equals("x&lt;", Test::C2FIT::Fixture->escape("x<"));
	$self->assert_str_equals("&amp;", Test::C2FIT::Fixture->escape("&"));
	$self->assert_str_equals("&lt;&amp;&lt;", Test::C2FIT::Fixture->escape("<&<"));
	$self->assert_str_equals("&amp;&lt;&amp;", Test::C2FIT::Fixture->escape("&<&"));
	$self->assert_str_equals("a &lt; b &amp;&amp; c &lt; d", Test::C2FIT::Fixture->escape("a < b && c < d"));
	$self->assert_str_equals("a<br />b", Test::C2FIT::Fixture->escape("a\nb"));
}

#===============================================================================================
# Protected Methods - Don't even think about calling these from outside the class.
#===============================================================================================

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

package MyTest::Class;

use strict;
use warnings 'all';

use base qw[Test::Class];

sub class {
	# Return class name
	return $_[0]->{class};
}

sub alpha_startup : Tests(startup) {
	my $class = ref $_[0];

	return if $class eq __PACKAGE__;

	# Remove namespace prefix
	$class =~ s{\A MyTest::}{}msx;

	# Load the class (and die on failure)
	die "$class load error: $@" unless eval qq{use $class (); 1};

	# Set the class name
	$_[0]->{class} = $class;
}

1;

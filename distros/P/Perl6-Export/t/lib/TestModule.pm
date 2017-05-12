package TestModule;

use Perl6::Export;

sub foo is export(:MANDATORY) {
	return 1;
}

sub bar is export {
	return 1;
}

sub qux is export(:Q) {
	return 1;
}

sub import {
	Test::More::ok(1, "Invoked Module::import");
	Test::More::ok("@_" eq "TestModule other",
					  "Module::import received correct args");
}

1;

package Local::Example;
use MooX::Pression;

class Foo {
	has foo;
}

include MoreClasses;

class Bar {
	with MyRole;
	has bar;
}

include ::Local::Example::Roles;

1;

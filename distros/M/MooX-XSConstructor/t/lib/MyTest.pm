package MyTest;

use Moo;
use MooX::XSConstructor;

extends 'TestBase';

has 'x' => (
	is => 'ro',
	weak_ref => 1,
);

sub FOREIGNBUILDARGS {
	my ( $class, %args ) = @_;
	our %GOT = %args;
	return %args;
}

1;

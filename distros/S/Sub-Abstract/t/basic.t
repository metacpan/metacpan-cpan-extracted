use strict;
use warnings;
use Test::Most;
use Sub::Abstract;

# Core enforcement: calling an abstract method that has no implementation
# in the call chain must croak with the correct message.

local $ENV{HARNESS_ACTIVE}   = 0;
local $Sub::Abstract::BYPASS = 0;

{
	package Animal;
	use Sub::Abstract;
	sub new   { bless {}, shift }
	sub speak :Abstract { }
}

{
	package Dog;
	our @ISA = ('Animal');
	sub new   { bless {}, shift }
	sub speak { 'Woof' }
}

{
	package Cat;
	our @ISA = ('Animal');
	sub new { bless {}, shift }
	# Cat does NOT implement speak
}

# Dog implements speak -- wrapper in Animal is never reached
my $dog = Dog->new;
lives_and { is $dog->speak, 'Woof' }
	'subclass that implements the method: wrapper never fires';

# Cat does not implement speak -- wrapper in Animal fires
my $cat = Cat->new;
throws_ok { $cat->speak }
	qr/\Qspeak() is an abstract method of Animal and must be implemented by Cat\E/,
	'subclass that omits the method: croaks with correct message';

# Calling directly on the base class (class method, invocant is 'Animal')
throws_ok { Animal->speak }
	qr/\Qspeak() is an abstract method of Animal and must be implemented by Animal\E/,
	'calling abstract method directly on base class: invocant is the class name';

# Error message format: ref invocant (object) -> class name of object
throws_ok { Animal->new->speak }
	qr/\Qspeak() is an abstract method of Animal and must be implemented by Animal\E/,
	'object invocant: message names the blessed class';

done_testing;

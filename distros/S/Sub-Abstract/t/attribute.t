use strict;
use warnings;
use Test::Most;
use Sub::Abstract;

# Test the :Abstract attribute form.

local $ENV{HARNESS_ACTIVE}   = 0;
local $Sub::Abstract::BYPASS = 0;

# Single abstract method
{
	package Shape;
	use Sub::Abstract;
	sub new  { bless {}, shift }
	sub area :Abstract { }
}

{
	package Circle;
	our @ISA = ('Shape');
	sub new  { bless {}, shift }
	sub area { 3.14 }
}

{
	package Square;
	our @ISA = ('Shape');
	sub new { bless {}, shift }
	# Square does NOT implement area
}

lives_and { is(Circle->new->area, 3.14) }
	'attribute form: subclass implementing method: wrapper never fires';

throws_ok { Square->new->area }
	qr/\Qarea() is an abstract method of Shape and must be implemented by Square\E/,
	'attribute form: subclass omitting method: croaks with correct message';

# Multiple abstract methods in same package
{
	package Vehicle;
	use Sub::Abstract;
	sub new    { bless {}, shift }
	sub start  :Abstract { }
	sub stop   :Abstract { }
}

{
	package Car;
	our @ISA = ('Vehicle');
	sub new   { bless {}, shift }
	sub start { 'vroom' }
	sub stop  { 'squeal' }
}

{
	package Bike;
	our @ISA = ('Vehicle');
	sub new   { bless {}, shift }
	sub start { 'pedal' }
	# Bike does NOT implement stop
}

lives_ok { Car->new->start } 'attribute form: multiple abstract, first implemented: ok';
lives_ok { Car->new->stop  } 'attribute form: multiple abstract, second implemented: ok';

throws_ok { Bike->new->stop }
	qr/\Qstop() is an abstract method of Vehicle and must be implemented by Bike\E/,
	'attribute form: second method not implemented: correct error';

done_testing;

package GH3;

use strict;
use warnings;
use Moo;
use MooX::XSConstructor -wrapconstructor;

{
	package GH3::Child1;

	use Moo;
	extends 'GH3';
}

{
	package GH3::Child2;

	use Moo;
	use MooX::XSConstructor;
	extends 'GH3';
}

1;

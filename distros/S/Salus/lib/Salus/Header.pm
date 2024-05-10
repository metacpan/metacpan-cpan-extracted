package Salus::Header;

use Rope;
use Rope::Autoload;
use Types::Standard qw/Str Int/; 

property index => (
	initable => 1,
	writeable => 0,
	configurable => 1,
	required => 1,
	enumerable => 1,
	type => Int
);

property name => (
	initable => 1,
	writeable => 0,
	configurable => 1,
	required => 1,
	enumerable => 1,
	type => Str
);

property label => (
	initable => 1,
	writeable => 0,
	configurable => 1,
	required => 1,
	enumerable => 1,
	type => Str
);


1;

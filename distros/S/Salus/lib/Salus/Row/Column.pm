package Salus::Row::Column;

use Rope;
use Rope::Autoload;
use Types::Standard qw/Str Object/; 

property header => (
	initable => 1,
	writeable => 0,
	configurable => 1,
	enumerable => 1,
	type => Object
);

property value => (
	initable => 1,
	writeable => 0,
	configurable => 1,
	enumerable => 1,	
	type => Str
);

1;

package Packme::Test2;

use Moo;
use MooX::Pack;

seperator (
	character => 'x',
	pack => '|',
	index => [ 1, 3 ],
);

line one => (
    key => 'data',
    character => 'A10',
    catch => 1,
);

line one => (
    name => 'description',
    character => 'A27',
    catch => 1,
);

line one => (
    name => 'income',
    character => 'A7',
    catch => 1,
);

line two => (
    name => 'data',
    character => 'A10',
    catch => 1,
    index => 4,
);

line two => (
    key => 'description',
    character => 'A27',
    catch => 1,
    index => 0,
);

line two => (
    name => 'notes',
    character => 'A7',
    catch => 1,
    index => 2,
);

1;


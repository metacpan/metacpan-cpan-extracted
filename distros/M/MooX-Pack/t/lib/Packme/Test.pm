package Packme::Test;

use Moo;
use MooX::Pack;

all seperator => (
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
    name => 'first name',
    character => 'A20',
    catch => 1,
    index => 4,
);

line two => (
    key => 'last name',
    character => 'A20',
    catch => 1,
    index => 0,
);

line two => (
    name => 'age',
    character => 'A3',
    catch => 1,
    index => 2,
);

1;


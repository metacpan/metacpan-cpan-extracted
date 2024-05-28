package Packme::Test;

use Moo;
use MooX::Pack;

seperator (
	character => 'x',
	pack => '|',
);

line title => (
    key => 'data',
    character => 'A10',
    catch => 1,
);

line title => (
    name => 'description',
    character => 'A27',
    catch => 1,
);

line title => (
    name => 'income',
    character => 'A7',
    catch => 1,
);

line rest => (
    name => 'first name',
    character => 'A20',
    catch => 1,
    index => 4,
);

line rest => (
    key => 'last name',
    character => 'A20',
    catch => 1,
    index => 0,
);

line rest => (
    name => 'age',
    character => 'A3',
    catch => 1,
    index => 2,
);

1;


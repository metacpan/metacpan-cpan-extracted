use Test2::V0;

plan 29;

use String::Copyright {
	format => sub { join ':', $_->[0] || '', $_->[1] || '' }
};

is copyright("© 1999,2000 \n , 2001 ,2002, 2003 Foo"),
	'1999-2003:Foo',
	'comma list';
is copyright("© 1999,2000 \n  2001 ,2002, 2003 Foo"),
	'1999-2003:Foo',
	'non-comma list';
is copyright("© 1999-2000  , 2001 - 2002\n, 2003 Foo"),
	'1999-2003:Foo',
	'single-year ranges';
is copyright("© 1999-2000  , 2001\n - 2002\n, 2003 Foo"),
	'1999-2001:- 2002',
	'range w/ newline before hyphen and before comma';
is copyright("© 1999,2000,2003,2005,2006 Foo"),
	'1999-2000, 2003, 2005-2006:Foo',
	'range non-range range';

is copyright("© 1999-2000  , 2001 -\n 2002\n, 2003 Foo"),
	'1999-2003:Foo',
	'range w/ newline after hyphen';
is copyright("© 1999-2002, 2003 Foo"), '1999-2003:Foo', 'multi-year ranges';

is copyright("© 1999\n, 2003 Foo"),
	'1999, 2003:Foo',
	'newline before year-delimiting comma';

is copyright("© 1999-2000 -2004-2005 Foo"),
	'1999-2000:-2004-2005 Foo',
	'broken range - bogus multi-range';

is copyright("(c) <year> Foo"),
	'', 'bogus dummy year "<year>"';
is copyright("Copyright (C) 19xx name of author"),
	'', 'bogus dummy year "19xx"';
is copyright("(c) 19yy Foo"),
	'', 'bogus dummy year "19yy"';
is copyright("(c) yyyy Foo"),
	'', 'bogus dummy year "yyyy"';

my $todo = todo 'not yet handled';
is copyright("© 1999-2000-2004-2005 Foo"),
	':1999-2000-2004-2005 Foo',
	'broken range - bogus multi-nonspace-range';
is copyright("© 1999-2000-2005-2004 Foo"),
	'1999-2000-2005-2004:Foo',
	'broken range - bogus multi-range wrong order';
is copyright("© 1999,2000 \n - 2000 ,2002, 2003 \nFoo"),
	'1999-2000, 2002-2003:Foo',
	'broken range - same year';
is copyright("© 1999,2000 \n - 1999 ,2002, 2003 \nFoo"),
	'1999, 2000:- 1999, 2002-2003 Foo',
	'broken range - earlier year';

$todo = undef;

is copyright("© 1999,2000  , 2001 ,200\n2, 2003 Foo"),
	'1999-2001:200',
	'broken range - newline in year';

is copyright("© 1999"), '1999:', 'owner-less year';

is copyright("© . 1999"), '', 'bogus owner-less year starting with dot';

is copyright("© , 1999, 2000"), '1999-2000:', 'initial comma';

is copyright("© -1999, 2000"),
	':-1999, 2000',
	'not-treated-as-year starting with dash';

is copyright("© 2001, 2001"), '2001:', 'duplicate year';

is copyright("© 2001-2001"), '2001:', 'single-year range';

is copyright("© 2002-2000"), '2000-2002:', 'backwards range';

$todo = todo 'not yet handled';

is copyright("© 2000-03"), '2000-2003:', 'sloppy range-end, 2 digits';

is copyright("© 2005-7"), '2005-2007:', 'sloppy range-end, 1 digit';

is copyright("Copyright (c) Foo, 2000"), '2000:Foo', 'year at end';

is copyright("Copyright (c) Foo, 2000,\n 2001"),
	'2000-2001:Foo',
	'year at end and next line';

done_testing;

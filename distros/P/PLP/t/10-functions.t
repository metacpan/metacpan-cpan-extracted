use strict;

use Test::More tests => 6;

BEGIN { use_ok('PLP::Functions') }

# legacy

is(
	Entity(q{<a test="'&'"/>}),
	"&lt;a test=&quot;'&amp;'&quot;/&gt;",
	'Entity escaping'
);

is(
	Entity(" . .  .   .\t. \n"),
	" . .&nbsp;&nbsp;.&nbsp;&nbsp; .&nbsp; &nbsp; &nbsp; &nbsp;&nbsp;. <br>\n",
	'Entity formatting'
);

is(
	EncodeURI("/test.plp?f00=~_a&b!\n "),
	'/test.plp?f00%3d~_a%26b!%0a%20',
	'EncodeURI'
);

is(
	DecodeURI('?f0%30+%20b%61r!'),
	'?f00  bar!',
	'DecodeURI'
);

is(
	DecodeURI('%0A%0a%a %000 %fg%%fF'."\377"),
	"\n\n%a \0000 %fg%\377\377",
	'DecodeURI 2'
);


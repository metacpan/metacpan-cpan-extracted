use strict;

use Test::More tests => 6;

BEGIN { use_ok('PLP::Functions', 1.01) }

# EscapeHTML

is(
	EscapeHTML(qq{\t<a  test="'&'"/>\n}),
	"\t&lt;a  test=&quot;'&amp;'&quot;/&gt;\n",
	'EscapeHTML'
);

is(
	EscapeHTML(undef),
	undef,
	'EscapeHTML undef'
);

is(
	eval { EscapeHTML('output', '') },
	undef,
	'EscapeHTML parameters'
);

is(
	eval { my $val = qq{  ><"\n}; EscapeHTML($val); $val },
	"  &gt;&lt;&quot;\n",
	'EscapeHTML replace'
);

is(
	eval { EscapeHTML('output'); return 'no error' },
	undef,
	'EscapeHTML read-only modification'
);


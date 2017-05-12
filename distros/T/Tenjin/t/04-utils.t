#!perl -T

use strict;
use warnings;
use Test::More;
use Tenjin;

my $t = Tenjin->new({ path => ['t/data/utils'] });
ok($t, 'Got a proper Tenjin instance');

# the encode_url method
is(
	$t->render('encode_url.html', { url => "http://www.google.com/search?q=tenjin&ie=utf-8&oe=utf-8&aq=t" }),
	"http%3A//www.google.com/search%3Fq%3Dtenjin%26ie%3Dutf-8%26oe%3Dutf-8%26aq%3Dt",
	'encode_url() works'
);

# the escape_xml() and unescape_xml() methods
is(
	$t->render('escape_xml.html', {
		escape => "<a href=\"http://localhost:3000/?key=value&value=key\">test\"test</a>",
		unescape => "<a href=\"http://localhost:3000/?key=value&amp;value=key\">test&quot;test</a>"
	}),
	"&lt;a href=&quot;http://localhost:3000/?key=value&amp;value=key&quot;&gt;test&quot;test&lt;/a&gt;\n<a href=\"http://localhost:3000/?key=value&value=key\">test\"test</a>",
	'(un)escape_xml() works'
);

# the p() and P() methods
is(
	$t->render('pP.html', { p => "whaddup?", P => "encode & me" }),
	"<`#whaddup?#`>\n<`\$encode & me\$`>",
	'p() and P() work'
);

done_testing();

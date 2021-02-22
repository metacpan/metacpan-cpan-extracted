use strict;
use warnings;

use PYX::SGML::Tags;
use Tags::Output::Raw;
use Test::More 'tests' => 5;
use Test::NoWarnings;
use Unicode::UTF8 qw(decode_utf8);

# Test.
my $tags = Tags::Output::Raw->new(
	'xml' => 0,
);
my $obj = PYX::SGML::Tags->new(
	'tags' => $tags,
);
my $pyx_data = <<'END';
(element
)element
END
$obj->parse($pyx_data);
is($tags->flush, "<element></element>", 'Simple element (sgml version).');
$tags->reset;

# Test.
$pyx_data = <<'END';
(element
Apar val
)element
END
$obj->parse($pyx_data);
is($tags->flush, "<element par=\"val\"></element>",
	'Simple element with attribute (sgml version).');
$tags->reset;

# Test.
$pyx_data = <<'END';
(element
Apar val\nval
)element
END
$obj->parse($pyx_data);
is($tags->flush, "<element par=\"val\\nval\"></element>",
	'Simple element with attribute with \n in value (sgml version).');
$tags->reset;

# Test.
$pyx_data = <<'END';
(čupřina
Acíl ředkev
)čupřina
END
$obj->parse(decode_utf8($pyx_data));
is($tags->flush, decode_utf8('<čupřina cíl="ředkev"></čupřina>'),
	'Parse element with attribute in utf-8 (sgml version).');
$tags->reset;

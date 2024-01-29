#! perl

use Test::More tests => 7;
use SVGPDF::Parser;

my $p = SVGPDF::Parser->new;

$SIG{__WARN__} = sub { die("Caught a warning, making it fatal:\n\n$_[0]\n"); };

is_deeply(
    $p->_parse(q{<x>&amp;&lt;&gt;&quot;&apos;</x>}),
    [{name => 'x', attrib => {}, type => 'e', content => [{type => 't', content => '&<>"\''}]}],
    "All five entities are normally parsed OK"
);
is_deeply(
    $p->_parse(q{<x>&#65;</x>}),
    [{name => 'x', attrib => {}, type => 'e', content => [{type => 't', content => 'A'}]}],
    "base ten numeric char entities are normally parsed OK"
);
is_deeply(
    $p->_parse(q{<x>&#x41;</x>}),
    [{name => 'x', attrib => {}, type => 'e', content => [{type => 't', content => 'A'}]}],
    "base 16 numeric char entities are normally parsed OK"
);
is_deeply(
    $p->_parse(q{<x>&#xAa;</x>}),
    $p->_parse(q{<x>&#170;</x>}),
    "non-ASCII works, and hex entities aren't case-sensitive"
);

is_deeply(
    $p->_parse(q{<x>&&rubbish;&amp;&lt;&gt;&quot;&apos;</x>}, no_entity_parsing => 1),
    [{name => 'x', attrib => {}, type => 'e', content => [{type => 't', content => '&&rubbish;&amp;&lt;&gt;&quot;&apos;'}]}],
    "no_entity_parsing works"
);

my $e;
eval { $e = $p->_parse(q{<x>&</x>}) };
( my $s = $@ ) =~ s/SVG Parser: (.*) at .*/$1/s;
is( $s, 'Illegal ampersand or entity "&"',
    "naked ampersands not allowed" );
eval { $p->_parse(q{<x>&rubbish;</x>}) };
( $s = $@ ) =~ s/SVG Parser: (.*) at .*/$1/s;
is( $s, 'Illegal ampersand or entity "&rubbish"',
    "unknown entities not allowed" )

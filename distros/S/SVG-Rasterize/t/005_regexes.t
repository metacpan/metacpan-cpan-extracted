#!perl -T
use strict;
use warnings;

use Test::More tests => 802;

use Test::Exception;
use SVG::Rasterize;
use SVG::Rasterize::Regexes qw(:all);

sub white_space {
    my $s;

    # WSP
    foreach $s (' ', "\n", "\r", "\t") {
	ok($s =~ $WSP, "WSP");
    }
    foreach $s ('.', "a", ',',) {
	ok($s !~ $WSP, "!WSP");
    }
    foreach $s (' ', '  ', "\t \r", "\t\r\n", "\n\r") {
	ok($s =~ qr/$WSP+/, "WSP+");
    }
    foreach $s (', ', " \t .") {
	ok($s !~ qr/^$WSP+$/, '! ^WSP+$');
    }

    # CWSP
    foreach $s (' ', "\n", "\r", "\t", ',', ' ,', ' ,', "\t,\n") {
	ok($s =~ qr/^$CWSP$/, "p_CWSP");
    }
    foreach $s (';', ' , &', "a\n") {
	ok($s !~ qr/^$CWSP$/, "!p_CWSP");
    }
}

sub package_name {
    my $s;

    foreach $s (qw(A::B
                   a::b
                   A
                   Foo_Bar::Qux
                   f00
                   X2000::A_03))
    {
	ok($s =~ $RE_PACKAGE{p_PACKAGE_NAME}, "$s =~ p_PACKAGE_NAME");
    }
    foreach $s (qw(!A::B
                   a::b$
                   0A::B
                   _A
                   ?
                   A/B::C))
    {
	ok($s !~ $RE_PACKAGE{p_PACKAGE_NAME}, "$s =~ p_PACKAGE_NAME");
    }
}

sub xml_uri {
    my $s;
    my $r;

    # XML
    $r = 'NAME_START_CHAR';
    foreach $s ('r', 'R', ':', '_') {
	ok($s =~ $RE_XML{$r}, "'$s' =~ $r");
    }
    foreach $s ('1', '/', '?', '.', '-') {
	ok($s !~ $RE_XML{$r}, "'$s' !~ $r");
    }
    $r = 'NAME_CHAR';
    foreach $s ('r', 'R', ':', '_', '.', '-') {
	ok($s =~ $RE_XML{$r}, "'$s' =~ $r");
    }
    foreach $s ('/', '?') {
	ok($s !~ $RE_XML{$r}, "'$s' !~ $r");
    }
    $r = 'p_NAME';
    foreach $s ('foo', ':HAY012', 'foo.bar') {
	ok($s =~ $RE_XML{$r}, "'$s' =~ $r");
    }
    foreach $s ('#foo', 'f#o', 'f?0', '0zero') {
	ok($s !~ $RE_XML{$r}, "'$s' !~ $r");
    }

    # URI
    $r = 'p_URI';
    foreach $s ('http://123.456.789.001/foo/bar?utz#otz',
	        'http://www.xxx.yz',
                'ftp://foo.bar.baz?qux',
	        'foo://bar/baz#qux',
	        '../corge/',
	        '#quux',
	        'foo://bar/baz#xpointer(id(qux))',
	        'xpointer(id(:bro_qux-bar.baz))')
    {
	ok($s =~ $RE_URI{$r}, "'$s' =~ $r");
    }
    foreach $s ('#q?x',
                'http://www.xxx.yz#xpointer(ID)',
                '#xpointer(f123)',
	        '#xpointer(id(HO)',
	        '#xpointer(id(A&B))')
    {
	ok($s !~ $RE_URI{$r}, "'$s' !~ $r");
    }
}

sub re_number {
    my $s;
    my $r;

    $r = 'p_NNINTEGER';
    foreach $s (qw(0
                   000
                   001
                   +0
                   +000
                   +001
                   +1
                   1
                   10
                   12345
                   0123
                   +912))
    {
	ok($s =~ $RE_NUMBER{$r}, "'$s' =~ $r");
    }
    foreach $s (qw(-0
                   -1
                   .1
                   0.1223
                   1E7
                   -8.1))
    {
	ok($s !~ $RE_NUMBER{$r}, "'$s' !~ $r");
    }
    $r = 'p_INTEGER';
    foreach $s (qw(0
                   000
                   001
                   +0
                   +000
                   +001
                   +1
                   1
                   10
                   12345
                   0123
                   +912
                   -0
                   -1))
    {
	ok($s =~ $RE_NUMBER{$r}, "'$s' =~ $r");
    }
    foreach $s (qw(.1
                   0.1223
                   1E7
                   -8.1))
    {
	ok($s !~ $RE_NUMBER{$r}, "'$s' !~ $r");
    }
    $r = 'w_INTEGER';
    foreach $s (' 123', "+15\n", "\t000\r") {
	ok($s =~ $RE_NUMBER{$r}, "... =~ $r");
    }
    foreach $s ('x 123', "+15\nt", "\t0|0") {
	ok($s !~ $RE_NUMBER{$r}, "... !~ $r");
    }

    $r = 'NNFRACTION';
    foreach $s (qw(0.1
                   .1
                   0.
                   123.
                   000.
                   0.000
                   +0.
                   +.0
                   +.1
                   +12.456
                   +.0012300))
    {
	ok($s =~ qr/^$RE_NUMBER{$r}$/, "'$s' =~ emulated $r");
    }
    foreach $s (qw(-1
                   -1.
                   -0.1
                   -.1
                   1E7
                   a+.1
                   0.001foo
                   0e123))
    {
	ok($s !~ qr/^$RE_NUMBER{$r}$/, "'$s' !~ emulated $r");
    }

    $r = 'p_FRACTION';
    foreach $s (qw(0.1
                   .1
                   0.
                   123.
                   000.
                   0.000
                   +0.
                   +.0
                   +.1
                   -1.
                   -0.1
                   -.1
                   +12.456
                   +.0012300))
    {
	ok($s =~ $RE_NUMBER{$r}, "'$s' =~ $r");
    }
    foreach $s (qw(-1
                   1E7
                   a+.1
                   0.001foo
                   0e123))
    {
	ok($s !~ $RE_NUMBER{$r}, "'$s' !~ $r");
    }
    $r = 'w_FRACTION';
    foreach $s (' 123.', "+1.5\n", "\t.0\r") {
	ok($s =~ $RE_NUMBER{$r}, "... =~ $r");
    }
    foreach $s ('x 123', "+15\nt", "\t0|0", ' 89 ') {
	ok($s !~ $RE_NUMBER{$r}, "... !~ $r");
    }

    $r = 'EXPONENT';
    foreach $s (qw(e0
                   E00
                   e+00
                   E-000
                   E123
                   E+78
                   E-1))
    {
	ok($s =~ qr/^$RE_NUMBER{$r}$/, "'$s' =~ emulated $r");
    }
    foreach $s (qw(-1
                   +3
                   +0
                   E.3
                   e12+
                   -E32
                   aE34
                   e-12U))
    {
	ok($s !~ qr/^$RE_NUMBER{$r}$/, "'$s' !~ emulated $r");
    }

    $r = 'NNFLOAT';
    foreach $s (qw(+.1
                   1.
                   +23.
                   +0.123
                   0000.000
                   00.E12
                   1.345E-02))
    {
	ok($s =~ qr/^$RE_NUMBER{$r}$/, "'$s' =~ emulated $r");
    }
    foreach $s (qw(1
                   +1
                   123
                   -1
                   -.1
                   -1.
                   123a09
                   a12
                   34.56z))
    {
	ok($s !~ qr/^$RE_NUMBER{$r}$/, "'$s' !~ emulated $r");
    }

    $r = 'p_FLOAT';
    foreach $s (qw(0.1
                   .1
                   0.e123
                   123.
                   000.
                   0.000E43
                   +0.
                   +.0
                   +.1
                   1E7
                   -1.
                   -0.1E34
                   -.1
                   +12.456
                   +.0012300
                   0e123))
    {
	ok($s =~ $RE_NUMBER{$r}, "'$s' =~ $r");
    }
    foreach $s (qw(-1
                   a+.1
                   0.001foo))
    {
	ok($s !~ $RE_NUMBER{$r}, "'$s' !~ $r");
    }
    $r = 'w_FLOAT';
    foreach $s (' 123.e7', "+1.5E3\n", "\t.0E-9\r") {
	ok($s =~ $RE_NUMBER{$r}, "... =~ $r");
    }
    foreach $s ('x 123e-2', "+15E3\nt", "\t0|0", ' 89 ') {
	ok($s !~ $RE_NUMBER{$r}, "... !~ $r");
    }

    $r = 'p_P_NNNUMBER';
    foreach $s (qw(0.1
                   .1
                   123.
                   000.
                   +0.
                   +.0
                   +.1
                   +12.456
                   +.0012300))
    {
	ok($s =~ $RE_NUMBER{$r}, "'$s' =~ $r");
    }
    foreach $s (qw(-1
                   0.e123
                   1E7
                   0.000E43
                   -1.
                   0e123
                   -0.1E34
                   -.1
                   a+.1
                   0.001foo))
    {
	ok($s !~ $RE_NUMBER{$r}, "'$s' !~ $r");
    }
    $r = 'w_P_NNNUMBER';
    foreach $s (' 123.', "+1.5\n", "\t.0\r") {
	ok($s =~ $RE_NUMBER{$r}, "... =~ $r");
    }
    foreach $s ('x 123', "+15\nt", "\t0|0", ' -89 ') {
	ok($s !~ $RE_NUMBER{$r}, "... !~ $r");
    }

    $r = 'p_P_NUMBER';
    foreach $s (qw(0.1
                   .1
                   123.
                   000.
                   +0.
                   +.0
                   +.1
                   +12.456
                   -1
                   -1.
                   -.1
                   +.0012300))
    {
	ok($s =~ $RE_NUMBER{$r}, "'$s' =~ $r");
    }
    foreach $s (qw(0.e123
                   1E7
                   0.000E43
                   0e123
                   -0.1E34
                   a+.1
                   0.001foo))
    {
	ok($s !~ $RE_NUMBER{$r}, "'$s' !~ $r");
    }
    $r = 'w_P_NUMBER';
    foreach $s (' 123.', "+1.5\n", "\t.0\r") {
	ok($s =~ $RE_NUMBER{$r}, "... =~ $r");
    }
    foreach $s ('x 123', "+15\nt", "\t0|0", ' -89.2.3 ') {
	ok($s !~ $RE_NUMBER{$r}, "... !~ $r");
    }

    $r = 'p_A_NNNUMBER';
    foreach $s (qw(0.1
                   .1
                   123.
                   000.
                   +0.
                   +.0
                   +.1
                   +12.456
                   0.e123
                   1E7
                   0e123
                   0.000E43
                   +.0012300))
    {
	ok($s =~ $RE_NUMBER{$r}, "'$s' =~ $r");
    }
    foreach $s (qw(-1
                   -1.
                   -0.1E34
                   -.1
                   a+.1
                   0.001foo))
    {
	ok($s !~ $RE_NUMBER{$r}, "'$s' !~ $r");
    }
    $r = 'w_A_NNNUMBER';
    foreach $s (' 123.', "+1.5\n", "\t.0\r") {
	ok($s =~ $RE_NUMBER{$r}, "... =~ $r");
    }
    foreach $s ('x 123', "+15\nt", "\t0|0", ' -89 ') {
	ok($s !~ $RE_NUMBER{$r}, "... !~ $r");
    }

    $r = 'p_A_NUMBER';
    foreach $s (qw(0.1
                   .1
                   123.
                   000.
                   +0.
                   +.0
                   +.1
                   +12.456
                   -1
                   -1.
                   -.1
                   0.e123
                   1E7
                   0.000E43
                   0e123
                   -0.1E34
                   +.0012300))
    {
	ok($s =~ $RE_NUMBER{$r}, "'$s' =~ $r");
    }
    foreach $s (qw(a+.1
                   0.001foo))
    {
	ok($s !~ $RE_NUMBER{$r}, "'$s' !~ $r");
    }
    $r = 'w_A_NUMBER';
    foreach $s (' 123.', "+1.5\n", "\t.0\r") {
	ok($s =~ $RE_NUMBER{$r}, "... =~ $r");
    }
    foreach $s ('x 123', "+15\nt", "\t0|0", ' -89.2.3 ') {
	ok($s !~ $RE_NUMBER{$r}, "... !~ $r");
    }
}

sub re_length {
    my $s;
    my $r;

    $r = 'UNIT';
    foreach $s (qw(em ex px pt pc cm mm in %))
    {
	ok($s =~ qr/^$RE_LENGTH{$r}$/, "'$s' =~ emulated $r");
    }
    foreach $s (qw(ab q em1 nm qpc))
    {
	ok($s !~ qr/^$RE_LENGTH{$r}$/, "'$s' !~ emulated $r");
    }

    $r = 'ABS_UNIT';
    foreach $s (qw(px pt pc cm mm in))
    {
	ok($s =~ qr/^$RE_LENGTH{$r}$/, "'$s' =~ emulated $r");
    }
    foreach $s (qw(ab q em1 nm qpc em ex %))
    {
	ok($s !~ qr/^$RE_LENGTH{$r}$/, "'$s' !~ emulated $r");
    }

    $r = 'p_P_LENGTH';
    foreach $s (qw(0.1em
                   .1%
                   123.
                   000.
                   +0.cm
                   +.0
                   +.1mm
                   +12.456
                   -1
                   -1.
                   -.1in
                   +.0012300))
    {
	ok($s =~ $RE_LENGTH{$r}, "'$s' =~ $r");
    }
    foreach $s (qw(0.e123
                  1E7%
                  0.000E43
                  0e123
                  -0.1E34pc
                  a+.1
                  0.001foo), '12 in')
    {
	ok($s !~ $RE_LENGTH{$r}, "'$s' !~ $r");
    }
    $r = 'w_P_LENGTH';
    foreach $s (' 123.%', "+1.5cm\n", "\t.0\r") {
	ok($s =~ $RE_LENGTH{$r}, "... =~ $r");
    }
    foreach $s ('x 123', "+15\nt", "\t0|0", ' -89.2.3% ') {
	ok($s !~ $RE_LENGTH{$r}, "... !~ $r");
    }

    $r = 'p_ABS_P_LENGTH';
    foreach $s (qw(0.1in 3cm 5.3mm))
    {
	ok($s =~ $RE_LENGTH{$r}, "'$s' =~ $r");
    }
    foreach $s (qw(5% 12.3em 3ex))
    {
	ok($s !~ $RE_LENGTH{$r}, "'$s' !~ $r");
    }
    $r = 'w_ABS_P_LENGTH';
    foreach $s (' 123.pc', "+1.5cm\n", "\t.0\r") {
	ok($s =~ $RE_LENGTH{$r}, "... =~ $r");
    }
    foreach $s ('x 123', "+15\nt", "\t0|0", ' -89.2.3cm ') {
	ok($s !~ $RE_LENGTH{$r}, "... !~ $r");
    }

    $r = 'p_A_LENGTH';
    foreach $s (qw(0.1E3em
                   .1%
                   123.
                   000.
                   +0.e-7cm
                   +.0
                   +.1mm
                   +12.456
                   -1
                   -1.e5
                   -.1in
                   +.0012300))
    {
	ok($s =~ $RE_LENGTH{$r}, "'$s' =~ $r");
    }
    foreach $s (qw(a+.1 0.001foo), '12 in')
    {
	ok($s !~ $RE_LENGTH{$r}, "'$s' !~ $r");
    }
    $r = 'w_A_LENGTH';
    foreach $s (' 123.e4%', "+1.5E-13cm\n", "\t.0\r") {
	ok($s =~ $RE_LENGTH{$r}, "... =~ $r");
    }
    foreach $s ('x 123', "+15\nt", "\t0|0", ' -89.2.3% ') {
	ok($s !~ $RE_LENGTH{$r}, "... !~ $r");
    }

    $r = 'p_ABS_A_LENGTH';
    foreach $s (qw(0.1in 3e7cm 5.3E3mm))
    {
	ok($s =~ $RE_LENGTH{$r}, "'$s' =~ $r");
    }
    foreach $s (qw(5% 12.3e-1em 3e0ex))
    {
	ok($s !~ $RE_LENGTH{$r}, "'$s' !~ $r");
    }
    $r = 'w_ABS_A_LENGTH';
    foreach $s (' 123.pc', "+1.5cm\n", "\t.0\r") {
	ok($s =~ $RE_LENGTH{$r}, "... =~ $r");
    }
    foreach $s ('x 123', "+15\nt", "\t0|0", ' -89.2.3cm ') {
	ok($s !~ $RE_LENGTH{$r}, "... !~ $r");
    }

    $r = 'p_A_LENGTHS';
    foreach $s ('5in',
		'1',
		'12',
		'1 2',
		'1,2',
		'1 ,2',
		'1, 2',
		'1 , 2',
		'3 12ex',
		'1pc 1in',
		'1.3E7ex,3',
		'4.5%, 4pc',
		'3 , 9em',
		'3mm, 5mm 3ex 2.3pc , 5')
    {
	ok($s =~ $RE_LENGTH{$r}, "'$s' =~ $r");
    }
    foreach $s ('',
		' ',
		',',
		' 1',
		'1,',
		',1',
		'3px, 4em, 5qq')
    {
	ok($s !~ $RE_LENGTH{$r}, "'$s' !~ $r");
    }

    my %hash = ('1'          => [1],
		'3cm'        => ['3cm'],
		'12'         => [12],
		'1 2'        => [1, 2],
		'1,2'        => [1, 2],
		'1 ,2'       => [1, 2],
		'1, 2'       => [1, 2],
		'1 , 2'      => [1, 2],
		'3 12ex'     => [3, '12ex'],
		'1pc 1in'    => ['1pc', '1in'],
		'1.3E7ex,3'  => ['1.3E7ex', 3],
		'4.5%, 4pc'  => ['4.5%', '4pc'],
		'3 , 9em'    => [3, '9em'],
		'3mm, 5 3ex' => ['3mm', '5', '3ex']);
    while(my ($key, $value) = each %hash)
    {
	is_deeply([split($RE_LENGTH{LENGTHS_SPLIT}, $key)], $value,
		  "split $key");
    }
}

sub re_paint {
    my $s;
    my $r;

    $r = 'RGB';
    foreach $s ('rgb(0,0,0)',
		'rgb(0, 0, 0)',
		'rgb( 0 , 0 , 0 )',
		'rgb(-1, -3, -5)',
		'rgb(1000, 1000, -1000)')
    {
	ok($s =~ qr/^$RE_PAINT{$r}$/, "'$s' =~ emulated $r");
    }
    foreach $s ('rgb',
		'rgb(',
		'rgb(0, 0)',
		' rgb(0, 0, 0)',
		'rgb (0, 0, 0)',
		'rgb(0, 0, 0) ',
		'rgb(0 0 0)',
		'rgb(0, A, 0)')
    {
	ok($s !~ qr/^$RE_PAINT{$r}$/, "'$s' !~ emulated $r");
    }

    $r = 'HEX';
    foreach $s ('#000',
		'#FFF',
		'#ABC',
		'#1A2',
		'#000000',
		'#FFFFFF',
		'#09ABCD')
    {
	ok($s =~ qr/^$RE_PAINT{$r}$/, "'$s' =~ emulated $r");
    }
    foreach $s (' #000',
		'#000 ',
		'#0',
		'#12',
		'#1234',
		'#12345',
		'#1234567')
    {
	ok($s !~ qr/^$RE_PAINT{$r}$/, "'$s' !~ emulated $r");
    }

    $r = 'NAME';
    foreach $s ('abc',
		'red',
		'cornflowerblue')
    {
	ok($s =~ qr/^$RE_PAINT{$r}$/, "'$s' =~ emulated $r");
    }
    foreach $s (' red',
		'red ',
		'Red',
		'currentColor',
		'red0',
		'rgb(0, 0, 0)',
		'red icc-color')
    {
	ok($s !~ qr/^$RE_PAINT{$r}$/, "'$s' !~ emulated $r");
    }

    $r = 'p_COLOR';
    foreach $s ('mediumspringgreen',
                '#AB013C',
	        '#345',
                'rgb(1, 4, 255)',
	        'rgb(10%, -3%, 100%)')
    {
	ok($s =~ $RE_PAINT{$r}, "'$s' =~ $r");
    }
    foreach $s ('cornflowerbluE',
		'#AB',
                'red icc-color(foo, 0.1, 3, 5)',
	        'none icc-color(bar)',
	        'currentColor',
		'url(foo://bar.baz#cux) none #FFFFFF',
		'rgb(0, 0, 1) icc-color(qux 0 1 0.45)',
	        'url(http://foo.bar.baz#qux)',
		'url(ftp://foo.bar.baz/qux.svg?124#xpointer(id(ID)))',
		'url(foo://bar.baz#cux) none')
    {
	ok($s !~ $RE_PAINT{$r}, "'$s' !~ $r");
    }

    $r = 'ICC_SPEC';
    foreach $s ('icc-color(foo-bar)',
		'icc-color(foo, 3, 4, 5.34)',
		'icc-color(foo)',
		'icc-color( foo)')
    {
	ok($s =~ qr/^$RE_PAINT{$r}$/, "'$s' =~ emulated $r");
    }
    foreach $s (' icc-color(foo)',
		'icc-color(foo) ',
		'icc-color (foo)',
		'icc-color(foo',
		'Icc-color(foo)')
    {
	ok($s !~ qr/^$RE_PAINT{$r}$/, "'$s' !~ emulated $r");
    }

    $r = 'p_DIRECT';
    foreach $s ('cornflowerblue',
		'inherit',
		'none',
                '#AB013C',
	        '#345',
                'red icc-color(foo, 0.1, 3, 5)',
		'#010 icc-color(foo, 1, 0.1)',
	        'none icc-color(bar)',
	        'currentColor',
                'rgb(1, 4, 255)',
		'rgb(0, 0, 1) icc-color(qux 0 1 0.45)')
    {
	ok($s =~ $RE_PAINT{$r}, "'$s' =~ $r");
    }
    foreach $s ('cornflowerbluE',
		'#AB',
	        'url(http://foo.bar.baz#qux)',
		'url(ftp://foo.bar.baz/qux.svg?124#xpointer(id(ID)))',
		'url(foo://bar.baz#cux) none',
		'url(foo://bar.baz#cux) none #FFFFFF')
    {
	ok($s !~ $RE_PAINT{$r}, "'$s' !~ $r");
    }

    $r = 'URI';
    foreach $s ('url(http://123.456.789.001/foo/bar?utz#otz)',
	        'url(http://www.xxx.yz)',
                'url(ftp://foo.bar.baz?qux)',
	        'url(foo://bar/baz#qux)',
	        'url(../corge/)',
	        'url(#quux)',
	        'url(foo://bar/baz#xpointer(id(qux)))',
	        'url(xpointer(id(:bro_qux-bar.baz)))')
    {
	ok($s =~ qr/^$RE_PAINT{$r}$/, "'$s' =~ emulated $r");
    }
    foreach $s (' url(#quux)',
		'url(#quux) ',
		'url (#quux)',
		'url(#quux')
    {
	ok($s !~ qr/^$RE_PAINT{$r}$/, "'$s' !~ emulated $r");
    }

    $r = 'p_PAINT';
    foreach $s ('cornflowerblue',
                '#AB013C',
	        '#345',
                'red icc-color(foo, 0.1, 3, 5)',
		'#010 icc-color(foo, 1, 0.1)',
	        'none icc-color(bar)',
	        'currentColor',
                'rgb(1, 4, 255)',
		'rgb(0, 0, 1) icc-color(qux 0 1 0.45)',
	        'url(http://foo.bar.baz#qux)',
		'url(ftp://foo.bar.baz/qux.svg?124#xpointer(id(ID)))',
		'url(foo://bar.baz#cux) none')
    {
	ok($s =~ $RE_PAINT{$r}, "'$s' =~ $r");
    }
    foreach $s ('cornflowerbluE',
		'#AB',
		'url(foo://bar.baz#cux) none #FFFFFF')
    {
	ok($s !~ $RE_PAINT{$r}, "'$s' !~ $r");
    }

    # split
    $r = 'RGB_SPLIT';
    $s = 'rgb(1, 12, 123)';
    is_deeply([$s =~ $RE_PAINT{$r}], [1, 12, 123], "$s =~ $r");
    $s = 'rgb(-1, +12, +000)';
    is_deeply([$s =~ $RE_PAINT{$r}], [-1, '+12', '+000'], "$s =~ $r");
    $r = 'ICC_SPLIT';
    $s = 'rgb(0, 0, 1) icc-color(qux 0 1 0.45)';
    is_deeply([$s =~ $RE_PAINT{$r}],
	      ['rgb(0, 0, 1)', 'icc-color(qux 0 1 0.45)'], "$s =~ $r");
    $s = 'foo icc-color(bar)';
    is_deeply([$s =~ $RE_PAINT{$r}],
	      ['foo', 'icc-color(bar)'], "$s =~ $r");
    $r = 'HEX_SPLIT';
    $s = '#AA0';
    is_deeply([$s =~ $RE_PAINT{$r}], ['A', 'A', '0'], "$s =~ $r");
    $s = '#AAD07a';
    is_deeply([$s =~ $RE_PAINT{$r}], ['AA', 'D0', '7a'], "$s =~ $r");
    $r = 'URI_SPLIT';
    $s = 'url(#foo)';
    is_deeply([$s =~ $RE_PAINT{$r}], ['url(#foo)', undef], "$s =~ $r");
    $s = 'url(#foo)none';
    is_deeply([$s =~ $RE_PAINT{$r}], ['url(#foo)', 'none'], "$s =~ $r");
    $s = 'url(#foo) none';
    is_deeply([$s =~ $RE_PAINT{$r}], ['url(#foo)', 'none'], "$s =~ $r");
    $s = 'url(#foo) bar';
    is_deeply([$s =~ $RE_PAINT{$r}], ['url(#foo)', 'bar'], "$s =~ $r");
    $s = 'url(#foo)#0AB';
    is_deeply([$s =~ $RE_PAINT{$r}], ['url(#foo)', '#0AB'], "$s =~ $r");
    $s = 'url(#foo) #0ABCD1 icc-color(qux)';
    is_deeply([$s =~ $RE_PAINT{$r}],
	      ['url(#foo)', '#0ABCD1 icc-color(qux)'], "$s =~ $r");
}

sub re_transform {
    my $s;
    my $r;

    $r = 'p_TRANSFORM_LIST';
    foreach $s ('matrix(0, 0, 0, 0, 0, 0)',
		'matrix(0 0 0 0 0 0)',
		'matrix ( 0 1.2, 1.34 , -0.78E22 5, 6 )',
		'translate(1, 2)',
		'translate(-1)',
		'translate ( -3 , -2e-8 )',
		'rotate(3.14)',
		'rotate(4  -10 5)',
		'rotate ( -0E4 +1 1E+7)',
		'skewX( 1)',
		'skewY(-4 )',
		'translate(1 2),rotate(1) skewX(-4E+1)')
    {
	ok($s =~ $RE_TRANSFORM{$r}, "'$s' =~ $r");
    }
    foreach $s (' matrix(1 2 3 4 5 6)',
		'matrix(1 2 3 4 5 6) ',
		'matrix(1 2 3 4 5 6',
		'matrix(1)',
		'matrix(1 2 3 4 5)',
		' translate(1 2)',
		'translate(1 2) ',
		'translate(1 2',
		'translate(1 2 3)',
		'translate(1 a)',
		' rotate(1)',
		'rotate(1) ',
		'rotate(1',
		'rotate(1 2)',
		'rotate(+)',
		' skewX(1)',
		'skewX(1) ',
		'skewX(1',
		'skewX(1 2)',
		' skewY(1)',
		'skewY(1) ',
		'skewY(1',
		'skewY(0, 0)',
		'translate(1 2)rotate(1)')
    {
	ok($s !~ $RE_TRANSFORM{$r}, "'$s' !~ $r");
    }

    $r = 'TRANSFORM_SPLIT';
    $s = 'matrix(1 2 3 4 5 6)';
    is_deeply([$s =~ $RE_TRANSFORM{$r}], ['matrix(1 2 3 4 5 6)', undef],
	      "$s =~ $r");
    $s = 'rotate(1 2 3) translate(1 2)';
    is_deeply([$s =~ $RE_TRANSFORM{$r}],
	      ['rotate(1 2 3)', 'translate(1 2)'], "$s =~ $r");
    $s = 'rotate(1 2 3) translate(1 2) skewX(1)';
    is_deeply([$s =~ $RE_TRANSFORM{$r}],
	      ['rotate(1 2 3)', 'translate(1 2) skewX(1)'], "$s =~ $r");

    $r = 'TRANSFORM_CAPTURE';
    $s = 'matrix(1 2 3 4 5 6)';
    is_deeply([$s =~ $RE_TRANSFORM{$r}], ['matrix', '1 2 3 4 5 6'],
	      "$s =~ $r");
    $s = 'rotate(1 2 3)';
    is_deeply([$s =~ $RE_TRANSFORM{$r}],
	      ['rotate', '1 2 3'], "$s =~ $r");
    $s = 'skewY(1)';
    is_deeply([$s =~ $RE_TRANSFORM{$r}],
	      ['skewY', '1'], "$s =~ $r");
}

sub re_viewBox {
    my $r;
    my $s;

    $r = 'p_VIEW_BOX';
    foreach $s ('1 2 3 4',
		'1,2,3,4',
		'1, 2, 3, 4',
		'1 , 2 , 3 , 4',
		'100 50 37.5, 13.45E+1')
    {
	ok($s =~ $RE_VIEW_BOX{$r}, "'$s' =~ $r");
    }
    foreach $s (' 1,2,3,4',
		'1,2,3,4 ',
		'1,2,3,4,5')
    {
	ok($s !~ $RE_VIEW_BOX{$r}, "'$s' !~ $r");
    }

    $r = 'ALIGN';
    foreach $s ('none',
		'xMinYMin',
		'xMinYMid',
		'xMinYMax',
		'xMidYMin',
		'xMidYMid',
		'xMidYMax',
		'xMaxYMin',
		'xMaxYMid',
		'xMaxYMax')
    {
	ok($s =~ qr/^$RE_VIEW_BOX{$r}$/, "'$s' =~ emulated $r");
    }
    foreach $s (' xMinYMax',
		'xMinYMin ',
		'XMinYMax',
		'xminYMax',
		'xMinyMax',
		'xMinYmax')
    {
	ok($s !~ qr/^$RE_VIEW_BOX{$r}$/, "'$s' !~ emulated $r");
    }

    $r = 'MOS';
    foreach $s ('meet', 'slice')
    {
	ok($s =~ qr/^$RE_VIEW_BOX{$r}$/, "'$s' =~ emulated $r");
    }
    foreach $s (' meet',
		'meet ',
		'meetslice',
		'Meet',
		'sLice')
    {
	ok($s !~ qr/^$RE_VIEW_BOX{$r}$/, "'$s' !~ emulated $r");
    }

    $r = 'p_PAR';
    foreach $s ('none',
		'defer none',
		'defer  none',
		'defer none meet',
		'defer none  meet',
		'defer none slice',
		'none slice',
		'none  slice',
		'defer xMinYMax',
		'xMidYMid',
		'defer xMaxYMin slice',
		'xMidYMax   meet')
    {
	ok($s =~ $RE_VIEW_BOX{$r}, "'$s' =~ $r");
    }
    foreach $s ('defer',
		'defer meet',
		'defer slice',
		'meet',
		'slice',
		' none',
		'none ',
		"xMidYMax\tmeet")
    {
	ok($s !~ $RE_VIEW_BOX{$r}, "'$s' !~ $r");
    }
}

sub re_path {
    my $r;
    my $s;

    $r = 'p_PATH_LIST';
    foreach $s ('M0 0',
		'M 0 0',
		'M 0,0',
		'M 0, 0',
		'M12',
		'M1.2E4 -0.5e-13',
		'M123',
		'M1.2.3',
		'M1.2 0',
		'M1.2 0.3',
		'm0 0',
		'M.2.3L123',
		'M10 20L20, 30, 30, 50',
		'm10 20  L0 0, 10 20, 30 50',
		'M1.2 0.3C1.3,5,10,1,5-4',
		'M4 3H10',
		'M 125 , 75 L 100 50 20 30 H 1  '.
		    'C 1 2 3 4 5 6 a 1 2 3 0 1 4 5',
		'M 125 , 75 L 100 50 20 30',
		'M 125 , 75 L 100 50 20 30 H1',
		'M 125 , 75 L 100 50 20 30 H 1',
		'M 600,81 A 107,107 0 0,1 600,295',
		'M 600,81 A 107,107 0 0,1 600,295 '.
		    'A 107,107 0 0,1 600,81 z',
		'M 600,81 A 107,107 0 0,1 600,295 '.
		    'A 107,107 0 0,1 600,81 z M 600,139',
		'M 600,81 A 107,107 0 0,1 600,295 '.
		    'A 107,107 0 0,1 600,81 zM 600,139',
		'M 600,81 A 107,107 0 0,1 600,295 '.
		    'A 107,107 0 0,1 600,81 z'.
		    'M 600,139 A 49,49 0 0,1 600,237 '.
		    'A 49,49 0 0,1 600,139 z',
		'm0 0L1 2 3 4M5 6Q1 2 3 4',
		'M 0 0 A1 1 0 0 0 2 0')
    {
	ok($s =~ $RE_PATH{$r}, "'$s' =~ $r");
    }
    foreach $s ('',
		' M0 0',
		'M0 0 ',
		'L0 0',
		'K 7 3',
		'M0,,0',
		'M0 0 0',
		'M 0 0 A-1 1 0 0 0 2 0',
		'M 0 0 A1 -1 0 0 0 2 0')
    {
	ok($s !~ $RE_PATH{$r}, "'$s' !~ $r");
    }

    $r = 's_PATH_LIST';
    foreach $s ('M0 0 ',
		'M0 0 0',
		'M0 0abc')
    {
	ok($s =~ $RE_PATH{$r}, "'$s' =~ $r");
    }
    foreach $s ('',
		' M0 0',
		'L0 0',
		'K 7 3',
		'M0,,0')
    {
	ok($s !~ $RE_PATH{$r}, "'$s' !~ $r");
    }

    $r = 'MAS_SPLIT';
    $s = '1 2';
    is_deeply([$s =~ $RE_PATH{$r}], [1, 2, ''],
	      "$s =~ $r");
    $s = '1 2 3 4';
    is_deeply([$s =~ $RE_PATH{$r}], [1, 2, '3 4'],
	      "$s =~ $r");
    $s = '1 2 0.5';
    is_deeply([$s =~ $RE_PATH{$r}], [1, 2, '0.5'],
	      "$s =~ $r");
    $s = '0.5 1 2';
    is_deeply([$s =~ $RE_PATH{$r}], ['0.', 5, '1 2'],
	      "$s =~ $r");
    $s = '1 2 3 4 5.6 7';
    is_deeply([$s =~ $RE_PATH{$r}], [1, 2, '3 4 5.6 7'],
	      "$s =~ $r");

    $r = 'HLAS_SPLIT';
    $s = '-1';
    is_deeply([$s =~ $RE_PATH{$r}], [-1, ''],
	      "$s =~ $r");
    $s = '12';
    is_deeply([$s =~ $RE_PATH{$r}], [12, ''],
	      "$s =~ $r");
    $s = '1 2';
    is_deeply([$s =~ $RE_PATH{$r}], [1, 2],
	      "$s =~ $r");
    $s = '1 2 -3';
    is_deeply([$s =~ $RE_PATH{$r}], [1, '2 -3'],
	      "$s =~ $r");

    $r = 'CAS_SPLIT';
    $s = '1 2 3 4 5 6';
    is_deeply([$s =~ $RE_PATH{$r}], [1, 2, 3, 4, 5, 6, ''],
	      "$s =~ $r");
    $s = '123456 789012';
    is_deeply([$s =~ $RE_PATH{$r}], [123456, 78, 9, 0, 1, 2, ''],
	      "$s =~ $r");
    $s = '1 2 3 4 5 6 7 8 9 0 1 2';
    is_deeply([$s =~ $RE_PATH{$r}], [1, 2, 3, 4, 5, 6, '7 8 9 0 1 2'],
	      "$s =~ $r");

    $r = 'SCAS_SPLIT';
    $s = '1 2 3 4';
    is_deeply([$s =~ $RE_PATH{$r}], [1, 2, 3, 4, ''],
	      "$s =~ $r");
    $s = '123456 789012';
    is_deeply([$s =~ $RE_PATH{$r}], [123456, 7890, 1, 2, ''],
	      "$s =~ $r");
    $s = '1 2 3 4 5 6 7 8 9 0 1 2';
    is_deeply([$s =~ $RE_PATH{$r}], [1, 2, 3, 4, '5 6 7 8 9 0 1 2'],
	      "$s =~ $r");

    $r = 'EAAS_SPLIT';
    $s = '1 1 0 0 0 2 0';
    is_deeply([$s =~ $RE_PATH{$r}], [1, 1, 0, 0, 0, 2, 0, ''],
	      "$s =~ $r");
    $s = '123456 78 1 0 12';
    is_deeply([$s =~ $RE_PATH{$r}], [123456, 7, 8, 1, 0, 1, 2, ''],
	      "$s =~ $r");
    $s = '1 1 0 0 0 2 0 2 2 0 0 1 6 0';
    is_deeply([$s =~ $RE_PATH{$r}], [1, 1, 0, 0, 0, 2, 0, '2 2 0 0 1 6 0'],
	      "$s =~ $r");
}

sub re_dasharray {
    my $r;
    my $s;

    $r = 'p_DASHARRAY';
    foreach $s ('0',
		'0, 0',
		'0 , 0',
		'0 ,  0',
		'0, 1, 2')
    {
	ok($s =~ $RE_DASHARRAY{$r}, "'$s' =~ $r");
    }
    foreach $s (' 0',
		'0 ',
		'0 0',
		'0, 0 0',
		'0, 0 ')
    {
	ok($s !~ $RE_DASHARRAY{$r}, "'$s' !~ $r");
    }

    $r = 'SPLIT';
    foreach $s (',',
		' ,',
		', ',
		' , ',
		'  ,  ',
		"\t, ")
    {
	ok($s =~ qr/^$RE_DASHARRAY{$r}$/, "'$s' =~ emulated $r");
    }
    foreach $s (' ',
		"\t",
		';',
		',;')
    {
	ok($s !~ qr/^$RE_DASHARRAY{$r}$/, "'$s' !~ emulated $r");
    }
}

sub re_text {
    my $r;
    my $s;

    $r = 'p_FONT_SIZE';
    foreach $s ('xx-small',
                'x-small',
	        'small',
		'medium',
		'large',
		'x-large',
		'xx-large',
		'smaller',
		'larger',
		'5pt',
		'30%',
		'40')
    {
	ok($s =~ $RE_TEXT{$r}, "'$s' =~ $r");
    }
    foreach $s ('exorbitant',
		'30km',
		'50 %')
    {
	ok($s !~ $RE_TEXT{$r}, "'$s' !~ $r");
    }
}

sub units {
    my $rasterize;

    $rasterize = SVG::Rasterize->new;
    cmp_ok($rasterize->px_per_in, '==', 90, 'default value');
    cmp_ok(abs($rasterize->px_per_in(81.3e-1) - 8.13), '<', 1e-10,
	   'mutator return');
    cmp_ok(abs($rasterize->px_per_in - 8.13), '<', 1e-10,
	   'new value');
    throws_ok(sub { $rasterize->px_per_in('--1') },
	      qr/px_per_in/, 'px_per_in check');

    # map_abs_length
    $rasterize = SVG::Rasterize->new;
    throws_ok(sub { $rasterize->map_abs_length }, qr/map_abs_length/,
	      'map_abs_length no argument');
    throws_ok(sub { $rasterize->map_abs_length('-13xy') },
	      qr/map_abs_length/,
	      'map_abs_length invalid argument');
    lives_ok(sub { $rasterize->map_abs_length('-13px') },
	     'valid argument');
    throws_ok(sub { $rasterize->map_abs_length('-13 px') },
	      qr/map_abs_length/,
	      'map_abs_length invalid argument (space)');
    cmp_ok($rasterize->map_abs_length(-3), '==', -3, 'no unit');
    cmp_ok($rasterize->map_abs_length('-3px'), '==', -3, 'px');
    throws_ok(sub { $rasterize->map_abs_length(' -25px ') },
	      qr/to SVG::Rasterize::map_abs_length did not pass regex/,
	      'whitespace in length');
    cmp_ok($rasterize->map_abs_length('1.5in'), '==', 135, 'in');
    $rasterize->dpi(120);
    cmp_ok($rasterize->map_abs_length('1.5in'), '==', 180,
	   'in, custom dpi');
    cmp_ok(abs($rasterize->map_abs_length('5.08cm') - 240), '<', 1e-10,
	   'cm');
}

sub path_data_splitting {
    my $rasterize = SVG::Rasterize->new;
    my $d;

    is_deeply([$rasterize->_split_path_data('M3 -4')],
	      [0, ['M', 3, -4]],
	      q{path data 'M3 -4'});
    is_deeply([$rasterize->_split_path_data('M3 -4 12.3')],
	      [0, ['M', 3, -4], ['L', '12.', 3]],
	      q{path data 'M3 -4 12.3'});
    is_deeply([$rasterize->_split_path_data('M3 -4 M12.3')],
	      [0, ['M', 3, -4], ['M', '12.', 3]],
	      q{path data 'M3 -4 M12.3'});
    is_deeply([$rasterize->_split_path_data('M3 -4 12.23')],
	      [0, ['M', 3, -4], ['L', 12.2, 3]],
	      q{path data 'M3 -4 12.23'});
    is_deeply([$rasterize->_split_path_data('M-13')],
	      [0, ['M', -1, 3]],
	      q{path data 'M-13'});
    is_deeply([$rasterize->_split_path_data('M-13.4')],
	      [0, ['M', '-13.', 4]],
	      q{path data 'M-13.4'});
    is_deeply([$rasterize->_split_path_data('M3-1l100Z')],
	      [0, ['M', 3, -1], ['l', 10, 0], ['Z']],
	      q{path data 'M3-1l100Z'});
    is_deeply([$rasterize->_split_path_data('M-1-2H.4 3')],
	      [0, ['M', -1, -2], ['H', '.4'], ['H', 3]],
	      q{path data 'M-1-2H.4 3'});
    is_deeply([$rasterize->_split_path_data('C1 2 3 4 5 6 1 2 3 4 5 6')],
	      [0, ['C', 1, 2, 3, 4, 5, 6], ['C', 1, 2, 3, 4, 5, 6]],
	      q{path data 'C1 2 3 4 5 6 1 2 3 4 5 6'});
    is_deeply([$rasterize->_split_path_data('S1 2 3 4 5 6 1 2')],
	      [0, ['S', 1, 2, 3, 4], ['S', 5, 6, 1, 2]],
	      q{path data 'S1 2 3 4 5 6 1 2'});
    is_deeply([$rasterize->_split_path_data('Q1 2 3 4t56')],
	      [0, ['Q', 1, 2, 3, 4], ['t', 5, 6]],
	      q{path data 'Q1 2 3 4t56'});
    is_deeply([$rasterize->_split_path_data('A1 2 -3 0 0 1 4')],
	      [0, ['A', 1, 2, -3, 0, 0, 1, 4]],
	      q{path data 'A1 2 -3 0 0 1 4'});
    $d = 'M 125,75 a100,50 0 0,0 100,50';
    ok($d =~ $RE_PATH{p_PATH_LIST}, $d);
    is_deeply([$rasterize->_split_path_data($d)],
	      [0, ['M', 125, 75], ['a', 100, 50, 0, 0, 0, 100, 50]],
	      qq{path data '$d'});
    $d = 'M 125 , 75 L 100 50 20 30 H 1  C 1 2 3 4 5 6 a 1 2 3 0 1 4 5';
    ok($d =~ $RE_PATH{p_PATH_LIST}, $d);
    is_deeply([$rasterize->_split_path_data($d)],
	      [0, ['M', 125, 75], ['L', 100, 50], ['L', 20, 30], ['H', 1],
	       ['C', 1, 2, 3, 4, 5, 6], ['a', 1, 2, 3, 0, 1, 4, 5]],
	      qq{path data '$d'});
}

sub poly_points_validation {
    ok('1 2 3 4' =~ $RE_POLY{p_POINTS_LIST},
       q{poly '1 2 3 4'});
    ok('1 2 3' !~ $RE_POLY{p_POINTS_LIST},
       q{poly '1 2 3'});
    my ($x, $y, $rest) = '1 2 3 4' =~ $RE_POLY{POINTS_SPLIT};
    is($x, 1, 'split x');
    is($y, 2, 'split y');
    is($rest, '3 4', 'split rest');
}

white_space;
package_name;
xml_uri;
re_number;
re_length;
re_paint;
re_transform;
re_viewBox;
re_path;
re_dasharray;
re_text;

units;
path_data_splitting;
poly_points_validation;

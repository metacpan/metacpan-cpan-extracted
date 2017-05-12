# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Encode-LaTeX.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 37;
use Encode;
BEGIN { use_ok('TeX::Encode') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

# decode of an encode should be equivalent
my $str = "eacute = '" . chr(0xe9) . "'";
is(encode('LaTeX', $str), "eacute = '\\'e'", "eacute => '\\'e'");
is(decode('latex', "eacute = '\\'e'"), $str, $str);

# General decode tests
my @DECODE_TESTS = (
	'foo x^2 bar' => 'foo x'.chr(0xb2).' bar',
	'xxx \\texttt{\char92} yyy' => 'xxx \\ yyy',
	'\\sqrt{2}' => (chr(0x221a) . "2"),
	'hyper-K\\"ahler background' => ('hyper-K'.chr(0xe4).'hler background'),
	'$0<\\sigma\\leq{}2$' => ('0<'.chr(0x3c3).chr(0x2264).'2'),
	'foo \\{ bar' => 'foo { bar', # Unescaping Tex escapes
	'foo \\\\ bar' => "foo \n bar", # Tex newline
	'foo $mathrm$ bar' => 'foo mathrm bar', # Math mode test (strictly should eat spaces inside math mode too)
	'{\\L}' => chr(0x141), # Polish suppressed-L
	'\\ss' => chr(0xdf), # German sharp S
	'\\oe' => chr(0x153), # French oe
	'\\OE' => chr(0x152), # French OE
	'\\ae' => chr(0xe6), # Scandinavian ligature ae
"consist of \$\\sim{}260,000\$ of subprobes \$\\sim{}4\\\%\$ of in \$2.92\\cdot{}10^{8}\$ years. to \$1.52\\cdot{}10^{7}\$ years." =>
"consist of ".chr(0x223c)."260,000 of subprobes ".chr(0x223c)."4% of in 2.92".chr(0x22c5)."10".chr(0x2078)." years. to 1.52".chr(0x22c5)."10".chr(0x2077)." years.", # Should remove empty braces too
	'L\Boxr' => 'L'.chr(0x25A1).'r', # %MATH box
	'L\earthr' => 'L'.chr(0x2295).'r', # %ASTRONOMY
	'L\blackpawnr' => 'L'.chr(0x265f).'r', # %GAMES chess
	'L\epsdice{6}r' => 'L'.chr(0x2685).'r', # %GAMES dice
	'L\returnkeyr' => 'L'.chr(0x23CE).'r', # %KEYS
	'L\texteshr' => 'L'.chr(0x0283).'r', # voiceless palato-alveolar median laminal fricative
);

# General encode tests
my @ENCODE_TESTS = (
	'underscores _ should be escaped' => "underscores \\_ should be escaped",
	'#$%&_' => '\\#\\$\\%\\&\\_',
	'\\' => '\\texttt{\\char92}',
	'^' => '\\^{ }',
	'~' => '\\texttt{\\char126}',
	'<>' => '\ensuremath{<}\ensuremath{>}',
	chr(0xe6) => '\\ae',
	chr(0xe6).'foo' => '\\ae{}foo',
	chr(0x3b1) => '\\ensuremath{\\alpha}',
	chr(0xe6).' foo' => '\\ae foo',
	'abcd'.chr(0xe9).'fg' => 'abcd\\\'e{}fg',
	chr(0x107) => '\\\'c',
);

while( my( $in, $out ) = splice(@DECODE_TESTS,0,2) ) {
	is( decode('latex', $in), $out );
}

while( my( $in, $out ) = splice(@ENCODE_TESTS,0,2) ) {
	is( encode('latex', $in), $out );
}

# Check misquoting of tex strings ({})
$str = 'mathrm $\\mathrm{E}$';
is(decode('latex', $str), 'mathrm \\mathrmE');

ok(1);

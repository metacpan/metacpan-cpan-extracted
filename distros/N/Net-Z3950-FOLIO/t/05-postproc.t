use strict;
use warnings;
use utf8;

BEGIN {
    binmode(STDOUT, "encoding(UTF-8)");
    use vars qw(@stripDiacriticsTests @regsubTests @applyRuleTests @transformTests);
    @stripDiacriticsTests = (
	# value, expected, caption
	[ 'water', 'water', 'null transformation' ],
	[ 'expérience', 'experience', 'e-acute' ],
	[ 'pour célébrer', 'pour celebrer', 'multiple e-acute' ],
	[ 'Museum für Naturkunde', 'Museum fur Naturkunde', 'u-umlaut' ],
	[ 'façade', 'facade', 'cedilla' ],
	[ 'àÀâÂäçéÉèÈêÊëîïôùÙûüÜ', 'aAaAaceEeEeEeiiouUuuU', 'kitchen sink' ],
	# Individual characters specified in ZF-31
	[ 'ß', 'ss', 'small letter sharp S (Eszett)' ],
	[ 'ẞ', 'SS', 'capital letter sharp S (Eszett)' ],
	[ 'Þ', 'TH', 'upper-case THORN' ],
	[ 'þ', 'th', 'lower case THORN' ],
	[ 'Đ', 'D', 'upper-case ETH' ],
	[ 'ð', 'd', 'lower case ETH' ],
	[ 'Æ', 'AE', 'upper-case AE ligature' ],
	[ 'æ', 'ae', 'lower-case AE ligature' ],
	[ 'Œ', 'OE', 'upper-case OE ligature' ],
	[ 'œ', 'oe', 'lower-case OE ligature' ],
	[ 'Ł', 'L', 'capital letter L with stroke' ],
	[ 'ł', 'l', 'small letter L with stroke' ],
	[ 'ßẞÞþĐðÆæŒœŁł', 'ssSSTHthDdAEaeOEoeLl', 'all of the above' ],
	[ 'ßẞÞþĐðÆæŒœŁłßẞÞþĐðÆæŒœŁł', 'ssSSTHthDdAEaeOEoeLlssSSTHthDdAEaeOEoeLl', 'twice' ],
    );
    @regsubTests = (
	# value, pattern, replacement, flags, expected, caption
	[ 'foobar', 'O', 'x', '', 'foobar', 'case-sensitive non-match' ],
	[ 'foobar', 'O', 'x', 'i', 'fxobar', 'case-insensitive match' ],
	[ 'foobar', 'o', 'x', '', 'fxobar', 'single replacement' ],
	[ 'foobar', 'o', 'x', 'g', 'fxxbar', 'global replacement' ],
	[ 'foobar', '[aeiou]', 'x', 'g', 'fxxbxr', 'replace character class' ],
	[ 'foobar', '[aeiou]', 'X/Y', 'g', 'fX/YX/YbX/Yr', 'replacement containing /' ],
	[ 'foobar', '([aeiou])', '[$1]', 'g', 'f[o][o]b[a]r', 'group reference in pattern' ],
	[ 'foobar', '(.)(.)', '$2$1', 'g', 'ofbora', 'group references in pattern' ],
	[ 'foo/bar', '(.)/(.)', '$2/$1', 'g', 'fob/oar', 'pattern containing /' ],
	[ 'foobar', '(.)\1', 'XXX', 'g', 'fXXXbar', 'back-reference in pattern' ],
    );
    @applyRuleTests = (
	# value, rule, expected, caption
	[ 'expérience', { op => 'stripDiacritics' }, 'experience', 'stripDiacritics e-acute' ],
	[ 'expérience', {
	    op => 'regsub',
	    pattern => '[aeiou]',
	    replacement => '*',
	    flags => 'g',
	  }, '*xpér**nc*', 'regsub s/[aeiou]/*/g' ],
    );
    @transformTests = (
	# value, ruleset, expected, caption
	@applyRuleTests, # Check that single rules also work as rulesets
	[ 'expérience', [
	    { op => 'stripDiacritics' },
	    {
		op => 'regsub',
		pattern => '[aeiou]',
		replacement => '*',
		flags => 'g',
	    },
	], '*xp*r**nc*', 'stripDiacritics and regsub' ],
    );
}

use Test::More tests => 1 + @stripDiacriticsTests + @regsubTests + @applyRuleTests + @transformTests;

BEGIN { use_ok('Net::Z3950::FOLIO::PostProcess') };
use Net::Z3950::FOLIO::PostProcess qw(applyStripDiacritics applyRegsub applyRule transform);

foreach my $stripDiacriticsTest (@stripDiacriticsTests) {
    my($value, $expected, $caption) = @$stripDiacriticsTest;
    my $got = applyStripDiacritics({}, $value);
    is($got, $expected, "stripDiacritics '$value' ($caption)");
}

foreach my $regsubTest (@regsubTests) {
    my($value, $pattern, $replacement, $flags, $expected, $caption) = @$regsubTest;
    my $rule = {
	pattern => $pattern,
	replacement => $replacement,
	flags => $flags,
    };
    my $got = applyRegsub($rule, $value);
    is($got, $expected, "s/$pattern/$replacement/$flags ($caption)");
}

foreach my $applyRuleTest (@applyRuleTests) {
    my($value, $rule, $expected, $caption) = @$applyRuleTest;
    my $got = applyRule($rule, $value);
    is($got, $expected, "applyRule '$value' ($caption)");
}

foreach my $transformTest (@transformTests) {
    my($value, $cfg, $expected, $caption) = @$transformTest;
    my $got = transform($cfg, $value);
    is($got, $expected, "transform '$value' ($caption)");
}


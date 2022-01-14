use strict;
use warnings;
use utf8;

use MARC::Record;

sub makeMarcRecord {
    my $marc = new MARC::Record();
    my $field = new MARC::Field('999','','','z' => 'water');
    $marc->append_fields($field);
    my $field2 = new MARC::Field('001','fire');
    $marc->append_fields($field2);
    # warn $marc->as_formatted();
    return $marc;
}


BEGIN {
    binmode(STDOUT, "encoding(UTF-8)");
    use vars qw(@stripDiacriticsTests @regsubTests @applyRuleTests @transformTests @postProcessTests);
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
    my $marc = makeMarcRecord();
    @postProcessTests = (
	# MARC record, ruleset, field, expected, caption
	[ $marc, {}, '001', 'fire', 'null transformation on control field' ],
	[ $marc, {}, '999$z', 'water', 'null transformation on subfield' ],
	[ $marc, {
	    '999$z' => [
		{
		    op => 'regsub',
		    pattern => 'a',
		    replacement => 'A',
		}
	    ]
	  }, '999$z', 'wAter', 'single transformation'

	],
	[ $marc, {
	    '999$z' => [
		{
		    op => 'regsub',
		    pattern => 'a',
		    replacement => 'A',
		},
		{
		    op => 'regsub',
		    pattern => '(.*)',
		    replacement => '$1/$1',
		}
	    ]
	  }, '999$z', 'wAter/wAter', 'double transformation'
	],
	[ $marc, {
	    '999$z' => [
		{
		    op => 'regsub',
		    pattern => 'a',
		    replacement => 'foo%{001}bar',
		}
	    ]
	  }, '999$z', 'wfoofirebarter', 'substituting field value'

	],
	[ $marc, {
	    '001' => [
		{
		    op => 'regsub',
		    pattern => '[aeiou]',
		    replacement => '%{999$z}',
		    flags => 'g',
		}
	    ]
	  }, '001', 'fwaterrwater', 'substituting multiple subfield values'
	],
	[ $marc, {
	    '002' => [ { op => 'regsub', pattern => '^$', replacement => '%{999$z}' } ]
	  }, '002', 'water', 'creating new control field'
	],
	[ $marc, {
	    '999$y' => [ { op => 'regsub', pattern => '^$', replacement => '%{999$z}' } ]
	  }, '999$y', 'water', 'creating subfield of existing field'
	],
	[ $marc, {
	    '998$y' => [ { op => 'regsub', pattern => '^$', replacement => '%{999$z}' } ]
	  }, '998$y', 'water', 'creating subfield of new field'
	],
	[ $marc, {
	    '002' => [ { op => 'regsub', pattern => '^$', replacement => '%{999$x}' } ]
	  }, '002', undef, 'not creating field by substituting empty value'
	],
	[ $marc, {
	    '998$y' => [ { op => 'regsub', pattern => '^$', replacement => '%{999$x}' } ]
	  }, '998$y', undef, 'not creating subfield by substituting empty value'
	],
    );
}

use Test::More tests => 1 + @stripDiacriticsTests + @regsubTests + @applyRuleTests + @transformTests + @postProcessTests;

BEGIN { use_ok('Net::Z3950::FOLIO::PostProcess') };
use Net::Z3950::FOLIO::PostProcess qw(applyStripDiacritics applyRegsub applyRule transform postProcessMARCRecord fieldOrSubfield);

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

foreach my $postProcessTest (@postProcessTests) {
    my($marc, $cfg, $field, $expected, $caption) = @$postProcessTest;
    my $newMarc = postProcessMARCRecord($cfg, $marc);
    my $got = fieldOrSubfield($newMarc, $field);
    is($got, $expected, "postProcessMARCRecord field $field ($caption)");
}


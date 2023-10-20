use strict;
use warnings;
use utf8;

use MARC::Record;

sub makeMarcRecord {
    my @fields;
    push @fields, new MARC::Field('001', 'fire');
    push @fields, new MARC::Field('999', '', '', z => 'water');
    push @fields, new MARC::Field('952', '', '', d => 'cn1', v => 'v1', b => '123');
    push @fields, new MARC::Field('952', '', '', d => 'cn2', v => 'v2', b => '234');
    my $marc = new MARC::Record();
    $marc->append_fields(@fields);
    # warn $marc->as_formatted();
    return $marc;
}

sub makeHoldings {
  return [
    bless([
      ['typeOfRecord', 'n'],
      ['encodingLevel', '1'],
      ['format', 'cr'],
      ['receiptAcqStatus', '3'],
      ['generalRetention', '|'],
      ['completeness', 'a'],
      ['nucCode', "xeno"],
      ['localLocation', 'Online'],
      ['shelvingLocation', 'Online'],
      ['_callNumberPrefix', 'f'],
      ['callNumber', '123.456'],
      ['_callNumberSuffix', 'b'],
      ['circulations', [
	   bless([
	       ['itemId', '1234567890'],
	       ['enumAndChron', 'Spring edition'],
	   ], 'Net::z3950::FOLIO::OPACXMLRecord::item'),
	   bless([
	       ['itemId', '1234567891'],
	       ['enumAndChron', 'Summer edition'],
	   ], 'Net::z3950::FOLIO::OPACXMLRecord::item'),
      ]],
    ], 'Net::z3950::FOLIO::OPACXMLRecord::holding'),
    bless([
      ['nucCode', "bronto"],
    ], 'Net::z3950::FOLIO::OPACXMLRecord::holding'),
  ];
}

sub opacFieldOrSubfield {
    my($holdings, $field) = @_;

    my($n, $wanted, $rest) = split(/\./, $field, 3);
    my $holding = $holdings->[$n];
    for (my $i = 0; $i < @$holding; $i++) {
	my $entry = $holding->[$i];
	my($name, $value) = @$entry;
	next if $name ne $wanted;
	return $value if $name ne 'circulations';
	return opacFieldOrSubfield($value, $rest)
    }

    return undef;
}

BEGIN {
    binmode(STDOUT, "encoding(UTF-8)");
    use vars qw(@stripDiacriticsTests @regsubTests @applyRuleTests @transformTests @postProcessMarcTests @postProcessHoldingsTests);
    my $censorVowels = {
	op => 'regsub',
	pattern => '[aeiou]',
	replacement => '*',
	flags => 'g',
    };
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
	[ 'expérience', $censorVowels, '*xpér**nc*', 'regsub s/[aeiou]/*/g' ],
    );
    @transformTests = (
	# value, ruleset, expected, caption
	@applyRuleTests, # Check that single rules also work as rulesets
	[ 'expérience', [
	    { op => 'stripDiacritics' },
	      $censorVowels,
	], '*xp*r**nc*', 'stripDiacritics and regsub' ],
    );
    my $marc = makeMarcRecord();
    @postProcessMarcTests = (
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
	[ $marc, {}, '952$d/0', 'cn1', 'null transformation in first copy of a field' ],
	[ $marc, {}, '952$d/1', 'cn2', 'null transformation in second copy of a field' ],
	[ $marc, {
	    '952$d' => { op => 'regsub', pattern => '(.*)', replacement => '$1 %{952$v} - %{952$b}' }
	  }, '952$d/0', 'cn1 v1 - 123', 'substitutions in first copy of a field'
	],
	[ $marc, {
	    '952$d' => { op => 'regsub', pattern => '(.*)', replacement => '$1 %{952$v} - %{952$b}' }
	  }, '952$d/1', 'cn2 v2 - 234', 'substitutions in second copy of a field'
	],
	[ $marc, {
	    '952$d' => { op => 'regsub', pattern => '(.*)', replacement => '$1 %{952$v} - %{999$z}' }
	  }, '952$d/1', 'cn2 v2 - water', 'substitutions in second copy from a separate field'
	],
    );
    @postProcessHoldingsTests = (
	# OPAC record, ruleset, field, expected, caption
	[ makeHoldings(), {}, '0.nucCode', 'xeno', 'null transformation on holdings field' ],
	[ makeHoldings(), {
	    holding => { nucCode => $censorVowels }
	  }, '0.nucCode', 'x*n*', 'substitution on holdings field'
	],
	[ makeHoldings(), {
	    holding => { nucCode => $censorVowels }
	  }, '1.nucCode', 'br*nt*', 'substitition on second holding'
	],
	[ makeHoldings(), {
	    holding => { localLocation => [
		$censorVowels,
		{ op => 'regsub', pattern => '(n.)', replacement => '$1$1' }
            ] }
	  }, '0.localLocation', 'Onlnl*n*', 'double substitition on holdings'
	],
	[ makeHoldings(), {
	    holding => {
		callNumber => {
		    op => 'regsub',
		    pattern => '(.*)',
		    replacement => '%{_callNumberPrefix}%{callNumber}%{_callNumberSuffix}',
		}
	    }
	  }, '0.callNumber', 'f123.456b', 'add prefix/suffix to call-number'
	],
	[ makeHoldings(), {
	    circulation => {
		enumAndChron => $censorVowels,
	    }
	  }, '0.circulations.0.enumAndChron', 'Spr*ng *d*t**n', 'substitute item-level field'
	],
	[ makeHoldings(), {
	    circulation => {
		enumAndChron => $censorVowels,
	    }
	  }, '0.circulations.1.enumAndChron', 'S*mm*r *d*t**n', 'substitute second item-level field'
	],
	[ makeHoldings(), {
	    circulation => {
		itemId => {
		    op => 'regsub',
		    pattern => '$',
		    replacement => ' (%{enumAndChron})',
		}
	    }
	  }, '0.circulations.0.itemId', '1234567890 (Spring edition)', 'substitute item-level field'
	],
    );
}

use Test::More tests => 3 + (@stripDiacriticsTests +
			     @regsubTests +
			     @applyRuleTests +
			     @transformTests +
			     @postProcessMarcTests +
			     @postProcessHoldingsTests);

BEGIN { use_ok('Net::Z3950::FOLIO::PostProcess::Transform') };
use Net::Z3950::FOLIO::PostProcess::Transform qw(applyStripDiacritics applyRegsub applyRule transform);
BEGIN { use_ok('Net::Z3950::FOLIO::PostProcess::MARC') };
use Net::Z3950::FOLIO::PostProcess::MARC qw(postProcessMARCRecord marcFieldOrSubfield);
BEGIN { use_ok('Net::Z3950::FOLIO::PostProcess::OPAC') };
use Net::Z3950::FOLIO::PostProcess::OPAC qw(postProcessHoldings);

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

foreach my $postProcessMarcTest (@postProcessMarcTests) {
    my($marc, $cfg, $field, $expected, $caption) = @$postProcessMarcTest;
    my $index;
    if ($field =~ /(.*)\/(.*)/) {
	$field = $1;
	$index = $2;
    }
    my $newMarc = postProcessMARCRecord($cfg, $marc);
    my $got = marcFieldOrSubfield($newMarc, $field, $index);
    is($got, $expected, "postProcessMARCRecord field $field ($caption)");
}

foreach my $postProcessHoldingsTest (@postProcessHoldingsTests) {
    my($holdings, $cfg, $field, $expected, $caption) = @$postProcessHoldingsTest;
    my $newHoldings = postProcessHoldings($cfg, $holdings);
    my $got = opacFieldOrSubfield($newHoldings, $field);
    is($got, $expected, "postProcessHoldings field $field ($caption)");
}

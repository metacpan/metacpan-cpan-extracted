# Pragmas.
use strict;
use warnings;

# Modules.
use English qw(-no_match_vars);
use Tags::Output::Indent;
use Test::More 'tests' => 4;

# Test.
my $obj = Tags::Output::Indent->new;
$obj->put(
	['b', 'tag'],
	['cd', 'aaaaa<dddd>dddd'],
	['e', 'tag'],
);
my $ret = $obj->flush;
my $right_ret = "<tag>\n  <![CDATA[aaaaa<dddd>dddd]]>\n</tag>";
is($ret, $right_ret);

# Test.
$obj = Tags::Output::Indent->new(
	'cdata_indent' => 1,
);
$obj->put(
	['b', 'tag'],
	['cd', (('aaaaa<dddd>dddd') x 10)],
	['e', 'tag'], 
);
$ret = $obj->flush;
$right_ret = <<'END';
<tag>
  <![CDATA[aaaaa<dddd>ddddaaaaa<dddd>ddddaaaaa<dddd>ddddaaaaa<dddd>dddd
    aaaaa<dddd>ddddaaaaa<dddd>ddddaaaaa<dddd>ddddaaaaa<dddd>ddddaaaaa<dddd>dddd
    aaaaa<dddd>dddd]]>
</tag>
END
chomp $right_ret;
is($ret, $right_ret);

# Test.
$obj = Tags::Output::Indent->new(
	'cdata_indent' => 0,
);
$obj->put(
	['b', 'tag'],
	['cd', (('aaaaa<dddd>dddd') x 10)],
	['e', 'tag'], 
);
$ret = $obj->flush;
$right_ret = <<'END';
<tag>
  <![CDATA[aaaaa<dddd>ddddaaaaa<dddd>ddddaaaaa<dddd>ddddaaaaa<dddd>ddddaaaaa<dddd>ddddaaaaa<dddd>ddddaaaaa<dddd>ddddaaaaa<dddd>ddddaaaaa<dddd>ddddaaaaa<dddd>dddd]]>
</tag>
END
chomp $right_ret;
is($ret, $right_ret);

# Test.
$obj = Tags::Output::Indent->new;
eval {
	$obj->put(
		['b', 'tag'],
		['cd', 'aaaaa<dddd>dddd', ']]>'],
		['e', 'tag'],
	);
};
is($EVAL_ERROR, "Bad CDATA section.\n");

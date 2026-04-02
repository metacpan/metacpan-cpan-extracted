use strict;
use warnings;

use Tags::Output::Indent;
use Test::More 'tests' => 7;

# Test.
my $obj = Tags::Output::Indent->new(
	'preserved' => [],
);
$obj->put(
	['b', 'CHILD1'],
	['d', 'DATA'],
	['e', 'CHILD1'],
);
my $ret = $obj->flush;
my $right_ret = <<'END';
<CHILD1>
  DATA
</CHILD1>
END
chomp $right_ret;
is($ret, $right_ret, 'Element with data without preservation.');

# Test.
$obj = Tags::Output::Indent->new(
	'preserved' => [],
);
$obj->put(
	['b', 'MAIN'],
	['b', 'CHILD1'],
	['d', 'text'],
	['e', 'CHILD1'],
	['b', 'CHILD2'],
	['e', 'CHILD2'],
	['e', 'MAIN']
);
$ret = $obj->flush;
$right_ret = <<'END';
<MAIN>
  <CHILD1>
    text
  </CHILD1>
  <CHILD2>
  </CHILD2>
</MAIN>
END
chomp $right_ret;
is($ret, $right_ret, 'Nested element with simple data without preservation '.
	'and another element after it.');

# Test.
my $text = <<'END';
  text
     text
	text
END
$obj = Tags::Output::Indent->new(
	'preserved' => [],
);
$obj->put(
	['b', 'MAIN'],
	['b', 'CHILD1'],
	['a', 'xml:space', 'default'],
	['d', $text],
	['e', 'CHILD1'],
	['e', 'MAIN'],
);
$ret = $obj->flush;
$right_ret = <<'END';
<MAIN>
  <CHILD1 xml:space="default">
    text text text
  </CHILD1>
</MAIN>
END
chomp $right_ret;
is($ret, $right_ret, 'Element with data which has removed white characters.');

# Test.
$obj = Tags::Output::Indent->new(
	'preserved' => ['CHILD1'],
);
$obj->put(
	['b', 'CHILD1'],
	['d', 'DATA'],
	['e', 'CHILD1'],
);
$ret = $obj->flush;
$right_ret = <<'END';
<CHILD1>
DATA</CHILD1>
END
chomp $right_ret;
is($ret, $right_ret, 'Element with data with explicit preservation.');

# Test.
$obj = Tags::Output::Indent->new(
	'preserved' => ['CHILD1'],
);
$obj->put(
	['b', 'MAIN'],
	['b', 'CHILD1'],
	['d', $text],
	['e', 'CHILD1'],
	['e', 'MAIN']
);
$ret = $obj->flush;
$right_ret = <<'END';
<MAIN>
  <CHILD1>
  text
     text
	text
</CHILD1>
</MAIN>
END
chomp $right_ret;
is($ret, $right_ret, 'Nested element with multiline data with explicit preservation.');

# Test.
$obj = Tags::Output::Indent->new(
	'preserved' => ['CHILD1'],
);
$obj->put(
	['b', 'MAIN'],
	['b', 'CHILD1'],
	['d', 'text'],
	['e', 'CHILD1'],
	['e', 'MAIN']
);
$ret = $obj->flush;
$right_ret = <<'END';
<MAIN>
  <CHILD1>
text</CHILD1>
</MAIN>
END
chomp $right_ret;
is($ret, $right_ret, 'Nested element with simple data with explicit preservation.');

# Test.
$obj = Tags::Output::Indent->new(
	'preserved' => ['CHILD1'],
);
$obj->put(
	['b', 'MAIN'],
	['b', 'CHILD1'],
	['d', 'text'],
	['e', 'CHILD1'],
	['b', 'CHILD2'],
	['e', 'CHILD2'],
	['e', 'MAIN']
);
$ret = $obj->flush;
$right_ret = <<'END';
<MAIN>
  <CHILD1>
text</CHILD1>
  <CHILD2>
  </CHILD2>
</MAIN>
END
chomp $right_ret;
is($ret, $right_ret, 'Nested element with simple data with explicit preservation '.
	'and another element after it.');

# Test.
# TODO Pridat vnorene testy.
# Bude jich hromada. Viz. ex18.pl az ex24.pl v Tags::Output::Indent.

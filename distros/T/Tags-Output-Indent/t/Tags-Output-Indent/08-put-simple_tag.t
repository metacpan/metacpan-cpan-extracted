use strict;
use warnings;

use Tags::Output::Indent;
use Test::More 'tests' => 6;

# Test.
my $obj = Tags::Output::Indent->new(
	'xml' => 0,
);
$obj->put(
	['b', 'MAIN'],
	['e', 'MAIN'],
);
my $ret = $obj->flush;
my $right_ret = <<'END';
<MAIN>
</MAIN>
END
chomp $right_ret;
is($ret, $right_ret);

# Test.
$obj->reset;
$obj->put(
	['b', 'MAIN'],
	['a', 'id', 'id_value'],
	['e', 'MAIN'],
);
$ret = $obj->flush;
$right_ret = <<'END';
<MAIN id="id_value">
</MAIN>
END
chomp $right_ret;
is($ret, $right_ret);

# Test.
$obj->reset;
$obj->put(
	['b', 'MAIN'],
	['a', 'id', 'id_value'],
	['e', 'MAIN'],
	['b', 'MAIN'],
	['a', 'id', 'id_value2'],
	['e', 'MAIN']
);
$ret = $obj->flush;
$right_ret = <<'END';
<MAIN id="id_value">
</MAIN>
<MAIN id="id_value2">
</MAIN>
END
chomp $right_ret;
is($ret, $right_ret);

# Test.
$obj = Tags::Output::Indent->new(
	'xml' => 1,
);
$obj->put(
	['b', 'main'],
	['e', 'main'],
);
$ret = $obj->flush;
is($ret, '<main />');

# Test.
$obj->reset;
$obj->put(
	['b', 'main'],
	['a', 'id', 'id_value'],
	['e', 'main'],
);
$ret = $obj->flush;
is($ret, '<main id="id_value" />');

# Test.
$obj->reset;
$obj->put(
	['b', 'main'],
	['a', 'id', 'id_value'],
	['e', 'main'],
	['b', 'main'],
	['a', 'id', 'id_value2'],
	['e', 'main'],
);
$ret = $obj->flush;
$right_ret = <<'END';
<main id="id_value" />
<main id="id_value2" />
END
chomp $right_ret;
is($ret, $right_ret);

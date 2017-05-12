# Pragmas.
use strict;
use warnings;

# Modules.
use Tags::Output::PYX;
use Test::More 'tests' => 7;
use Test::NoWarnings;

# Test.
my $obj = Tags::Output::PYX->new;
$obj->put(
	['b', 'MAIN'],
	['e', 'MAIN'],
);
my $ret = $obj->flush;
my $right_ret = <<'END';
(MAIN
)MAIN
END
chomp $right_ret;
is($ret, $right_ret, 'Simple element in uppercase form.');

# Test.
$obj->reset;
$obj->put(
	['b', 'MAIN'],
	['a', 'id', 'id_value'],
	['e', 'MAIN'],
);
$ret = $obj->flush;
$right_ret = <<'END';
(MAIN
Aid id_value
)MAIN
END
chomp $right_ret;
is($ret, $right_ret, 'Simple element with attribute in uppercase form.');

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
(MAIN
Aid id_value
)MAIN
(MAIN
Aid id_value2
)MAIN
END
chomp $right_ret;
is($ret, $right_ret, 'Two elements with attributes in uppercase form.');

# Test.
$obj->reset;
$obj->put(
	['b', 'main'],
	['e', 'main'],
);
$ret = $obj->flush;
$right_ret = <<'END';
(main
)main
END
chomp $right_ret;
is($ret, $right_ret, 'Simple element in lowercase form.');

# Test.
$obj->reset;
$obj->put(
	['b', 'main'],
	['a', 'id', 'id_value'],
	['e', 'main'],
);
$ret = $obj->flush;
$right_ret = <<'END';
(main
Aid id_value
)main
END
chomp $right_ret;
is($ret, $right_ret, 'Simple element with attribute in lowercase form.');

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
(main
Aid id_value
)main
(main
Aid id_value2
)main
END
chomp $right_ret;
is($ret, $right_ret, 'Two elements with attributes in lowercase form.');

use strict;
use warnings;

use Tags::Output::LibXML;
use Test::More 'tests' => 6;
use Test::NoWarnings;

# Test.
my $obj = Tags::Output::LibXML->new;
$obj->put(
	['b', 'MAIN'],
	['d', 'data'],
	['e', 'MAIN'],
);
my $ret = $obj->flush;
my $right_ret = <<'END';
<?xml version="1.1" encoding="UTF-8"?>
<MAIN>data</MAIN>
END
is($ret, $right_ret);

# Test.
$obj = Tags::Output::LibXML->new;
$obj->put(
	['b', 'MAIN'],
	['a', 'id', 'id_value'],
	['d', 'data'],
	['e', 'MAIN'],
);
$ret = $obj->flush;
$right_ret = <<'END';
<?xml version="1.1" encoding="UTF-8"?>
<MAIN id="id_value">data</MAIN>
END
is($ret, $right_ret);

# Test.
$obj->reset;
$obj->put(
	['b', 'MAIN'], 
	['a', 'id', 0], 
	['d', 'data'], 
	['e', 'MAIN'],
);
$ret = $obj->flush;
$right_ret = <<'END';
<?xml version="1.1" encoding="UTF-8"?>
<MAIN id="0">data</MAIN>
END
is($ret, $right_ret);

# Test.
my $long_data = 'a' x 1000;
$obj = Tags::Output::LibXML->new;
$obj->put(
	['b', 'MAIN'],
	['d', $long_data],
	['e', 'MAIN'],
);
$ret = $obj->flush;
$right_ret = <<"END";
<?xml version="1.1" encoding="UTF-8"?>
<MAIN>$long_data</MAIN>
END
is($ret, $right_ret);

# Test.
$long_data = 'aaaa ' x 1000;
$obj = Tags::Output::LibXML->new;
$obj->put(
	['b', 'MAIN'],
	['d', $long_data],
	['e', 'MAIN'],
);
$ret = $obj->flush;
$right_ret = <<"END";
<?xml version="1.1" encoding="UTF-8"?>
<MAIN>$long_data</MAIN>
END
is($ret, $right_ret);

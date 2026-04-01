use strict;
use warnings;

use Tags::Output::LibXML;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $obj = Tags::Output::LibXML->new;
$obj->put(
	['b', 'element'],
);
$obj->finalize;
my $ret = $obj->flush;
my $right_ret = <<'END';
<?xml version="1.1" encoding="UTF-8"?>
<element/>
END
is($ret, $right_ret, 'Finalize open element.');

# Test.
$obj = Tags::Output::LibXML->new;
$obj->put(
	['b', 'element'],
	['e', 'element'],
);
$obj->finalize;
$ret = $obj->flush;
$right_ret = <<'END';
<?xml version="1.1" encoding="UTF-8"?>
<element/>
END
is($ret, $right_ret, 'Finalize element.');

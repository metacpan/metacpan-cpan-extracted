use strict;
use warnings;

use Tags::Output::PYX;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
my $obj = Tags::Output::PYX->new;
$obj->put(
	['c', 'comment'],
	['c', ' comment '],
);
my $ret = $obj->flush;
my $right_ret = <<'END';
-<!--comment-->
-<!-- comment -->
END
chomp $right_ret;
is($ret, $right_ret, 'Simple comment test.');

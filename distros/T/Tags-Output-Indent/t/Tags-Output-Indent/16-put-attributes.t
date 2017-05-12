# Pragmas.
use strict;
use warnings;

# Modules.
use Tags::Output::Indent;
use Test::More 'tests' => 1;

# Test.
my $obj = Tags::Output::Indent->new(
	'xml' => 1,
);
$obj->put(
	['b', 'foo'],
	['a', 'one', '...........................'],
	['a', 'two', '...........................'],
	['a', 'three', '.........................'],
	['e', 'foo'],
);
my $ret = $obj->flush;
my $right_ret = <<'END';
<foo one="..........................." two="..........................." three=
  "........................." />
END
chomp $right_ret;
is($ret, $right_ret);

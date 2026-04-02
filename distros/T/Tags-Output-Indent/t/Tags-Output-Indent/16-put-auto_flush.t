use strict;
use warnings;

use File::Object;
use IO::Scalar;
use Tags::Output::Indent;
use Test::More 'tests' => 5;

# Test.
my $obj = Tags::Output::Indent->new(
	'auto_flush' => 1,
	'output_handler' => \*STDOUT,
	'xml' => 1,
);
my $ret;
tie *STDOUT, 'IO::Scalar', \$ret;
$obj->put(
	['b', 'tag'],
	['e', 'tag'],
);
untie *STDOUT;
my $right_ret = '<tag />';
is($ret, $right_ret);

# Test.
$obj->reset;
undef $ret;
tie *STDOUT, 'IO::Scalar', \$ret;
$obj->put(['b', 'tag']);
$obj->put(['e', 'tag']);
untie *STDOUT;
is($ret, $right_ret);

# Test.
$obj->reset;
undef $ret;
tie *STDOUT, 'IO::Scalar', \$ret;
$obj->put(
	['b', 'tag'],
	['d', 'data'],
	['e', 'tag'],
);
untie *STDOUT;
$right_ret = <<'END';
<tag>
  data
</tag>
END
chomp $right_ret;
is($ret, $right_ret);

# Test.
$obj->reset;
undef $ret;
tie *STDOUT, 'IO::Scalar', \$ret;
$obj->put(
	['b', 'tag'],
	['b', 'other_tag'],
	['d', 'data'],
	['e', 'other_tag'],
	['e', 'tag'],
);
untie *STDOUT;
$right_ret = <<'END';
<tag>
  <other_tag>
    data
  </other_tag>
</tag>
END
chomp $right_ret;
is($ret, $right_ret);

# Test.
$obj->reset;
undef $ret;
tie *STDOUT, 'IO::Scalar', \$ret;
$obj->put(['b', 'tag']);
$obj->put(['b', 'other_tag']);
$obj->put(['d', 'data']);
$obj->put(['e', 'other_tag']);
$obj->put(['e', 'tag']);
untie *STDOUT;
is($ret, $right_ret);

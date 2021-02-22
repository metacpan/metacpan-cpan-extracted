use strict;
use warnings;

use File::Object;
use PYX::Optimization;
use Test::More 'tests' => 7;
use Test::NoWarnings;
use Test::Output;

# Directories.
my $data_dir = File::Object->new->up->dir('data');

# Test.
my $obj = PYX::Optimization->new;
my $right_ret = <<"END";
_comment
_comment
_comment
_comment
_comment
_comment
END
stdout_is(
	sub {
		$obj->parse_file($data_dir->file('ex1.pyx')->s);
		return;
	},
	$right_ret,
	'Dfferent comments which are cleaned.',
);

# Test.
$right_ret = <<"END";
-data
-data
-data
-data
-data
-data
END
stdout_is(
	sub {
		$obj->parse_file($data_dir->file('ex2.pyx')->s);
		return;
	},
	$right_ret,
	'Different data which are cleaned (simple).',
);

# Test.
$right_ret = <<"END";
-data data
-data data
-data data
-data data
-data data
-data data
END
stdout_is(
	sub {
		$obj->parse_file($data_dir->file('ex4.pyx')->s);
		return;
	},
	$right_ret,
	'Different data which are cleaned (multiple).',
);

# Test.
$right_ret = <<"END";
_comment
(tag
Aattr value
-data
)tag
?app vskip="10px"
END
stdout_is(
	sub {
		$obj->parse_file($data_dir->file('ex3.pyx')->s);
		return;
	},
	$right_ret,
	'Complex data which are cleaned.',
);

# Test.
$right_ret = <<'END';
-žluťoučký
-žluťoučký
-žluťoučký
-žluťoučký
-žluťoučký
-žluťoučký
END
stdout_is(
	sub {
		$obj->parse_file($data_dir->file('ex6.pyx')->s);
		return;
	},
	$right_ret,
	'Different data which are cleaned (simple - utf8).',
);

# Test.
$right_ret = <<'END';
(žlutá
Aattr červená
)žlutá
?app color=červená
END
stdout_is(
	sub {
		$obj->parse_file($data_dir->file('ex7.pyx')->s);
		return;
	},
	$right_ret,
	'PYX rewrite in utf8.',
);

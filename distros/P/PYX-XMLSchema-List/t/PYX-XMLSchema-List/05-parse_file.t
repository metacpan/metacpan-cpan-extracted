# Pragmas.
use strict;
use warnings;

# Modules.
use File::Object;
use PYX::XMLSchema::List;
use Test::More 'tests' => 4;
use Test::NoWarnings;
use Test::Output;

# Directories.
my $data_dir = File::Object->new->up->dir('data');

# Test.
my $obj = PYX::XMLSchema::List->new;
my $right_ret = <<"END";
No XML schemas.
END
stdout_is(
	sub {
		$obj->parse_file($data_dir->file('ex1.pyx')->s);
		return;
	},
	$right_ret,
	'Parse ex1.pyx file.',
);

# Test.
$right_ret = <<'END';
[ bar ] (E: 0000, A: 0001) http://bar.foo
[ fo  ] (E: 0001, A: 0001) http://foo.bar
[ xml ] (E: 0000, A: 0001)
END
stdout_is(
	sub {
		$obj->parse_file($data_dir->file('ex2.pyx')->s);
		return;
	},
	$right_ret,
	'Parse ex2.pyx file.',
);
$obj->reset;

# Test.
$right_ret = <<'END';
[ foo ] (E: 0001, A: 0000) http://foo
END
stdout_is(
	sub {
		$obj->parse_file($data_dir->file('ex3.pyx')->s);
		return;
	},
	$right_ret,
	'Parse ex3.pyx file.',
);
$obj->reset;

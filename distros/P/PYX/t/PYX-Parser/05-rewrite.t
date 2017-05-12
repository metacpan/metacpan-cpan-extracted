# Pragmas.
use strict;
use warnings;

# Modules.
use File::Object;
use PYX::Parser;
use Test::More 'tests' => 14;
use Test::NoWarnings;
use Test::Output;

# Directories.
my $data_dir = File::Object->new->up->dir('data');

# Test.
my $obj = PYX::Parser->new(
	'output_rewrite' => 1,
);
my $right_ret = <<'END';
-char
END
stdout_is(
	sub {
		$obj->parse_file($data_dir->file('char1.pyx')->s);
		return;
	},
	$right_ret,
);

# Test.
$right_ret = <<'END';
-char\nchar
END
stdout_is(
	sub {
		$obj->parse_file($data_dir->file('char2.pyx')->s);
		return;
	},
	$right_ret,
);

# Test.
$right_ret = <<'END';
(tag
END
stdout_is(
	sub {
		$obj->parse_file($data_dir->file('start_tag1.pyx')->s);
		return;
	},
	$right_ret,
);

# Test.
$right_ret = <<'END';
(tag
Apar val
END
stdout_is(
	sub {
		$obj->parse_file($data_dir->file('start_tag2.pyx')->s);
		return;
	},
	$right_ret,
);

# Test.
$right_ret = <<'END';
(tag
Apar val\nval
END
stdout_is(
	sub {
		$obj->parse_file($data_dir->file('start_tag3.pyx')->s);
		return;
	},
	$right_ret,
);

# Test.
$right_ret = <<'END';
(prefix:tag
END
stdout_is(
	sub {
		$obj->parse_file($data_dir->file('start_tag4.pyx')->s);
		return;
	},
	$right_ret,
);

# Test.
$right_ret = <<'END';
(prefix:tag
Aprefix:par val
END
stdout_is(
	sub {
		$obj->parse_file($data_dir->file('start_tag5.pyx')->s);
		return;
	},
	$right_ret,
);

# Test.
$right_ret = <<'END';
)tag
END
stdout_is(
	sub {
		$obj->parse_file($data_dir->file('end_tag1.pyx')->s);
		return;
	},
	$right_ret,
);

# Test.
$right_ret = <<'END';
?target code
END
stdout_is(
	sub {
		$obj->parse_file($data_dir->file('instruction1.pyx')->s);
		return;
	},
	$right_ret,
);

# Test.
$right_ret = <<'END';
?target data\ndata
END
stdout_is(
	sub {
		$obj->parse_file($data_dir->file('instruction2.pyx')->s);
		return;
	},
	$right_ret,
);

# Test.
$right_ret = <<'END';
_comment
END
stdout_is(
	sub {
		$obj->parse_file($data_dir->file('comment1.pyx')->s);
		return;
	},
	$right_ret,
);

# Test.
$right_ret = <<'END';
_comment\ncomment
END
stdout_is(
	sub {
		$obj->parse_file($data_dir->file('comment2.pyx')->s);
		return;
	},
	$right_ret,
);

# Test.
$right_ret = <<'END';
(xml
-text
)xml
END
stdout_is(
	sub {
		$obj->parse_file($data_dir->file('example5.pyx')->s);
		return;
	},
	$right_ret,
);

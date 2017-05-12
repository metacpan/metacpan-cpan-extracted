# Pragmas.
use strict;
use warnings;

# Modules.
use File::Object;
use PYX::XMLNorm;
use Test::More 'tests' => 8;
use Test::Output;

# Directories.
my $data_dir = File::Object->new->up->dir('data');

# Test.
my $rules_hr = {
	'*' => ['br', 'hr', 'link', 'meta', 'input'],
	'html' => ['body'],
	'table' => ['td', 'tr'],
	'td' => ['td'],
	'th' => ['th'],
	'tr' => ['td', 'th', 'tr'],
};
my $obj = PYX::XMLNorm->new(
	'rules' => $rules_hr,
);
my $right_ret = <<'END';
(html
(head
(link
)link
(meta
)meta
)head
(body
(input
)input
(br
)br
(hr
)hr
)body
)html
END
stdout_is(
	sub {
		$obj->parse_file($data_dir->file('ex1.pyx')->s);
		return;
	},
	$right_ret,
	'Multiple opened elements.',
);

# Test.
$right_ret = <<'END';
(table
(tr
(td
-example1
)td
(td
-example2
)td
)tr
(tr
(td
-example1
)td
(td
-example2
)td
)tr
)table
END
stdout_is(
	sub {
		$obj->parse_file($data_dir->file('ex2.pyx')->s);
		return;
	},
	$right_ret,
	'Table td opened elements.',
);

# Test.
stdout_is(
	sub {
		$obj->parse_file($data_dir->file('ex3.pyx')->s);
		return;
	},
	$right_ret,
	'Table td opened elements.',
);

# Test.
$right_ret = <<'END';
(html
(head
(LINK
)LINK
(meta
)meta
(META
)META
)head
(body
(input
)input
(br
)br
(BR
)BR
(hr
)hr
(hr
)hr
)body
)html
END
stdout_is(
	sub {
		$obj->parse_file($data_dir->file('ex4.pyx')->s);
		return;
	},
	$right_ret,
	'Multiple opened elements (upper and lower case names).',
);

SKIP: {
	skip 'Some problem.', 1;

# Test.
$right_ret = <<'END';
(td
(table
(tr
(td
-text1
)td
(td
-text2
)td
)tr
)table
)td
END
stdout_is(
	sub {
		$obj->parse_file($data_dir->file('ex5.pyx')->s);
		return;
	},
	$right_ret,
	'td with table problem.',
);
};

# Test.
$right_ret = <<'END';
(br
)br
-text
END
stdout_is(
	sub {
		$obj->parse_file($data_dir->file('ex6.pyx')->s);
		return;
	},
	$right_ret,
	'Simple opened br with data after it.',
);

# Test.
$right_ret = <<'END';
(br
)br
(br
)br
-text
END
stdout_is(
	sub {
		$obj->parse_file($data_dir->file('ex7.pyx')->s);
		return;
	},
	$right_ret,
	'Multiple opened br with data after its.',
);

# Test.
$right_ret = <<'END';
(table
(tr
(td
-text
)td
)tr
)table
END
stdout_is(
	sub {
		$obj->parse_file($data_dir->file('ex8.pyx')->s);
		return;
	},
	$right_ret,
	'Simple table with opened tr and td.',
);

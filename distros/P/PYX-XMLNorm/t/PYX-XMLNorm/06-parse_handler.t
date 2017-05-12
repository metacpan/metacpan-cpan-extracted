# Pragmas.
use strict;
use warnings;

# Modules.
use File::Object;
use PYX::XMLNorm;
use Test::More 'tests' => 1;
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
my $ex1_file = $data_dir->file('ex1.pyx')->s;
open my $inf, '<', $ex1_file;
stdout_is(
	sub {
		$obj->parse_handler($inf);
		return;
	},
	$right_ret,
	'Simple test for parse_handler() method.',
);
close $inf;

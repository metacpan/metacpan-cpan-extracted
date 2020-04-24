use strict;
use warnings;

use File::Object;
use SGML::PYX;
use Test::More 'tests' => 5;
use Test::NoWarnings;
use Test::Output;

# Directories.
my $data_dir = File::Object->new->up->dir('data');

# Test.
my $obj = SGML::PYX->new;
my $right_ret = <<'END';
-<element />
END
stdout_is(
	sub {
		$obj->parsefile($data_dir->file('cdata1.sgml')->s);
		return;
	},
	$right_ret,
	'Test single character data.',
);

# Test.
$obj = SGML::PYX->new;
$right_ret = <<'END';
-<element />
END
stdout_is(
	sub {
		$obj->parsefile($data_dir->file('cdata2.sgml')->s);
		return;
	},
	$right_ret,
	'Test single character data - lower case version.',
);

# Test.
$obj = SGML::PYX->new;
$right_ret = <<'END';
-\n<element/>\n
END
stdout_is(
	sub {
		$obj->parsefile($data_dir->file('cdata3.sgml')->s);
		return;
	},
	$right_ret,
	'Test single character data - data in block.',
);

# Test.
$obj = SGML::PYX->new;
$right_ret = <<'END';
-\n<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN"\n  "http://www.w3.org/TR/html4/strict.dtd">\n<html>\n<body>\n\n<script>\nfunction add() {\n  google.calendar.addCalendar("en.usa#holiday@group.v.calendar.google.com",\n      "US Holidays");\n}\n</script>\n\n<center>\n<button onclick="add()">Add US Holidays</button>\n</center>\n\n</body>\n</html>\n
END
stdout_is(
	sub {
		$obj->parsefile($data_dir->file('cdata4.sgml')->s);
		return;
	},
	$right_ret,
	'Test single character data - Big CDATA section.',
);

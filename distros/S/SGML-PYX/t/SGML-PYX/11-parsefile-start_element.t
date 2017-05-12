# Pragmas.
use strict;
use warnings;

# Modules.
use File::Object;
use SGML::PYX;
use Test::More 'tests' => 21;
use Test::NoWarnings;
use Test::Output;

# Directories.
my $data_dir = File::Object->new->up->dir('data');

# Test.
my $obj = SGML::PYX->new;
my $right_ret = <<'END';
(element
END
stdout_is(
	sub {
		$obj->parsefile($data_dir->file('start_element01.sgml')->s);
		return;
	},
	$right_ret,
	'Test start of element.',
);

# Test.
$obj = SGML::PYX->new;
$right_ret = <<'END';
(element
Apar val
END
stdout_is(
	sub {
		$obj->parsefile($data_dir->file('start_element02.sgml')->s);
		return;
	},
	$right_ret,
	'Test start of element with attribute.',
);

# Test.
$obj = SGML::PYX->new;
$right_ret = <<'END';
(element
Apar val\nval
END
stdout_is(
	sub {
		$obj->parsefile($data_dir->file('start_element03.sgml')->s);
		return;
	},
	$right_ret,
	'Test start of element with advanced attribute.',
);

# Test.
$obj = SGML::PYX->new;
$right_ret = <<'END';
(prefix:element
END
stdout_is(
	sub {
		$obj->parsefile($data_dir->file('start_element04.sgml')->s);
		return;
	},
	$right_ret,
	'Test start of prefixed element.',
);

# Test.
$obj = SGML::PYX->new;
$right_ret = <<'END';
(prefix:element
Aprefix:par val
END
stdout_is(
	sub {
		$obj->parsefile($data_dir->file('start_element05.sgml')->s);
		return;
	},
	$right_ret,
	'Test start of prefixed element with prefixed attribute.',
);

# Test.
$obj = SGML::PYX->new;
$right_ret = <<'END';
(element
Apar val
END
stdout_is(
	sub {
		$obj->parsefile($data_dir->file('start_element06.sgml')->s);
		return;
	},
	$right_ret,
	'Test start of element with attribute with extra spaces.',
);

# Test.
$obj = SGML::PYX->new;
$right_ret = <<'END';
(element
AonClick javascript:window.open('/url', 'key', 'par1=val1,par2=val2'); return false;
END
stdout_is(
	sub {
		$obj->parsefile($data_dir->file('start_element07.sgml')->s);
		return;
	},
	$right_ret,
	'Test start of element with Javascript attribute.',
);

# Test.
$obj = SGML::PYX->new;
$right_ret = <<'END';
(ELEMENT
END
stdout_is(
	sub {
		$obj->parsefile($data_dir->file('start_element08.sgml')->s);
		return;
	},
	$right_ret,
	'Test start of element writed in upper-case.',
);

# Test.
$obj = SGML::PYX->new;
$right_ret = <<'END';
(element
Achecked checked
END
stdout_is(
	sub {
		$obj->parsefile($data_dir->file('start_element09.sgml')->s);
		return;
	},
	$right_ret,
	'Test start of element with attribute without value.',
);

# Test.
$obj = SGML::PYX->new;
$right_ret = <<'END';
(element
Achecked checked
Apar val
END
stdout_is(
	sub {
		$obj->parsefile($data_dir->file('start_element10.sgml')->s);
		return;
	},
	$right_ret,
	'Test start of element with attribute without value.',
);

# Test.
$obj = SGML::PYX->new;
$right_ret = <<'END';
(element
Apar val
Achecked checked
END
stdout_is(
	sub {
		$obj->parsefile($data_dir->file('start_element11.sgml')->s);
		return;
	},
	$right_ret,
	'Test start of element with attribute without value.',
);

# Test.
$obj = SGML::PYX->new;
$right_ret = <<'END';
(element
Apar1 val1
Achecked checked
Apar2 val2
END
stdout_is(
	sub {
		$obj->parsefile($data_dir->file('start_element12.sgml')->s);
		return;
	},
	$right_ret,
	'Test start of element with attribute without value.',
);

# Test.
$obj = SGML::PYX->new;
$right_ret = <<'END';
(element
A_para-me.ter foo
A:para-me.ter bar
END
stdout_is(
	sub {
		$obj->parsefile($data_dir->file('start_element13.sgml')->s);
		return;
	},
	$right_ret,
	'Test start of element with special characters in attribute.',
);

# Test.
$obj = SGML::PYX->new;
$right_ret = <<'END';
(element
Apar 0
END
stdout_is(
	sub {
		$obj->parsefile($data_dir->file('start_element14.sgml')->s);
		return;
	},
	$right_ret,
	'Test start of element with attribute without »\'« and »"«.',
);

# Test.
$obj = SGML::PYX->new;
$right_ret = <<'END';
(element
Apar val
END
stdout_is(
	sub {
		$obj->parsefile($data_dir->file('start_element15.sgml')->s);
		return;
	},
	$right_ret,
	'Test start of element with attribute without »\'« and »"«.',
);
# Test.
$obj = SGML::PYX->new;
$right_ret = <<'END';
(element
Apar 
END
stdout_is(
	sub {
		$obj->parsefile($data_dir->file('start_element16.sgml')->s);
		return;
	},
	$right_ret,
	'Test start of element with blank attribute (\').',
);

# Test.
$obj = SGML::PYX->new;
$right_ret = <<'END';
(element
Apar 
END
stdout_is(
	sub {
		$obj->parsefile($data_dir->file('start_element17.sgml')->s);
		return;
	},
	$right_ret,
	'Test start of element with blank attribute (").',
);

# Test.
$obj = SGML::PYX->new;
$right_ret = <<'END';
(element
Apar 
END
stdout_is(
	sub {
		$obj->parsefile($data_dir->file('start_element18.sgml')->s);
		return;
	},
	$right_ret,
	'Test start of element with blank attribute without quotes #1.',
);

# Test.
$obj = SGML::PYX->new;
$right_ret = <<'END';
(element
Apar 
END
stdout_is(
	sub {
		$obj->parsefile($data_dir->file('start_element19.sgml')->s);
		return;
	},
	$right_ret,
	'Test start of element with blank attribute without quotes #2.',
);

# Test.
$obj = SGML::PYX->new;
$right_ret = <<'END';
(element
Apar 
END
stdout_is(
	sub {
		$obj->parsefile($data_dir->file('start_element20.sgml')->s);
		return;
	},
	$right_ret,
	'Test start of element with blank attribute without quotes #3.',
);

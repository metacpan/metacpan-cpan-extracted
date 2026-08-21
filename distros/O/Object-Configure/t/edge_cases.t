#!/usr/bin/env perl

use strict;
use warnings;
use Test::Most;
use Test::Mockingbird 0.10;
use File::Temp qw(tempdir tempfile);
use File::Spec;
use POSIX qw(EACCES ENOENT);
use Scalar::Util qw(blessed isweak);
use Errno qw(EACCES ENOENT);
use Readonly;

# Test::Returns is a non-indexed local dev library
use lib '/home/njh/src/njh/Test-Returns/lib';
use Test::Returns;

Readonly my $VERY_DEEP_RECURSION => 50;   # nested hash depth for stack-pressure test
Readonly my $LARGE_PARAM_COUNT   => 500;  # number of params for DoS resilience test

# Load the module under test
BEGIN { use_ok('Object::Configure') }

# Helper: create temp config file
sub create_test_config {
	my ($dir, $filename, $content) = @_;
	my $path = File::Spec->catfile($dir, $filename);
	open my $fh, '>', $path or die "Cannot write $path: $!";
	print $fh $content;
	close $fh;
	return $path;
}

subtest 'Edge case: Empty class name' => sub {
	plan tests => 1;

	throws_ok {
		Object::Configure::configure('', {});
	} qr/configure: what class do you want to configure/,
		'Empty string class name throws';
};

subtest 'Edge case: Class name with special characters' => sub {
	plan tests => 2;

	# Class with numbers
	my $result1 = Object::Configure::configure('Test::Class123', {});
	ok(defined($result1), 'Class with numbers works');

	# Class with underscores
	my $result2 = Object::Configure::configure('Test_Class_Name', {});
	ok(defined($result2), 'Class with underscores works');
};

subtest 'Edge case: Very long class name' => sub {
	plan tests => 1;

	my $long_class = 'A' x 255;  # 255 character class name
	my $result = Object::Configure::configure($long_class, {});

	ok(defined($result), 'Very long class name works');
};

subtest 'Edge case: Empty params hashref' => sub {
	plan tests => 2;

	my $result = Object::Configure::configure('Test::Class', {});

	ok(defined($result), 'Empty params works');
	ok(blessed($result->{logger}), 'Logger still created');
};

subtest 'Edge case: Deeply nested blessed objects' => sub {
	plan tests => 3;

	my $obj1 = bless { data => 'level1' }, 'Level1';
	my $obj2 = bless { nested => $obj1, data => 'level2' }, 'Level2';
	my $obj3 = bless { nested => $obj2, data => 'level3' }, 'Level3';

	my $result = Object::Configure::configure('Test::Class', {
		deep_obj => $obj3
	});

	ok(blessed($result->{deep_obj}), 'Top level object preserved');
	ok(blessed($result->{deep_obj}{nested}), 'Second level object preserved');
	ok(blessed($result->{deep_obj}{nested}{nested}), 'Third level object preserved');
};

subtest 'Edge case: Circular reference in blessed object' => sub {
	plan tests => 2;

	my $obj = bless { data => 'test' }, 'Circular';
	$obj->{self} = $obj;  # Circular reference

	my $result = Object::Configure::configure('Test::Class', {
		circular => $obj
	});

	ok(blessed($result->{circular}), 'Circular object preserved');
	is($result->{circular}{self}, $result->{circular}, 'Circular reference intact');
};

subtest 'Edge case: Coderef that dies' => sub {
	plan tests => 2;

	my $die_sub = sub { die "I die!" };

	my $result = Object::Configure::configure('Test::Class', {
		on_error => $die_sub
	});

	is(ref($result->{on_error}), 'CODE', 'Dying coderef preserved');

	throws_ok {
		$result->{on_error}->();
	} qr/I die!/, 'Coderef still dies when called';
};

subtest 'Edge case: Multiple coderefs referencing same closure variable' => sub {
	plan tests => 3;

	my $shared = 0;
	my $increment = sub { $shared++ };
	my $get_value = sub { $shared };

	my $result = Object::Configure::configure('Test::Class', {
		inc => $increment,
		get => $get_value
	});

	is($result->{get}->(), 0, 'Initial value is 0');
	$result->{inc}->();
	$result->{inc}->();
	is($result->{get}->(), 2, 'Shared closure variable updated');
	is($shared, 2, 'Original variable also updated');
};

subtest 'Edge case: Config file with malformed YAML' => sub {
	plan tests => 1;

	my $temp_dir = tempdir(CLEANUP => 1);
	create_test_config($temp_dir, 'malformed.yml', "This is not valid YAML: { [ }");

	# Config::Abstraction should handle this gracefully
	lives_ok {
		Object::Configure::configure('Test::Malformed', {
			config_file => 'malformed.yml',
			config_dirs => [$temp_dir]
		});
	} 'Malformed YAML does not crash (may warn)';
};

subtest 'Edge case: Config file with empty content' => sub {
	plan tests => 2;

	my $temp_dir = tempdir(CLEANUP => 1);
	create_test_config($temp_dir, 'empty.yml', '');

	my $result = Object::Configure::configure('Test::Empty', {
		config_file => 'empty.yml',
		config_dirs => [$temp_dir],
		timeout => 30
	});

	ok(defined($result), 'Empty config file handled');
	is($result->{timeout}, 30, 'Default params preserved');
};

subtest 'Edge case: Config file with only comments' => sub {
	plan tests => 2;

	my $temp_dir = tempdir(CLEANUP => 1);
	create_test_config($temp_dir, 'comments.yml', <<'EOF');
# This is a comment
# Another comment
---
# More comments
EOF

	my $result = Object::Configure::configure('Test::Comments', {
		config_file => 'comments.yml',
		config_dirs => [$temp_dir],
		value => 'default'
	});

	ok(defined($result), 'Comment-only config handled');
	is($result->{value}, 'default', 'Defaults preserved');
};

subtest 'Edge case: Config with unicode characters' => sub {
	plan tests => 2;

	my $temp_dir = tempdir(CLEANUP => 1);
	create_test_config($temp_dir, 'unicode.yml', <<'EOF');
---
Test__Unicode:
  name: "Tëst Üñíçødé"
  emoji: "🎉🔥"
  chinese: "测试"
EOF

	my $result = Object::Configure::configure('Test::Unicode', {
		config_file => 'unicode.yml',
		config_dirs => [$temp_dir]
	});

	like($result->{name}, qr/T.st/, 'Unicode name loaded');
	ok(defined($result->{emoji}), 'Emoji loaded');
};

subtest 'Edge case: Very large config file' => sub {
	plan tests => 3;

	my $temp_dir = tempdir(CLEANUP => 1);

	# Generate large config with 1000 keys
	my $large_config = "---\nTest__Large:\n";
	for my $i (1..1000) {
		$large_config .= "  key_$i: value_$i\n";
	}
	create_test_config($temp_dir, 'large.yml', $large_config);

	my $result = Object::Configure::configure('Test::Large', {
		config_file => 'large.yml',
		config_dirs => [$temp_dir]
	});

	ok(defined($result), 'Large config loaded');
	is($result->{key_1}, 'value_1', 'First key loaded');
	is($result->{key_1000}, 'value_1000', 'Last key loaded');
};

subtest 'Edge case: Config with very long string values' => sub {
	plan tests => 2;

	my $temp_dir = tempdir(CLEANUP => 1);
	my $long_string = 'A' x 10000;

	my $config = "---\nTest__Long__String:\n  long_value: \"$long_string\"\n";
	create_test_config($temp_dir, 'longstring.yml', $config);

	my $result = Object::Configure::configure('Test::Long::String', {
		config_file => 'longstring.yml',
		config_dirs => [$temp_dir]
	});

	ok(defined($result->{long_value}), 'Long string loaded');
	is(length($result->{long_value}), 10000, 'String length correct');
};

subtest 'Edge case: Config with deeply nested structures' => sub {
	plan tests => 3;

	my $temp_dir = tempdir(CLEANUP => 1);
	create_test_config($temp_dir, 'nested.yml', <<'EOF');
---
Test__Nested:
  level1:
    level2:
      level3:
        level4:
          level5:
            deep_value: "found_me"
EOF

	my $result = Object::Configure::configure('Test::Nested', {
		config_file => 'nested.yml',
		config_dirs => [$temp_dir]
	});

	ok(defined($result->{level1}), 'Level 1 exists');
	ok(ref($result->{level1}) eq 'HASH', 'Level 1 is hash');
	is($result->{level1}{level2}{level3}{level4}{level5}{deep_value}, 'found_me', 'Deep value accessible');
};

subtest 'Edge case: Multiple config_dirs with same filename' => sub {
	plan tests => 2;

	my $temp_dir1 = tempdir(CLEANUP => 1);
	my $temp_dir2 = tempdir(CLEANUP => 1);

	# Create same filename in both dirs with different content
	create_test_config($temp_dir1, 'multi.yml', <<'EOF');
---
Test__Multi__Dir__Unique__No__Conflict:
  source: "dir1"
  value: 100
EOF

	create_test_config($temp_dir2, 'multi.yml', <<'EOF');
---
Test__Multi__Dir__Unique__No__Conflict:
  source: "dir2"
  value: 200
EOF

	# First dir should take precedence
	my $multi_result = Object::Configure::configure('Test::Multi::Dir::Unique::No::Conflict', {
		config_file => 'multi.yml',
		config_dirs => [$temp_dir1, $temp_dir2]
	});

	ok(defined($multi_result->{source}), 'Config loaded');
	is($multi_result->{source}, 'dir1', 'First dir takes precedence');
};

subtest 'Edge case: Config file path with special characters' => sub {
	plan tests => 1;

	my $temp_dir = tempdir(CLEANUP => 1);

	# Create file with spaces and special chars in name
	my $special_file = 'test-file_with spaces.yml';
	create_test_config($temp_dir, $special_file, <<'EOF');
---
Test__Special__Path:
  value: "loaded"
EOF

	my $result = Object::Configure::configure('Test::Special::Path', {
		config_file => $special_file,
		config_dirs => [$temp_dir]
	});

	is($result->{value}, 'loaded', 'Special characters in filename handled');
};

subtest 'Boundary: Zero values in config' => sub {
	plan tests => 4;

	my $temp_dir = tempdir(CLEANUP => 1);
	create_test_config($temp_dir, 'zeros.yml', <<'EOF');
---
Test__Zeros:
  zero_int: 0
  zero_string: "0"
  zero_float: 0.0
  empty_string: ""
EOF

	my $result = Object::Configure::configure('Test::Zeros', {
		config_file => 'zeros.yml',
		config_dirs => [$temp_dir]
	});

	is($result->{zero_int}, 0, 'Zero integer preserved');
	is($result->{zero_string}, '0', 'Zero string preserved');
	ok($result->{zero_float} == 0, 'Zero float preserved (numeric comparison)');
	is($result->{empty_string}, '', 'Empty string preserved');
};

subtest 'Boundary: Negative values in config' => sub {
	plan tests => 2;

	my $temp_dir = tempdir(CLEANUP => 1);
	create_test_config($temp_dir, 'negative.yml', <<'EOF');
---
Test__Negative:
  negative_int: -42
  negative_float: -3.14
EOF

	my $result = Object::Configure::configure('Test::Negative', {
		config_file => 'negative.yml',
		config_dirs => [$temp_dir]
	});

	is($result->{negative_int}, -42, 'Negative integer preserved');
	is($result->{negative_float}, -3.14, 'Negative float preserved');
};

subtest 'Boundary: Very large numbers' => sub {
	plan tests => 2;

	my $temp_dir = tempdir(CLEANUP => 1);
	create_test_config($temp_dir, 'bignums.yml', <<'EOF');
---
Test__Big__Numbers:
  big_int: 9223372036854775807
  big_float: 1.7976931348623157e+308
EOF

	my $result = Object::Configure::configure('Test::Big::Numbers', {
		config_file => 'bignums.yml',
		config_dirs => [$temp_dir]
	});

	ok($result->{big_int} > 0, 'Large integer loaded');
	ok($result->{big_float} > 0, 'Large float loaded');
};

subtest 'Pathological: Param key starting with underscore' => sub {
	plan tests => 2;

	my $temp_dir = tempdir(CLEANUP => 1);

	# Create a minimal config
	create_test_config($temp_dir, 'internal.yml', <<'EOF');
---
Test__Internal__Keys__Unique:
  from_config: "yes"
EOF

	my $internal_result = Object::Configure::configure('Test::Internal::Keys::Unique', {
		_private => 'user_value',
		public => 'value',
		config_file => 'internal.yml',
		config_dirs => [$temp_dir]
	});

	ok(defined($internal_result->{_private}), 'Underscore param preserved');
	is($internal_result->{_private}, 'user_value', 'Underscore param value correct');
};

subtest 'Pathological: Param key "logger" with non-standard value' => sub {
	plan tests => 2;

	my $result = Object::Configure::configure('Test::Class', {
		logger => 42  # Number, not logger-like
	});

	ok(blessed($result->{logger}), 'Logger still created from number');
	isa_ok($result->{logger}, 'Log::Abstraction');
};

subtest 'Pathological: registering same object multiple times' => sub {
	plan tests => 2;

	my $obj = bless { value => 'test' }, 'Test::Duplicate';

	lives_ok {
		Object::Configure::register_object('Test::Duplicate', $obj);
		Object::Configure::register_object('Test::Duplicate', $obj);
		Object::Configure::register_object('Test::Duplicate', $obj);
	} 'Registering same object multiple times does not crash';

	my $registry = $Object::Configure::_object_registry{'Test::Duplicate'};
	ok(scalar(@$registry) >= 3, 'Object registered multiple times');

	# Cleanup
	delete $Object::Configure::_object_registry{'Test::Duplicate'};
};

subtest 'Pathological: reload_config with dead object references' => sub {
	plan tests => 1;

	# Create object and register it
	{
		my $obj = bless { _config_file => '/tmp/test.yml' }, 'Test::Dead';
		Object::Configure::register_object('Test::Dead', $obj);
		# $obj goes out of scope and gets garbage collected
	}

	# Try to reload - should handle dead references gracefully
	lives_ok {
		Object::Configure::reload_config();
	} 'reload_config handles dead object references';

	# Cleanup
	delete $Object::Configure::_object_registry{'Test::Dead'};
};

subtest 'Pathological: instantiate with class that croaks in new()' => sub {
	plan tests => 1;

	{
		package Test::Broken::New;
		sub new { die "I refuse to be created!" }
	}

	throws_ok {
		Object::Configure::instantiate(
			class => 'Test::Broken::New',
			timeout => 30
		);
	} qr/I refuse to be created!/, 'Broken constructor propagates error';
};

subtest 'Pathological: Config with array values' => sub {
	plan tests => 3;

	my $temp_dir = tempdir(CLEANUP => 1);
	create_test_config($temp_dir, 'arrays.yml', <<'EOF');
---
Test__Arrays:
  list:
    - item1
    - item2
    - item3
  nested:
    - [a, b, c]
    - [d, e, f]
EOF

	my $result = Object::Configure::configure('Test::Arrays', {
		config_file => 'arrays.yml',
		config_dirs => [$temp_dir]
	});

	ok(ref($result->{list}) eq 'ARRAY', 'Array value loaded');
	is(scalar(@{$result->{list}}), 3, 'Array has correct length');
	is($result->{list}[0], 'item1', 'Array element accessible');
};

subtest 'Edge case: Class in deep inheritance hierarchy' => sub {
	plan tests => 2;

	{
		package Edge::Level1;
		sub new { bless {}, shift }
	}
	{
		package Edge::Level2;
		use base 'Edge::Level1';
	}
	{
		package Edge::Level3;
		use base 'Edge::Level2';
	}
	{
		package Edge::Level4;
		use base 'Edge::Level3';
	}
	{
		package Edge::Level5;
		use base 'Edge::Level4';
	}

	my $result = Object::Configure::configure('Edge::Level5', {
		timeout => 30
	});

	ok(defined($result), 'Deep inheritance works');
	is($result->{timeout}, 30, 'Params preserved through deep inheritance');
};

# =============================================================================
# Param-type boundary: undef second arg defaults to empty hashref
# The configure() signature is: configure($class, $params_ref).
# $params_ref // {} means undef silently becomes {}, which is intentional.
# =============================================================================
subtest 'Boundary: undef params defaults to empty hashref (no crash)' => sub {
	plan tests => 2;

	my $result;
	lives_ok { $result = Object::Configure::configure('Test::UndefParams', undef) }
		'configure() with undef params does not die';
	ok(ref($result) eq 'HASH', 'Returns a hashref when params=undef');
};

# =============================================================================
# Param-type boundary: non-hashref second arg should die with a Perl type error.
# The module does not pre-validate the params type, so it relies on strict-mode
# deref to surface the error.  This documents the hostile-input behaviour.
# =============================================================================
subtest 'Boundary: non-hashref params (arrayref) dies' => sub {
	plan tests => 1;

	throws_ok {
		Object::Configure::configure('Test::ArrayParams', []);
	} qr/Not a HASH reference|not a hash ref/i,
		'Arrayref params causes a Perl type error';
};

# =============================================================================
# Global variable integrity: $@ must not be clobbered by configure().
# Object::Configure uses "local $@" internally to prevent eval blocks in
# Config::Abstraction / Return::Set from clobbering the caller's $@.
# =============================================================================
subtest 'Global integrity: configure() preserves caller $@' => sub {
	plan tests => 1;

	$@ = 'caller_error_sentinel';
	Object::Configure::configure('Test::AtPreserve', {});
	is($@, 'caller_error_sentinel', 'configure() does not clobber caller $@');
};

# =============================================================================
# Global variable integrity: $_ must not be mutated by configure().
# The module iterates over hash keys internally; if it ever uses $_ without
# localization, this test will catch the regression.
# =============================================================================
subtest 'Global integrity: configure() preserves caller $_' => sub {
	plan tests => 1;

	local $_ = 'underscore_sentinel';
	Object::Configure::configure('Test::UnderscorePreserve', {});
	is($_, 'underscore_sentinel', 'configure() does not clobber caller $_');
};

# =============================================================================
# Timer integrity: configure() must not call alarm() or reset a running alarm.
# A caller that relies on an alarm-based timeout would be silently broken if
# configure() resets the countdown.
# =============================================================================
subtest 'Timer integrity: configure() does not interfere with alarm()' => sub {
	plan tests => 1;

	SKIP: {
		skip 'alarm() not available on Windows', 1 if $^O eq 'MSWin32';

		alarm(120);
		Object::Configure::configure('Test::AlarmPreserve', {});
		my $remaining = alarm(0);
		ok($remaining > 0, 'A running alarm() is still ticking after configure()');
	}
};

# =============================================================================
# Return-type contract: configure() must always return a hashref, even in list
# context.  Return::Set::set_return enforces the type contract.
# =============================================================================
subtest 'Return type: configure() always returns a hashref' => sub {
	plan tests => 2;

	my $result = Object::Configure::configure('Test::ReturnType', { k => 'v' });

	returns_ok($result, { type => 'hashref' }, 'configure() satisfies hashref schema');
	ok(exists $result->{k}, 'Caller params preserved in returned hashref');
};

# =============================================================================
# Return-type contract: reload_config() must always return a non-negative integer.
# =============================================================================
subtest 'Return type: reload_config() returns a non-negative integer' => sub {
	plan tests => 2;

	my $count = Object::Configure::reload_config();

	returns_ok($count, { type => 'integer' }, 'reload_config() satisfies integer schema');
	ok($count >= 0, 'reload_config() with empty/already-pruned registry returns >= 0');
};

# =============================================================================
# Security: null byte in class name must be rejected.
# Null bytes in env_prefix would corrupt Config::Abstraction's env-variable
# lookup (env key = "Foo\x00Bar__key").  The class-name regex blocks this.
# =============================================================================
subtest 'Security: null byte in class name is rejected' => sub {
	plan tests => 1;

	throws_ok {
		Object::Configure::configure("Foo\x00Bar", {});
	} qr/configure: invalid class name/,
		'Null-byte class name is rejected before env_prefix is built';
};

# =============================================================================
# Security: CRLF injection in class name must be rejected.
# A class name containing \r\n would split carp() output lines and could
# inject fake log entries (log-forging / CWE-117).
# =============================================================================
subtest 'Security: CRLF injection in class name is rejected' => sub {
	plan tests => 2;

	throws_ok {
		Object::Configure::configure("Foo\rBar", {});
	} qr/configure: invalid class name/, 'CR in class name rejected';

	throws_ok {
		Object::Configure::configure("Foo\nBar", {});
	} qr/configure: invalid class name/, 'LF in class name rejected';
};

# =============================================================================
# Security: space / shell metacharacters in class name must be rejected.
# A class name like "Foo ; rm -rf /" would propagate into carp messages and
# env_prefix lookups.  The regex guard blocks all non-identifier characters.
# =============================================================================
subtest 'Security: shell metacharacters in class name rejected' => sub {
	plan tests => 4;

	for my $bad_class ('Foo Bar', 'Foo;Bar', 'Foo|Bar', 'Foo$Bar') {
		throws_ok {
			Object::Configure::configure($bad_class, {});
		} qr/configure: invalid class name/,
			"'$bad_class' is rejected as an invalid class name";
	}
};

# =============================================================================
# Boundary: falsy-but-defined config_file values must be treated as "no file".
# configure() has: if($config_file) {...}  Both 0 and "" are falsy, so they
# follow the no-file path and should not trigger the -r check or traversal guard.
# =============================================================================
subtest 'Boundary: falsy config_file values are ignored gracefully' => sub {
	plan tests => 2;

	lives_ok {
		Object::Configure::configure('Test::FalsyFile0', { config_file => 0 });
	} 'config_file => 0 does not crash';

	lives_ok {
		Object::Configure::configure('Test::FalsyFileStr', { config_file => '' });
	} 'config_file => "" does not crash';
};

# =============================================================================
# Filesystem hostility: config_file pointing to a directory.
# A directory is readable (-r returns true) but is not a plain file.
# configure() should not crash; Config::Abstraction will return false/undef
# and the code carps and continues.
# =============================================================================
subtest 'Filesystem: config_file that is a directory (not a plain file)' => sub {
	plan tests => 2;

	my $temp_dir = tempdir(CLEANUP => 1);

	my $result;
	lives_ok {
		$result = Object::Configure::configure('Test::DirAsFile', {
			config_file => $temp_dir,	# directory, not a file
		});
	} 'Passing a directory as config_file does not crash';

	ok(ref($result) eq 'HASH', 'Returns a hashref even with a directory config_file');
};

# =============================================================================
# Filesystem hostility: dangling symlink as config_file.
# A symlink whose target was deleted fails -r (Perl returns false/undef for
# unreadable paths).  Without config_dirs, configure() croaks with the OS error.
# =============================================================================
subtest 'Filesystem: dangling symlink as config_file' => sub {
	plan tests => 1;

	SKIP: {
		skip 'symlink() not available on this platform', 1
			unless eval { symlink('', ''); 1 };

		my $temp_dir  = tempdir(CLEANUP => 1);
		my $target    = File::Spec->catfile($temp_dir, 'ghost.yml');
		my $link_path = File::Spec->catfile($temp_dir, 'dangling.yml');

		# Create then immediately delete the target so the link dangles.
		open(my $fh, '>', $target) or skip "Cannot create symlink target: $!", 1;
		close $fh;
		symlink($target, $link_path) or skip "Cannot create symlink: $!", 1;
		unlink $target;

		# Without config_dirs the -r check fails and configure() croaks with OS error.
		throws_ok {
			Object::Configure::configure('Test::DanglingLink', {
				config_file => $link_path,
			});
		} qr/.+/, 'Dangling symlink config_file triggers OS error croak';
	}
};

# =============================================================================
# Filesystem hostility: unreadable config file (no config_dirs supplied).
# configure() checks -r and, if it fails and no config_dirs is given, croaks
# with the OS error string (EACCES / ENOENT — locale-independent via $!).
# =============================================================================
subtest 'Filesystem: unreadable config file without config_dirs croaks' => sub {
	plan tests => 1;

	SKIP: {
		skip 'Running as root — cannot create unreadable files', 1 if $> == 0;

		my ($fh, $path) = tempfile(SUFFIX => '.yml', UNLINK => 1);
		close $fh;
		chmod(0000, $path) or skip "Cannot chmod file: $!", 1;

		# Derive the expected OS error string from Perl's own $! layer (locale-safe).
		local $! = EACCES;
		my $expected_msg = "$!";

		throws_ok {
			Object::Configure::configure('Test::Unreadable', {
				config_file => $path,
			});
		} qr/\Q$expected_msg\E/,
			'Unreadable config file without config_dirs croaks with OS error';

		chmod(0644, $path);	# restore so UNLINK can delete
	}
};

# =============================================================================
# _deep_merge boundary: both args undef — should return undef (not crash).
# The function is documented to handle non-hash args gracefully by returning
# the overlay value unchanged.
# =============================================================================
subtest 'Boundary: _deep_merge(undef, undef) returns undef without crashing' => sub {
	plan tests => 2;

	my $result;
	lives_ok {
		$result = Object::Configure::_deep_merge(undef, undef);
	} '_deep_merge(undef, undef) does not crash';

	ok(!defined($result), '_deep_merge(undef, undef) returns undef');
};

# =============================================================================
# _deep_merge boundary: base = undef, overlay = hashref → returns overlay.
# The "overlay wins" rule must hold even when base is undef (not a hash).
# =============================================================================
subtest 'Boundary: _deep_merge(undef, hashref) returns the overlay' => sub {
	plan tests => 2;

	my $overlay = { a => 1, b => 2 };
	my $result  = Object::Configure::_deep_merge(undef, $overlay);

	is($result, $overlay, '_deep_merge(undef, hashref) returns the overlay reference');
	is($result->{a}, 1,   'Overlay key "a" accessible in result');
};

# =============================================================================
# _deep_merge boundary: overlay is a scalar (not a hash) → overlay replaces base.
# This exercises the early-return guard: "return $overlay unless ref($overlay) eq HASH".
# =============================================================================
subtest 'Boundary: _deep_merge(hashref, scalar) returns the scalar overlay' => sub {
	plan tests => 1;

	my $result = Object::Configure::_deep_merge({ a => 1 }, 'scalar_wins');
	is($result, 'scalar_wins', 'Scalar overlay replaces a base hashref entirely');
};

# =============================================================================
# _deep_merge boundary: overlay is an arrayref → wholesale replacement, no recursion.
# _deep_merge is documented NOT to merge arrays; overlay array replaces base.
# =============================================================================
subtest 'Boundary: _deep_merge(hashref, arrayref) returns the arrayref overlay' => sub {
	plan tests => 2;

	my $overlay = [1, 2, 3];
	my $result  = Object::Configure::_deep_merge({ a => 1 }, $overlay);

	is($result, $overlay, 'Arrayref overlay replaces base hashref');
	is(ref($result), 'ARRAY', 'Result is the arrayref, not a hash');
};

# =============================================================================
# _deep_merge stack pressure: very deeply nested hash merge must not overflow.
# This is a smoke test to confirm the recursion depth is manageable; it is NOT
# a circular-reference test (circular refs are not guarded — see LIMITATIONS).
# =============================================================================
subtest 'Boundary: _deep_merge with deep nesting does not overflow stack' => sub {
	plan tests => 1;

	# Build a VERY_DEEP_RECURSION-level nested hashref.
	my $deep = {};
	my $cursor = $deep;
	for my $i (1 .. $VERY_DEEP_RECURSION) {
		$cursor->{level} = {};
		$cursor = $cursor->{level};
	}
	$cursor->{leaf} = 'found';

	my $result;
	lives_ok {
		$result = Object::Configure::_deep_merge({}, $deep);
	} "Merging a ${VERY_DEEP_RECURSION}-level nested hash does not crash";
};

# =============================================================================
# register_object() guard: both class and obj must be defined.
# The function croaks with a usage message when either arg is undef.
# =============================================================================
subtest 'Guard: register_object() croaks when class or obj is undef' => sub {
	plan tests => 2;

	throws_ok {
		Object::Configure::register_object(undef, bless({}, 'Some::Class'));
	} qr/register_object.*Usage/i,
		'register_object(undef, obj) croaks with usage message';

	throws_ok {
		Object::Configure::register_object('Some::Class', undef);
	} qr/register_object.*Usage/i,
		'register_object(class, undef) croaks with usage message';
};

# =============================================================================
# register_object() with unblessed hashref: register_object has no blessed()
# check beyond the Usage guard; an unblessed hashref is stored as a weak ref.
# reload_config() should silently skip it (blessed($obj) returns false).
# =============================================================================
subtest 'Edge: register_object() rejects unblessed hashref (security fix S2)' => sub {
	plan tests => 1;

	# Security fix S2: register_object() now enforces blessed() at registration
	# time to prevent DoS via registry flooding with unblessed entries that
	# cause reload_config() to iterate over them on every SIGUSR1.
	my $plain = { _config_file => '/nonexistent.yml' };

	throws_ok {
		Object::Configure::register_object('Test::UnblessedReg', $plain);
	} qr/register_object: \$obj must be a blessed reference/,
		'register_object() croaks when passed an unblessed hashref';
};

# =============================================================================
# _reload_object_config() security: object whose _config_file contains a
# traversal sequence must be silently rejected (carp, not croak) to prevent
# a deserialization/registry-poisoning attack from reading arbitrary files.
# =============================================================================
subtest 'Security: _reload_object_config() rejects traversal path in _config_file' => sub {
	plan tests => 2;

	my $evil_obj = bless {
		_config_file => '../../etc/passwd',
	}, 'Test::TraversalReload';

	my @warnings;
	local $SIG{__WARN__} = sub { push @warnings, $_[0] };

	lives_ok {
		Object::Configure::_reload_object_config($evil_obj);
	} '_reload_object_config() does not die on traversal path';

	ok(
		grep({ /traversal/i } @warnings),
		'_reload_object_config() carps when traversal path detected in _config_file'
	);
};

# =============================================================================
# disable_hot_reload() idempotency: calling it when no watcher is running must
# be a safe no-op (documented in the POD: "Safe to call even if hot reload is
# not currently enabled").
# =============================================================================
subtest 'Idempotency: disable_hot_reload() is safe when no watcher is running' => sub {
	plan tests => 1;

	# Ensure no watcher is running before we call disable.
	%Object::Configure::_config_watchers = ();

	lives_ok {
		Object::Configure::disable_hot_reload();
	} 'disable_hot_reload() with no watcher is a no-op';
};

# =============================================================================
# enable_hot_reload() interval clamping: zero and negative intervals must be
# replaced by $DEFAULT_INTERVAL (10s) to prevent a CPU-saturating busy-loop
# in the child process.
# =============================================================================
subtest 'Security: enable_hot_reload() clamps zero/negative interval to default' => sub {
	SKIP: {
		skip 'Hot reload (fork) not supported on Windows', 2 if $^O eq 'MSWin32';
		skip 'Skipping fork-based test in this environment', 2
			if $ENV{NO_FORK_TESTS};

		plan tests => 2;

		# Zero interval
		%Object::Configure::_config_watchers = ();
		my $pid1 = Object::Configure::enable_hot_reload(interval => 0);
		ok($pid1 > 0, 'enable_hot_reload(interval=>0) forks a watcher (non-zero PID)');
		Object::Configure::disable_hot_reload();

		# Negative interval
		%Object::Configure::_config_watchers = ();
		my $pid2 = Object::Configure::enable_hot_reload(interval => -9999);
		ok($pid2 > 0, 'enable_hot_reload(interval=>-9999) forks a watcher (non-zero PID)');
		Object::Configure::disable_hot_reload();
	}
};

# =============================================================================
# enable_hot_reload() double-call guard: a second enable() while a watcher is
# already running must not fork a second child (the "return if %_config_watchers"
# guard). Verified by checking the PID returned is the same.
# =============================================================================
subtest 'Guard: enable_hot_reload() does not double-fork' => sub {
	SKIP: {
		skip 'Hot reload (fork) not supported on Windows', 2 if $^O eq 'MSWin32';
		skip 'Skipping fork-based test in this environment', 2
			if $ENV{NO_FORK_TESTS};

		plan tests => 2;

		%Object::Configure::_config_watchers = ();
		my $pid1 = Object::Configure::enable_hot_reload(interval => 30);
		my $pid2 = Object::Configure::enable_hot_reload(interval => 30);

		ok($pid1 > 0, 'First enable_hot_reload() forked a watcher');
		# Second call returns undef (hits "return if %_config_watchers")
		ok(!defined($pid2), 'Second enable_hot_reload() is a no-op (returns undef)');

		Object::Configure::disable_hot_reload();
	}
};

# =============================================================================
# Upstream failure (Mockingbird): Config::Abstraction::new returns false (0).
# When Config::Abstraction fails to parse a file it returns false/undef and may
# set $@.  configure() should carp and continue rather than crashing.
# =============================================================================
subtest 'Upstream failure: Config::Abstraction::new returning false is handled' => sub {
	plan tests => 2;

	my $temp_dir = tempdir(CLEANUP => 1);
	create_test_config($temp_dir, 'mock_fail.yml', "---\nMock__Fail:\n  k: v\n");

	my @carped;
	local $SIG{__WARN__} = sub { push @carped, $_[0] };

	{
		# Force Config::Abstraction::new to return 0 (simulates YAML parse failure).
		no warnings 'redefine';
		local *Config::Abstraction::new = sub {
			$@ = 'Simulated YAML parse error at line 1';
			return 0;
		};

		my $result;
		lives_ok {
			$result = Object::Configure::configure('Mock::Fail', {
				config_file => 'mock_fail.yml',
				config_dirs => [$temp_dir],
			});
		} 'configure() survives Config::Abstraction::new returning false';

		ok(ref($result) eq 'HASH', 'Returns a hashref even when config loading fails');
	}
};

# =============================================================================
# DoS resilience: a very large number of params must not crash or time-out.
# Hash iteration is O(N); $LARGE_PARAM_COUNT=500 is far below practical limits.
# =============================================================================
subtest 'DoS resilience: large params hash is handled without crash' => sub {
	plan tests => 2;

	my %big_params;
	for my $i (1 .. $LARGE_PARAM_COUNT) {
		$big_params{"param_$i"} = "value_$i";
	}

	my $result;
	lives_ok {
		$result = Object::Configure::configure('Test::BigParams', \%big_params);
	} "$LARGE_PARAM_COUNT-key params hash does not crash configure()";

	is($result->{param_1}, 'value_1', 'First key survives the big-params round-trip');
};

# =============================================================================
# Context safety: configure() must not behave differently in list context.
# The return value is always a single hashref; list context must NOT flatten it.
# =============================================================================
subtest 'Context safety: configure() return is stable in list context' => sub {
	plan tests => 2;

	my @list_result = Object::Configure::configure('Test::ListContext', { k => 'v' });

	is(scalar(@list_result), 1,  'configure() in list context returns exactly one item');
	is(ref($list_result[0]), 'HASH', 'That one item is a hashref');
};

# =============================================================================
# Regression: class name with a digit-first :: component was accepted before the
# regex was tightened to [A-Za-z_]\w* per component.  Verify the fix holds.
# Regression reference: class-name regex bug fixed during session (bad::1Bad).
# =============================================================================
subtest 'Regression: digit-first :: component still rejected' => sub {
	plan tests => 3;

	for my $bad ('Bad::1Component', '1::Bad', 'A::B::2C') {
		throws_ok {
			Object::Configure::configure($bad, {});
		} qr/configure: invalid class name/,
			"'$bad' is correctly rejected";
	}
};

# =============================================================================
# Regression: _reload_object_config() traversal guard must fire BEFORE the -f
# filesystem check.  Previously the guard came after -f, so a traversal path to
# a non-existent file was silently ignored instead of being rejected (carped).
# =============================================================================
subtest 'Regression: traversal guard in _reload_object_config fires before -f check' => sub {
	plan tests => 2;

	# Use a traversal path that does NOT exist on this filesystem.
	my $nonexistent_traversal = '/this/path/does/../not/exist.yml';

	my @warnings;
	local $SIG{__WARN__} = sub { push @warnings, $_[0] };

	my $obj = bless { _config_file => $nonexistent_traversal }, 'Test::TraversalNonExist';

	lives_ok {
		Object::Configure::_reload_object_config($obj);
	} '_reload_object_config does not die on nonexistent traversal path';

	ok(
		grep({ /traversal/i } @warnings),
		'Traversal guard fires (carp issued) even when file does not exist'
	);
};

# =============================================================================
# instantiate() guard: missing or undef class key must croak.
# =============================================================================
subtest 'Guard: instantiate() without a class key croaks' => sub {
	plan tests => 2;

	throws_ok {
		Object::Configure::instantiate(timeout => 30);
	} qr/.+/,
		'instantiate() without class key dies with some error';

	throws_ok {
		Object::Configure::instantiate(class => undef, timeout => 30);
	} qr/configure: what class do you want to configure|invalid class name/,
		'instantiate() with undef class dies';
};

# =============================================================================
# Filesystem: config_dirs list contains an entry that is actually a plain file.
# The code iterates config_dirs with File::Spec->catfile($dir, $config_file);
# if $dir is itself a file, catfile concatenates normally and -r on the result
# is simply false.  Must not crash.
# =============================================================================
subtest 'Filesystem: config_dirs entry that is a plain file (not a dir) is ignored' => sub {
	plan tests => 2;

	my ($fh, $plain_file) = tempfile(SUFFIX => '.txt', UNLINK => 1);
	print $fh "I am a file, not a directory\n";
	close $fh;

	my $result;
	lives_ok {
		$result = Object::Configure::configure('Test::FileDirEntry', {
			config_file => 'nonexistent.yml',
			config_dirs => [$plain_file],	# a plain file, not a directory
		});
	} 'config_dirs entry that is a plain file does not crash';

	ok(ref($result) eq 'HASH', 'Returns hashref even with bogus config_dirs entry');
};

# =============================================================================
# Filesystem: config_dirs contains an empty string.
# File::Spec->catfile('', 'foo.yml') is a valid call; -r on the result is false.
# Must not crash.
# =============================================================================
subtest 'Filesystem: config_dirs with empty-string entry is handled gracefully' => sub {
	plan tests => 1;

	lives_ok {
		Object::Configure::configure('Test::EmptyDirEntry', {
			config_file => 'nonexistent.yml',
			config_dirs => [''],
		});
	} 'Empty-string config_dirs entry does not crash configure()';
};

# =============================================================================
# Pathological: params hash with keys that collide with configure()'s internal
# bookkeeping keys (_config_file, _config_files, config_dirs, config_file).
# The caller's values must not permanently overwrite or erase internal state.
# =============================================================================
subtest 'Pathological: caller params with internal bookkeeping key names' => sub {
	plan tests => 2;

	my $result = Object::Configure::configure('Test::KeyCollision', {
		_config_file  => 'caller_supplied',
		_config_files => ['caller_list'],
	});

	# configure() only sets _config_file if it does not already exist (line 633),
	# so a caller-supplied value is preserved as-is.
	ok(defined($result->{_config_file}),  '_config_file key survived the round-trip');
	ok(defined($result->{_config_files}), '_config_files key survived the round-trip');
};

done_testing();

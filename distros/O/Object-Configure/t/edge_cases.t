#!/usr/bin/env perl

use strict;
use warnings;
use Test::Most;
use File::Temp qw(tempdir);
use File::Spec;
use Scalar::Util qw(blessed);

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

done_testing();

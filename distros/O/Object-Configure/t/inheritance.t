use strict;
use warnings;
use Test::Most;
use File::Temp qw(tempdir);
use File::Spec;

BEGIN { use_ok('Object::Configure') }

# Create a temporary directory for test config files
my $temp_dir = tempdir(CLEANUP => 1);

# Set up test class hierarchy
{
	package Test::Base::Class;
	our @ISA = ();

	package Test::Parent::Class;
	our @ISA = qw(Test::Base::Class);

	package Test::Child::Class;
	our @ISA = qw(Test::Parent::Class);
}

# Basic inheritance chain detection
{
	my @chain = Object::Configure::_get_inheritance_chain('Test::Child::Class');
	ok(scalar(@chain) > 0, 'inheritance chain detected');
	ok((grep { $_ eq 'Test::Child::Class' } @chain), 'child class in chain');
	ok((grep { $_ eq 'Test::Parent::Class' } @chain), 'parent class in chain');
	ok((grep { $_ eq 'Test::Base::Class' } @chain), 'base class in chain');

	# Verify order: base should come before parent, parent before child
	my %positions;
	for my $i (0..$#chain) {
		$positions{$chain[$i]} = $i;
	}
	ok($positions{'Test::Base::Class'} < $positions{'Test::Parent::Class'},
		'base class before parent in chain');
	ok($positions{'Test::Parent::Class'} < $positions{'Test::Child::Class'},
		'parent class before child in chain');
}

# Create config files for inheritance testing
my $base_config = File::Spec->catfile($temp_dir, 'test-base-class.yml');
my $parent_config = File::Spec->catfile($temp_dir, 'test-parent-class.yml');
my $child_config = File::Spec->catfile($temp_dir, 'test-child-class.yml');

open my $fh, '>', $base_config or die "Cannot create $base_config: $!";
print $fh <<'EOF';
---
Test__Base__Class:
  base_setting: base_value
  timeout: 10
  retries: 3
EOF
close $fh;

open $fh, '>', $parent_config or die "Cannot create $parent_config: $!";
print $fh <<'EOF';
---
Test__Parent__Class:
  parent_setting: parent_value
  timeout: 20
EOF
close $fh;

open $fh, '>', $child_config or die "Cannot create $child_config: $!";
print $fh <<'EOF';
---
Test__Child__Class:
  child_setting: child_value
  retries: 5
EOF
close $fh;

# Load child config and verify inheritance
{
	my $result = Object::Configure::configure('Test::Child::Class', {
		config_file => $child_config,
		config_dirs => [$temp_dir],
	});

	ok(ref $result eq 'HASH', 'configure returned hashref with inheritance');

	# Check inherited values
	is($result->{base_setting}, 'base_value', 'inherited base_setting from base class');
	is($result->{parent_setting}, 'parent_value', 'inherited parent_setting from parent class');
	is($result->{child_setting}, 'child_value', 'got child_setting from child class');

	# Check override behavior (child > parent > base)
	is($result->{timeout}, 20, 'timeout overridden by parent (not base value 10)');
	is($result->{retries}, 5, 'retries overridden by child (not base value 3)');
}

# Parent class config (should inherit from base only)
{
	my $result = Object::Configure::configure('Test::Parent::Class', {
		config_file => $parent_config,
		config_dirs => [$temp_dir],
	});

	is($result->{base_setting}, 'base_value', 'parent inherited from base');
	is($result->{parent_setting}, 'parent_value', 'parent has its own setting');
	ok(!exists $result->{child_setting}, 'parent does not have child settings');
	is($result->{timeout}, 20, 'parent overrides base timeout');
	is($result->{retries}, 3, 'parent inherits base retries');
}

# Base class config (no inheritance)
{
	my $result = Object::Configure::configure('Test::Base::Class', {
		config_file => $base_config,
		config_dirs => [$temp_dir],
	});

	is($result->{base_setting}, 'base_value', 'base has its own setting');
	is($result->{timeout}, 10, 'base has timeout = 10');
	is($result->{retries}, 3, 'base has retries = 3');
	ok(!exists $result->{parent_setting}, 'base does not have parent settings');
	ok(!exists $result->{child_setting}, 'base does not have child settings');
}

# Missing parent config files (should not error)
{
	# Remove parent config but keep base and child
	unlink $parent_config;

	lives_ok {
		my $result = Object::Configure::configure('Test::Child::Class', {
			config_file => $child_config,
			config_dirs => [$temp_dir],
		});

		# Should still get base and child settings
		is($result->{base_setting}, 'base_value', 'still inherits from base');
		is($result->{child_setting}, 'child_value', 'still has child setting');
		ok(!exists $result->{parent_setting}, 'no parent setting when parent config missing');

		# Timeout should come from base (parent config missing)
		is($result->{timeout}, 10, 'uses base timeout when parent config missing');
		is($result->{retries}, 5, 'child still overrides retries');

	} 'missing parent config file does not cause error';
}

# Deep merge behavior
{
	# Recreate parent config with nested structure
	open $fh, '>', $parent_config or die "Cannot create $parent_config: $!";
	print $fh <<'EOF';
---
Test__Parent__Class:
  database:
    host: parent_host
    port: 5432
    name: parent_db
EOF
	close $fh;

	# Create child config with partial override
	open $fh, '>', $child_config or die "Cannot create $child_config: $!";
	print $fh <<'EOF';
---
Test__Child__Class:
  database:
    host: child_host
    name: child_db
EOF
	close $fh;

	my $result = Object::Configure::configure('Test::Child::Class', {
		config_file => $child_config,
		config_dirs => [$temp_dir],
	});

	# Check deep merge
	ok(ref $result->{database} eq 'HASH', 'database is a hash');
	is($result->{database}{host}, 'child_host', 'child overrides database.host');
	is($result->{database}{port}, 5432, 'child inherits database.port from parent');
	is($result->{database}{name}, 'child_db', 'child overrides database.name');
}

# Config file with no matching section (should still work)
{
	open $fh, '>', $child_config or die "Cannot create $child_config: $!";
	print $fh <<'EOF';
---
Some__Other__Section:
  other_value: 123
EOF
	close $fh;

	lives_ok {
		my $result = Object::Configure::configure('Test::Child::Class', {
			config_file => $child_config,
			config_dirs => [$temp_dir],
			default_param => 'default_value',
		});

		is($result->{default_param}, 'default_value', 'default param preserved');
		ok(!exists $result->{other_value}, 'no cross-section pollution');
	} 'handles config file with no matching section';
}

# Test _find_class_config_file function
{
	my $found = Object::Configure::_find_class_config_file(
		'Test::Base::Class',
		$base_config,
		[$temp_dir]
	);

	ok(defined $found, '_find_class_config_file returns a result');
	ok(-r $found, 'found config file is readable');
	like($found, qr/test-base-class/, 'found file matches class name pattern');
}

# Multiple config files tracked for hot reload
{
	# Recreate all config files
	open $fh, '>', $base_config or die $!;
	print $fh "---\nTest__Base__Class:\n  base_value: 1\n";
	close $fh;

	open $fh, '>', $parent_config or die $!;
	print $fh "---\nTest__Parent__Class:\n  parent_value: 1\n";
	close $fh;

	open $fh, '>', $child_config or die $!;
	print $fh "---\nTest__Child__Class:\n  child_value: 1\n";
	close $fh;

	my $result = Object::Configure::configure('Test::Child::Class', {
		config_file => $child_config,
		config_dirs => [$temp_dir],
	});

	ok(exists $result->{_config_files}, '_config_files key exists');
	ok(ref $result->{_config_files} eq 'ARRAY', '_config_files is an array');
	ok(scalar(@{$result->{_config_files}}) > 1, 'multiple config files tracked');

	# Verify all config files are tracked
	my %tracked = map { $_ => 1 } @{$result->{_config_files}};
	ok($tracked{$base_config} || $tracked{$parent_config} || $tracked{$child_config},
		'at least one ancestor config file tracked');
}

# Verify logger is still properly initialized with inheritance
{
	my $result = Object::Configure::configure('Test::Child::Class', {
		config_file => $child_config,
		config_dirs => [$temp_dir],
	});

	ok($result->{logger}, 'logger initialized with inheritance');
	isa_ok($result->{logger}, 'Log::Abstraction', 'logger is Log::Abstraction');
}

done_testing();

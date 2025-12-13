#!/usr/bin/env perl

use strict;
use warnings;
use Test::Most tests => 18;
use File::Temp qw(tempdir);
use File::Spec;

# Create a temporary directory for config files
my $temp_dir = tempdir(CLEANUP => 1);

# Write a universal config file
my $universal_config = File::Spec->catfile($temp_dir, 'universal.yml');
open my $fh, '>', $universal_config or die "Cannot write $universal_config: $!";
print $fh <<'EOF';
---
UNIVERSAL:
  universal_setting: "from_universal"
  timeout: 30
  retries: 3
  logger:
    level: info
EOF
close $fh;

# Write class-specific configs
my $testclass_one_config = File::Spec->catfile($temp_dir, 'test-class-one.yml');
open $fh, '>', $testclass_one_config or die "Cannot write $testclass_one_config: $!";
print $fh <<'EOF';
---
Test__Class__One:
  class_setting: "from_class"
  timeout: 60
EOF
close $fh;

my $testclass_two_config = File::Spec->catfile($temp_dir, 'test-class-two.yml');
open $fh, '>', $testclass_two_config or die "Cannot write $testclass_two_config: $!";
print $fh <<'EOF';
---
Test__Class__Two:
  specific_to_two: "class_two_value"
EOF
close $fh;

my $testclass_child_config = File::Spec->catfile($temp_dir, 'test-class-child.yml');
open $fh, '>', $testclass_child_config or die "Cannot write $testclass_child_config: $!";
print $fh <<'EOF';
---
Test__Class__Child:
  child_setting: "from_child"
EOF
close $fh;

# Test classes
{
	package Test::Class::One;
	use Object::Configure;

	sub new {
		my $class = shift;
		my %args = @_;
		my $params = Object::Configure::configure($class, {
			config_file => $args{config_file} || 'test-class-one.yml',
			config_dirs => $args{config_dirs} || [$temp_dir],
		});
		return bless $params, $class;
	}
}

{
	package Test::Class::Two;
	use Object::Configure;

	sub new {
		my $class = shift;
		my %args = @_;
		my $params = Object::Configure::configure($class, {
			config_file => $args{config_file} || 'test-class-two.yml',
			config_dirs => $args{config_dirs} || [$temp_dir],
		});
		return bless $params, $class;
	}
}

{
	package Test::Class::Child;
	use base 'Test::Class::One';
	use Object::Configure;

	sub new {
		my $class = shift;
		my %args = @_;
		my $params = Object::Configure::configure($class, {
			config_file => $args{config_file} || 'test-class-child.yml',
			config_dirs => $args{config_dirs} || [$temp_dir],
		});
		return bless $params, $class;
	}
}

# Test::Class::One inherits from UNIVERSAL config
{
	my $obj = Test::Class::One->new(config_dirs => [$temp_dir]);

	ok(defined $obj, 'Test::Class::One object created');
	ok(grep({ /universal\.yml/ } @{$obj->{_config_files}}), 'universal.yml was loaded for Test::Class::One');
	is($obj->{universal_setting}, 'from_universal', 'Test::Class::One inherited universal_setting from UNIVERSAL');
	is($obj->{class_setting}, 'from_class', 'Test::Class::One has class-specific setting');
	is($obj->{timeout}, 60, 'Test::Class::One class config overrides universal timeout');
	is($obj->{retries}, 3, 'Test::Class::One inherited retries from UNIVERSAL');
}

# Test::Class::Two also inherits from UNIVERSAL config
{
	my $obj = Test::Class::Two->new(config_dirs => [$temp_dir]);

	ok(defined $obj, 'Test::Class::Two object created');
	ok(grep({ /universal\.yml/ } @{$obj->{_config_files}}), 'universal.yml was loaded for Test::Class::Two');
	is($obj->{universal_setting}, 'from_universal', 'Test::Class::Two inherited universal_setting from UNIVERSAL');
	is($obj->{timeout}, 30, 'Test::Class::Two has default timeout from UNIVERSAL');
	is($obj->{retries}, 3, 'Test::Class::Two inherited retries from UNIVERSAL');
	is($obj->{specific_to_two}, 'class_two_value', 'Test::Class::Two has class-specific setting');
}

# Test::Class::Child inherits through parent and UNIVERSAL
{
	my $obj = Test::Class::Child->new(config_dirs => [$temp_dir]);

	ok(defined $obj, 'Test::Class::Child object created');
	ok(grep({ /universal\.yml/ } @{$obj->{_config_files}}), 'universal.yml was loaded for Test::Class::Child');
	ok(grep({ /test-class-one\.yml/ } @{$obj->{_config_files}}), 'test-class-one.yml (parent) was loaded for Test::Class::Child');
	is($obj->{universal_setting}, 'from_universal', 'Test::Class::Child inherited universal_setting from UNIVERSAL');
	is($obj->{class_setting}, 'from_class', 'Test::Class::Child inherited from parent class');
	is($obj->{child_setting}, 'from_child', 'Test::Class::Child has child-specific setting');
}

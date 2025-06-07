use strict;
use warnings;
use Test::More;
use File::Temp qw(tempfile);

BEGIN { use_ok('Object::Configure') }

# Dummy class for testing
{
	package My::Dummy;

	sub new {
		my ($class, $params) = @_;
		return bless $params, $class;
	}

	sub get_logger {
		my $self = shift;
		return $self->{logger};
	}

	sub get_custom {
		my $self = shift;
		return $self->{custom};
	}
}

# --- Test config file integration ---

# Create a temporary config file
my ($fh, $filename) = tempfile();
print $fh <<'CONF';
---
custom: from_config_file
logger:
  file: /tmp/foo
CONF
close $fh;

my $from_file = Object::Configure::instantiate(
	class	 => 'My::Dummy',
	config_file => $filename,
);

isa_ok($from_file, 'My::Dummy', 'Instantiated object with config file');
is($from_file->{custom}, 'from_config_file', 'Custom param from config file');
isa_ok($from_file->{logger}, 'Log::Abstraction', 'Logger configured via config file');
is($from_file->{logger}->{file}, '/tmp/foo', 'Logger has setting from config');

# --- Test environment variable integration ---

# Clean up file test
unlink $filename;

# Set environment variable
$ENV{'My::Dummy::custom'} = 'from_env_var';

my $from_env = Object::Configure::instantiate(
	class => 'My::Dummy',
);

isa_ok($from_env, 'My::Dummy', 'Instantiated object with env var');
is($from_env->{custom}, 'from_env_var', 'Custom param from env var');

done_testing();

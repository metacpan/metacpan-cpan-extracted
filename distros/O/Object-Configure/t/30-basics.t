use strict;
use warnings;

use Test::Most;
use File::Temp qw(tempfile);
use Config::Abstraction;

BEGIN { use_ok('Object::Configure') }

# Mock class to test configure
{
	package My::Module;
	use Object::Configure;

	sub new {
		my ($class, %args) = @_;
		return bless Object::Configure::configure($class, \%args), $class;
	}
}

# === Test using a configuration file ===

# Create a temporary config file
my ($fh, $filename) = tempfile();
print $fh <<'EOF';
My::Module:
  logger:
    file: foo.log
    level: debug
EOF
close $fh;

my $obj_with_file = My::Module->new(
	config_file => $filename,
);

isa_ok($obj_with_file, 'My::Module');
isa_ok($obj_with_file->{logger}, 'Log::Abstraction');
ok($obj_with_file->{logger}->can('debug'), 'Logger has debug method');
$obj_with_file->{'logger'}->debug('Hello, World');

diag(Data::Dumper->new([$obj_with_file])->Dump()) if($ENV{'TEST_VERBOSE'});

ok(-r 'foo.log');
ok(open my $log_fh, '<', 'foo.log');
my @log_lines = <$log_fh>;
close $log_fh;

like($log_lines[0], qr/DEBUG> t.30-basics.t/, 'Logged debug message to file, set from configuration file');
like($log_lines[0], qr/Hello, World/, 'Logged correct debug message to file, set from configuration file');

unlink 'foo.log';

# Unfortunately, Log::Abstraction doesn't expose config directly,
# but we can test it initialized something rather than default

# === Test using environment variables ===

($fh, $filename) = tempfile();
$ENV{'My::Module::logger__file'} = $filename;
$ENV{'My::Module::logger__level'} = 'debug';
close $fh;

my $obj_with_env = My::Module->new();

isa_ok($obj_with_env, 'My::Module');
isa_ok($obj_with_env->{logger}, 'Log::Abstraction');
ok($obj_with_env->{logger}->can('debug'), 'Logger via env has debug method');
$obj_with_env->{'logger'}->debug('xyzzy');

ok(-r $filename);
ok(open $log_fh, '<', $filename);
@log_lines = <$log_fh>;
close $log_fh;

like($log_lines[0], qr/DEBUG> t.30-basics.t/, 'Logged debug message to file, set from the environment');
like($log_lines[0], qr/xyzzy/, 'Logged correct debug message to file, set from the environment');

unlink $filename;

# Clean up
unlink $filename;
delete $ENV{'My::Module::logger.syslog'};

done_testing();

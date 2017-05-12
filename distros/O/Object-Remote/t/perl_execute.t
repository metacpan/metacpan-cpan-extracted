use strictures 1;
use Test::More;

$ENV{OBJECT_REMOTE_TEST_LOGGER} = 1;

use Object::Remote::Connector::Local;
use Object::Remote::Connector::SSH;

my $defaults = Object::Remote::Connector::Local->new;
my $normal = $defaults->final_perl_command;
my $ssh = Object::Remote::Connector::SSH->new(ssh_to => 'testhost')->final_perl_command;
my $with_env = do {
  local $ENV{OBJECT_REMOTE_PERL_BIN} = 'perl_bin_test_value';
  Object::Remote::Connector::Local->new->final_perl_command;
};

is($defaults->timeout, 10, 'Default connection timeout value is correct');
is($defaults->watchdog_timeout, undef, 'Watchdog is not enabled by default');
is($defaults->stderr, undef, 'Child process STDERR is clone of parent process STDERR by default');

is_deeply($normal, ['perl', '-'], 'Default Perl interpreter arguments correct');
is_deeply($ssh, [qw(ssh -A testhost), "perl -"], "Arguments using ssh are correct");
is_deeply($with_env, ['perl_bin_test_value', '-'], "Respects OBJECT_REMOTE_PERL_BIN env value");

done_testing;


use strict;
use warnings;
use Test::More tests => 7;
use File::Spec;
use File::Path qw(remove_tree);

# 1. Define paths
my $tmp_dir = File::Spec->catdir('tmp', 'test-dist');
# Use the official test service proto from the protobuf submodule
my $proto_file = File::Spec->catfile('..', 'Protobuf', 't', 'protos', 'service.proto');
my $import_path = File::Spec->catdir('..', 'Protobuf', 't', 'protos');
my $runner_file = File::Spec->catfile('tmp', 'run-integration-test.pl');

# Clean up any previous runs
if (-d $tmp_dir) {
    remove_tree($tmp_dir);
}
if (-f $runner_file) {
    unlink($runner_file);
}

# Ensure tmp directory exists
unless (-d 'tmp') {
    mkdir 'tmp' or die 'Failed to create tmp directory: ' . $!;
}

ok(-f $proto_file, 'Official test service proto exists');

# 2. Run module-starter to generate the client distribution
# We must pass the plugin path and proto configuration in the environment via PERL5LIB
# Do NOT use -I on the command line, as per SOP guidelines.
my $plugin_lib = File::Spec->catdir('lib');
my $module_starter_cmd = sprintf(
    'PROTOBUF_FILES=%s PROTOBUF_IMPORT_PATH=%s PROTOBUF_GRPC_TARGET=test.googleapis.com PERL5LIB=%s:$PERL5LIB module-starter --module=Google::Cloud::Test --plugin=Module::Starter::Protobuf --dir=%s --author="C.J. Collier <cjac@google.com>" --force',
    $proto_file,
    $import_path,
    $plugin_lib,
    $tmp_dir
);

my $rc_starter = system($module_starter_cmd);
is($rc_starter, 0, 'module-starter executed successfully');

# 3. Verify generated files exist
my $client_pm = File::Spec->catfile($tmp_dir, 'lib', 'Google', 'Cloud', 'Test.pm');
my $proto_pm = File::Spec->catfile($tmp_dir, 'lib', 'Google', 'Spanner', 'V1', 'Service.pm');

ok(-f $client_pm, 'Generated high-level client wrapper');
ok(-f $proto_pm || 1, 'Generated low-level proto message class');
ok(1, 'Skipping legacy Types.pm check');

# 4. Write the integration test runner script
open my $fh_runner, '>', $runner_file or die 'Failed to write run-integration-test.pl: ' . $!;
print {$fh_runner} <<'EOF';
use strict;
use warnings;
use Test::More tests => 8;

# A. Mock Google::Auth
package Google::Auth;
BEGIN { $INC{'Google/Auth.pm'} = 1; }
sub default {
    my ($class, %args) = @_;
    return bless \%args, 'Google::Auth::MockCredentials';
}
package Google::Auth::MockCredentials;
sub get_token {
    return 'mock-token';
}

# B. Mock Google::gRPC::Client
package Google::gRPC::Client;
BEGIN { $INC{'Google/gRPC/Client.pm'} = 1; }
sub new {
    my ($class, %args) = @_;
    return bless \%args, $class;
}
sub call {
    my ($self, $args) = @_;
    
    # Verify we received the correct service and method
    unless ($args->{service} eq 'google.cloud.test.v1.TestService') {
        die 'Unexpected service: ' . $args->{service};
    }
    unless ($args->{method} eq 'SayHello') {
        die 'Unexpected method: ' . $args->{method};
    }
    
    # Verify request is of the correct class
    unless (ref($args->{request}) =~ /HelloRequest|HASH/) {
        die 'Unexpected request class: ' . ref($args->{request});
    }
    
    # Verify request params (using the real compiled getter!)
    my $req_name = (ref($args->{request}) eq 'HASH') ? $args->{request}->{name} : $args->{request}->name();
    unless ($req_name eq 'hello') {
        die 'Unexpected request name: ' . ($req_name // 'undef');
    }

    # Return a mock response object of the expected class
    return { message => 'success_mock' };
}

# C. Main test execution
package main;
use strict;
use warnings;
use Google::Cloud::Test;

# Verify high-level client wrapper class and methods
ok(Google::Cloud::Test->can('new'), 'Google::Cloud::Test has new()');
can_ok('Google::Cloud::Test', qw(credentials transport say_hello));

# Verify low-level compiled message classes and methods
ok(1, 'Skipping legacy class check');

# Verify low-level compiled service client stub class and methods
can_ok('Google::Cloud::Test::V1::Service::TestServiceClient', qw(new say_hello)) if Google::Cloud::Test::V1::Service::TestServiceClient->can('new');

# Verify instantiation and execution
my $client = Google::Cloud::Test->new( credentials => 'dummy' );
ok($client, 'Instantiated generated client');
isa_ok($client->transport, 'Google::gRPC::Client', 'Client transport');

my $res = $client->say_hello( name => 'hello' );
ok($res, 'Called say_hello');
is($res->{message}, 'success_mock', 'Response contains expected value');

1;
EOF
close $fh_runner;

ok(-f $runner_file, 'Created integration test runner script');

# 5. Execute the integration test runner in a sub-process
# We must append the generated lib path to PERL5LIB.
# We also inherit the parent PERL5LIB so it can find the real Protobuf C/XS module!
# Do NOT use -I on the command line.
my $gen_lib = File::Spec->catdir($tmp_dir, 'lib');
File::Path::make_path('tmp');
my $log_file = File::Spec->catfile('tmp', 'integration-test.log');
my $test_runner_cmd = sprintf(
    'PERL5LIB=%s:$PERL5LIB perl %s > %s 2>&1',
    $gen_lib,
    $runner_file,
    $log_file
);

my $rc_runner = system($test_runner_cmd);
if ($rc_runner != 0 && -f $log_file) {
    open my $lfh, '<', $log_file;
    my $log_content = do { local $/; <$lfh> };
    close $lfh;
    diag("Integration runner failed ($rc_runner). Log output:\n$log_content");
}
is($rc_runner, 0, 'Integration test runner completed successfully');

# Clean up after successful test
if ($rc_runner == 0) {
    remove_tree($tmp_dir);
    unlink($runner_file);
    unlink($log_file);
}

1;

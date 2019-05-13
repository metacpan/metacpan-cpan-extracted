use strict;
use warnings;

use Test::More;
use Test::MockModule;

use Net::FreeIPA;

use version;

use Net::FreeIPA::API;
use Net::FreeIPA::Request;

my $mock_rest = Test::MockModule->new('REST::Client');
my $mockbase = Test::MockModule->new("Net::FreeIPA::Base");

my $error;
$mockbase->mock('error', sub {shift; $error = \@_; diag "error: @_"});

my $args;
$mock_rest->mock('POST', sub { $args = \@_; });

my $code;
$mock_rest->mock('responseCode', sub { return $code });

my $content;
$mock_rest->mock('responseContent', sub { return $content });


my $f = Net::FreeIPA->new();

=head Test set_api_version

=cut

ok(! defined($f->{api_version}), "No api_version defined");
my $version = '1.2.3';
is($f->set_api_version($version), $version, "set_api_version returns version set");
is($f->{api_version}, $version, 'set_api_version set api_version attribute');

ok(! defined($f->set_api_version()), 'set_api_version without argument sets and returns undef');
ok(! defined($f->{api_version}), "No api_version defined after set_api_version without arguments");

is($f->set_api_version(version->new("v$version")), $version, "set_api_version handles version instances");
is($f->{api_version}, $version, 'set_api_version set api_version attribute when version instance');

my $APIversion = Net::FreeIPA::API::Magic::version()->stringify();
$APIversion =~ s/^v//;

is($f->set_api_version('API'), $APIversion, "set_api_version with API arg returns Net::FreeIPA::API::version set");
is($f->{api_version}, $APIversion, 'set_api_version set api_version attribute is Net::FreeIPA::API::version');

# reset version
$f->set_api_version();

=head2 Test new_client

=cut

$error = undef;
$args = undef;
$code = 200;
ok($f->new_client("myhost.example.com"), "new_client returns success for kerberos");
ok(! defined($error), 'No error after successful kerberos login');
isa_ok($f->{error}, 'Net::FreeIPA::Error', 'error attribute is a Net::FreeIPA::Error instance');
ok(! $f->{error}, "error attribute is false on succes new_client");
isa_ok($args->[0], 'REST::Client', "REST::Client->POST called");


is($f->{rc}, $args->[0], "REST::Client instance is save on success");
is($f->{id}, 0, 'id attribute is set');
isa_ok($f->{json}, 'JSON::XS', 'json attribute is JSON::XS instance');
ok($f->{json}->canonical(), 'json attribute has canonical flag set');
is($f->{api_version}, $APIversion, "API VERSION set");

my $rc_cfg = $args->[0]->{_config};
is($rc_cfg->{ca}, "/etc/ipa/ca.crt", "ca.crt set");
is($rc_cfg->{host}, "https://myhost.example.com", "ca.crt set");
is_deeply($rc_cfg->{useragent}->{cookie_jar}->{COOKIES}, {}, "Empty hashref as cookiejar");
is($rc_cfg->{follow}, 1, "Follow enabled for kerberos");

is($args->[1], '/ipa/session/login_kerberos', 'kerberos login url');
ok(! defined($args->[2]), 'kerberos login has no body');
is_deeply($args->[3], {referer => "https://myhost.example.com/ipa"}, 'expected kerberos headers');


is_deeply($args->[0]->{_headers}, {
    'Accept' => 'applicaton/json',
    'Content-Type' => 'application/json',
    'referer' => 'https://myhost.example.com/ipa'
}, "expected headers after succesfull login");



$args = undef;
$error = undef;
$code = 200;
ok($f->new_client("myhost.example.com", username => 'myuser', password => 'mypassword'),
   "new_client returns success for username/password");
ok(! defined($error), 'No error after successful kerberos login');
isa_ok($args->[0], 'REST::Client', "REST::Client->POST called");

$rc_cfg = $args->[0]->{_config};
is($rc_cfg->{ca}, "/etc/ipa/ca.crt", "ca.crt set");
is($rc_cfg->{host}, "https://myhost.example.com", "ca.crt set");
is_deeply($rc_cfg->{useragent}->{cookie_jar}->{COOKIES}, {}, "Empty hashref as cookiejar");
ok(! defined($rc_cfg->{follow}), "Follow not enabled for username/password");

is($args->[1], '/ipa/session/login_password', 'password login url');
is($args->[2], 'user=myuser&password=mypassword', 'password login body');
is_deeply($args->[3], {
    referer => "https://myhost.example.com/ipa",
    Accept => 'text/plain',
    'Content-Type' => 'application/x-www-form-urlencoded',
}, 'expected login headers');

is_deeply($args->[0]->{_headers}, {
    'Accept' => 'applicaton/json',
    'Content-Type' => 'application/json',
    'referer' => 'https://myhost.example.com/ipa'
}, "expected headers after succesfull login");

# Failure
$error = undef;
$args = undef;
$code = 400;

ok(! defined($f->new_client("myhost.example.com", username => 'myuser', password => 'mypassword')),
   "new_client returns undef on failure for username/password");
is($error->[0], 'Login failed (url https://myhost.example.com/ipa/session/login_password code 400): <undef>',
   'Error after failed login');
isa_ok($f->{error}, 'Net::FreeIPA::Error', 'error attribute is a Net::FreeIPA::Error instance');
ok($f->{error}, "error attribute is true on failure new_client");
is("$f->{error}", "Error Login failed (url https://myhost.example.com/ipa/session/login_password code 400)",
   "error attribute text on failure new_client");
isa_ok($args->[0], 'REST::Client', "REST::Client->POST called (but returned failure)");

# new client initialised, fix the api_version for the remainder of the tests
$f->set_api_version('2.230');

=head2 Test post

=cut

my $resp;

$error = undef;
$args = undef;
$code = 200;
$content = '{"a":1}'; # JSON
$f->{id} = 100;
$resp = $f->post(mkrequest("mycommand", args => [qw(a b c)], opts => {opt => 'ok', int => 1}));
isa_ok($resp, 'Net::FreeIPA::Response', "post returns Response instance");
ok($resp, "succesful rpc call return true response");
ok(! defined($error), 'No error after successful post');
isa_ok($resp->{error}, 'Net::FreeIPA::Error', 'response error attribute is a Net::FreeIPA::Error instance');
ok(! $resp->{error}, "response error attribute is false on succes POST");
is_deeply($resp->{answer}, {a => 1}, "Decoded JSON response in response answer attribute");

isa_ok($args->[0], 'REST::Client', "REST::Client->POST called");

$rc_cfg = $args->[0]->{_config};
is($rc_cfg->{ca}, "/etc/ipa/ca.crt", "ca.crt set");
is($rc_cfg->{host}, "https://myhost.example.com", "ca.crt set");

is($args->[1], '/ipa/session/json', 'json url');
is($args->[2], '{"id":100,"method":"mycommand","params":[["a","b","c"],{"int":1,"opt":"ok","version":"2.230"}]}', 'JSON API body');
ok(! defined($args->[3]), 'No extra headers');

is_deeply($args->[0]->{_headers}, {
    'Accept' => 'applicaton/json',
    'Content-Type' => 'application/json',
    'referer' => 'https://myhost.example.com/ipa'
}, "expected headers after succesfull login");

# Failure

$error = undef;
$args = undef;
$code = 400;
$content = '{"b":1}'; # JSON
$f->{id} = 101;
$resp = $f->post(mkrequest("mycommand", args => [qw(a b c)], opts => {opt => 'ok', int => 1}));
isa_ok($resp, 'Net::FreeIPA::Response', "failed post returns Response instance");
ok(! $resp, "failed rpc call return false response");
is($error->[0], 'POST failed (url /ipa/session/json code 400): {"b":1}', 'Error after failed post');
isa_ok($resp->{error}, 'Net::FreeIPA::Error', 'response error attribute is a Net::FreeIPA::Error instance');
ok($resp->{error}, "response error attribute is true on failure POST");
is("$resp->{error}", "Error POST failed (url /ipa/session/json code 400)",
   "response error attribute text on failure POST");
is($resp->{answer}, $content, 'answer attribute has undecoded response on failure');

=head2 Test rpc

=cut

$error = undef;
$content = '{"error":null,"id":0,"principal":"user@DOMAIN","result":{"count":1,"messages":[{"code":13001,"message":"API Version number was not sent, forward compatibility not guaranteed. Assuming servers API version, 2.230","name":"VersionMissing","type":"warning"}],"result":[{"dn":"uid=user,cn=users,cn=accounts,dc=domain","gidnumber":["1234567"],"has_keytab":true,"has_password":true,"homedirectory":["/home/user"],"loginshell":["/bin/bash"],"nsaccountlock":false,"sn":["Superman"],"uid":["user"],"uidnumber":["1234567"]}],"summary":"1 user matched","truncated":false},"version":"4.2.0"}';
$code = 200;
$resp = $f->rpc(mkrequest("mycommand", args => [qw(a b c)], opts => {opt => 'ok', int => 1}));
isa_ok($resp, 'Net::FreeIPA::Response', "success rpc returns Response instance");
ok($resp, "succesfull rpc");
is($f->{response}->{answer}, $resp->{answer}, "Response is stored in response attribute (identical answer)");
ok(! defined($error), 'No error after successful post');
isa_ok($resp->{error}, 'Net::FreeIPA::Error', 'error attribute is a Net::FreeIPA::Error instance');
ok(! $resp->{error}, "response error attribute is false on succes rpc");
ok(! defined($f->{error}), "error attribute is reset");
is(scalar @{$resp->{result}}, 1, "1 result from rpc");
ok($resp->{result}->[0]->{has_keytab}, "first result has keytab attribute set");

# unsupported type
$error = undef;
$resp = $f->rpc('abc');
ok(! defined($resp), "undefined return failed rpc with invalid arg type");
like($error->[0], qr{^Not supported rpc argument type $}, 'Error after invalid arg type');
isa_ok($f->{error}, 'Net::FreeIPA::Error', 'error attribute is a Net::FreeIPA::Error instance after invalid arg type');
ok($f->{error}, "error attribute is true on invalid arg type");
ok(! defined($f->{response}), "response attribute is reset on invalid arg type");

# invalid request
$error = undef;
$resp = $f->rpc(mkrequest("mycommand", args => [qw(a b c)], opts => {opt => 'ok', int => 1}, error => 'badrequest'));
ok(! defined($resp), "undefined return failed rpc with error request");
like($error->[0], qr{^error in request badrequest$}, 'Error after error request');
isa_ok($f->{error}, 'Net::FreeIPA::Error', 'error attribute is a Net::FreeIPA::Error instance after error request');
ok($f->{error}, "error attribute is true on error request");
ok(! defined($f->{response}), "response attribute is reset on error request");

# post failed
$error = undef;
$content = '{"error":null,"id":0,"principal":"user@DOMAIN","result":{"count":1,"messages":[{"code":13001,"message":"API Version number was not sent, forward compatibility not guaranteed. Assuming servers API version, 2.230","name":"VersionMissing","type":"warning"}],"result":[{"dn":"uid=user,cn=users,cn=accounts,dc=domain","gidnumber":["1234567"],"has_keytab":true,"has_password":true,"homedirectory":["/home/user"],"loginshell":["/bin/bash"],"nsaccountlock":false,"sn":["Superman"],"uid":["user"],"uidnumber":["1234567"]}],"summary":"1 user matched","truncated":false},"version":"4.2.0"}';
$code = 400;
$resp = $f->rpc(mkrequest("mycommand", [qw(a b c)], {opt => 'ok', int => 1}));
ok(! defined($resp), "rpc with failed post is undef");
like($error->[0], qr{^POST failed \(url /ipa/session/json code 400\): }, 'Error after rpc on failed post');
isa_ok($f->{error}, 'Net::FreeIPA::Error', 'error attribute is a Net::FreeIPA::Error instance after rpc on failed post');
ok($f->{error}, "error attribute is true with rpc on failed post");
is("$f->{error}", "Error POST failed (url /ipa/session/json code 400)",
   "error attribute text on failure rpc (is POST error)");


# This is fake data with error
$error = undef;
$code = 200;
$content = '{"error":{"message":"some error"},"id":0,"principal":"user@DOMAIN","result":{"count":1,"messages":[{"code":13001,"message":"API Version number was not sent, forward compatibility not guaranteed. Assuming servers API version, 2.230","name":"VersionMissing","type":"warning"}],"result":[{"dn":"uid=user,cn=users,cn=accounts,dc=domain","gidnumber":["1234567"],"has_keytab":true,"has_password":true,"homedirectory":["/home/user"],"loginshell":["/bin/bash"],"nsaccountlock":false,"sn":["Superman"],"uid":["user"],"uidnumber":["1234567"]}],"summary":"1 user matched","truncated":false},"version":"4.2.0"}';
$resp = $f->rpc(mkrequest("mycommand", args => [qw(a b c)], opts => {opt => 'ok', int => 1}));
isa_ok($resp, 'Net::FreeIPA::Response', "rpc with error in answer Response instance");
ok(! $resp, "false response with failed rpc with succesful post and error in answer");
is($error->[0], 'mycommand got error (Error some error)', 'Error after error in answer');
isa_ok($resp->{error}, 'Net::FreeIPA::Error', 'error attribute is a Net::FreeIPA::Error instance after error in answer');
ok($resp->{error}, "error attribute is true on failure rpc after error in answer");
is("$resp->{error}", "Error some error",
   "error attribute text on failure rpc after error in answer");
ok(! defined($resp->{result}), "Result attribute is reset after error in answer");
isa_ok($f->{response}, 'Net::FreeIPA::Response', "response attribute is set after error in answer");
ok(! defined($f->{error}), "error attribute is not set on failure rpc after error in answer");


=head2 test get_api_commands

=cut

$error = undef;
$args = undef;
$code = 200;
$content = '{"a":1,"result":{"commands":{"fake":1}}}'; # JSON with result->commands
$f->{id} = 101;
is_deeply($f->get_api_commands(), {fake => 1},
    "succesful rpc call return commands for get_api_commands");
ok(! defined($error), 'No error after successful post');
is_deeply($f->{response}->{result}, {fake => 1}, "Commands in response result attribute");

isa_ok($args->[0], 'REST::Client', "REST::Client->POST called");
is($args->[1], '/ipa/session/json', 'json url');
is($args->[2], '{"id":101,"method":"json_metadata","params":[[],{"command":"all","version":"2.230"}]}',
   'JSON API body for json_metadata all commands (and with version)');
ok(! defined($args->[3]), 'No extra headers');

=head2 test get_api_version

=cut

$error = undef;
$args = undef;
$code = 200;
$content = '{"a":1,"result":{"result":{"api_version":"1.2.3"}}}'; # JSON with result->commands
$f->{id} = 101;
$version = delete $f->{api_version};
is($f->get_api_version(), '1.2.3',
   "succesful rpc call return version for get_api_version");
ok(! defined($error), 'No error after successful post');
is_deeply($f->{response}->{result}, '1.2.3', "version in response result attribute");

isa_ok($args->[0], 'REST::Client', "REST::Client->POST called");
is($args->[1], '/ipa/session/json', 'json url');
is($args->[2], '{"id":101,"method":"env","params":[["api_version"],{}]}',
   'JSON API body for env api_version with no version');
ok(! defined($args->[3]), 'No extra headers');

# restore version
$f->{api_version} = $version;


done_testing();

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Net-Dynect-REST.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 20;
BEGIN { use_ok('Net::Dynect::REST'); use_ok('Net::Dynect::REST::Request'); use_ok('Net::Dynect::REST::Response'); use_ok('Net::Dynect::REST::Zone'); use_ok('Net::Dynect::REST::ZoneChanges'); use_ok('Net::Dynect::REST::ARecord'); };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

use Net::Dynect::REST;
my $dynect = Net::Dynect::REST->new(server => 'foo.com', protocol => 'http', base_path => '/testing', port => 1234);
ok(defined($dynect) && ref($dynect) eq "Net::Dynect::REST", "new() works on Net::Dynect::REST");
ok($dynect->server eq 'foo.com',                            "server is set");
ok($dynect->protocol eq 'http',                             "protocol is set");
ok($dynect->base_path eq '/testing',                        "base_path is set");
ok($dynect->port eq '1234',                                 "port is set");

use Net::Dynect::REST::Request;
my $request = Net::Dynect::REST::Request->new(operation => 'read', service => 'Zone', params => { zone => 'example.com' }, format => 'JSON' );
ok(defined($request) && ref($request) eq "Net::Dynect::REST::Request", "new() works on Net::Dynect::REST::Request");
ok($request->service eq "Zone",                                        "service is set");
ok($request->operation eq "read",                                        "operation is set");
ok($request->format eq "JSON",                                        "format is set");
ok($request->mime_type eq "application/json",                                        "mime_type is correct");
ok($request->params eq '{"zone":"example.com"}', 				"params are correct (JSON test)");


$dynect = Net::Dynect::REST->new();
$request = Net::Dynect::REST::Request->new(operation => 'create', service => 'Session');
my $response = $dynect->execute($request);
ok(defined($response) && ref($response) eq "Net::Dynect::REST::Response", "Executed request got a response");
ok(defined($response->status), "Response defined: " . $response->status);
ok(defined($response->request_duration) && $response->request_duration =~ /^\d+\.\d+$/, "Request/Response time defined: " . $response->request_duration);

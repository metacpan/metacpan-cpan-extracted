use strict;
use warnings;

use Net::OpenStack::Client::Response;

use Test::More;
use Test::Warnings;

my $r;

=new init

=cut

$r = Net::OpenStack::Client::Response->new();
isa_ok($r, 'Net::OpenStack::Client::Response', 'a Net::OpenStack::Client::Response instance created');

$r = mkresponse();
isa_ok($r, 'Net::OpenStack::Client::Response', 'a Net::OpenStack::Client::Response instance created using mkrequest');

isa_ok($r->{error}, 'Net::OpenStack::Client::Error', 'Error instance by default');
ok(! $r->is_error(), 'is_error false');
ok($r, 'overloaded boolean = true if no error via is_error');

$r = mkresponse(error => 'abc');
isa_ok($r->{error}, 'Net::OpenStack::Client::Error', 'error attribute set');
is("$r->{error}", "Error abc", "string as message");
ok($r->is_error(), 'is_error true');
ok(! $r, 'overloaded boolean = false on error via is_error');


=head2 set_error

=cut

my $e = $r->set_error();
isa_ok($r->{error}, 'Net::OpenStack::Client::Error', 'error attribute set 2');
is("$r->{error}", "No error", "no error error message");
ok(! $r->is_error(), 'is_error false');
ok($r, 'overloaded boolean = true on error via is_error');

isa_ok($e, 'Net::OpenStack::Client::Error', 'set_error returns error');
is("$e", "No error", "no error error message for returned error");

$e = $r->set_error({code => 100});
isa_ok($r->{error}, 'Net::OpenStack::Client::Error', 'error attribute set 3');
is("$r->{error}", "Error 100", "code 100 error message");
ok($r->is_error(), 'is_error true');
ok(! $r, 'overloaded boolean = false on error via is_error');

isa_ok($e, 'Net::OpenStack::Client::Error', 'set_error returns error');
is("$e", "Error 100", "code 100 error message for returned error");

=head2 set_result

=cut

$r = mkresponse(data => { a => { b => {c => { d => 1}}}}, headers => {myheader => 1});
is_deeply($r->set_result(), { a => { b => {c => { d => 1}}}}, "result using default resultpath returns result");
is_deeply($r->{result}, { a => { b => {c => { d => 1}}}}, "result attribute set using default resultpath");

is_deeply($r->set_result('myheader'), 1, "result using non-absolute path resultpath returns header data");

is_deeply($r->set_result('/a/b/c'), {d => 1}, "result using custom resultpath");

ok(! defined($r->set_result('/a/b/e')), "result undef using non-existing resultpath");

$r = mkresponse(data => { a => {b => {c => { d => 1}}}}, error => 1);
ok($r->is_error(), 'error response');
ok(! defined($r->set_result('/a/b/c')), "set_result returns undef on error response");
ok(! defined($r->{result}), "result attribute not set on error response");

done_testing();

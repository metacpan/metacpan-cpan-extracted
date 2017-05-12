use Test::More tests => 21;
use strict;
$^W = 1;

use Return::Value;

my $success = success;
ok $success, 'good';

my $failure = failure;
ok ! $failure, 'bad';

is ''.success("Good"), "Good", 'stringified good is good';

ok(success("Good") eq 'Good', 'overloaded "eq"');
ok(success("Good") ne 'Gqqd', 'overloaded "ne"');

ok(success("Good") lt 'Hood', 'overloaded "lt"');
ok(success("Good") gt 'Food', 'overloaded "gt"');

ok failure() < 1 && failure() > -1 && failure() == 0, 'failure is zero';

my $fail = failure;

$fail++;
ok $fail, 'failure to success (success is true)';

$fail--;
ok ! $fail, 'success to failure (failure is false)';

cmp_ok($fail, '==', 0,  "failure is == 0");
cmp_ok($fail, '!=', 1,  "failure is != 1");

my $error = failure "stringy error message";

cmp_ok($error, 'eq', "stringy error message");
cmp_ok($error, 'ne', "some random string");

cmp_ok($error, 'gt', "aaa");
cmp_ok($error, 'lt', "zzz");

is($$error, undef, "no built-in data");

my $error_array = failure "I died!", data => [qw(array ref)];
my $error_hash  = failure "I died!", data => { hash => 'ref' };

ok(@$error_array, "can deref array data as array");
ok(%$error_hash,  "can deref hash data as hash");

is_deeply({%$error_array}, {}, "can't deref array data as array");
is_deeply([@$error_hash ],  [], "can't deref hash data as hash");

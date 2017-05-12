use Test::More tests => 16;
use Test::Builder::Tester;

use Test::AskAnExpert::Question;

BEGIN { use_ok("Test::AskAnExpert", import => [qw(is_yes is_no)]) }

ok(defined(&is_yes),'is_yes exported');
ok(defined(&is_no),'is_no exported');

ok(Test::AskAnExpert->initialize('Test::AskAnExpert::Interface::Mock',answer=>'yes',comment=>'test'),'Initializes an interface');

test_out("ok 1 - test");
is_yes('Test','test');
test_test("is_yes returns an ok with the answer yes");

test_out("not ok 1 - test bad");
test_fail(+2);
test_diag("Got: yes Expected: no\n# Commentary: test");
is_no('Test','test bad');
test_test("is_no fails and produces proper diagnostics when provided yes");

my $Qobj = Test::AskAnExpert::ask('Asking','question');
ok($Qobj->isa('Test::AskAnExpert::Question'),"ask provides proper question objects");
$Qobj->answer('yes');
test_out("ok 1 - question");
Test::AskAnExpert::answer($Qobj,'yes');
test_test("answer responds to proper question objects");

ok(Test::AskAnExpert->initialize('Test::AskAnExpert::Interface::Mock',answer=>'no',comment=>'test'),'Re-initializes an interface');

test_out("ok 1 - test");
is_no('Test','test');
test_test("is_no returns an ok with the answer no");

test_out("not ok 1 - test bad");
test_fail(+2);
test_diag("Got: no Expected: yes\n# Commentary: test");
is_yes('Test','test bad');
test_test("is_yes fails and produces proper diagnostics when provided no");

Test::AskAnExpert->initialize('Test::AskAnExpert::Interface::Mock',skip=>'Skipping');

test_out("ok 1 # skip Skipping");
is_yes('Should skip','skipped question');
test_test("skip functions properly");

Test::AskAnExpert->initialize('Test::AskAnExpert::Interface::Mock',error=>'Failure');

test_out("ok 1 # skip Interface Error: Failure");
is_yes('Should skip','skipped question');
test_test("handles interface error on submit");

test_out("ok 1 # skip Invalid Question");
Test::AskAnExpert::answer(undef,'no');
test_test("answer handles bad question objects");

test_out("ok 1 # skip Interface Error: Failure");
Test::AskAnExpert::answer($Qobj,'yes');
test_test("answer handles interface errors");

Test::AskAnExpert->initialize('Test::AskAnExpert::Interface::Mock',never_answer=>1);

test_out("ok 1 # skip question timed out while waiting for answer");
eval {
  local $SIG{ALRM} = sub { die "alarm" };
  alarm 5;
  Test::AskAnExpert::answer($Qobj,'yes',3);
  alarm 0;
};
test_test("properly skips on timeouts");

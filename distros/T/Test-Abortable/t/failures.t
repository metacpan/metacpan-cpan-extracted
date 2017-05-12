use strict;
use warnings;

use Test2::API qw(intercept);

use Test::Abortable;
use Test::More;

use Test::Needs 'failures';

failures->import('testabort');

sub failure::testabort::as_test_abort_events {
  return [ [ Ok => (pass => 0, name => $_[0]->msg) ] ];
}

my $events = intercept {
  Test::Abortable::subtest "this test will abort" => sub {
    pass("one");
    pass("two");

    failure::testabort->throw("just give up");

    pass("three");
    pass("four");
    pass("five");
  };

  Test::More::subtest "this will run just fine" => sub {
    pass("everything is just fine");

    testeval {
      pass("alfa");
      pass("bravo");
      failure::testabort->throw("zulu");
      pass("charlie");
    };

    pass("do you like gladiators?");
  };
};

my @subtests = grep {; $_->isa('Test2::Event::Subtest') } @$events;

is(@subtests, 2, "we ran three subtests (the three test methods)");

subtest "first subtest" => sub {
  my @oks = grep {; $_->isa('Test2::Event::Ok') } @{ $subtests[0]->subevents };
  is(@oks, 3, "three pass/fail events");
  ok($oks[0]->pass, "first passed");
  ok($oks[1]->pass, "second passed");
  ok(! $oks[2]->pass, "third failed");
  is($oks[2]->name, "just give up", "the final Ok test looks like our abort");
  isa_ok($oks[2]->get_meta('test_abort_object'), 'failure::testabort', 'test_abort_object');
};

subtest "second subtest" => sub {
  my @oks = grep {; $_->isa('Test2::Event::Ok') } @{ $subtests[1]->subevents };
  is(@oks, 5, "three pass/fail events");
  ok($oks[0]->pass,   "first passed");
  ok($oks[1]->pass,   "second passed");
  ok($oks[2]->pass,   "third passed");
  ok(! $oks[3]->pass, "fourth failed");
  ok($oks[4]->pass,   "fifth passed");

  is($oks[3]->name, "zulu", "the abort Ok test looks like our abort");
  isa_ok($oks[3]->get_meta('test_abort_object'), 'failure::testabort', 'test_abort_object');
};

done_testing;

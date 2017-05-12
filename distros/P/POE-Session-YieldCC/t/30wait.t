use strict;
use warnings;
use POE;
use POE::Session::YieldCC;
use Test::More tests => 19;

POE::Session::YieldCC->create(
  inline_states => {
    _start => sub {
      $_[KERNEL]->yield('waiter1');
      $_[KERNEL]->delay('event1', 5);
      $_[KERNEL]->delay('in_between1', 1);
    },
    waiter1 => sub {
      my $start = time;
      ok($_[SESSION]->wait('event1'), "didn't time out waiting for 'event1'");
      ok((time - $start) > 3, "waited at least 3 seconds for 'event1'?");
      ok($_[HEAP]{in_between1}, "stuff happened while we waited");

      $_[KERNEL]->delay('event1',1);
      $_[SESSION]->sleep(5);
      ok($_[HEAP]{caught_event1}, "'event1' handler gone after finished waiting");

      $_[KERNEL]->yield('waiter2');
      $_[KERNEL]->delay('event2', 5, 1, 2, [3, 4], "abc");
      $_[KERNEL]->yield('in_between2', 1);
    },
    waiter2 => sub {
      my $start = time;
      my ($res, @args) = $_[SESSION]->wait('event2');
      ok($res, "didn't time out waiting for 'event2'");
      ok((time - $start) > 3, "waited at least 3 seconds for 'event2'?");
      is_deeply(\@args, [1, 2, [3, 4], "abc"], "got the arguments back we passed into 'event2'");
      ok($_[HEAP]{in_between1}, "stuff happened while we waited");

      $_[KERNEL]->delay('event2',1);
      $_[SESSION]->sleep(5);
      ok($_[HEAP]{caught_event2}, "'event2' handler gone after finished waiting");

      $_[KERNEL]->yield('waiter3');
      $_[KERNEL]->delay('event3', 10);
      $_[KERNEL]->yield('in_between3', 1);
    },
    waiter3 => sub {
      my $start = time;
      ok(!$_[SESSION]->wait('event3', 5), "timed out waiting for 'event3'");
      ok((time - $start) > 3, "waited at least 3 seconds for 'event3'?");
      ok($_[HEAP]{in_between3}, "stuff happened while we waited");

      $_[SESSION]->sleep(10);
      ok($_[HEAP]{caught_event3}, "'event3' handler gone after finished waiting");

      $_[KERNEL]->yield('waiter4');
      $_[KERNEL]->delay('event4', 10);
      $_[KERNEL]->delay('in_between4', 1);
    },
    waiter4 => sub {
      my $start = time;
      ok(!$_[SESSION]->wait('event4', 5, sub {
        $_[HEAP]{'caught_'.$_[STATE].'x'}++ && $poe_kernel->state($_[STATE]);
      }), "timed out waiting for 'event4'");
      ok((time - $start) > 3, "waited at least 3 seconds for 'event4'?");
      ok($_[HEAP]{in_between4}, "stuff happened while we waited");

      $_[SESSION]->sleep(10);
      is($_[HEAP]{caught_event4x}, 1, "'event4' handler still there after finished waiting");

      $_[KERNEL]->delay('event4',1);
      $_[SESSION]->sleep(5);
      is($_[HEAP]{caught_event4x}, 2, "'event4' handler still there....");

      $_[KERNEL]->delay('event4',1);
      $_[SESSION]->sleep(5);
      ok($_[HEAP]{caught_event4}, "'event4' handler now gone");
    },
    in_between1 => sub { $_[HEAP]{in_between1} = 1 },
    in_between2 => sub { $_[HEAP]{in_between2} = 1 },
    in_between3 => sub { $_[HEAP]{in_between3} = 1 },
    in_between4 => sub { $_[HEAP]{in_between4} = 1 },
    _default => sub { $_[HEAP]{'caught_'.$_[ARG0]} = 1; },
  },
);

$poe_kernel->run();

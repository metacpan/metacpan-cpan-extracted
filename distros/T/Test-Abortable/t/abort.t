use strict;
use warnings;

use Test2::API qw(intercept);

use Test::Abortable;
use Test::More;

{
  package Test2::EventDumper;
  sub dump {
    my ($events) = @_;
    _dump($events, '');
  }

  sub _dump {
    my ($events, $prefix) = @_;

    my $str = q{};
    for my $event (@$events) {
      (my $type = ref $event) =~ s/^Test2::Event:://;
      if ($event->isa('Test2::Event::Subtest')) {
        $str .= ref($event) . "\n";
        $str .= _dump($event->subevents, q{  });
      } elsif ($event->isa('Test2::Event::Plan')) {
        (my $plan = $event->summary) =~ s/^Plan is //;
        $str .= sprintf qq{%s(%s)\n}, $type, $event->summary;
      } elsif ($event->isa('Test2::Event::Ok')) {
        my $name = $event->name;
        $name =~ s/[\v\n\r]//g;
        $str .= sprintf qq{%s/%s(%s)\n},
          $type,
          ($event->pass ? 'Pass' : 'Fail'),
          $name;
      } elsif ($event->isa('Test2::Event::Diag') or $event->isa('Test2::Event::Note')) {
        my $msg = $event->message;
        chomp $msg;
        $msg =~ s/[\v\n\r]/<>/g;
        $str .= sprintf qq{%s("%s")\n}, $type, $msg;
      } else {
        $str .= ref($event) . "\n";
      }
    }

    $str =~ s/^/$prefix/gm;
    return $str;
  }
}

{
  package Abort::Test;

  use Data::Dumper;

  use overload '""' => sub { Dumper($_[0]) };

  sub throw {
    my $self = bless $_[1], $_[0];
    die $self;
  }

  sub as_test_abort_events {
    my @diag = @{ $_[0]{diagnostics} || [] };
    return [
      [ Ok => (pass => $_[0]{pass} || 0, name => $_[0]{description}) ],
      map {; [ Diag => (message => $_) ] } @diag,
    ];
  }
}

my $events = intercept {
  Test::Abortable::subtest "this test will abort" => sub {
    pass("one");
    pass("two");

    Abort::Test->throw({
      description => "just give up",
    });

    pass("three");
    pass("four");
    pass("five");
  };

  Test::More::subtest "this will run just fine" => sub {
    pass("everything is just fine");

    testeval {
      pass("alfa");
      pass("bravo");
      Abort::Test->throw({ description => "zulu" });
      pass("charlie");
    };

    pass("do you like gladiators?");
  };

  Test::Abortable::subtest "I like fine wines and cheeses" => sub {
    pass("wine wine wine wine cheese");

    Abort::Test->throw({
      pass => 1,
      description => "that was enough wine and cheese",
      diagnostics => [ "Fine wine", "Fine cheese" ],
    });

    fail("feeling gross");
  };

  Test::Abortable::subtest "I like fine wines and cheeses" => sub {
    pass("I like New York in June.");
    die "How 'bout you?";
  }
};

# diag( Test2::EventDumper::dump($events) );

my @subtests = grep {; $_->isa('Test2::Event::Subtest') } @$events;

is(@subtests, 4, "we ran three subtests (the three test methods)");

subtest "first subtest" => sub {
  ok(! $subtests[0]->pass, "it failed");

  my @oks = grep {; $_->isa('Test2::Event::Ok') } @{ $subtests[0]->subevents };
  is(@oks, 3, "three pass/fail events");
  ok($oks[0]->pass, "first passed");
  ok($oks[1]->pass, "second passed");
  ok(! $oks[2]->pass, "third failed");
  is($oks[2]->name, "just give up", "the final Ok test looks like our abort");
  isa_ok($oks[2]->get_meta('test_abort_object'), 'Abort::Test', 'test_abort_object');
};

subtest "second subtest" => sub {
  ok(! $subtests[1]->pass, "it failed");

  my @oks = grep {; $_->isa('Test2::Event::Ok') } @{ $subtests[1]->subevents };
  is(@oks, 5, "three pass/fail events");
  ok($oks[0]->pass,   "first passed");
  ok($oks[1]->pass,   "second passed");
  ok($oks[2]->pass,   "third passed");
  ok(! $oks[3]->pass, "fourth failed");
  ok($oks[4]->pass,   "fifth passed");

  is($oks[3]->name, "zulu", "the abort Ok test looks like our abort");
  isa_ok($oks[3]->get_meta('test_abort_object'), 'Abort::Test', 'test_abort_object');
};

subtest "third subtest" => sub {
  ok($subtests[2]->pass, "it passed");

  my @oks = grep {; $_->isa('Test2::Event::Ok') } @{ $subtests[2]->subevents };
  is(@oks, 2, "two pass/fail events");
  ok($oks[0]->pass, "first passed");
  ok($oks[1]->pass, "second passed");
  is(
    $oks[1]->name,
    "that was enough wine and cheese",
    "the final Ok test looks like our abort"
  );
  isa_ok($oks[1]->get_meta('test_abort_object'), 'Abort::Test', 'test_abort_object');

  my @diags = grep {; $_->isa('Test2::Event::Diag') } @{ $subtests[2]->subevents };
  is(@diags, 2, "we have two diagnostics");
  is_deeply(
    [ map {; $_->message } @diags ],
    [
      "Fine wine",
      "Fine cheese",
    ],
    "...which we expected",
  );
};

subtest "fourth subtest" => sub {
  ok(! $subtests[3]->pass, "it failed");

  my @events = @{ $subtests[3]->subevents };
  is(@events, 1, "we get two events");
  ok($events[0]->pass, "first passed");
  # TODO: test the diag of the error

};

done_testing;

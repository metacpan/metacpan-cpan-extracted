use strictures 1;
use Test::More;
use Test::Fatal;
use FindBin;
use lib "$FindBin::Bin/lib";
$ENV{OBJECT_REMOTE_TEST_LOGGER} = 1;

use Object::Remote;
use Object::Remote::Future qw( await_all await_future );
use ORTestClass;

my $state = [];

my $_make_future_keep_proxy = sub {
  # note: do not store the remote proxy somewhere
  my $proxy = ORTestClass->new::on('-');
  my $future = $proxy->start::call_callback(23, sub { sleep 1 });
  push @$state, $proxy;
  return $future;
};

my $_make_future = sub {
  # note: do not store the remote proxy somewhere
  my $future = ORTestClass
    ->new::on('-')
    ->start::call_callback(23, sub { sleep 1 });
};

my @tests = (
  ['proxy kept', $_make_future_keep_proxy],
  ['proxy thrown away', $_make_future],
);

for my $test (@tests) {
  my ($title, $make) = @$test;
  subtest $title, sub {

    do {
      my $future = $make->();
      local $SIG{ALRM} = sub { die "future timed out" };
      alarm 10;
      is exception {
        my $result = await_future $future;
        is $result, 23, 'correct value';
        alarm 0;
      }, undef, 'no errors for await_future';
    };

    do {
      my $future = $make->();
      local $SIG{ALRM} = sub { die "future timed out" };
      alarm 10;
      is exception {
        my @result = await_all $future;
        is $result[0], 23, 'correct value';
        alarm 0;
      }, undef, 'no errors for await_all';
    };

    done_testing;
  };
}

done_testing;

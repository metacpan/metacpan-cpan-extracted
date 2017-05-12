use strict;
use warnings;
use Test::More;
use Module::New::Queue;

sub items_in_queue_are {
  my ($expected) = @_;

  my $number_in_queue = scalar Module::New::Queue->queue;
  ok $number_in_queue == $expected,
     "$number_in_queue items are queued";
}

sub joined_string_is {
  my ($expected) = @_;

  my $string = join ', ', map { $_->() } Module::New::Queue->queue;
  ok $string eq $expected,
     "and the order is right: $string";
}

subtest basic => sub {
  Module::New::Queue->clear;
  Module::New::Queue->register(sub { "first" });
  Module::New::Queue->register(sub { "second" });
  Module::New::Queue->register(sub { "third" });

  items_in_queue_are(3);
  joined_string_is('first, second, third');
};

subtest localized => sub {
  Module::New::Queue->clear;
  Module::New::Queue->register(sub { "first" });
  Module::New::Queue->register(sub { "second" });
  Module::New::Queue->localize(sub {
    Module::New::Queue->register(sub { "local first" });
    Module::New::Queue->register(sub { "local second" });

    items_in_queue_are(2);
    joined_string_is('local first, local second');
  });
  Module::New::Queue->register(sub { "third" });

  items_in_queue_are(3);
  joined_string_is('first, second, third');
};

done_testing;

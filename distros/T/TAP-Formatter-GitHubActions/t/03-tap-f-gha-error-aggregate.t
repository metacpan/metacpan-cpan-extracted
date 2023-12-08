use strict;
use warnings;
use v5.16;
use Test::More;
use TAP::Harness;
use TAP::Formatter::GitHubActions::Error;
use TAP::Formatter::GitHubActions::ErrorAggregate;

sub _make_error {
  my ($title, $line, $message) = @_;
  return TAP::Formatter::GitHubActions::Error->new(
    test_name => $title,
    filename => 't/filename.t',
    line => $line,
    context_msg => $message,
  );
}

my @tests = grep { -f $_ } <t/fixtures/tests/*>;

plan tests => 4;

use_ok('TAP::Formatter::GitHubActions::Error');

subtest 'add' => sub {
  my $aggregate = TAP::Formatter::GitHubActions::ErrorAggregate->new();
  my $error1 = _make_error('title', 10, 'context');
  my $error2 = _make_error('second title', 7);
  $aggregate->add($error1);

  is(scalar keys %{$aggregate->groups}, 1, 'saves into a group');

  $aggregate->add($error2);
  is(scalar keys %{$aggregate->groups}, 2, 'saves into another group');

  is_deeply([sort keys %{$aggregate->groups}], [10, 7], 'groups');
};

subtest 'group' => sub {
  my $aggregate = TAP::Formatter::GitHubActions::ErrorAggregate->new();
  my $error1 = _make_error('title', 10, 'context');
  my $error2 = _make_error('second title', 7);
  $aggregate->add($error1, $error2);

  ok($aggregate->group(99)->isa('TAP::Formatter::GitHubActions::ErrorGroup'), 'creates a group');
  is_deeply($aggregate->group(99)->errors, [], 'fetches the group');
};


subtest 'as_sorted_array' => sub {
  my $aggregate = TAP::Formatter::GitHubActions::ErrorAggregate->new();
  my $error1 = _make_error('title', 10, 'context');
  my $error3 = _make_error('second title', 6);
  my $error2 = _make_error('second title', 20);

  $aggregate->add($error1, $error2, $error3);
  is_deeply([map { $_->line } $aggregate->as_sorted_array('t/sample-test.t')], [6, 10, 20], 'gets groups sorted');
};

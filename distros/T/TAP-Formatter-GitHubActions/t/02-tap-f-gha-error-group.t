use strict;
use warnings;
use v5.16;
use Test::More;
use TAP::Harness;
use TAP::Formatter::GitHubActions::Error;
use TAP::Formatter::GitHubActions::ErrorGroup;

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

plan tests => 5;

use_ok('TAP::Formatter::GitHubActions::Error');

subtest 'add' => sub {
  my $group = TAP::Formatter::GitHubActions::ErrorGroup->new(line => 10);
  my $error1 = _make_error('title', 10, 'context');
  my $error2 = _make_error('second title', 7);
  $group->add($error1);

  is_deeply($group->errors, [$error1], 'adds correctly');
  $group->add($error2);
  is_deeply($group->errors, [$error1, $error2], 'adds correctly');
};

subtest 'as_markdown_summary' => sub {
  my $group = TAP::Formatter::GitHubActions::ErrorGroup->new(line => 10);
  my $error1 = _make_error('title', 10, 'context');
  my $error2 = _make_error('second title', 7);

  $group->add($error1, $error2);

  my $output = <<~MARKDOWN
     - title on line 10
        ```
        context
        ```
     - second title on line 7
    MARKDOWN
    ;

  is($group->as_markdown_summary(), $output, 'renders in markdown');
};

subtest 'as_summary_hash' => sub {
  my $group = TAP::Formatter::GitHubActions::ErrorGroup->new(line => 10);
  my $error1 = _make_error('title', 10, 'context');
  my $error2 = _make_error('second title', 7);

  my $body = <<~BODY
    title
    --- CAPTURED CONTEXT ---
    context
    ---  END OF CONTEXT  ---

    second title
    BODY
    ;
  chomp($body);

  my $expected = {
    title => '2 failed tests',
    body => $body,
  };
  $group->add($error1, $error2);

  is_deeply($group->as_summary_hash(), $expected, 'build summary');
};

subtest 'as_gha_summary_for' => sub {
  my $group = TAP::Formatter::GitHubActions::ErrorGroup->new(line => 10);
  my $error1 = _make_error('title', 10, 'context');
  my $error2 = _make_error('second title', 10);

  my $body = <<~BODY
    title
    --- CAPTURED CONTEXT ---
    context
    ---  END OF CONTEXT  ---

    second title
    BODY
    ;
  chomp($body);

  $group->add($error1, $error2);

  my $expected = "::error file=t/sample-test.t,line=10,title=2 failed tests::title%0A--- CAPTURED CONTEXT ---%0Acontext%0A---  END OF CONTEXT  ---%0A%0Asecond title\n";
  is($group->as_gha_summary_for('t/sample-test.t'), $expected, 'renders gha error line');
};

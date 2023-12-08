use strict;
use warnings;
use v5.16;
use Test::More;
use TAP::Harness;
use TAP::Formatter::GitHubActions::Error;

my @tests = grep { -f $_ } <t/fixtures/tests/*>;

plan tests => 5;

use_ok('TAP::Formatter::GitHubActions::Error');

my $err;

subtest 'Regular Constructor' => sub {
  my $err = TAP::Formatter::GitHubActions::Error->new(
    test_name => 'Failed test',
    filename => 't/filename.t',
    line => 10,
    context_msg => 'a context message',
  );

  my $expected = <<~PLAIN_TEXT
    Failed test
    --- CAPTURED CONTEXT ---
    a context message
    ---  END OF CONTEXT  ---
    PLAIN_TEXT
    ;
  chomp($expected);

  is($err->as_plain_text(), $expected, 'render error in plain text correctly');
};

subtest 'From output constructor' => sub {
  my $original_output = <<~ORIGINAL_OUT
    Failed test 'render error'
    at t/sample-test.t line 20.
           got: 'Failed test'
      expected: 'Not Failing'
    ORIGINAL_OUT
    ;

  chomp($original_output);

  my $err = TAP::Formatter::GitHubActions::Error->from_output($original_output);

  my $expected = <<~PLAIN_TEXT
    Failed test 'render error'
    --- CAPTURED CONTEXT ---
           got: 'Failed test'
      expected: 'Not Failing'
    ---  END OF CONTEXT  ---
    PLAIN_TEXT
    ;
  chomp($expected);

  is($err->as_plain_text(), $expected, 'render error in plain text correctly');

  # with an invalid output
  $original_output = <<~ORIGINAL_OUT
    Faild test 'render error'
    at t/sample-test.t line 20.
           got: 'Failed test'
      expected: 'Not Failing'
    ORIGINAL_OUT
    ;
  $err = TAP::Formatter::GitHubActions::Error->from_output($original_output);
  is($err, undef, 'returns undef if the pattern does not match');
};

subtest 'Without context' => sub {
  my $original_output = <<~ORIGINAL_OUT
    Failed test at t/sample-test.t line 20.
    ORIGINAL_OUT
    ;

  chomp($original_output);

  my $err = TAP::Formatter::GitHubActions::Error->from_output($original_output);

  my $expected = <<~PLAIN_TEXT
    Failed test
    PLAIN_TEXT
    ;
  chomp($expected);

  is($err->as_plain_text(), $expected, 'render error in plain text correctly');
};

subtest 'Decorated context' => sub {
  my $original_output = <<~ORIGINAL_OUT
    Failed test 'render error'
    at t/sample-test.t line 20.
           got: 'Failed test'
      expected: 'Not Failing'
    ORIGINAL_OUT
    ;

  chomp($original_output);

  my $err = TAP::Formatter::GitHubActions::Error->from_output($original_output);

  my $expected = <<~PLAIN_TEXT
           got: 'Failed test'
      expected: 'Not Failing'
    PLAIN_TEXT
    ;
  chomp($expected);

  is($err->decorated_context_message(), $expected, 'render decorated context');

  $expected = <<~PLAIN_TEXT
    ---
           got: 'Failed test'
      expected: 'Not Failing'
    PLAIN_TEXT
    ;
  chomp($expected);

  is($err->decorated_context_message('---'), $expected, 'render decorated context with pre');

  $expected = <<~PLAIN_TEXT
           got: 'Failed test'
      expected: 'Not Failing'
    ---
    PLAIN_TEXT
    ;
  chomp($expected);

  is($err->decorated_context_message(undef, '---'), $expected, 'render decorated context with post');

  $expected = <<~PLAIN_TEXT
    ---
           got: 'Failed test'
      expected: 'Not Failing'
    ---
    PLAIN_TEXT
    ;
  chomp($expected);

  is($err->decorated_context_message('---', '---'), $expected, 'render decorated context with pre and post');

  $original_output = <<~ORIGINAL_OUT
    Failed test at t/sample-test.t line 20.
    ORIGINAL_OUT
    ;

  $err = TAP::Formatter::GitHubActions::Error->from_output($original_output);

  is($err->decorated_context_message(), undef, 'does not render if there is no context');
};


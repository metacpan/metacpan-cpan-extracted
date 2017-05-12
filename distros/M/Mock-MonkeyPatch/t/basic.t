use strict;
use warnings;

use Test::More;
use Mock::MonkeyPatch;

my $called;
{
  package Local::Func;
  sub func { $called++; 'orig' }
}

my $orig = \&Local::Func::func;

subtest 'standard usage' => sub {
  my $mock = Mock::MonkeyPatch->patch(
    'Local::Func::func' => sub { 'mock' }
  );

  isnt \&Local::Func::func, $orig, 'mock was injected';
  ok $mock->store_arguments, 'store_arguments defaults to true';

  is Local::Func::func(qw/a b c/), 'mock', 'got mocked value';
  is $mock->called, 1, 'mock was called';
  ok !$called, 'original function was not called';
  is_deeply $mock->arguments, [qw/a b c/], 'got the passed arguments';

  is Local::Func::func('x'), 'mock', 'got mocked value';
  is $mock->called, 2, 'mock was called again';
  ok !$called, 'original function was not called';
  is_deeply $mock->arguments(1), ['x'], 'got the new passed arguments';

  $mock->reset;
  ok !$mock->called, 'called is false after reset';
  ok !$mock->arguments(0), 'no arguments available after reset';
};

is \&Local::Func::func, $orig, 'mock was removed (DESTROY)';

subtest 'store arguments' => sub {
  my $mock = Mock::MonkeyPatch->patch(
    'Local::Func::func' => sub { 'mock' }, { store_arguments => 0 }
  );
  is $mock->store_arguments, 0, 'constructor arg';

  Local::Func::func(qw/a b c/);
  is $mock->called, 1, 'mock was called';
  is_deeply $mock->arguments, [], 'passed arguments not stored';

  $mock->store_arguments(1);
  Local::Func::func(qw/d e f/);
  is $mock->called, 2, 'mock was called';
  is_deeply $mock->arguments(1), [qw/d e f/], 'got the passed arguments';

  $mock->store_arguments(0);
  Local::Func::func(qw/g h i/);
  is $mock->called, 3, 'mock was called';
  is_deeply $mock->arguments(2), [], 'passed arguments not stored';

  $mock->restore;
  is \&Local::Func::func, $orig, 'mock was removed';
};

subtest 'only restore once' => sub {
  my $mock = Mock::MonkeyPatch->patch(
    'Local::Func::func' => sub { 'mock' }
  );

  isnt \&Local::Func::func, $orig, 'mock was injected';
  $mock->restore;
  is \&Local::Func::func, $orig, 'mock was removed';

  my $other = Mock::MonkeyPatch->patch(
    'Local::Func::func' => sub { 'other' }
  );

  my $new = \&Local::Func::func;
  isnt $new, $orig, 'new mock was injected';
  $mock->restore;
  is \&Local::Func::func, $new, 'new mock is still in place';
  isnt \&Local::Func::func, $orig, 'new mock was not removed';
};

subtest 'use ORIGINAL' => sub {
  my $mock = Mock::MonkeyPatch->patch(
    'Local::Func::func' => sub { Mock::MonkeyPatch::ORIGINAL() }
  );
  isnt \&Local::Func::func, $orig, 'mock was injected';
  is Local::Func::func(), 'orig', 'original function called via mock (return value)';
  ok $called, 'original was called via mock (counter)';
  ok $mock->called, 'mock was called';
};

subtest 'methods arguments' => sub {
  my $mock = Mock::MonkeyPatch->patch(
    'Local::Func::func' => sub { 'mock' }
  );
  my $inst = bless {}, 'Local::Func';
  is $inst->func(qw/a b c/), 'mock', 'mock a method call';
  is_deeply $mock->arguments, [$inst, qw/a b c/], 'standard arguments includes instance';
  is_deeply $mock->method_arguments, [qw/a b c/], 'method_arguments removes the first parameter';

  is_deeply $mock->method_arguments(0, 'Local::Func'), [qw/a b c/], 'method_arguments tests ISA with optional class';
  ok !$mock->method_arguments(0, 'Wrong::Class'), 'method_arguments with incorrect ISA returns undef';
};

subtest 'defined symbol required' => sub {
  my $symbol = 'Local::Func::doEzNotEXIstZ';
  my $mock;
  my $success = eval {
    $mock = Mock::MonkeyPatch->patch($symbol => sub { 'mock' });
    1;
  };

  my $err = "$@";
  like $@, qr/\QSymbol &$symbol is not already defined/, 'correct error message';
  ok !$success, 'statement did not succeed';
};

{
  package Local::Func;
  sub one { 1 }
  sub two { 2 }
}

subtest 'redefine warnings for ORIGINAL' => sub {
  my $warn = 0;
  local $SIG{__WARN__} = sub { $warn++ };
  my $one = Mock::MonkeyPatch->patch('Local::Func::one' => sub{ });
  my $two = Mock::MonkeyPatch->patch('Local::Func::two' => sub{ Local::Func::one() });
  Local::Func::two();
  ok !$warn, 'no warnings';
};

done_testing;


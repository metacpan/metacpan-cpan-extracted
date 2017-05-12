#!perl -T

use strict;
use warnings;
use lib 't/lib';

use Test::More 'no_plan';

BEGIN { use_ok('Sub::Pipeline'); }

use Test::SubPipeline;

{
  my $sub = test_pipeline;
  isa_ok($sub, 'Sub::Pipeline', 'sub');
  $sub->on_success('throw');

  my $code = \&$sub;

  isa_ok($code, 'CODE', "referenced code dereference of sub");

  eval { $code->() };
  isa_ok($@, 'Sub::Pipeline::Success');
}

{
  my $sub = test_pipeline;
  $sub->on_success('throw');

  my $r = eval { $sub->call; };

  isa_ok($@, 'Sub::Pipeline::Success', 'thrown exception');
}

{
  my $sub = test_pipeline;

  $sub->on_success('return');
  my $r = eval { $sub->call; };
  ok( !$@, "no exception thrown with 'return' behavior on");
  isa_ok($r, 'Sub::Pipeline::Success', 'return value');
}

SKIP: {
  skip "Why does the trace show ->call's invocant as undef?" => 3; # XXX
  my ($sub, $value) = test_pipeline;
  $sub->pipe(init => sub { $value = -10; die "internal failure" });
  eval { $sub->call; };
  my $e = $@;
  ok($e, "sub call threw exception");
  is(ref $e, '', "but it wasn't the success exception");
  cmp_ok($value, '==', -10, 'and now $value is -10');
}

{
  my $sub = test_pipeline;

  # XXX: inelegant way to test this! -- rjbs, 2006-03-21
  delete $sub->{pipe}{init};

  eval { $sub->call; };
  my $e = $@;
  ok($e, "sub call threw exception");
  isa_ok($e, 'Sub::Pipeline::PipeMissing');
}

{
  my $sub = test_pipeline;

  # XXX: inelegant way to test this! -- rjbs, 2006-03-21
  delete $sub->{pipe}{init};

  eval { $sub->check; };
  my $e = $@;
  ok($e, "sub check threw exception");
  isa_ok($e, 'Sub::Pipeline::PipeMissing');
}

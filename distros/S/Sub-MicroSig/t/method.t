#!perl -T
use strict;
use warnings;

use Test::More tests => 18;

BEGIN { use_ok('Sub::MicroSig'); }

sub method_with_params :MethodSig(foo) {
  shift;
  return @_;
}

sub method_with_optional_only :MethodSig(;foo) {
  shift;
  return @_;
}

sub zero_arg_method :MethodSig() {
  shift;
  return @_;
}

is_deeply(
  main->method_with_params({ foo => 20 }),
  { foo => 20 },
  "named params to simple sig"
);

is_deeply(
  main->method_with_params([ 20 ]),
  { foo => 20 },
  "positional params to simple sig"
);

eval { main::method_with_params(undef, [ 20 ]); };
like($@, qr/valid invocant/, "a method must have a valid invocant");

eval { main->method_with_params(10); };
like($@, qr/args to microsig'd method/, "a plain scalar isn't an OK arg");

eval { main->method_with_params; };
like($@, qr/parameter 'foo' missing/, "passing no arg fails: missing foo");

eval { main->method_with_params([ ]); };
like($@, qr/not enough arg/, "passing [] fails: missing foo");

eval { main->method_with_params({ }); };
like($@, qr/parameter 'foo' missing/, "passing {} fails: missing foo");

eval { main->method_with_params([1], [2]); };
like($@, qr/args to microsig'd method/, "you can only give one arg");

eval { main->method_with_params([1, 2]); };
like($@, qr/too many arguments/, "error on too many args to one-arg method");

eval { main->zero_arg_method({}); };
is($@, '', "no error calling zero-arg method with {}");

eval { main->zero_arg_method([]); };
is($@, '', "no error calling zero-arg method with []");

eval { main->zero_arg_method; };
is($@, '', "no error calling zero-arg method with NO param (even {} or [])");

eval { main->zero_arg_method([ 1 ]); };
like($@, qr/too many arguments/, "error with too many args to zero-arg method");

eval { main->method_with_optional_only([ 1 ]); };
is($@, '', "no error calling one-optional-arg method with one pos'l arg");

eval { main->method_with_optional_only({}); };
is($@, '', "no error calling one-optional-arg method with {}");

eval { main->method_with_optional_only([]); };
is($@, '', "no error calling one-optional-arg method with []");

eval { main->method_with_optional_only; };
is($@, '', "no error calling one-optional-arg method with NO param");

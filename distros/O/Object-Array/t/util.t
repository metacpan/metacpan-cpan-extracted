#!perl

use strict;
use warnings;

use Data::Dumper;
use Test::More;
use Object::Array qw(Array);
use List::MoreUtils ();

my @UTILS = @Object::Array::Plugin::ListMoreUtils::UTILS;

my %ARR = (
  DEFAULT => [ 1, undef, 0, "a", "z" ],
  minmax  => [ 1, 5, -3, 7, 2.5 ],
  uniq    => [ 1, 0, 7, 7, 2, 0, 5 ],
);

my %ARG = (
  DEFAULT => [ sub { defined } ],
  apply => [ sub { ++$_ } ],
  insert_after => [ sub { !defined }, "hello" ],
  insert_after_string => [ 'a', 'bcd' ],
);

my %SKIP_RESULT = (
  map { $_ => 1 }
    qw(natatime),
);

my %NEED_REF = (
  map { $_ => 1 }
    qw(insert_after insert_after_string)
);

plan(tests => 6 + @UTILS * 2 - keys %SKIP_RESULT);

no strict 'refs';
for my $util (@UTILS) {
  my @arr = @{ $ARR{$util} || $ARR{DEFAULT} };
  my $arr = Array [ @arr ];
  local $SIG{__WARN__} = sub { diag("$util: @_") };
  my @args = @{ $ARG{$util} || $ARG{DEFAULT} };
  my $got  = [ $arr->$util(@args) ];
  my $want = [ &{"List::MoreUtils::$util"}(
    @args, ($NEED_REF{$util} ? \@arr : @arr),
  ) ];
  my $error = 0;
  $SKIP_RESULT{$util} || is_deeply($got, $want, "$util: result") or $error++;
  
  is_deeply([ @$arr ], \@arr, "$util: arrays") or $error++;
  
  $error and diag(Dumper(
    $got, $want,
    $arr, \@arr,
  ));
}

my $ref = \1;
my $arr = Array([ 1, 5, "hello", $ref, undef, 0 ]);
ok($arr->contains(undef), "array contains undef");
ok(!$arr->contains(""), "empty string doesn't match undef");
ok($arr->contains("hello"), "array contains string");
ok($arr->contains(5), "array contains number");
ok($arr->contains("5.00"), "array contains number (string)");
ok($arr->contains($ref), "array contains reference");

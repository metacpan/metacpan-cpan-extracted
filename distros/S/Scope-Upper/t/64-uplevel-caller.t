#!perl -T

use strict;
use warnings;

use Test::More tests => ((3 * 4) / 2) * 2 * 2 + 8;

use Scope::Upper qw<uplevel HERE CALLER>;

sub callstack {
 my ($check_args) = @_;
 my $i = 1;
 my @stack;
 while (1) {
  my @c = $check_args ? do { package DB; caller($i++) }
                      : caller($i++);
  last unless @c;
  if ($check_args) {
   my $args = $c[4] ? [ @DB::args ] : undef;
   push @c, $args;
  }
  push @stack, \@c;
 }
 return \@stack;
}

my @stacks;

sub three {
 my ($depth, $code) = @_;
 $stacks[0] = callstack(1);
 &uplevel($code, 'three', CALLER($depth));
}

my $two = sub {
 $stacks[1] = callstack(1);
 three(@_, 'two');
};

sub one {
 $stacks[2] = callstack(1);
 $two->(@_, 'one');
}

sub tester_sub { callstack(1) }

my $tester_anon = sub { callstack(1) };

my @subs = (\&three, $two, \&one);

for my $height (0 .. 2) {
 my $base = $subs[$height];

 for my $anon (0, 1) {
  my $code = $anon ? $tester_anon : \&tester_sub;

  for my $depth (0 .. $height) {
   my $desc = "callstack at depth $depth/$height";
   $desc .= $anon ? ' (anonymous callback)' : ' (named callback)';

   local $@;
   my $result = eval { $base->($depth, $code, 'zero') };
   is        $@,    '',                "$desc: no error";
   is_deeply $result, $stacks[$depth], "$desc: correct call stack";
  }
 }
}

sub four {
 my $cb = shift;
 &uplevel($cb, 1, HERE);
}

{
 my $desc = "recalling in the coderef passed to uplevel (anonymous)";
 my $cb;
 $cb = sub { $_[0] ? $cb->(0) : callstack(0) };
 local $@;
 my ($expected, $got) = eval { $cb->(1), four($cb) };
 is $@, '', "$desc: no error";
 $expected->[1]->[3] = 'main::four';
 is_deeply $got, $expected, "$desc: correct call stack";
}

sub test_named_recall { $_[0] ? test_named_recall(0) : callstack(0) }

{
 my $desc = "recalling in the coderef passed to uplevel (named)";
 local $@;
 my ($expected, $got) = eval { test_named_recall(1),four(\&test_named_recall) };
 is $@, '', "$desc: no error";
 $expected->[1]->[3] = 'main::four';
 is_deeply $got, $expected, "$desc: correct call stack";
}

my $mixed_recall_1;
sub test_mixed_recall_1 {
 if ($_[0]) {
  $mixed_recall_1->(0)
 } else {
  callstack(0)
 }
}
$mixed_recall_1 = \&test_mixed_recall_1;

{
 my $desc = "recalling in the coderef passed to uplevel (mixed 1)";
 local $@;
 my ($expected, $got) = eval { test_mixed_recall_1(1), four($mixed_recall_1) };
 is $@, '', "$desc: no error";
 $expected->[1]->[3] = 'main::four';
 is_deeply $got, $expected, "$desc: correct call stack";
}

my $mixed_recall_2_bis = do {
 my $mixed_recall_2;

 {
  my $fake1;

  eval q{
   my $fake2;

   {
    my $fake3;

    sub test_mixed_recall_2 {
     $fake1++;
     $fake2++;
     $fake3++;
     if ($_[0]) {
      $mixed_recall_2->(0)
     } else {
      callstack(0)
     }
    }
   }
  };
 }

 $mixed_recall_2 = \&test_mixed_recall_2;
};

{
 my $desc = "recalling in the coderef passed to uplevel (mixed 2)";
 local $@;
 my ($expected, $got) = eval { test_mixed_recall_2(1), four($mixed_recall_2_bis) };
 is $@, '', "$desc: no error";
 $expected->[1]->[3] = 'main::four';
 is_deeply $got, $expected, "$desc: correct call stack";
}

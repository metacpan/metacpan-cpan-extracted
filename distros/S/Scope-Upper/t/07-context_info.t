#!perl -T

my $exp0 = ::expected('block', 0, undef);

use strict;
use warnings;

use Config qw<%Config>;

# We're using Test::Leaner here because Test::More loads overload, which itself
# uses warning::register, which may cause the "all warnings on" bitmask to
# change ; and that doesn't fit well with how we're testing things.

use lib 't/lib';
use Test::Leaner tests => 18 + 6;

use Scope::Upper qw<context_info UP HERE CALLER>;

sub HINT_BLOCK_SCOPE () { 0x100 }

sub expected {
 my ($type, $line, $want) = @_;

 my $top;

 my @caller = caller 1;
 my @here   = caller 0;
 unless (@caller) {
  @caller   = @here;
  $top++;
 }

 my $pkg = $here[0];
 my ($file, $eval, $require, $hints, $warnings, $hinthash)
                                                   = @caller[1, 6, 7, 8, 9, 10];

 $line = $caller[2] unless defined $line;

 my ($sub, $hasargs);
 if ($type eq 'sub' or $type eq 'eval' or $type eq 'format') {
  $sub     = $caller[3];
  $hasargs = $caller[4];
  $want    = $caller[5];
  $want    = '' if defined $want and not $want;
 }

 if ($top) {
  $want      = "$]" < 5.015_001 ? '' : undef;
  $hints    &= ~HINT_BLOCK_SCOPE if $Config{usesitecustomize};
  $hints    |=  HINT_BLOCK_SCOPE if "$]" >= 5.019003;
  $warnings  = sub { use warnings; (caller 0)[9] }->() if  "$]" < 5.007
                                                       and not $^W;
 }

 my @exp = (
  $pkg,
  $file,
  $line,
  $sub,
  $hasargs,
  $want,
  $eval,
  $require,
  $hints,
  $warnings,
 );
 push @exp, $hinthash if "$]" >= 5.010;

 return \@exp;
}

sub setup () {
 my $pkg = caller;

 for my $sub (qw<context_info UP HERE is_deeply expected>) {
  no strict 'refs';
  *{"${pkg}::$sub"} = \&{"main::$sub"};
 }
}

is_deeply [ context_info       ], $exp0, 'main : context_info';
is_deeply [ context_info(HERE) ], $exp0, 'main : context_info HERE';
is_deeply [ context_info(-1)   ], $exp0, 'main : context_info -1';

package Scope::Upper::TestPkg::A; BEGIN { ::setup }
my @a = sub {
 my $exp1 = expected('sub', undef);
 is_deeply [ context_info ], $exp1, 'sub0 : context_info';
 package Scope::Upper::TestPkg::B; BEGIN { ::setup }
 {
  my $exp2 = expected('block', __LINE__, 1);
  is_deeply [ context_info     ], $exp2, 'sub : context_info';
  is_deeply [ context_info(UP) ], $exp1, 'sub : context_info UP';
  package Scope::Upper::TestPkg::C; BEGIN { ::setup }
  for (1) {
   my $exp3 = expected('loop', __LINE__ - 1, undef);
   is_deeply [ context_info        ], $exp3, 'for : context_info';
   is_deeply [ context_info(UP)    ], $exp2, 'for : context_info UP';
   is_deeply [ context_info(UP UP) ], $exp1, 'for : context_info UP UP';
  }
  package Scope::Upper::TestPkg::D; BEGIN { ::setup }
  my $eval_line = __LINE__+1;
  eval <<'CODE';
   my $exp4 = expected('eval', $eval_line);
   is_deeply [ context_info        ], $exp4, 'eval string : context_info';
   is_deeply [ context_info(UP)    ], $exp2, 'eval string : context_info UP';
   is_deeply [ context_info(UP UP) ], $exp1, 'eval string : context_info UP UP';
CODE
  die $@ if $@;
  package Scope::Upper::TestPkg::E; BEGIN { ::setup }
  my $x = eval {
   my $exp5 = expected('eval', __LINE__ - 1);
   package Scope::Upper::TestPkg::F; BEGIN { ::setup }
   do {
    my $exp6 = expected('block', __LINE__ - 1, undef);
    is_deeply [ context_info        ], $exp6, 'do : context_info';
    is_deeply [ context_info(UP)    ], $exp5, 'do : context_info UP';
    is_deeply [ context_info(UP UP) ], $exp2, 'do : context_info UP UP';
   };
   is_deeply [ context_info        ], $exp5, 'eval : context_info';
   is_deeply [ context_info(UP)    ], $exp2, 'eval : context_info UP';
   is_deeply [ context_info(UP UP) ], $exp1, 'eval : context_info UP UP';
  };
 }
}->(1);

package main;

sub first {
 do {
  second(@_);
 }
}

my $fourth;

sub second {
 my $x = eval {
  my @y = $fourth->();
 };
 die $@ if $@;
}

$fourth = sub {
 my $z = do {
  my $dummy;
  eval q[
   call(@_);
  ];
  die $@ if $@;
 }
};

sub call {
 for my $depth (0 .. 5) {
  my @got = context_info(CALLER $depth);
  my @exp = caller $depth;
  defined and not $_ and $_ = '' for $exp[5];
  is_deeply \@got, \@exp, "context_info vs caller $depth";
 }
}

first();

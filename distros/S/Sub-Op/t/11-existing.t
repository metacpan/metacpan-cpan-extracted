#!perl

use strict;
use warnings;

use blib 't/Sub-Op-LexicalSub';

use Test::More tests => 2 * ((2 + 2) * 4 + (1 + 2) * 5) + 2 * (2 + 2) + 4;

our $call_foo;
sub foo { ok $call_foo, 'the preexistent foo was called' }

our $call_bar;
sub bar () { ok $call_bar, 'the preexistent bar was called' }

sub X () { 1 }

our $call_blech;
sub blech { ok $call_blech, 'initial blech was called' };

our $called;

{
 local $/ = "####\n";
 while (<DATA>) {
  chomp;
  s/\s*$//;

  my ($code, $params)           = split /----\s*/, $_;
  my ($names, $ret, $exp, $seq) = split /\s*#\s*/, $params;

  my @names = split /\s*,\s*/, $names;

  my @exp = eval $exp;
  if ($@) {
   fail "@names: unable to get expected values: $@";
   next;
  }
  my $calls = @exp;

  my @seq;
  if ($seq) {
   s/^\s*//, s/\s*$//  for $seq;
   @seq = split /\s*,\s*/, $seq;
   die "calls and seq length mismatch" unless @seq == $calls;
  } else {
   @seq = ($names[0]) x $calls;
  }

  my $test = "{\n{\n";
  for my $name (@names) {
   $test .= <<"   INIT"
    use Sub::Op::LexicalSub $name => sub {
     ++\$called;
     my \$exp = shift \@exp;
     is_deeply \\\@_, \$exp,   '$name: arguments are correct';
     my \$seq = shift \@seq;
     is        \$seq, '$name', '$name: sequence is correct';
     $ret;
    };
   INIT
  }
  $test .= "{\n$code\n}\n";
  $test .= "}\n";
  for my $name (grep +{ map +($_, 1), qw/foo bar blech/ }->{ $_ }, @names) {
   $test .= <<"   CHECK_SUB"
    {
     local \$call_$name = 1;
     $name();
    }
   CHECK_SUB
  }
  $test .= "}\n";

  local $called = 0;
  eval $test;
  if ($@) {
   fail "@names: unable to evaluate test case: $@";
   diag $test;
  }

  is $called, $calls, "@names: the hook was called the right number of times";
  if ($called < $calls) {
   fail, fail for $called + 1 .. $calls;
  }
 }
}

is prototype('main::foo'), undef, "foo's prototype was preserved";
is prototype('main::bar'), '',    "bar's prototype was preserved";
is prototype('main::X'),   '',    "X's prototype was preserved";
ok Sub::Op::_constant_sub(do { no strict "refs"; \&{"main::X"} }),
                                  'X is still a constant';

__DATA__
foo();
----
foo # () # [ ]
####
foo;
----
foo # () # [ ]
####
foo(1);
----
foo # () # [ 1 ]
####
foo 2;
----
foo # () # [ 2 ]
####
local $call_foo = 1;
&foo();
----
foo # () #
####
local $call_foo = 1;
&foo;
----
foo # () #
####
local $call_foo = 1;
&foo(3);
----
foo # () #
####
local $call_foo = 1;
my $foo = \&foo;
$foo->();
----
foo # () #
####
local $call_foo = 1;
my $foo = \&foo;
&$foo;
----
foo # () #
####
bar();
----
bar # () # [ ]
####
bar;
----
bar # () # [ ]
####
bar(1);
----
bar # () # [ 1 ]
####
bar 2;
----
bar # () # [ 2 ]
####
local $call_bar = 1;
&bar();
----
bar # () #
####
local $call_bar = 1;
&bar;
----
bar # () #
####
local $call_bar = 1;
&bar(3);
----
bar # () #
####
local $call_bar = 1;
my $bar = \&bar;
$bar->();
----
bar # () #
####
local $call_bar = 1;
my $bar = \&bar;
&$bar;
----
bar # () #
####
is X, 2, 'constant overriding';
----
X # 2 # [ ]
####
no warnings 'redefine';
sub blech { fail 'redefined blech was called' }
BEGIN { $call_blech = 0 }
blech 7;
BEGIN { $call_blech = 1 }
----
blech # () # [ 7 ]

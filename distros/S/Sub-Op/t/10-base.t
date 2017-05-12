#!perl

use strict;
use warnings;

use blib 't/Sub-Op-LexicalSub';

use Test::More tests => (1 + 3) * 15 + (1 + 2 * 3) * 2 + 2 * 28;

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

  my $test = "{\n";
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
  for my $name (@names) {
   $test .= <<"   CHECK_VIVID"
    BEGIN {
     no warnings 'uninitialized'; # Test::Builder can't get the file name
     ok !exists &main::${name},  '$name: not stubbed';
     ok !defined &main::${name}, '$name: body not defined';
     is *main::${name}\{CODE\}, undef, '$name: empty symbol table entry';
    }
   CHECK_VIVID
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

__DATA__
foo();
----
foo # () # [ ]
####
bar;
----
bar # () # [ ]
####
baz(1);
----
baz # () # [ 1 ]
####
zap 2;
----
zap # () # [ 2 ]
####
package X;
main::flap 7, 8;
----
flap # () # [ 7, 8 ]
####
wut; wut 1; wut 2, 3
----
wut # () # [ ], [ 1 ], [ 2, 3 ]
####
qux(qux(1));
----
qux # @_ # [ 1 ], [ 1 ]
####
wat 1, wat, 2, wat(3, 4), 5
----
wat # @_ # [ ], [ 3, 4 ], [ 1, 2, 3, 4, 5 ]
####
sum sum sum(1, 2), sum(3, 4)
----
sum # do { my $s = 0; $s += $_ for @_; $s } # [ 1, 2 ], [ 3, 4 ], [ 3, 7 ], [ 10 ]
####
return;
my $x = \&func
----
func # () # ()
####
return;
__PACKAGE__->meth
----
meth # () # ()
####
fetch 1, do { no strict 'refs'; *{__PACKAGE__.'::fetch'}{CODE} }, 2
----
fetch # () # [ 1, undef, 2 ]
####
our $scalr = 1;
scalr $scalr;
----
scalr # () # [ 1 ]
####
our @array = (2, 3);
array @array;
----
array # () # [ 2, 3 ]
####
our %hash = (x => 4);
hash $hash{x};
----
hash # () # [ 4 ]
####
foo 1;
bar 2;
----
foo, bar # () # [ 1 ], [ 2 ] # foo, bar
####
foo 1, foo(2), 3, bar(4, foo(bar, 5), 6);
----
foo, bar # @_ # [ 2 ], [ ], [ 5 ], [ 4, 5, 6 ], [ 1, 2, 3, 4, 5, 6 ] # foo, bar, foo, bar, foo

#!/usr/bin/perl
require 5.00561;

use ExtUtils::testlib;
use Rx;
use strict;
my ($TESTS, $SUCCEED, $FAIL);
$/ = "";
while (<DATA>) {
  chomp;
  s/^#.*$//smg;
  my ($regex, @test_strings) = split /\n/;

  my %test;
  for (@test_strings) {
    my ($type, @args) = split;
    $test{$type} = \@args;
  }
  $test{END} = [length($regex)+1,0] unless exists $test{FAILS};
  $TESTS += exists $test{FAILS} ? 1 : 2 * keys %test;

  my $h = eval { Rx::rxdump($regex) };
  if (! defined $h) {
    if ($test_strings[0] eq 'FAILS') {
      ++$SUCCEED;               # It was *supposed* to fail
    } else {
      print "* Test $. /$regex/ failed to compile.\n";
      $FAIL += 2 * @test_strings;
    }
    next;
  }

  my %untested_node_types;
  my @nodes = (0);
  my %seq;
  while (@nodes) {
    my $nn = shift @nodes;
    my ($off, $len) = ($h->{OFFSETS}[$nn], $h->{LENGTHS}[$nn]);
    my $n = $h->{$nn};
    for my $item (qw(CHILD NEXT LOOKFOR)) {
      push @nodes, $n->{$item} if exists $n->{$item};
    }
    my $key = $n->{TYPE};
    $key .= "-$n->{STRING}" if $key eq 'EXACT';
    $key .= "-$n->{ARGS}" if $key eq 'OPEN' || $key eq 'CLOSE';
    $key .= "-" . ++$seq{$key} if $key eq 'BRANCH';
    if (exists $test{$key}) {
      my ($ex_off, $ex_len) = @{$test{$key}};
      my $good = 2;
      if ($ex_off != $off) {
        print "  Test $. /$regex/: $key had offset $off, s/b $ex_off\n";
        --$good;
      }
      if ($ex_len != $len) {
        print "  Test $. /$regex/: $key had length $len, s/b $ex_len\n";
        --$good;
      }
      $SUCCEED += $good;
      $FAIL += 2 - $good;
      delete $test{$key};
    } else {
      ++$untested_node_types{$key} ;
    }
  }

  $FAIL += 2 * keys %test;
  my $missing_tests;
  for my $testname (keys %test) {
    print "> Test $. /$regex/: Test $testname never tried.\n";
    $missing_tests = 1;
  }
  if ($missing_tests) {
    print "> Node types not tested: ", (join ' ', keys %untested_node_types), "\n";
  }
  undef %test;
}

print "Oops!  $SUCCEED + $FAIL != $TESTS\n" 
  if $SUCCEED + $FAIL != $TESTS;
my $WIN = sprintf "%.2f", 100*$SUCCEED/$TESTS;
print "\nFailed $FAIL/$TESTS tests.  Success: $WIN%.\n";

__DATA__
a+
EXACT-a 1 1
PLUS 2 1

a*
EXACT-a 1 1
STAR 2 1

(?:ab)+
CURLYM 7 1
EXACT-ab 4 2

(?:ab)*
CURLYM 7 1
EXACT-ab 4 2

(?:ab){12,42}
CURLYM 7 7
EXACT-ab 4 2

a[\r]b
EXACT-a 1 1
ANYOF 2 4
EXACT-b 6 1

a[\cM]b
EXACT-a 1 1
ANYOF 2 5
EXACT-b 7 1

a[\015]b
EXACT-a 1 1
ANYOF 2 6
EXACT-b 8 1

a{12}
CURLY 2 4
EXACT-a 1 1

a\db
EXACT-a 1 1
EXACT-b 4 1
DIGIT 2 2

^abc$
EXACT-abc 2 3
BOL 1 1
EOL 5 1

a|b
EXACT-a 1 1
EXACT-b 3 1
BRANCH-1 0 0
BRANCH-2 2 1

(a)b\1c
EXACT-a 2 1
EXACT-b 4 1
EXACT-c 7 1
OPEN-1 1 1
CLOSE-1 3 1
REF 5 2

(a)b\2c.
FAILS

(a)(b)\2c.
EXACT-a 2 1
EXACT-b 5 1
EXACT-c 9 1
OPEN-1 1 1
CLOSE-1 3 1
OPEN-2 4 1
CLOSE-2 6 1
REF 7 2

(a)b\22c.
EXACT-a 2 1
EXACT-bc 4 5 
OPEN-1 1 1
CLOSE-1 3 1
REG_ANY 9 1

(a)b\223c
EXACT-a 2 1
EXACT-b“c 4 6
OPEN-1 1 1
CLOSE-1 3 1

()()()()()()()()()()()\11c.
EXACT-c 26 1
REF 23 3

bc[d]ef
EXACT-bc 1 2
EXACT-ef 6 2
ANYOF 3 3

bc[defgh]ef
EXACT-bc 1 2
EXACT-ef 10 2
ANYOF 3 7

bc[^defgh]ef
EXACT-bc 1 2
EXACT-ef 11 2
ANYOF 3 8

(ab)c
EXACT-ab 2 2
EXACT-c 5 1
OPEN-1 1 1
CLOSE-1 4 1

(abc|defgh)
EXACT-abc 2 3
EXACT-defgh 6 5
BRANCH-1 1 1
BRANCH-2 5 1
OPEN-1 1 1
CLOSE-1 11 1

(ab|cde|fghi)
EXACT-ab 2 2
EXACT-cde 5 3
EXACT-fghi 9 4
BRANCH-1 1 1
BRANCH-2 4 1
BRANCH-3 8 1
OPEN-1 1 1
CLOSE-1 13 1

a.b
EXACT-a 1 1
EXACT-b 3 1
REG_ANY 2 1

a\p{Space}b
EXACT-a 1 1
EXACT-b 11 1
ANYOF 2 9

a(?>b*)c
EXACT-a 1 1
SUSPEND 2 6
EXACT-b 5 1
STAR 6 1
EXACT-c 8 1

a(?{print "dammit"})b
EXACT-a 1 1
EXACT-b 21 1
EVAL 2 19

(a(b*)c)+
EXACT-a 2 1
EXACT-b 4 1
EXACT-c 7 1
STAR 5 1
CURLYX 9 1
OPEN-1 1 1
CLOSE-1 8 1
OPEN-2 3 1
CLOSE-2 6 1


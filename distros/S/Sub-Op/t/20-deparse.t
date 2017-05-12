#!perl

use strict;
use warnings;

use blib 't/Sub-Op-LexicalSub';

use Test::More tests => 13;

use Devel::Peek;
use B::Deparse;

my $bd = B::Deparse->new;

$bd->ambient_pragmas(
 strict   => 'all',
 warnings => 'all',
);

{
 local $/ = "####\n";
 while (<DATA>) {
  chomp;
  s/\s*$//;
  my $code = $_;

  my $test = eval <<"  TESTCASE";
   sub {
    use Sub::Op::LexicalSub f => sub { };
    use Sub::Op::LexicalSub g => sub { };
    $code
   }
  TESTCASE
  if ($@) {
   fail "unable to compile testcase: $@";
   next;
  }
  my $deparsed = $bd->coderef2text($test);
  $deparsed =~ s[BEGIN \s* \{ \s* \$\^H \s* \{ .*? \} .*? \} \s*][]gxs;

  my $expected = do {
   local *f = sub { };
   local *g = sub { };
   f(); g(); # silence 'once' warnings without setting the bits
   my $exp = eval <<"   EXPECTED";
    sub {
     $code
    }
   EXPECTED
   if ($@) {
    fail "unable to compile expected code: $@";
    next;
   }
   $bd->coderef2text($exp);
  };

  is $deparsed, $expected, "deparsed <$code> is as expected";
 }
}

__DATA__
f();
####
f;
####
f(1);
####
f 1;
####
f(1, 2);
####
f 1, 2;
####
f(1); g(2);
####
f 1, f(2), 3, g(4, f(g, 5), 6);
####
&f;
####
&f();
####
&f(1);
####
&f(1, 2);
####
my $x = \&f;

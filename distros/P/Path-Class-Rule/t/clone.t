use 5.006;
use strict;
use warnings;
use autodie;
use Test::More 0.92;
use Path::Class;
use File::Temp;
use Test::Deep qw/cmp_deeply/;
use File::pushd qw/pushd/;

use lib 't/lib';
use PCNTest;

use Path::Class::Rule;

#--------------------------------------------------------------------------#

my @tree = qw(
  aaaa.txt
  bbbb.txt
  aaaabbbb.txt
);

my $td = make_tree(@tree);

sub test
{
  my ($name, $rule, $expected) = @_;

  my @got = sort map { $_->relative($td)->as_foreign("Unix")->stringify } $rule->all($td);

  local $Test::Builder::Level = $Test::Builder::Level + 1;

  cmp_deeply( \@got, $expected, $name)
    or diag explain { got => \@got, expected => $expected };
} # end test

{
  my $ruleA = Path::Class::Rule->new->file;
  my $ruleB = $ruleA->new->name("*bb*");
  $ruleA->name("*aa*");

  test('new *aa*', $ruleA => [qw/aaaa.txt aaaabbbb.txt/]);
  test('new *bb*', $ruleB => [qw/aaaabbbb.txt bbbb.txt/]);
}

{
  my $ruleA = Path::Class::Rule->new->file;
  my $ruleB = $ruleA->clone->name("*bb*");
  $ruleA->name("*aa*");

  test('cloned *aa*', $ruleA => [qw/aaaa.txt aaaabbbb.txt/]);
  test('cloned *bb*', $ruleB => [qw/aaaabbbb.txt bbbb.txt/]);
}

done_testing;

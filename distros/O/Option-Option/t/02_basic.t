use strict;
use warnings;
use Test::More tests=>2;

use File::Basename qw/dirname/;
use FindBin qw/$RealBin/;
use lib "$RealBin/../lib/perl5";

my $thisDir = dirname($0);

use_ok("Option::Option");

subtest 'scalars' => sub{
  my @str = (
    "Foo",
    "Bar",
  );

  for my $str(@str){
    my $opt = Option::Option->new($str);
    my $unwrapped = $opt->unwrap();
    is($str, $unwrapped, "Unwrap string $str");
  }

  my @int = (
    0,
    9,
    98,
    ~0,
    -4,
    -42,
  );

  for my $int(@int){
    my $opt = Option::Option->new($int);
    my $unwrapped = $opt->unwrap();
    is($int, $unwrapped, "Unwrap int $int");
  }
  
  my @f = (
    0.0,
    -0.6,
    -99.8,
    87.2,
    99.9,
  );

  for my $f(@f){
    my $opt = Option::Option->new($f);
    my $unwrapped = $opt->unwrap();
    is($f, $unwrapped, "Unwrap float $f");
  }
};


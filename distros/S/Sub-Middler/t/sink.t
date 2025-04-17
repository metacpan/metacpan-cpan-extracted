use Test::More;
use Sub::Middler;
use feature "say";

my @array;
my %hash;
my $scalar;
my @last;

local $"=";";
my $dispatch=linker 
  \@array,
  \%hash,
  \$scalar,
  \sub { $_*=2 for $_[0]->@*;},
  \@last;

say STDERR "DISPATCH IS : ", $dispatch;
my $i=2;

REPEAT:
$dispatch->([1,2,3,4,5], sub { goto REPEAT if $i--; say STDERR "DONE"});


say STDERR "Array: @array";
say STDERR "Hash: @{[%hash]}";
say STDERR "Scalar: $scalar";
say STDERR "Last @last";

ok 1;
done_testing;
1;

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



# array
my @exp=((1..5),(1..5), (1..5));
for(0..@array-1){
  ok $array[$i]==$exp[$i];
}

# hash has missing value for odd key.
#  called multipltimes doesnt matter as the keys are the same
ok $hash{1}==2;
ok $hash{3}==4;
ok exists $hash{5} and !defined $hash{5};

#scalar
say STDERR "Array: @array";
say STDERR "Hash: @{[%hash]}";
say STDERR "Scalar: $scalar";
say STDERR "Last @last";


# map

my @exp2=map {$_*2} @exp;
for(0..@exp2-1){
  ok $last[$_]=$exp2[$_];
}



# Check non consumption of input
my @input=(1,2,3,4);

$dispatch->(\@input);

ok @input==4;

done_testing;
1;

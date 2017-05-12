use Test::More;

BEGIN {
    use_ok 'Sort::HashKeys';
}

my %hash = (
    'all' => 1,
    'ball' => 2,
    'carrot' => 3,
    'show' => 4,
    'xylophone' => 5,
    'zoo' => 6,
);

my @sorted = Sort::HashKeys::sort(%hash); 

for (1..@sorted/2) {
    is $_, $sorted[2*$_-1];
}

done_testing;



use Test::More;

BEGIN {
    use_ok 'Sort::HashKeys';
}

my @arr = (
    'all' => 0,
    'ball' => 1,
    'carrot' => 2,
    'show' => 4,
    'xylophone' => 5,
    'zoo' => 6,
    'dipole'
);


is @arr, 13;

@sorted = Sort::HashKeys::sort(@arr); 

is @sorted, 14;

for (0..@sorted/2-2) {
    my ($k, $v) = @sorted[2*$_, 2*$_+1];
    if ($k eq 'dipole') {
        is $v, undef;
    } else {
        is $v, $_;
    }
}

done_testing;



